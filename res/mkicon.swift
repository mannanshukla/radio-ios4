import AppKit
// App icon: monochrome white radio glyph on deep blue.
let a = CommandLine.arguments
func bitmap(_ w: Int, _ h: Int) -> NSBitmapImageRep { return NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)! }
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { return NSColor(calibratedRed: r/255, green: g/255, blue: b/255, alpha: 1) }
func icon(_ size: Int, _ path: String) {
    let rep = bitmap(size, size); NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(size), u = s / 100
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath { return NSBezierPath(roundedRect: NSRect(x: x * u, y: s - (y + h) * u, width: w * u, height: h * u), xRadius: r * u, yRadius: r * u) }
    func C(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> NSBezierPath { return NSBezierPath(ovalIn: NSRect(x: (cx - r) * u, y: s - (cy + r) * u, width: 2 * r * u, height: 2 * r * u)) }
    let bg0 = rgb(52, 92, 150), bg1 = rgb(24, 52, 96)
    NSGradient(starting: bg0, ending: bg1)!.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)
    let mid = rgb(36, 70, 120)
    // antenna
    NSColor.white.setStroke(); let ant = NSBezierPath(); ant.move(to: NSPoint(x: 62 * u, y: s - 36 * u)); ant.line(to: NSPoint(x: 86 * u, y: s - 12 * u)); ant.lineWidth = 5 * u; ant.lineCapStyle = .round; ant.stroke()
    // body with shadow
    NSColor(white: 0, alpha: 0.22).setFill(); R(14, 37, 72, 50, 10).fill()
    NSColor.white.setFill(); R(14, 34, 72, 50, 10).fill()
    // cut-outs: speaker and dial, in the background blue
    mid.setFill(); C(34, 59, 13).fill(); R(56, 48, 22, 7, 3.5).fill(); R(56, 60, 22, 7, 3.5).fill()
    NSColor.white.setFill(); C(34, 59, 5).fill()
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
icon(57, a[1] + "/Icon.png"); icon(114, a[1] + "/Icon@2x.png"); icon(256, a[1] + "/Icon-preview.png"); print("icon ok")
