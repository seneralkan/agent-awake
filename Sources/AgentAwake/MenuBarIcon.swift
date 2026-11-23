import AppKit

/// Menu bar glyph matching the app icon: crescent moon, plus a `>_` prompt while sleep is blocked.
/// Template image, so macOS tints it for light/dark menu bars.
enum MenuBarIcon {
    static let awake = make(awake: true)
    static let idle = make(awake: false)

    static func make(awake: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            NSColor.black.set()

            // Crescent: moon disc clipped to everything outside an offset disc.
            let moon = awake ? NSRect(x: 8.5, y: 6.5, width: 10.5, height: 10.5)
                             : NSRect(x: 3.5, y: 2, width: 14, height: 14)
            let cut = moon.offsetBy(dx: -moon.width * 0.36, dy: moon.height * 0.26).insetBy(dx: 0.4, dy: 0.4)
            NSGraphicsContext.saveGraphicsState()
            let mask = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 20, height: 18))
            mask.append(NSBezierPath(ovalIn: cut))
            mask.windingRule = .evenOdd
            mask.addClip()
            NSBezierPath(ovalIn: moon).fill()
            NSGraphicsContext.restoreGraphicsState()

            if awake {
                let chevron = NSBezierPath()
                chevron.move(to: NSPoint(x: 1.8, y: 10))
                chevron.line(to: NSPoint(x: 5.6, y: 6.8))
                chevron.line(to: NSPoint(x: 1.8, y: 3.6))
                chevron.lineWidth = 1.9
                chevron.lineCapStyle = .round
                chevron.lineJoinStyle = .round
                chevron.stroke()
                NSBezierPath(roundedRect: NSRect(x: 7.6, y: 2.7, width: 5.4, height: 1.9), xRadius: 0.95, yRadius: 0.95).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
