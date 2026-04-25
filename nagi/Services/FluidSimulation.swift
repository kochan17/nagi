import Foundation
import Metal
import MetalKit
import simd

// MARK: - Fluid simulation parameters passed to GPU

struct FluidUniforms {
    var resolution: SIMD2<Float>
    var touch: SIMD2<Float>
    var touchVelocity: SIMD2<Float>
    var touchActive: Float
    var dt: Float
    var viscosity: Float
    var diffusion: Float
    var time: Float
    var tint: SIMD3<Float> = SIMD3<Float>(1, 1, 1) // color tint multiplier; white = no tint
}

// MARK: - Metal-based 2D Fluid Simulation (Navier-Stokes)

final class FluidSimulation {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    // Compute pipelines
    private let advectPipeline: MTLComputePipelineState
    private let diffusePipeline: MTLComputePipelineState
    private let divergencePipeline: MTLComputePipelineState
    private let pressurePipeline: MTLComputePipelineState
    private let gradientSubtractPipeline: MTLComputePipelineState
    private let addForcePipeline: MTLComputePipelineState
    private let renderPipeline: MTLComputePipelineState

    // Textures (ping-pong buffers)
    private var velocityTexture0: MTLTexture
    private var velocityTexture1: MTLTexture
    private var dyeTexture0: MTLTexture
    private var dyeTexture1: MTLTexture
    private var pressureTexture0: MTLTexture
    private var pressureTexture1: MTLTexture
    private var divergenceTexture: MTLTexture
    private var outputTexture: MTLTexture

    private let simWidth: Int
    private let simHeight: Int
    private var uniformBuffer: MTLBuffer

    var uniforms = FluidUniforms(
        resolution: .zero,
        touch: .zero,
        touchVelocity: .zero,
        touchActive: 0,
        dt: 1.0 / 60.0,
        viscosity: 0.0001,
        diffusion: 0.0001,
        time: 0
    )

    init(device: MTLDevice, width: Int, height: Int) throws {
        self.device = device
        self.simWidth = width
        self.simHeight = height

        guard let queue = device.makeCommandQueue() else {
            throw FluidError.noCommandQueue
        }
        self.commandQueue = queue

        // Load shader library
        guard let lib = device.makeDefaultLibrary() else {
            throw FluidError.noLibrary
        }
        self.library = lib

        // Create compute pipelines
        advectPipeline = try Self.makePipeline(lib, "advect", device)
        diffusePipeline = try Self.makePipeline(lib, "diffuse", device)
        divergencePipeline = try Self.makePipeline(lib, "divergence", device)
        pressurePipeline = try Self.makePipeline(lib, "pressure_solve", device)
        gradientSubtractPipeline = try Self.makePipeline(lib, "gradient_subtract", device)
        addForcePipeline = try Self.makePipeline(lib, "add_force", device)
        renderPipeline = try Self.makePipeline(lib, "fluid_render", device)

        // Create textures
        let float2Desc = Self.textureDescriptor(width: width, height: height, format: .rg32Float)
        let float4Desc = Self.textureDescriptor(width: width, height: height, format: .rgba32Float)
        let float1Desc = Self.textureDescriptor(width: width, height: height, format: .r32Float)
        let outputDesc = Self.textureDescriptor(width: width, height: height, format: .bgra8Unorm, shared: true)

        guard
            let v0 = device.makeTexture(descriptor: float2Desc),
            let v1 = device.makeTexture(descriptor: float2Desc),
            let d0 = device.makeTexture(descriptor: float4Desc),
            let d1 = device.makeTexture(descriptor: float4Desc),
            let p0 = device.makeTexture(descriptor: float1Desc),
            let p1 = device.makeTexture(descriptor: float1Desc),
            let div = device.makeTexture(descriptor: float1Desc),
            let out = device.makeTexture(descriptor: outputDesc)
        else {
            throw FluidError.textureCreationFailed
        }

        velocityTexture0 = v0
        velocityTexture1 = v1
        dyeTexture0 = d0
        dyeTexture1 = d1
        pressureTexture0 = p0
        pressureTexture1 = p1
        divergenceTexture = div
        outputTexture = out

        uniforms.resolution = SIMD2<Float>(Float(width), Float(height))

        guard let buf = device.makeBuffer(length: MemoryLayout<FluidUniforms>.stride, options: .storageModeShared) else {
            throw FluidError.bufferCreationFailed
        }
        uniformBuffer = buf
    }

    func step() -> MTLTexture? {
        uniforms.time += uniforms.dt
        uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<FluidUniforms>.stride)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }

        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (simWidth + 15) / 16,
            height: (simHeight + 15) / 16,
            depth: 1
        )

        // 1. Add force (touch input → velocity + dye)
        encode(commandBuffer, addForcePipeline, threadgroups, threadgroupSize) { encoder in
            encoder.setTexture(velocityTexture0, index: 0)
            encoder.setTexture(velocityTexture1, index: 1)
            encoder.setTexture(dyeTexture0, index: 2)
            encoder.setTexture(dyeTexture1, index: 3)
            encoder.setBuffer(uniformBuffer, offset: 0, index: 0)
        }
        swap(&velocityTexture0, &velocityTexture1)
        swap(&dyeTexture0, &dyeTexture1)

        // 2. Diffuse velocity
        for _ in 0..<20 {
            encode(commandBuffer, diffusePipeline, threadgroups, threadgroupSize) { encoder in
                encoder.setTexture(velocityTexture0, index: 0)
                encoder.setTexture(velocityTexture1, index: 1)
                encoder.setBuffer(uniformBuffer, offset: 0, index: 0)
            }
            swap(&velocityTexture0, &velocityTexture1)
        }

        // 3. Compute divergence
        encode(commandBuffer, divergencePipeline, threadgroups, threadgroupSize) { encoder in
            encoder.setTexture(velocityTexture0, index: 0)
            encoder.setTexture(divergenceTexture, index: 1)
        }

        // 4. Pressure solve (Jacobi iteration)
        for _ in 0..<40 {
            encode(commandBuffer, pressurePipeline, threadgroups, threadgroupSize) { encoder in
                encoder.setTexture(pressureTexture0, index: 0)
                encoder.setTexture(pressureTexture1, index: 1)
                encoder.setTexture(divergenceTexture, index: 2)
            }
            swap(&pressureTexture0, &pressureTexture1)
        }

        // 5. Gradient subtract (make velocity divergence-free)
        encode(commandBuffer, gradientSubtractPipeline, threadgroups, threadgroupSize) { encoder in
            encoder.setTexture(velocityTexture0, index: 0)
            encoder.setTexture(velocityTexture1, index: 1)
            encoder.setTexture(pressureTexture0, index: 2)
        }
        swap(&velocityTexture0, &velocityTexture1)

        // 6. Advect velocity
        encode(commandBuffer, advectPipeline, threadgroups, threadgroupSize) { encoder in
            encoder.setTexture(velocityTexture0, index: 0)
            encoder.setTexture(velocityTexture1, index: 1)
            encoder.setBuffer(uniformBuffer, offset: 0, index: 0)
        }
        swap(&velocityTexture0, &velocityTexture1)

        // 7. Advect dye
        encode(commandBuffer, advectPipeline, threadgroups, threadgroupSize) { encoder in
            encoder.setTexture(dyeTexture0, index: 0)
            encoder.setTexture(dyeTexture1, index: 1)
            encoder.setBuffer(uniformBuffer, offset: 0, index: 0)
        }
        swap(&dyeTexture0, &dyeTexture1)

        // 8. Render to output
        encode(commandBuffer, renderPipeline, threadgroups, threadgroupSize) { encoder in
            encoder.setTexture(dyeTexture0, index: 0)
            encoder.setTexture(outputTexture, index: 1)
            encoder.setBuffer(uniformBuffer, offset: 0, index: 0)
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return outputTexture
    }

    // MARK: - Helpers

    private func encode(
        _ commandBuffer: MTLCommandBuffer,
        _ pipeline: MTLComputePipelineState,
        _ threadgroups: MTLSize,
        _ threadgroupSize: MTLSize,
        _ configure: (MTLComputeCommandEncoder) -> Void
    ) {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.setComputePipelineState(pipeline)
        configure(encoder)
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()
    }

    private static func makePipeline(_ library: MTLLibrary, _ name: String, _ device: MTLDevice) throws -> MTLComputePipelineState {
        guard let function = library.makeFunction(name: name) else {
            throw FluidError.functionNotFound(name)
        }
        return try device.makeComputePipelineState(function: function)
    }

    private static func textureDescriptor(width: Int, height: Int, format: MTLPixelFormat, shared: Bool = false) -> MTLTextureDescriptor {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: width, height: height, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        desc.storageMode = shared ? .shared : .private
        return desc
    }
}

enum FluidError: Error {
    case noCommandQueue
    case noLibrary
    case functionNotFound(String)
    case textureCreationFailed
    case bufferCreationFailed
}
