import SwiftUI

/// Tracing mini-games: "Trace & Pop" and "First Letter".
struct TraceGameScreen: View {
    enum Kind {
        case pop, firstLetter
        var title: String { self == .pop ? "Trace & Pop" : "First Letter" }
        var titleMl: String { self == .pop ? "എഴുതി പൊട്ടിക്കാം" : "ആദ്യാക്ഷരം" }
    }

    let kind: Kind
    private let rounds: [TraceItem]

    @ObservedObject private var store = ProgressStore.shared
    @State private var round = 0
    @State private var totalSlips = 0
    @State private var popped = false
    @State private var confetti = 0
    @State private var finished = false
    @State private var attempt = 0
    @State private var mood: MascotMood = .idle
    @State private var message: String?
    @State private var newBadges: [Badge] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    init(kind: Kind, roundCount: Int = 5) {
        self.kind = kind
        // Prefer letters the child has met, mixed with a few new ones.
        let store = ProgressStore.shared
        let known = Curriculum.letters.filter { store.record(for: $0.id).completions > 0 }.shuffled()
        let fresh = Curriculum.pathItems.filter { store.record(for: $0.id).completions == 0 }.prefix(6).shuffled()
        var picks = Array((known.prefix(3) + fresh).prefix(roundCount))
        if picks.count < roundCount {
            picks += Curriculum.letters.shuffled().filter { !picks.contains($0) }.prefix(roundCount - picks.count)
        }
        rounds = picks.shuffled()
    }

    private var item: TraceItem { rounds[min(round, rounds.count - 1)] }
    private var color: Color { DS.color(for: round + 2) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [DS.sky.opacity(0.35), DS.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                KidTopBar(title: kind.title, subtitle: kind.titleMl, onBack: { dismiss() }) {
                    HStack(spacing: 6) {
                        ForEach(rounds.indices, id: \.self) { i in
                            Circle().fill(i < round || finished ? DS.yellow : (i == round ? DS.surface : DS.inkSoft.opacity(0.25)))
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(i == round && !finished ? DS.yellow : .clear, lineWidth: 3))
                        }
                    }
                    .accessibilityLabel("Round \(round + 1) of \(rounds.count)")
                }
                .padding(.top, 8)

                if finished {
                    summary
                } else {
                    prompt
                    TracingBoard(glyph: TraceGlyph.make(for: item.text), color: color,
                                 showHints: store.settings.showHints, mode: kind == .pop ? .faded : .guided,
                                 onEvent: react, onComplete: roundDone)
                        .id("\(round)-\(attempt)")
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .kidCard(DS.board, radius: 32)
                        .allowsHitTesting(!popped)
                    MascotView(mood: mood, message: message, size: 52)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 70)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: 900)

            ConfettiView(trigger: confetti).ignoresSafeArea()
            if !newBadges.isEmpty {
                BadgeUnlockedView(badges: newBadges) { withAnimation { newBadges = [] } }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .tracksLearningTime()
        .onAppear { startRound() }
    }

    // MARK: Prompt

    @ViewBuilder private var prompt: some View {
        switch kind {
        case .pop:
            HStack(spacing: 16) {
                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    ZStack {
                        Ellipse().fill(color.gradient)
                            .frame(width: 96, height: 116)
                            .overlay(Ellipse().fill(.white.opacity(0.35)).frame(width: 22, height: 34).offset(x: -22, y: -26))
                        Text(item.text).font(DS.display(52)).foregroundColor(.white)
                        Path { p in p.move(to: CGPoint(x: 48, y: 116)); p.addQuadCurve(to: CGPoint(x: 48, y: 160), control: CGPoint(x: 60, y: 138)) }
                            .stroke(DS.inkSoft, lineWidth: 2).frame(width: 96, height: 160)
                    }
                    .frame(width: 96, height: 160)
                    .offset(y: popped ? -40 : sin(t * 2) * 6)
                    .scaleEffect(popped ? 1.8 : 1)
                    .opacity(popped ? 0 : 1)
                    .animation(.easeOut(duration: 0.35), value: popped)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trace \(item.text) to pop the balloon!")
                        .font(DS.font(.title3)).foregroundColor(DS.ink)
                    Text("Follow the dots — no road this time.")
                        .font(DS.font(.subheadline, weight: .semibold)).foregroundColor(DS.inkSoft)
                }
                Spacer(minLength: 0)
            }
            .frame(height: 160)
        case .firstLetter:
            HStack(spacing: 16) {
                if let image = item.imageName {
                    Image(image).resizable().scaledToFit()
                        .frame(width: 130, height: 130)
                        .padding(8)
                        .kidCard()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(popped ? item.subtitle.components(separatedBy: " • ").first ?? "" : "What letter does this start with?")
                        .font(popped ? DS.display(34) : DS.font(.title3))
                        .foregroundColor(DS.ink)
                    Text(popped ? "starts with \(item.text)!" : "Trace the first letter")
                        .font(DS.font(.headline, weight: .bold)).foregroundColor(DS.inkSoft)
                }
                Spacer(minLength: 0)
            }
            .frame(height: 150)
        }
    }

    private var summary: some View {
        VStack(spacing: 18) {
            Spacer()
            AppuView(mood: .cheer, waving: true).frame(width: 150, height: 150)
            Text("You finished!").font(DS.font(.largeTitle)).foregroundColor(DS.ink)
            StarRow(filled: TraceTheme.stars(mistakes: totalSlips / max(1, rounds.count / 2)), size: 48)
            Text(rounds.map(\.text).joined(separator: "  ")).font(DS.display(36)).foregroundColor(DS.purple)
            HStack(spacing: 12) {
                BigButton(title: "Play again", icon: "arrow.counterclockwise", color: DS.orange, filled: false) {
                    round = 0; totalSlips = 0; finished = false; attempt += 1; startRound()
                }
                BigButton(title: "Done", icon: "checkmark", color: DS.green) {
                    InterstitialAdManager.shared.showAdIfAppropriate { dismiss() }
                }
            }
            .frame(maxWidth: 520)
            Spacer()
        }
    }

    // MARK: Flow

    private func startRound() {
        popped = false
        mood = .idle
        message = kind == .pop ? "Pop it! Start at the green dot." : "Look at the picture!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if kind == .pop { Speaker.shared.say(item) }
        }
    }

    private func react(_ event: TraceEngine.Event) {
        switch event {
        case .strokeDone: mood = .happy; message = "Keep going!"
        case .offPath: mood = .oops; message = "Oops! Try again from the dot."
        default: break
        }
    }

    private func roundDone(_ mistakes: Int) {
        totalSlips += mistakes
        popped = true
        mood = .cheer
        message = kind == .pop ? "POP!" : "Yes! \(item.text)!"
        confetti += 1
        TraceFeedback.shared.success()
        Speaker.shared.say(item)
        store.recordTrace(item: item, stars: TraceTheme.stars(mistakes: mistakes), slips: mistakes, mode: kind == .pop ? .faded : .guided)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if round + 1 < rounds.count {
                round += 1
                attempt += 1
                startRound()
            } else {
                withAnimation { finished = true }
                TraceFeedback.shared.celebrate()
                let badges = store.recordGameFinished()
                if !badges.isEmpty { newBadges = badges }
            }
        }
    }
}
