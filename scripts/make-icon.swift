// Renders the app icon (night sky, crescent moon, glowing terminal prompt) into Resources/AppIcon.icns.
// Usage: swift scripts/make-icon.swift   (run from the project root)
import AppKit

let size = 1024
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: colors as CFArray, locations: nil)!
}

// macOS icon grid: 824pt body centered on a 1024 canvas.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let squircle = CGPath(roundedRect: body, cornerWidth: 186, cornerHeight: 186, transform: nil)

// Drop shadow + background.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.45))
ctx.addPath(squircle); ctx.setFillColor(rgb(0x120F33)); ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(squircle); ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0x3A2380), rgb(0x1A1650), rgb(0x080B24)]),
                       start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Stars.
let stars: [(CGFloat, CGFloat, CGFloat)] = [
    (230, 820, 7), (330, 720, 4), (180, 640, 5), (450, 860, 4), (820, 330, 5),
    (760, 220, 4), (300, 480, 3), (880, 520, 3), (520, 760, 3), (640, 180, 3),
]
for (x, y, r) in stars {
    ctx.setFillColor(rgb(0xFFFFFF, 0.85))
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
}

// Moon glow.
let moonCenter = CGPoint(x: 640, y: 650), moonR: CGFloat = 190
ctx.drawRadialGradient(gradient([rgb(0xFFC86B, 0.35), rgb(0xFFC86B, 0)]),
                       startCenter: moonCenter, startRadius: moonR * 0.8,
                       endCenter: moonCenter, endRadius: moonR * 1.9, options: [])

// Crescent: moon disc minus an offset disc.
ctx.saveGState()
let moonRect = CGRect(x: moonCenter.x - moonR, y: moonCenter.y - moonR, width: moonR * 2, height: moonR * 2)
ctx.addEllipse(in: moonRect); ctx.clip()
ctx.addRect(body)
ctx.addEllipse(in: moonRect.offsetBy(dx: -95, dy: 70).insetBy(dx: 8, dy: 8))
ctx.clip(using: .evenOdd)
ctx.drawLinearGradient(gradient([rgb(0xFFE7A8), rgb(0xFFB547)]),
                       start: CGPoint(x: moonRect.minX, y: moonRect.maxY),
                       end: CGPoint(x: moonRect.maxX, y: moonRect.minY), options: [])
ctx.restoreGState()

// Terminal prompt ">_" with glow — the agent that keeps working at night.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 40, color: rgb(0x5CF2C2, 0.9))
ctx.setStrokeColor(rgb(0x7CF7D0))
ctx.setLineWidth(58); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: 245, y: 430))
ctx.addLine(to: CGPoint(x: 380, y: 330))
ctx.addLine(to: CGPoint(x: 245, y: 230))
ctx.strokePath()
ctx.setFillColor(rgb(0x7CF7D0))
ctx.addPath(CGPath(roundedRect: CGRect(x: 430, y: 202, width: 190, height: 56), cornerWidth: 28, cornerHeight: 28, transform: nil))
ctx.fillPath()
ctx.restoreGState()

// Subtle top highlight.
ctx.drawLinearGradient(gradient([rgb(0xFFFFFF, 0.10), rgb(0xFFFFFF, 0)]),
                       start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 640), options: [])
ctx.restoreGState()

// Write iconset and convert.
let master = NSBitmapImageRep(cgImage: ctx.makeImage()!)
let iconset = URL(fileURLWithPath: "build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try! master.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "build/AppIcon-1024.png"))

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        NSImage(cgImage: master.cgImage!, size: NSSize(width: size, height: size))
            .draw(in: NSRect(x: 0, y: 0, width: px, height: px))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! p.run(); p.waitUntilExit()
print(p.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
