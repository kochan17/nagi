import AppKit
import CoreGraphics

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create CGContext")
    exit(1)
}

let rect = CGRect(x: 0, y: 0, width: size, height: size)
let center = CGPoint(x: size / 2, y: size / 2)
let radius = CGFloat(size) / 2.0

// --- Background: deep dark purple to black radial gradient ---
let bgColors: [CGFloat] = [
    0.04, 0.00, 0.08, 1.0,  // #0a0014 at center
    0.00, 0.00, 0.00, 1.0   // #000000 at edge
]
let bgLocations: [CGFloat] = [0.0, 1.0]
guard let bgGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: bgColors,
    locations: bgLocations,
    count: 2
) else { exit(1) }

context.drawRadialGradient(
    bgGradient,
    startCenter: center,
    startRadius: 0,
    endCenter: center,
    endRadius: radius * 1.42,
    options: [.drawsAfterEndLocation]
)

// --- Outer cyan glow ring (large, very soft) ---
let cyanGlowColors: [CGFloat] = [
    0.00, 1.00, 1.00, 0.0,   // transparent at center
    0.00, 1.00, 1.00, 0.0,   // still transparent
    0.00, 0.85, 0.90, 0.18,  // soft cyan peak
    0.00, 0.70, 0.80, 0.0    // fade out
]
let cyanGlowLocations: [CGFloat] = [0.0, 0.38, 0.52, 1.0]
guard let cyanGlowGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: cyanGlowColors,
    locations: cyanGlowLocations,
    count: 4
) else { exit(1) }

context.drawRadialGradient(
    cyanGlowGradient,
    startCenter: center,
    startRadius: 0,
    endCenter: center,
    endRadius: radius * 0.85,
    options: []
)

// --- Magenta orb glow (wide bloom) ---
let bloomColors: [CGFloat] = [
    1.00, 0.08, 0.58, 0.55,  // #FF1493 at center
    0.75, 0.02, 0.42, 0.30,  // mid pink
    0.40, 0.00, 0.25, 0.08,  // dark edge
    0.00, 0.00, 0.00, 0.0    // transparent
]
let bloomLocations: [CGFloat] = [0.0, 0.22, 0.50, 1.0]
guard let bloomGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: bloomColors,
    locations: bloomLocations,
    count: 4
) else { exit(1) }

context.drawRadialGradient(
    bloomGradient,
    startCenter: center,
    startRadius: 0,
    endCenter: center,
    endRadius: radius * 0.62,
    options: []
)

// --- Core orb: bright magenta center ---
let orbColors: [CGFloat] = [
    1.00, 0.80, 0.95, 1.0,  // near-white pink highlight
    1.00, 0.08, 0.58, 1.0,  // #FF1493 magenta
    0.70, 0.00, 0.40, 0.85, // deep magenta
    0.00, 0.00, 0.00, 0.0   // transparent
]
let orbLocations: [CGFloat] = [0.0, 0.18, 0.55, 1.0]
guard let orbGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: orbColors,
    locations: orbLocations,
    count: 4
) else { exit(1) }

context.drawRadialGradient(
    orbGradient,
    startCenter: CGPoint(x: center.x - 18, y: center.y + 18),
    startRadius: 0,
    endCenter: center,
    endRadius: radius * 0.28,
    options: []
)

// --- Cyan edge highlight (top-left of orb) ---
let highlightColors: [CGFloat] = [
    0.00, 1.00, 1.00, 0.55,  // bright cyan
    0.00, 0.80, 0.90, 0.0    // transparent
]
let highlightLocations: [CGFloat] = [0.0, 1.0]
guard let highlightGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: highlightColors,
    locations: highlightLocations,
    count: 2
) else { exit(1) }

let highlightCenter = CGPoint(x: center.x - 55, y: center.y + 60)
context.drawRadialGradient(
    highlightGradient,
    startCenter: highlightCenter,
    startRadius: 0,
    endCenter: highlightCenter,
    endRadius: radius * 0.20,
    options: []
)

// --- Subtle inner specular (tiny white glint) ---
let specularColors: [CGFloat] = [
    1.00, 1.00, 1.00, 0.80,
    1.00, 1.00, 1.00, 0.0
]
let specularLocations: [CGFloat] = [0.0, 1.0]
guard let specularGradient = CGGradient(
    colorSpace: colorSpace,
    colorComponents: specularColors,
    locations: specularLocations,
    count: 2
) else { exit(1) }

let specularCenter = CGPoint(x: center.x - 28, y: center.y + 34)
context.drawRadialGradient(
    specularGradient,
    startCenter: specularCenter,
    startRadius: 0,
    endCenter: specularCenter,
    endRadius: radius * 0.055,
    options: []
)

// --- Export PNG ---
guard let cgImage = context.makeImage() else {
    print("Failed to create CGImage")
    exit(1)
}

let outputPath = "/Users/kotaishida/projects/personal/nagi/nagi/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
let url = URL(fileURLWithPath: outputPath)
let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

do {
    try pngData.write(to: url)
    print("Saved: \(outputPath)")
} catch {
    print("Write error: \(error)")
    exit(1)
}
