import AVFoundation
import SwiftUI
import UIKit

// Tracing board, session, sounds and haptics ported from the ABC Trace project.

// MARK: - Theme

enum TraceTheme {
    static let red = Color(hex: "F2655A")
    static let orange = Color(hex: "F6A04D")
    static let yellow = Color(hex: "F5C842")
    static let green = Color(hex: "5CC27A")
    static let blue = Color(hex: "5AA8F0")
    static let purple = Color(hex: "9C82F0")
    static let pink = Color(hex: "F27CB2")
    static let teal = Color(hex: "4CC4C0")

    static let rainbow: [Color] = [red, orange, yellow, green, teal, blue, purple, pink]

    static func color(for index: Int) -> Color { rainbow[abs(index) % rainbow.count] }

    static func kid(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// 3 = no slips, 2 = 1–2 slips, 1 = finished.
    static func stars(mistakes: Int) -> Int {
        switch mistakes {
        case 0: return 3
        case 1...2: return 2
        default: return 1
        }
    }
}

// MARK: - Feedback

/// System-synthesised sounds and haptics for tracing.
@MainActor
final class TraceFeedback {
    static let shared = TraceFeedback()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let notify = UINotificationFeedbackGenerator()

    var soundOn: Bool { ProgressStore.shared.settings.soundOn }
    var hapticsOn: Bool { ProgressStore.shared.settings.hapticsOn }

    func tick() {
        if soundOn { TraceSoundFX.shared.play(.tick) }
        if hapticsOn { light.impactOccurred(intensity: 0.5) }
    }

    func strokeDone() {
        if soundOn { TraceSoundFX.shared.play(.sparkle) }
        if hapticsOn { light.impactOccurred() }
    }

    func success() {
        if soundOn { TraceSoundFX.shared.play(.chime) }
        if hapticsOn { notify.notificationOccurred(.success) }
    }

    func oops() {
        if soundOn { TraceSoundFX.shared.play(.boing) }
        if hapticsOn { notify.notificationOccurred(.warning) }
    }

    func celebrate() {
        if soundOn { TraceSoundFX.shared.play(.tada) }
        if hapticsOn { notify.notificationOccurred(.success) }
    }
}

/// Small UI sounds synthesised on-device: no audio files.
@MainActor
final class TraceSoundFX {
    enum Effect: CaseIterable {
        case chime, sparkle, boing, tada, tick
    }

    static let shared = TraceSoundFX()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var started = false

    private init() {
        for _ in 0..<6 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.mainMixerNode.outputVolume = 0.32
        for effect in Effect.allCases { buffers[effect] = render(effect) }
    }

    func play(_ effect: Effect) {
        guard let buffer = buffers[effect] else { return }
        if !started || !engine.isRunning {
            do { try engine.start(); started = true } catch { return }
        }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    private func render(_ effect: Effect) -> AVAudioPCMBuffer {
        switch effect {
        case .tick:
            return synth(duration: 0.05) { t, _ in sin(2 * .pi * 1500 * t) * exp(-t * 90) * 0.6 }
        case .chime:
            return synth(duration: 0.6) { t, _ in
                (sin(2 * .pi * 1046.5 * t) + 0.6 * sin(2 * .pi * 1568 * t)) * exp(-t * 6) * 0.5
            }
        case .sparkle:
            return synth(duration: 0.45) { t, _ in
                let notes: [Double] = [1568, 2093, 2637, 3136]
                let i = min(notes.count - 1, Int(t / 0.08))
                let local = t - Double(i) * 0.08
                return sin(2 * .pi * notes[i] * t) * exp(-local * 30) * 0.45
            }
        case .boing:
            return synth(duration: 0.4) { t, _ in
                let f = 260 + 90 * sin(2 * .pi * 9 * t) * exp(-t * 4) - 120 * t
                return sin(2 * .pi * f * t) * exp(-t * 6) * 0.8
            }
        case .tada:
            return synth(duration: 1.0) { t, _ in
                let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
                let starts: [Double] = [0, 0.1, 0.2, 0.32]
                var v = 0.0
                for (n, s) in zip(notes, starts) where t >= s {
                    let local = t - s
                    v += (sin(2 * .pi * n * local) + 0.3 * sin(4 * .pi * n * local)) * exp(-local * 3.5)
                }
                return v * 0.28
            }
        }
    }

    private func synth(duration: Double, _ sample: (Double, Double) -> Double) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(duration * format.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let data = buffer.floatChannelData![0]
        let attack = 0.004 * format.sampleRate
        for i in 0..<Int(frames) {
            let t = Double(i) / format.sampleRate
            let fadeIn = min(1, Double(i) / attack)
            let fadeOut = min(1, Double(Int(frames) - i) / attack)
            data[i] = Float(max(-1, min(1, sample(t, duration) * fadeIn * fadeOut)))
        }
        return buffer
    }
}

// MARK: - Tracing session

@MainActor
final class TraceSession: ObservableObject {
    @Published private(set) var engine: TraceEngine
    @Published private(set) var finger: CGPoint?
    @Published private(set) var wobble = 0
    /// Times the finger left the path; used for stars.
    private(set) var mistakes = 0
    /// Recent finger positions for the sparkle trail.
    @Published private(set) var trail: [(point: CGPoint, time: Date)] = []
    /// Where and when the last stroke finished, for the little star pop.
    @Published private(set) var strokePops: [(point: CGPoint, time: Date)] = []

    var onComplete: (Int) -> Void = { _ in }
    var onEvent: (TraceEngine.Event) -> Void = { _ in }
    var onProgress: (Double) -> Void = { _ in }

    init(glyph: TraceGlyph) {
        engine = TraceEngine(strokes: glyph.strokes)
    }

    func touch(_ p: CGPoint, began: Bool) {
        guard !engine.isComplete else { return }
        finger = p
        let now = Date()
        trail.append((p, now))
        trail.removeAll { now.timeIntervalSince($0.time) > 0.45 }
        let progressPoint = engine.currentStroke?.last
        let event = began ? engine.touchBegan(at: p) : engine.touchMoved(to: p)
        if event != .none { onEvent(event) }
        switch event {
        case .strokeDone:
            TraceFeedback.shared.strokeDone()
            if let end = progressPoint { strokePops.append((end, now)) }
        case .glyphDone:
            finger = nil
            if let end = progressPoint { strokePops.append((end, now)) }
            onComplete(mistakes)
        case .offPath:
            TraceFeedback.shared.oops()
            mistakes += 1
            wobble += 1
        case .started:
            TraceFeedback.shared.tick()
        case .advanced, .none:
            break
        }
        if event != .none { onProgress(engine.fractionComplete) }
    }

    func release() {
        engine.touchEnded()
        finger = nil
    }
}

// MARK: - Tracing board

struct TracingBoard: View {
    let glyph: TraceGlyph
    let color: Color
    let showHints: Bool
    /// Guided shows the full road, arrows and demo finger; faded shows only a faint road.
    var mode: TraceMode = .guided
    var onEvent: (TraceEngine.Event) -> Void = { _ in }
    var onProgress: (Double) -> Void = { _ in }
    let onComplete: (Int) -> Void

    @StateObject private var session: TraceSession
    @State private var demoStart = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(glyph: TraceGlyph, color: Color, showHints: Bool = true, mode: TraceMode = .guided,
         onEvent: @escaping (TraceEngine.Event) -> Void = { _ in },
         onProgress: @escaping (Double) -> Void = { _ in },
         onComplete: @escaping (Int) -> Void) {
        self.glyph = glyph
        self.color = color
        self.showHints = showHints
        self.mode = mode
        self.onEvent = onEvent
        self.onProgress = onProgress
        self.onComplete = onComplete
        _session = StateObject(wrappedValue: TraceSession(glyph: glyph))
    }

    var body: some View {
        GeometryReader { geo in
            let width = glyph.designWidth
            let scale = min(geo.size.width / width, geo.size.height / 100)
            TimelineView(.animation(paused: reduceMotion && session.finger == nil)) { timeline in
                Canvas { ctx, _ in
                    draw(in: &ctx, scale: scale, time: timeline.date.timeIntervalSince(demoStart), now: timeline.date)
                }
            }
            .frame(width: width * scale, height: 100 * scale)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = CGPoint(x: value.location.x / scale, y: value.location.y / scale)
                        session.touch(p, began: session.finger == nil)
                    }
                    .onEnded { _ in
                        session.release()
                        demoStart = Date()
                    }
            )
            .modifier(Jelly(animatableData: CGFloat(session.wobble)))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: session.wobble)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            session.onComplete = onComplete
            session.onEvent = onEvent
            session.onProgress = onProgress
            demoStart = Date()
        }
    }

    // MARK: Drawing

    private func draw(in ctx: inout GraphicsContext, scale s: CGFloat, time: TimeInterval, now: Date) {
        let engine = session.engine
        func m(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * s, y: p.y * s) }
        func path(_ pts: some Collection<CGPoint>) -> Path {
            var path = Path()
            guard let first = pts.first else { return path }
            path.move(to: m(first))
            if pts.count == 1 {
                path.addLine(to: m(first).applying(.init(translationX: 0.01, y: 0)))
            }
            for p in pts.dropFirst() { path.addLine(to: m(p)) }
            return path
        }
        let round = { (w: CGFloat) in StrokeStyle(lineWidth: w * s, lineCap: .round, lineJoin: .round) }

        let guided = mode == .guided

        // Track (the "road" to trace on)
        for stroke in glyph.strokes {
            let p = path(stroke)
            ctx.stroke(p, with: .color(color.opacity(guided ? 0.28 : 0.12)), style: round(22))
        }
        for stroke in glyph.strokes {
            let p = path(stroke)
            ctx.stroke(p, with: .color(DS.board), style: round(17))
            ctx.stroke(p, with: .color(color.opacity(guided ? 0.07 : 0.03)), style: round(17))
        }

        // Dashed centre guide for untraced strokes
        for (i, stroke) in engine.strokes.enumerated() where i >= engine.strokeIndex {
            guard guided else {
                ctx.stroke(path(stroke), with: .color(color.opacity(0.3)),
                           style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, dash: [0.1, 6 * s]))
                continue
            }
            ctx.stroke(path(stroke), with: .color(color.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round, dash: [0.1, 3.2 * s]))
        }

        // Traced ink
        for i in engine.strokes.indices {
            let done = engine.tracedPoints(of: i)
            guard done.count > 1 else {
                if done.count == 1, i < engine.strokeIndex {
                    ctx.fill(Path(ellipseIn: CGRect(x: done.first!.x * s - 7 * s, y: done.first!.y * s - 7 * s,
                                                     width: 14 * s, height: 14 * s)), with: .color(color))
                }
                continue
            }
            ctx.stroke(path(done), with: .color(color), style: round(14))
            ctx.stroke(path(done), with: .color(.white.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 3 * s, lineCap: .round, lineJoin: .round))
        }

        guard let stroke = engine.currentStroke, let next = engine.nextPoint else { return }

        // Numbered start dots for strokes not yet begun
        for i in (engine.strokeIndex + 1)..<engine.strokes.count where guided {
            let start = engine.strokes[i][0]
            ctx.fill(Path(ellipseIn: CGRect(x: start.x * s - 4 * s, y: start.y * s - 4 * s, width: 8 * s, height: 8 * s)),
                     with: .color(.gray.opacity(0.35)))
            ctx.draw(Text("\(i + 1)").font(TraceTheme.kid(5.5 * s)).foregroundColor(.white), at: m(start))
        }

        // Direction arrow just ahead of the start point
        let ahead = min(stroke.count - 1, engine.progress + 7)
        let ahead2 = min(stroke.count - 1, engine.progress + 11)
        if guided, ahead2 > ahead {
            let a = stroke[ahead], b = stroke[ahead2]
            let angle = atan2(b.y - a.y, b.x - a.x)
            var arrow = Path()
            arrow.move(to: CGPoint(x: 3, y: 0))
            arrow.addLine(to: CGPoint(x: -2, y: -2.6))
            arrow.addLine(to: CGPoint(x: -2, y: 2.6))
            arrow.closeSubpath()
            let t = CGAffineTransform(translationX: b.x * s, y: b.y * s)
                .rotated(by: angle)
                .scaledBy(x: s, y: s)
            ctx.fill(arrow.applying(t), with: .color(color.opacity(0.85)))
        }

        // Pulsing start dot with stroke number
        let pulse = session.finger == nil ? 1 + 0.12 * sin(time * 5) : 1
        let r = 7 * s * pulse
        ctx.fill(Path(ellipseIn: CGRect(x: next.x * s - r - 1.2 * s, y: next.y * s - r - 1.2 * s,
                                        width: 2 * (r + 1.2 * s), height: 2 * (r + 1.2 * s))), with: .color(.white))
        ctx.fill(Path(ellipseIn: CGRect(x: next.x * s - r, y: next.y * s - r, width: 2 * r, height: 2 * r)),
                 with: .color(TraceTheme.green))
        if engine.strokes.count > 1 {
            ctx.draw(Text("\(engine.strokeIndex + 1)").font(TraceTheme.kid(7 * s)).foregroundColor(.white), at: m(next))
        }

        // Demo finger gliding along the remaining stroke
        if guided, showHints, session.finger == nil, stroke.count > 1 {
            let remaining = stroke.count - engine.progress
            let duration = max(0.8, Double(remaining) * Double(TraceEngine.spacing) / 45)
            let cycle = duration + 1.2
            let t = time.truncatingRemainder(dividingBy: cycle)
            if t < duration {
                let idx = engine.progress + Int(Double(remaining - 1) * (t / duration))
                let p = stroke[min(idx, stroke.count - 1)]
                let fade = min(1, min(t, duration - t) * 4)
                ctx.opacity = fade
                ctx.fill(Path(ellipseIn: CGRect(x: p.x * s - 5 * s, y: p.y * s - 5 * s, width: 10 * s, height: 10 * s)),
                         with: .color(TraceTheme.yellow.opacity(0.8)))
                ctx.draw(Text("👆").font(.system(size: 14 * s)), at: CGPoint(x: p.x * s + 2 * s, y: p.y * s + 9 * s))
                ctx.opacity = 1
            }
        }

        // Sparkle trail behind the finger
        for (i, sample) in session.trail.enumerated() {
            let age = now.timeIntervalSince(sample.time)
            guard age < 0.45 else { continue }
            let life = 1 - age / 0.45
            let r = (2 + 4 * life) * s
            let c = TraceTheme.rainbow[i % TraceTheme.rainbow.count]
            ctx.fill(Path(ellipseIn: CGRect(x: sample.point.x * s - r, y: sample.point.y * s - r, width: r * 2, height: r * 2)),
                     with: .color(c.opacity(0.55 * life)))
        }
        if let f = session.finger {
            ctx.fill(Path(ellipseIn: CGRect(x: f.x * s - 7 * s, y: f.y * s - 7 * s, width: 14 * s, height: 14 * s)),
                     with: .color(TraceTheme.yellow.opacity(0.4)))
            let spin = Angle.degrees(time * 180)
            var star = ctx
            star.translateBy(x: f.x * s + 7 * s, y: f.y * s - 7 * s)
            star.rotate(by: spin)
            star.draw(Text(Image(systemName: "sparkle")).font(.system(size: 9 * s)).foregroundColor(TraceTheme.orange), at: .zero)
        }

        // Little star pops where strokes were finished
        for pop in session.strokePops {
            let age = now.timeIntervalSince(pop.time)
            guard age < 0.7 else { continue }
            let progress = 1 - pow(1 - age / 0.7, 3)
            for k in 0..<7 {
                let a = Double(k) / 7 * 2 * .pi
                let d = CGFloat(progress) * 14 * s
                let p = CGPoint(x: pop.point.x * s + d * CGFloat(cos(a)), y: pop.point.y * s + d * CGFloat(sin(a)))
                var star = ctx
                star.opacity = 1 - age / 0.7
                star.draw(Text(Image(systemName: "star.fill")).font(.system(size: 5 * s))
                            .foregroundColor(TraceTheme.rainbow[k % TraceTheme.rainbow.count]), at: p)
            }
        }
    }
}

/// Soft squash-and-stretch wobble used when the finger slips.
struct Jelly: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let phase = animatableData - animatableData.rounded(.down)
        let amount = sin(phase * .pi * 6) * (1 - phase) * 0.05
        let t = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
            .scaledBy(x: 1 + amount, y: 1 - amount)
            .translatedBy(x: -size.width / 2, y: -size.height / 2)
        return ProjectionTransform(t)
    }
}


// MARK: - Free writing

/// Collects the child's own ink on a blank board and scores it against the letter.
@MainActor
final class FreeWriteModel: ObservableObject {
    @Published var strokes: [[CGPoint]] = []
    @Published var current: [CGPoint] = []
    /// Set after checking: 0...100.
    @Published var score: Int?

    var hasInk: Bool { !strokes.isEmpty || current.count > 1 }

    func clear() {
        strokes = []
        current = []
        score = nil
    }

    /// Coverage of the letter's path and how much ink stayed on it, blended into 0...100.
    func check(against glyph: TraceGlyph) -> Int {
        let target = glyph.strokes.flatMap { resample($0, spacing: 1.5) }
        let ink = strokes.flatMap { resample($0, spacing: 1.5) }
        guard !target.isEmpty, !ink.isEmpty else { score = 0; return 0 }
        func near(_ p: CGPoint, _ set: [CGPoint], _ r: CGFloat) -> Bool { set.contains { $0.distance(to: p) <= r } }
        let coverage = Double(target.filter { near($0, ink, 10) }.count) / Double(target.count)
        let precision = Double(ink.filter { near($0, target, 13) }.count) / Double(ink.count)
        let result = Int((100 * (0.7 * coverage + 0.3 * precision)).rounded())
        score = result
        return result
    }

    static func stars(for score: Int) -> Int {
        switch score {
        case 85...: return 3
        case 65..<85: return 2
        case 40..<65: return 1
        default: return 0
        }
    }
}

struct FreeWriteBoard: View {
    let glyph: TraceGlyph
    let color: Color
    @ObservedObject var model: FreeWriteModel

    var body: some View {
        GeometryReader { geo in
            let width = glyph.designWidth
            let s = min(geo.size.width / width, geo.size.height / 100)
            Canvas { ctx, _ in
                func path(_ pts: [CGPoint]) -> Path {
                    var p = Path()
                    guard let f = pts.first else { return p }
                    p.move(to: CGPoint(x: f.x * s, y: f.y * s))
                    if pts.count == 1 { p.addLine(to: CGPoint(x: f.x * s + 0.01, y: f.y * s)) }
                    for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.x * s, y: q.y * s)) }
                    return p
                }
                let round = { (w: CGFloat) in StrokeStyle(lineWidth: w * s, lineCap: .round, lineJoin: .round) }
                // Baseline guides
                for y in [12.0, 88.0] {
                    var l = Path()
                    l.move(to: CGPoint(x: 0, y: y * s))
                    l.addLine(to: CGPoint(x: width * s, y: y * s))
                    ctx.stroke(l, with: .color(DS.inkSoft.opacity(0.25)),
                               style: StrokeStyle(lineWidth: 0.6 * s, dash: [2.5 * s, 2 * s]))
                }
                // After checking, show the model letter underneath.
                if model.score != nil {
                    for st in glyph.strokes {
                        ctx.stroke(path(st), with: .color(TraceTheme.green.opacity(0.35)), style: round(17))
                    }
                }
                for st in model.strokes + [model.current] {
                    ctx.stroke(path(st), with: .color(color), style: round(9))
                }
            }
            .frame(width: width * s, height: 100 * s)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        guard model.score == nil else { return }
                        model.current.append(CGPoint(x: v.location.x / s, y: v.location.y / s))
                    }
                    .onEnded { _ in
                        guard model.score == nil else { return }
                        if !model.current.isEmpty { model.strokes.append(model.current) }
                        model.current = []
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
