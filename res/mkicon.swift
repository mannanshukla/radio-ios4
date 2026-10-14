import AppKit
// App icon: a little tuner. Amber gradient, dark dial window with a red needle, two knobs, an antenna.
let a = CommandLine.arguments
func bitmap(_ w: Int, _ h: Int) -> NSBitmapImageRep { return NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)! }
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { return NSColor(calibratedRed: r/255, green: g/255, blue: b/255, alpha: 1) }
func icon(_ size: Int, _ path: String) {
    let rep = bitmap(size, size); NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(size), u = s / 100
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath { return NSBezierPath(roundedRect: NSRect(x: x * u, y: s - (y + h) * u, width: w * u, height: h * u), xRadius: r * u, yRadius: r * u) }
    func C(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> NSBezierPath { return NSBezierPath(ovalIn: NSRect(x: (cx - r) * u, y: s - (cy + r) * u, width: 2 * r * u, height: 2 * r * u)) }
    NSGradient(starting: rgb(252, 176, 64), ending: rgb(196, 98, 10))!.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)
    // antenna
    rgb(60, 40, 20).setStroke(); let ant = NSBezierPath(); ant.move(to: NSPoint(x: 70 * u, y: s - 34 * u)); ant.line(to: NSPoint(x: 88 * u, y: s - 10 * u)); ant.lineWidth = 3.5 * u; ant.lineCapStyle = .round; ant.stroke(); rgb(60, 40, 20).setFill(); C(88, 10, 3.5).fill()
    // body
    NSColor(white: 0, alpha: 0.18).setFill(); R(14, 36, 72, 50, 9).fill()
    rgb(250, 240, 220).setFill(); R(13, 33, 72, 50, 9).fill()
    // dial window
    rgb(28, 24, 18).setFill(); R(20, 40, 40, 22, 4).fill()
    rgb(255, 200, 90).setStroke(); let ticks = NSBezierPath(); for i in 0..<9 { let x = (24 + CGFloat(i) * 4) * u; ticks.move(to: NSPoint(x: x, y: s - 44 * u)); ticks.line(to: NSPoint(x: x, y: s - (i % 2 == 0 ? 49 : 47) * u)) }; ticks.lineWidth = 1.2 * u; ticks.stroke()
    rgb(230, 50, 40).setStroke(); let needle = NSBezierPath(); needle.move(to: NSPoint(x: 44 * u, y: s - 42 * u)); needle.line(to: NSPoint(x: 44 * u, y: s - 60 * u)); needle.lineWidth = 2 * u; needle.stroke()
    // speaker grille
    rgb(40, 32, 24).setFill(); for r in 0..<4 { for c in 0..<3 { C(67 + CGFloat(c) * 6, 44 + CGFloat(r) * 6, 2).fill() } }
    // knobs
    rgb(70, 50, 30).setFill(); C(28, 73, 6).fill(); C(46, 73, 6).fill(); rgb(250, 240, 220).setFill(); C(28, 73, 2).fill(); C(46, 73, 2).fill()
    rgb(200, 190, 170).setFill(); R(58, 70, 20, 6, 3).fill()
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
icon(57, a[1] + "/Icon.png"); icon(114, a[1] + "/Icon@2x.png"); icon(256, a[1] + "/Icon-preview.png"); print("icon ok")
