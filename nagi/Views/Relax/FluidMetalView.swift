import SwiftUI
import MetalKit

struct FluidMetalView: UIViewRepresentable {
    @Binding var touchLocation: CGPoint?
    @Binding var previousTouchLocation: CGPoint?
    @Binding var isTouching: Bool
    var textureType: TextureType

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.delegate = context.coordinator

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator

        if let touch = touchLocation {
            let viewSize = uiView.bounds.size
            guard viewSize.width > 0, viewSize.height > 0 else { return }

            let simW = Float(coordinator.simWidth)
            let simH = Float(coordinator.simHeight)

            coordinator.touchPosition = SIMD2<Float>(
                Float(touch.x / viewSize.width) * simW,
                Float(touch.y / viewSize.height) * simH
            )

            if let prev = previousTouchLocation {
                coordinator.touchVelocity = SIMD2<Float>(
                    Float((touch.x - prev.x) / viewSize.width) * simW * 8.0,
                    Float((touch.y - prev.y) / viewSize.height) * simH * 8.0
                )
            }
        }
        coordinator.isTouching = isTouching

        // Switch texture type if changed
        if coordinator.currentTextureType != textureType {
            coordinator.switchTexture(to: textureType)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(textureType: textureType)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var simulation: FluidSimulation?
        var touchPosition: SIMD2<Float> = .zero
        var touchVelocity: SIMD2<Float> = .zero
        var isTouching = false

        var simWidth: Int = 256
        var simHeight: Int = 256
        var currentTextureType: TextureType

        private var blitPipelineState: MTLRenderPipelineState?
        private var commandQueue: MTLCommandQueue?
        private var hasSetup = false

        // Standalone render pipeline (for non-fluid textures)
        private var standaloneRenderPipeline: MTLComputePipelineState?
        private var standaloneOutputTexture: MTLTexture?
        private var materialTexture: MTLTexture?
        private var loadedMaterialName: String?
        private var uniformBuffer: MTLBuffer?
        private var uniforms = FluidUniforms(
            resolution: .zero,
            touch: .zero,
            touchVelocity: .zero,
            touchActive: 0,
            dt: 1.0 / 60.0,
            viscosity: 0.0001,
            diffusion: 0.0001,
            time: 0
        )

        init(textureType: TextureType) {
            self.currentTextureType = textureType
            super.init()
        }

        func switchTexture(to type: TextureType) {
            currentTextureType = type
            standaloneRenderPipeline = nil
            // Will be recreated on next draw
        }

        private func loadMaterialTextureIfNeeded(device: MTLDevice, name: String) {
            if loadedMaterialName == name, materialTexture != nil { return }
            let loader = MTKTextureLoader(device: device)
            guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else {
                materialTexture = nil
                loadedMaterialName = nil
                return
            }
            let options: [MTKTextureLoader.Option: Any] = [
                .SRGB: false,
                .generateMipmaps: true,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue)
            ]
            do {
                materialTexture = try loader.newTexture(URL: url, options: options)
                loadedMaterialName = name
            } catch {
                print("Failed to load material texture \(name): \(error)")
                materialTexture = nil
                loadedMaterialName = nil
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            guard let device = view.device else { return }
            setupIfNeeded(device: device, drawableSize: size)
        }

        func draw(in view: MTKView) {
            guard let device = view.device else { return }

            let drawableSize = view.drawableSize
            if !hasSetup {
                setupIfNeeded(device: device, drawableSize: drawableSize)
            }

            guard let commandQueue,
                  let drawable = view.currentDrawable,
                  let renderPassDesc = view.currentRenderPassDescriptor else { return }

            if currentTextureType.needsFluidSim {
                drawFluid(device: device, drawable: drawable, renderPassDesc: renderPassDesc)
            } else {
                drawStandalone(device: device, drawable: drawable, renderPassDesc: renderPassDesc)
            }
        }

        // MARK: - Fluid simulation path

        private func drawFluid(device: MTLDevice, drawable: CAMetalDrawable, renderPassDesc: MTLRenderPassDescriptor) {
            guard let simulation, let commandQueue, let blitPipeline = blitPipelineState else { return }

            simulation.uniforms.touch = touchPosition
            simulation.uniforms.touchVelocity = touchVelocity
            simulation.uniforms.touchActive = isTouching ? 1.0 : 0.0

            guard let outputTexture = simulation.step() else { return }
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc)
            renderEncoder?.setRenderPipelineState(blitPipeline)
            renderEncoder?.setFragmentTexture(outputTexture, index: 0)
            renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder?.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()

            touchVelocity *= 0.9
        }

        // MARK: - Standalone shader path (kaleidoscope, orbs, particles, slime, waves)

        private func drawStandalone(device: MTLDevice, drawable: CAMetalDrawable, renderPassDesc: MTLRenderPassDescriptor) {
            guard let commandQueue, let blitPipeline = blitPipelineState else { return }

            // Lazily create standalone pipeline
            if standaloneRenderPipeline == nil {
                guard let library = device.makeDefaultLibrary(),
                      let function = library.makeFunction(name: currentTextureType.kernelName) else { return }
                standaloneRenderPipeline = try? device.makeComputePipelineState(function: function)
            }

            // Lazily create output texture
            if standaloneOutputTexture == nil {
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .bgra8Unorm,
                    width: simWidth,
                    height: simHeight,
                    mipmapped: false
                )
                desc.usage = [.shaderRead, .shaderWrite]
                desc.storageMode = .shared
                standaloneOutputTexture = device.makeTexture(descriptor: desc)
            }

            // Create/update uniform buffer
            if uniformBuffer == nil {
                uniformBuffer = device.makeBuffer(length: MemoryLayout<FluidUniforms>.stride, options: .storageModeShared)
            }

            uniforms.resolution = SIMD2<Float>(Float(simWidth), Float(simHeight))
            uniforms.touch = touchPosition
            uniforms.touchVelocity = touchVelocity
            uniforms.touchActive = isTouching ? 1.0 : 0.0
            uniforms.time += uniforms.dt
            uniformBuffer?.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<FluidUniforms>.stride)

            guard let pipeline = standaloneRenderPipeline,
                  let outputTexture = standaloneOutputTexture,
                  let uniformBuf = uniformBuffer,
                  let commandBuffer = commandQueue.makeCommandBuffer() else { return }

            // Load material texture if this texture type needs one
            if let materialName = currentTextureType.materialTextureName {
                loadMaterialTextureIfNeeded(device: device, name: materialName)
            }

            // Dispatch compute shader
            let computeEncoder = commandBuffer.makeComputeCommandEncoder()
            computeEncoder?.setComputePipelineState(pipeline)
            computeEncoder?.setTexture(outputTexture, index: 0)
            if let materialTexture {
                computeEncoder?.setTexture(materialTexture, index: 2)
            }
            computeEncoder?.setBuffer(uniformBuf, offset: 0, index: 0)

            let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
            let threadgroups = MTLSize(
                width: (simWidth + 15) / 16,
                height: (simHeight + 15) / 16,
                depth: 1
            )
            computeEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
            computeEncoder?.endEncoding()

            // Blit to screen
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc)
            renderEncoder?.setRenderPipelineState(blitPipeline)
            renderEncoder?.setFragmentTexture(outputTexture, index: 0)
            renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder?.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()

            touchVelocity *= 0.9
        }

        // MARK: - Setup

        private func setupIfNeeded(device: MTLDevice, drawableSize: CGSize) {
            guard !hasSetup || simulation == nil else { return }

            simWidth = max(Int(drawableSize.width) / 3, 128)
            simHeight = max(Int(drawableSize.height) / 3, 128)

            do {
                simulation = try FluidSimulation(device: device, width: simWidth, height: simHeight)
            } catch {
                print("FluidSimulation init failed: \(error)")
            }

            commandQueue = device.makeCommandQueue()

            guard let library = device.makeDefaultLibrary(),
                  let vertFunc = library.makeFunction(name: "blit_vertex"),
                  let fragFunc = library.makeFunction(name: "blit_fragment") else { return }

            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = vertFunc
            pipelineDesc.fragmentFunction = fragFunc
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

            blitPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDesc)
            hasSetup = true
        }
    }
}
