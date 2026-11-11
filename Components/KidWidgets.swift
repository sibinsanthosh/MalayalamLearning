import AVFoundation
import SwiftUI

// MARK: - Speech

/// Plays a letter's recording, or speaks it with an on-device voice when there is none.
final class Speaker {
    static let shared = Speaker()

    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    /// iOS ships no Malayalam voice today; if one is ever installed we use it.
    static var malayalamVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("ml") }
    }
    static var hasMalayalamVoice: Bool { malayalamVoice != nil }

    private var soundOn: Bool { ProgressStore.shared.settings.soundOn }

    func say(_ item: TraceItem) {
        guard soundOn else { return }
        if let sound = item.sound, playFile(sound) { return }
        if let v = Self.malayalamVoice {
            speak(item.text, voice: v)
        } else if let fallback = item.spokenFallback {
            speak(fallback, voice: AVSpeechSynthesisVoice(language: "en-IN"))
        }
    }

    /// Speaks a Malayalam word if a Malayalam voice exists. Returns false otherwise.
    @discardableResult
    func sayMalayalam(_ text: String, rate: Float = 0.42) -> Bool {
        guard soundOn, let v = Self.malayalamVoice else { return false }
        speak(text, voice: v, rate: rate)
        return true
    }

    func sayEnglish(_ text: String) {
        guard soundOn else { return }
        speak(text, voice: AVSpeechSynthesisVoice(language: "en-IN"))
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        player?.stop()
    }

    private func speak(_ text: String, voice: AVSpeechSynthesisVoice?, rate: Float = 0.45) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = rate
        u.pitchMultiplier = 1.15
        synth.speak(u)
    }

    @discardableResult
    func playFile(_ name: String) -> Bool {
        guard soundOn else { return false }
        for sub in [nil, "Raw"] as [String?] {
            for ext in ["mp3", "m4a"] {
                guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) else { continue }
                // Some ".mp3" files are really AAC, so fall back to an m4a hint.
                let p = (try? AVAudioPlayer(contentsOf: url, fileTypeHint: ext == "m4a" ? AVFileType.m4a.rawValue : AVFileType.mp3.rawValue))
                    ?? (try? AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.m4a.rawValue))
                guard let p else { continue }
                player = p
                p.prepareToPlay()
                p.play()
                return true
            }
        }
        return false
    }
}

// MARK: - Mascot

enum MascotMood: Equatable {
    case idle, happy, oops, cheer, thinking
}

/// Appu the elephant: bobs while waiting, cheers on success, wobbles on slips.
struct MascotView: View {
    let mood: MascotMood
    var message: String? = nil
    var size: CGFloat = 84
    /// Speech bubble on the right of Appu (true) or the left.
    var bubbleTrailing = true

    @State private var bounce = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if !bubbleTrailing { bubble }
            TimelineView(.animation(paused: reduceMotion)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                AppuView(mood: mood, waving: mood == .cheer)
                    .frame(width: size * 1.2, height: size * 1.2)
                    .scaleEffect(x: bubbleTrailing ? 1 : -1, y: 1)
                    .rotationEffect(.degrees(mood == .oops ? sin(t * 22) * 8 : (mood == .thinking ? 6 : 0)))
                    .offset(y: mood == .idle || mood == .thinking ? sin(t * 2.4) * 3 : 0)
                    .modifier(JumpEffect(progress: CGFloat(bounce)))
            }
            .frame(width: size * 1.2, height: size * 1.2)
            if bubbleTrailing { bubble }
        }
        .onChange(of: mood) { _, new in
            if new == .cheer || new == .happy {
                withAnimation(.easeOut(duration: 0.7)) { bounce += 1 }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Appu the elephant says: \(message ?? "")")
    }

    @ViewBuilder private var bubble: some View {
        if let message, !message.isEmpty {
            Text(message)
                .font(DS.font(.headline))
                .foregroundColor(DS.ink)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .kidCard(DS.surface, radius: 18)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.scale.combined(with: .opacity))
                .id(message)
        }
    }
}

/// A hop: up and back down once per whole step of `progress`.
struct JumpEffect: GeometryEffect {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let phase = progress - progress.rounded(.down)
        let lift = sin(phase * .pi) * size.height * 0.35
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: -lift))
    }
}

// MARK: - Confetti

/// Burst of confetti every time `trigger` changes.
struct ConfettiView: View {
    let trigger: Int
    @State private var start: Date?
    @State private var pieces: [Piece] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Piece {
        let x: CGFloat, vx: CGFloat, vy: CGFloat, spin: Double, color: Color, size: CGFloat, shape: Int
    }

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { tl in
            Canvas { ctx, size in
                guard let start else { return }
                let t = tl.date.timeIntervalSince(start)
                guard t < 3 else { return }
                for p in pieces {
                    let x = p.x * size.width + p.vx * CGFloat(t) * 60
                    let y = -20 + p.vy * CGFloat(t) * 60 + 180 * CGFloat(t * t)
                    var c = ctx
                    c.opacity = max(0, 1 - t / 3)
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(p.spin * t))
                    let r = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)
                    c.fill(p.shape == 0 ? Path(r) : Path(ellipseIn: r), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            pieces = (0..<90).map { _ in
                Piece(x: .random(in: 0...1), vx: .random(in: -2...2), vy: .random(in: 1...6),
                      spin: .random(in: -8...8), color: DS.palette.randomElement()!,
                      size: .random(in: 8...16), shape: Int.random(in: 0...1))
            }
            start = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { start = nil }
        }
    }
}

// MARK: - New sticker toast

struct BadgeUnlockedView: View {
    let badges: [Badge]
    let onDone: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea().onTapGesture(perform: onDone)
            VStack(spacing: 16) {
                Text("New sticker!").font(DS.font(.title)).foregroundColor(DS.ink)
                ForEach(badges) { b in
                    HStack(spacing: 14) {
                        Text(b.emoji).font(.system(size: 54))
                            .rotationEffect(.degrees(appear ? 0 : -30))
                            .scaleEffect(appear ? 1 : 0.3)
                        VStack(alignment: .leading) {
                            Text(b.title).font(DS.font(.title3)).foregroundColor(DS.ink)
                            Text(b.detail).font(DS.font(.subheadline, weight: .semibold)).foregroundColor(DS.inkSoft)
                        }
                        Spacer(minLength: 0)
                    }
                }
                BigButton(title: "Yay!", icon: "hands.clap.fill", color: DS.green, action: onDone)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .kidCard(DS.surface, radius: 32)
            .padding(24)
            .scaleEffect(appear ? 1 : 0.7)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appear = true }
        }
    }
}

// MARK: - Time tracking

private struct LearningTimeTracker: ViewModifier {
    @State private var startedAt: Date?
    func body(content: Content) -> some View {
        content
            .onAppear { startedAt = Date() }
            .onDisappear {
                if let s = startedAt { ProgressStore.shared.addTime(seconds: Int(Date().timeIntervalSince(s))) }
                startedAt = nil
            }
    }
}

extension View {
    /// Adds the time spent on this screen to today's learning time.
    func tracksLearningTime() -> some View { modifier(LearningTimeTracker()) }
}
