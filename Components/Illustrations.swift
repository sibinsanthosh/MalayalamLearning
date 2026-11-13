import SwiftUI

// Hand-drawn (in code) animated artwork: no image files, no licences needed.
// Every piece pauses its animation when Reduce Motion is on.

// MARK: - Appu the elephant

/// Appu, the app's elephant friend, drawn with shapes. Blinks, flaps ears and sways trunk.
struct AppuView: View {
    var mood: MascotMood = .idle
    /// Extra lift for a wave of the trunk (e.g. when tapped).
    var waving = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let skin = Color(hex: "9DB6DD")
    private let skinDark = Color(hex: "7F9CC9")
    private let earInner = Color(hex: "F7B3C9")
    private let eye = Color(hex: "2E2A4F")

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let s = min(size.width, size.height) / 100
                ctx.translateBy(x: (size.width - 100 * s) / 2, y: (size.height - 100 * s) / 2)
                ctx.scaleBy(x: s, y: s)
                draw(&ctx, t: t)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, t: Double) {
        let flap = sin(t * 2.2) * 5
        let sway = sin(t * 1.6) * 6 + (waving ? sin(t * 9) * 14 - 18 : 0)
        let blinking = (t.truncatingRemainder(dividingBy: 4.2)) > 4.05
        let breathe = 1 + sin(t * 2) * 0.012

        // Body and feet
        ctx.fill(Path(ellipseIn: CGRect(x: 27, y: 66, width: 46, height: 30)), with: .color(skinDark))
        for x in [33.0, 55.0] {
            let foot = Path(roundedRect: CGRect(x: x, y: 84, width: 13, height: 12), cornerRadius: 5)
            ctx.fill(foot, with: .color(skinDark))
            for k in 0..<3 {
                ctx.fill(Path(ellipseIn: CGRect(x: x + 1.5 + Double(k) * 3.6, y: 92, width: 3, height: 2.4)),
                         with: .color(.white.opacity(0.85)))
            }
        }

        // Ears (behind the head), flapping
        for side in [-1.0, 1.0] {
            var ear = ctx
            ear.translateBy(x: 50 + side * 22, y: 40)
            ear.rotate(by: .degrees(side * (12 + flap)))
            ear.fill(Path(ellipseIn: CGRect(x: -17, y: -21, width: 34, height: 42)), with: .color(skin))
            ear.fill(Path(ellipseIn: CGRect(x: -11, y: -14, width: 22, height: 29)), with: .color(earInner))
        }

        // Head
        var head = ctx
        head.translateBy(x: 50, y: 42)
        head.scaleBy(x: breathe, y: breathe)
        let headRect = CGRect(x: -26, y: -24, width: 52, height: 48)
        head.fill(Path(ellipseIn: headRect),
                  with: .linearGradient(Gradient(colors: [Color(hex: "B6CBEA"), skin]),
                                        startPoint: CGPoint(x: 0, y: -24), endPoint: CGPoint(x: 0, y: 24)))
        // Little tuft of hair
        var tuft = Path()
        for dx in [-4.0, 0, 4] {
            tuft.move(to: CGPoint(x: dx, y: -23))
            tuft.addQuadCurve(to: CGPoint(x: dx * 1.6, y: -29), control: CGPoint(x: dx * 0.6 - 1.5, y: -27))
        }
        head.stroke(tuft, with: .color(skinDark), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Eyes
        for side in [-1.0, 1.0] {
            let c = CGPoint(x: side * 10, y: -3)
            switch (mood, blinking) {
            case (.happy, _), (.cheer, _):
                var arc = Path()
                arc.addArc(center: CGPoint(x: c.x, y: c.y + 2), radius: 4, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                head.stroke(arc, with: .color(eye), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            case (_, true):
                var line = Path()
                line.move(to: CGPoint(x: c.x - 3.5, y: c.y))
                line.addLine(to: CGPoint(x: c.x + 3.5, y: c.y))
                head.stroke(line, with: .color(eye), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            default:
                let big = mood == .oops ? 1.25 : 1
                head.fill(Path(ellipseIn: CGRect(x: c.x - 3.6 * big, y: c.y - 4.6 * big, width: 7.2 * big, height: 9.2 * big)),
                          with: .color(eye))
                head.fill(Path(ellipseIn: CGRect(x: c.x - 0.6, y: c.y - 3.4, width: 2.6, height: 2.6)), with: .color(.white))
            }
        }
        // Cheeks
        for side in [-1.0, 1.0] {
            head.fill(Path(ellipseIn: CGRect(x: side * 16 - 4.5, y: 6, width: 9, height: 5)), with: .color(earInner.opacity(0.75)))
        }
        // Mouth peeking beside the trunk
        var mouth = Path()
        if mood == .oops {
            mouth.addEllipse(in: CGRect(x: -12, y: 12, width: 5, height: 5))
            head.fill(mouth, with: .color(eye.opacity(0.8)))
        } else {
            mouth.addArc(center: CGPoint(x: -10, y: 11), radius: 4, startAngle: .degrees(20), endAngle: .degrees(150), clockwise: false)
            head.stroke(mouth, with: .color(eye.opacity(0.8)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }

        // Trunk, swaying from the middle of the face
        var trunkCtx = head
        trunkCtx.translateBy(x: 0, y: 6)
        trunkCtx.rotate(by: .degrees(sway))
        var trunk = Path()
        trunk.move(to: .zero)
        trunk.addCurve(to: CGPoint(x: 6, y: 26), control1: CGPoint(x: 0, y: 12), control2: CGPoint(x: -2, y: 22))
        trunk.addQuadCurve(to: CGPoint(x: 13, y: 20), control: CGPoint(x: 12, y: 28))
        trunkCtx.stroke(trunk, with: .color(skin), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        for k in 1...3 {
            var ring = Path()
            let y = Double(k) * 5.5
            ring.move(to: CGPoint(x: -3.5, y: y))
            ring.addLine(to: CGPoint(x: 2, y: y + 0.6))
            trunkCtx.stroke(ring, with: .color(skinDark.opacity(0.6)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
    }
}

// MARK: - Kerala backdrop

/// Animated sky, sun, drifting clouds, birds, hills, palm trees and a backwater boat.
struct KeralaScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in draw(&ctx, size: size, t: t) }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let w = size.width, h = size.height
        let night = scheme == .dark

        // Sky
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: night
                                                ? [Color(hex: "2B2D6E"), Color(hex: "5B4E9C")]
                                                : [Color(hex: "7FD3FF"), Color(hex: "D6F3FF")]),
                                       startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.55)))

        // Sun (or moon) with a friendly face
        let sunC = CGPoint(x: w - 70, y: 92)
        if night {
            ctx.fill(Path(ellipseIn: CGRect(x: sunC.x - 30, y: sunC.y - 30, width: 60, height: 60)), with: .color(Color(hex: "FFF3B0")))
            ctx.fill(Path(ellipseIn: CGRect(x: sunC.x - 16, y: sunC.y - 36, width: 56, height: 56)), with: .color(Color(hex: "2B2D6E")))
            for i in 0..<14 {
                let x = Double((i * 97) % Int(max(w, 1))), y = Double((i * 53) % 220) + 20
                let tw = 0.5 + 0.5 * sin(t * 2 + Double(i))
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)), with: .color(.white.opacity(tw)))
            }
        } else {
            var rays = ctx
            rays.translateBy(x: sunC.x, y: sunC.y)
            rays.rotate(by: .radians(t * 0.35))
            for i in 0..<12 {
                var ray = Path()
                let a = Double(i) / 12 * 2 * .pi
                let pulse = 6 * sin(t * 2 + Double(i))
                ray.move(to: CGPoint(x: cos(a) * 44, y: sin(a) * 44))
                ray.addLine(to: CGPoint(x: cos(a) * (60 + pulse), y: sin(a) * (60 + pulse)))
                rays.stroke(ray, with: .color(Color(hex: "FFC83D")), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: sunC.x - 36, y: sunC.y - 36, width: 72, height: 72)),
                     with: .radialGradient(Gradient(colors: [Color(hex: "FFE36E"), Color(hex: "FFC83D")]),
                                           center: sunC, startRadius: 4, endRadius: 40))
            for dx in [-11.0, 11.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: sunC.x + dx - 3, y: sunC.y - 9, width: 6, height: 8)), with: .color(Color(hex: "6B3E00")))
            }
            var smile = Path()
            smile.addArc(center: CGPoint(x: sunC.x, y: sunC.y + 2), radius: 13, startAngle: .degrees(25), endAngle: .degrees(155), clockwise: false)
            ctx.stroke(smile, with: .color(Color(hex: "6B3E00")), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            for dx in [-20.0, 20.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: sunC.x + dx - 6, y: sunC.y + 3, width: 12, height: 7)), with: .color(Color(hex: "FF9B71").opacity(0.7)))
            }
        }

        // Clouds drifting across
        let clouds: [(y: Double, scale: Double, speed: Double, offset: Double)] = [
            (60, 1.0, 14, 0), (150, 0.75, 9, 0.45), (230, 0.6, 18, 0.8)
        ]
        for c in clouds {
            let span = w + 260
            let x = (c.offset * span + t * c.speed).truncatingRemainder(dividingBy: span) - 130
            cloud(&ctx, at: CGPoint(x: x, y: c.y), scale: c.scale, night: night)
        }

        // Birds
        if !night {
            for i in 0..<3 {
                let span = w + 120
                let x = (Double(i) * 70 + t * 30).truncatingRemainder(dividingBy: span) - 60
                let y = 170 + Double(i) * 22 + sin(t * 1.5 + Double(i)) * 8
                let flap = sin(t * 8 + Double(i)) * 5
                var bird = Path()
                bird.move(to: CGPoint(x: x - 9, y: y - flap))
                bird.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 5, y: y - 5 - flap))
                bird.addQuadCurve(to: CGPoint(x: x + 9, y: y - flap), control: CGPoint(x: x + 5, y: y - 5 - flap))
                ctx.stroke(bird, with: .color(Color(hex: "3B2A5A").opacity(0.7)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }

        // Hills
        let horizon = max(h * 0.42, 300)
        var back = Path()
        back.move(to: CGPoint(x: 0, y: horizon))
        back.addCurve(to: CGPoint(x: w, y: horizon - 20),
                      control1: CGPoint(x: w * 0.3, y: horizon - 90), control2: CGPoint(x: w * 0.6, y: horizon + 30))
        back.addLine(to: CGPoint(x: w, y: h)); back.addLine(to: CGPoint(x: 0, y: h)); back.closeSubpath()
        ctx.fill(back, with: .color(night ? Color(hex: "2E6B47") : Color(hex: "8EDB7A")))
        var front = Path()
        front.move(to: CGPoint(x: 0, y: horizon + 60))
        front.addCurve(to: CGPoint(x: w, y: horizon + 30),
                       control1: CGPoint(x: w * 0.35, y: horizon + 10), control2: CGPoint(x: w * 0.7, y: horizon + 110))
        front.addLine(to: CGPoint(x: w, y: h)); front.addLine(to: CGPoint(x: 0, y: h)); front.closeSubpath()
        ctx.fill(front, with: .color(night ? Color(hex: "23573A") : Color(hex: "5DBB4F")))

        // Palm trees swaying
        palm(&ctx, base: CGPoint(x: 34, y: horizon + 70), height: 150, t: t, phase: 0, night: night)
        palm(&ctx, base: CGPoint(x: w - 40, y: horizon + 50), height: 120, t: t, phase: 1.3, night: night)

        // Backwater river with a little boat
        let riverY = horizon + 120
        var river = Path()
        river.move(to: CGPoint(x: 0, y: riverY))
        river.addCurve(to: CGPoint(x: w, y: riverY + 30),
                       control1: CGPoint(x: w * 0.4, y: riverY - 30), control2: CGPoint(x: w * 0.6, y: riverY + 60))
        river.addLine(to: CGPoint(x: w, y: h)); river.addLine(to: CGPoint(x: 0, y: h)); river.closeSubpath()
        ctx.fill(river, with: .linearGradient(Gradient(colors: night ? [Color(hex: "2C4F8F"), Color(hex: "1E3566")]
                                                                     : [Color(hex: "6CCDF5"), Color(hex: "3FA9E0")]),
                                               startPoint: CGPoint(x: 0, y: riverY), endPoint: CGPoint(x: 0, y: h)))
        for i in 0..<6 {
            let y = riverY + 40 + Double(i) * 34
            let x = (Double(i) * 90 + t * 20).truncatingRemainder(dividingBy: w + 80) - 40
            var wave = Path()
            wave.move(to: CGPoint(x: x, y: y))
            wave.addQuadCurve(to: CGPoint(x: x + 30, y: y), control: CGPoint(x: x + 15, y: y - 6))
            ctx.stroke(wave, with: .color(.white.opacity(0.45)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        let boatX = (t * 12).truncatingRemainder(dividingBy: w + 160) - 80
        boat(&ctx, at: CGPoint(x: boatX, y: riverY + 28 + sin(t * 2) * 3), tilt: sin(t * 2) * 3)
    }

    private func cloud(_ ctx: inout GraphicsContext, at p: CGPoint, scale s: Double, night: Bool) {
        let color = Color.white.opacity(night ? 0.25 : 0.95)
        for (dx, dy, r) in [(0.0, 0.0, 26.0), (26, -12, 30), (54, 0, 24), (28, 8, 26)] {
            ctx.fill(Path(ellipseIn: CGRect(x: p.x + dx * s - r * s, y: p.y + dy * s - r * s, width: 2 * r * s, height: 2 * r * s)),
                     with: .color(color))
        }
    }

    private func palm(_ ctx: inout GraphicsContext, base: CGPoint, height: Double, t: Double, phase: Double, night: Bool) {
        let sway = sin(t * 1.1 + phase) * 6
        let top = CGPoint(x: base.x + 18 + sway, y: base.y - height)
        var trunk = Path()
        trunk.move(to: base)
        trunk.addQuadCurve(to: top, control: CGPoint(x: base.x - 10, y: base.y - height * 0.55))
        ctx.stroke(trunk, with: .color(night ? Color(hex: "6B4A2B") : Color(hex: "A8743F")),
                   style: StrokeStyle(lineWidth: 11, lineCap: .round))
        let leaf = night ? Color(hex: "2F8A4E") : Color(hex: "2FAE5A")
        for i in 0..<6 {
            let a = Double(i) / 6 * 2 * .pi + sin(t * 1.3 + phase + Double(i)) * 0.08
            let len = 46.0
            let tip = CGPoint(x: top.x + cos(a) * len, y: top.y + sin(a) * len * 0.55 + 14)
            var l = Path()
            l.move(to: top)
            l.addQuadCurve(to: tip, control: CGPoint(x: top.x + cos(a) * len * 0.5, y: top.y - 18))
            ctx.stroke(l, with: .color(leaf), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        }
        for dx in [-5.0, 4.0] {
            ctx.fill(Path(ellipseIn: CGRect(x: top.x + dx - 4, y: top.y + 2, width: 9, height: 9)), with: .color(Color(hex: "7A4E1F")))
        }
    }

    private func boat(_ ctx: inout GraphicsContext, at p: CGPoint, tilt: Double) {
        var b = ctx
        b.translateBy(x: p.x, y: p.y)
        b.rotate(by: .degrees(tilt))
        var hull = Path()
        hull.move(to: CGPoint(x: -38, y: -6))
        hull.addQuadCurve(to: CGPoint(x: 38, y: -6), control: CGPoint(x: 0, y: 16))
        hull.closeSubpath()
        b.fill(hull, with: .color(Color(hex: "8B5A2B")))
        var roof = Path()
        roof.move(to: CGPoint(x: -18, y: -6))
        roof.addQuadCurve(to: CGPoint(x: 18, y: -6), control: CGPoint(x: 0, y: -30))
        b.fill(roof, with: .color(Color(hex: "E3B23C")))
    }
}

// MARK: - Tile pictures

/// Three wooden letter blocks; the top one wobbles.
struct LetterBlocksArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            ZStack {
                block("അ", color: DS.orange).offset(x: -26, y: 22)
                block("ക", color: DS.sky).offset(x: 26, y: 22)
                block("ആ", color: DS.pink)
                    .rotationEffect(.degrees(sin(t * 2.2) * 7))
                    .offset(y: -22 + sin(t * 2.2) * 2)
            }
        }
        .accessibilityHidden(true)
    }

    private func block(_ letter: String, color: Color) -> some View {
        Text(letter)
            .font(DS.display(26))
            .foregroundColor(.white)
            .frame(width: 48, height: 46)
            .background(RoundedRectangle(cornerRadius: 11).fill(color)
                .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: 4))
    }
}

/// A bunch of bobbing balloons.
struct BalloonsArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let s = min(size.width, size.height) / 100
                let tie = CGPoint(x: 50 * s, y: 96 * s)
                let balloons: [(x: Double, y: Double, c: Color, p: Double)] = [
                    (28, 34, DS.red, 0), (52, 24, DS.yellow, 1.1), (74, 38, DS.purple, 2.2)
                ]
                for b in balloons {
                    let bob = sin(t * 1.8 + b.p) * 4
                    let c = CGPoint(x: b.x * s, y: (b.y + bob) * s)
                    var string = Path()
                    string.move(to: CGPoint(x: c.x, y: c.y + 17 * s))
                    string.addQuadCurve(to: tie, control: CGPoint(x: c.x + sin(t + b.p) * 6 * s, y: (c.y + tie.y) / 2 + 10 * s))
                    ctx.stroke(string, with: .color(.white.opacity(0.9)), lineWidth: 1.4 * s)
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 14 * s, y: c.y - 17 * s, width: 28 * s, height: 34 * s)), with: .color(b.c))
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 8 * s, y: c.y - 11 * s, width: 6 * s, height: 10 * s)), with: .color(.white.opacity(0.45)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// An open storybook with a page turning and sparkles.
struct StoryBookArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let s = min(size.width, size.height) / 100
                ctx.translateBy(x: (size.width - 100 * s) / 2, y: (size.height - 100 * s) / 2)
                ctx.scaleBy(x: s, y: s)
                // Cover
                ctx.fill(Path(roundedRect: CGRect(x: 10, y: 34, width: 80, height: 52), cornerRadius: 8), with: .color(Color(hex: "7B3FA0")))
                // Pages
                var left = Path()
                left.move(to: CGPoint(x: 50, y: 40)); left.addQuadCurve(to: CGPoint(x: 14, y: 36), control: CGPoint(x: 32, y: 30))
                left.addLine(to: CGPoint(x: 14, y: 80)); left.addQuadCurve(to: CGPoint(x: 50, y: 84), control: CGPoint(x: 32, y: 76))
                left.closeSubpath()
                ctx.fill(left, with: .color(.white))
                var right = left
                right = right.applying(CGAffineTransform(translationX: 100, y: 0).scaledBy(x: -1, y: 1))
                ctx.fill(right, with: .color(Color(hex: "FFF8E8")))
                for k in 0..<3 {
                    var line = Path()
                    let y = 50 + Double(k) * 9
                    line.move(to: CGPoint(x: 21, y: y)); line.addLine(to: CGPoint(x: 43, y: y + 1))
                    ctx.stroke(line, with: .color(Color(hex: "C9B8E0")), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                }
                // Turning page
                let turn = (sin(t * 1.4) + 1) / 2
                var page = ctx
                page.translateBy(x: 50, y: 0)
                page.scaleBy(x: CGFloat(1 - 2 * turn), y: 1)
                var p = Path()
                p.move(to: CGPoint(x: 0, y: 40)); p.addQuadCurve(to: CGPoint(x: 34, y: 37), control: CGPoint(x: 18, y: 31))
                p.addLine(to: CGPoint(x: 34, y: 80)); p.addQuadCurve(to: CGPoint(x: 0, y: 84), control: CGPoint(x: 18, y: 76))
                p.closeSubpath()
                page.fill(p, with: .color(Color(hex: "FFEFD0")))
                // Sparkles
                for (i, pt) in [CGPoint(x: 20, y: 18), CGPoint(x: 50, y: 10), CGPoint(x: 80, y: 20)].enumerated() {
                    let r = 3 + 2.5 * (sin(t * 3 + Double(i) * 2) + 1)
                    var star = Path()
                    star.move(to: CGPoint(x: pt.x, y: pt.y - r)); star.addLine(to: CGPoint(x: pt.x, y: pt.y + r))
                    star.move(to: CGPoint(x: pt.x - r, y: pt.y)); star.addLine(to: CGPoint(x: pt.x + r, y: pt.y))
                    ctx.stroke(star, with: .color(DS.yellow), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// A word bubble with a magnifying glass gliding over it.
struct WordSearchArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
            ZStack {
                HStack(spacing: 4) {
                    Text("ആന").font(DS.display(24)).foregroundColor(DS.ink)
                    Text("·").font(DS.display(20)).foregroundColor(DS.inkSoft)
                    Text("Elephant").font(DS.font(.caption, weight: .heavy)).foregroundColor(DS.inkSoft)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                ZStack {
                    Circle().stroke(Color(hex: "3B2A5A"), lineWidth: 5).frame(width: 38, height: 38)
                    Circle().fill(.white.opacity(0.35)).frame(width: 33, height: 33)
                    Capsule().fill(Color(hex: "3B2A5A")).frame(width: 7, height: 22)
                        .rotationEffect(.degrees(-45)).offset(x: 20, y: 20)
                }
                .offset(x: cos(t * 1.2) * 34, y: sin(t * 2.4) * 8 - 6)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A pencil drawing a curly letter stroke, over and over.
struct PencilArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let t = reduceMotion ? 1 : (tl.date.timeIntervalSinceReferenceDate * 0.45).truncatingRemainder(dividingBy: 1.3)
            let progress = min(1, t)
            Canvas { ctx, size in
                let s = min(size.width, size.height) / 100
                ctx.translateBy(x: (size.width - 100 * s) / 2, y: (size.height - 100 * s) / 2)
                ctx.scaleBy(x: s, y: s)
                var curl = Path()
                curl.move(to: CGPoint(x: 18, y: 70))
                curl.addCurve(to: CGPoint(x: 50, y: 22), control1: CGPoint(x: 10, y: 40), control2: CGPoint(x: 30, y: 18))
                curl.addCurve(to: CGPoint(x: 62, y: 70), control1: CGPoint(x: 72, y: 26), control2: CGPoint(x: 76, y: 56))
                curl.addQuadCurve(to: CGPoint(x: 86, y: 74), control: CGPoint(x: 74, y: 82))
                ctx.stroke(curl, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 9, lineCap: .round, dash: [0.1, 14]))
                ctx.stroke(curl.trimmedPath(from: 0, to: progress), with: .color(.white),
                           style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                // Pencil at the tip of the line
                let tip = curl.trimmedPath(from: 0, to: max(0.001, progress)).currentPoint ?? CGPoint(x: 18, y: 70)
                var pencil = ctx
                pencil.translateBy(x: tip.x, y: tip.y)
                pencil.rotate(by: .degrees(-40))
                pencil.fill(Path(roundedRect: CGRect(x: -5, y: -44, width: 10, height: 34), cornerRadius: 3), with: .color(DS.yellow))
                pencil.fill(Path(CGRect(x: -5, y: -48, width: 10, height: 6)), with: .color(DS.pink))
                var nib = Path()
                nib.move(to: CGPoint(x: -5, y: -10)); nib.addLine(to: CGPoint(x: 5, y: -10)); nib.addLine(to: CGPoint(x: 0, y: 0)); nib.closeSubpath()
                pencil.fill(nib, with: .color(Color(hex: "F2D3A2")))
            }
        }
        .accessibilityHidden(true)
    }
}
