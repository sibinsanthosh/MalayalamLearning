import SwiftUI

struct TracingScreen: View {
    let items: [TraceItem]
    @State private var index: Int

    @ObservedObject private var store = ProgressStore.shared
    @State private var mode: TraceMode = .guided
    @State private var progress: Double = 0
    @State private var attempt = 0
    @State private var result: Result?
    @State private var newBadges: [Badge] = []
    @State private var confetti = 0
    @State private var mood: MascotMood = .idle
    @State private var message: String?
    @StateObject private var freeModel = FreeWriteModel()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    struct Result: Equatable {
        let stars: Int
        let score: Int?
    }

    init(items: [TraceItem], startIndex: Int = 0) {
        self.items = items
        _index = State(initialValue: min(max(0, startIndex), max(0, items.count - 1)))
    }

    /// Kept for existing call sites: traces `letter`, then continues through its group.
    init(viewModel: MainViewModel, letter: Letter) {
        let list = (letter.category == "vowel" ? viewModel.vowels : viewModel.consonants).map(TraceItem.init(letter:))
        self.init(items: list, startIndex: list.firstIndex { $0.text == letter.char } ?? 0)
    }

    private var item: TraceItem { items[index] }
    private var glyph: TraceGlyph { TraceGlyph.make(for: item.text) }
    private var color: Color { DS.color(for: index) }
    private var hasNext: Bool { index + 1 < items.count }
    private var leftHanded: Bool { store.settings.leftHanded }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()

            VStack(spacing: 12) {
                header
                modePicker
                if hSizeClass == .regular {
                    HStack(spacing: 16) {
                        if !leftHanded { sidePanel }
                        boardCard
                        if leftHanded { sidePanel }
                    }
                } else {
                    boardCard
                    bottomBar
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ConfettiView(trigger: confetti).ignoresSafeArea()

            if let result {
                completionCard(result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if !newBadges.isEmpty {
                BadgeUnlockedView(badges: newBadges) { withAnimation { newBadges = [] } }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .tracksLearningTime()
        .onAppear { startItem(speak: true) }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: result)
    }

    // MARK: Pieces

    private var header: some View {
        KidTopBar(title: "\(item.text)  \(item.title)", subtitle: item.subtitle.isEmpty ? nil : item.subtitle,
                  onBack: { dismiss() }) {
            if items.count > 1 {
                Text("\(index + 1)/\(items.count)")
                    .font(DS.font(.subheadline)).foregroundColor(DS.inkSoft)
                    .monospacedDigit()
            }
            CircleIconButton(systemName: "speaker.wave.2.fill", color: color, label: "Hear the letter") {
                Speaker.shared.say(item)
            }
        }
        .padding(.top, 8)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(TraceMode.allCases) { m in
                Button {
                    guard m != mode else { return }
                    mode = m
                    restart()
                } label: {
                    Label(m.label, systemImage: m.icon)
                        .font(DS.font(.subheadline))
                        .foregroundColor(mode == m ? .white : DS.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(mode == m ? color : DS.surface))
                }
                .buttonStyle(KidButtonStyle())
                .accessibilityAddTraits(mode == m ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(DS.surfaceAlt))
        .frame(maxWidth: 520)
    }

    private var boardCard: some View {
        VStack(spacing: 10) {
            ProgressView(value: mode == .free ? (freeModel.hasInk ? 0.5 : 0) : progress)
                .tint(color)
                .scaleEffect(x: 1, y: 2.2)
                .padding(.horizontal, 8)
                .padding(.top, 10)
                .accessibilityLabel("Tracing progress")

            Group {
                if mode == .free {
                    FreeWriteBoard(glyph: glyph, color: color, model: freeModel)
                } else {
                    TracingBoard(glyph: glyph, color: color, showHints: store.settings.showHints, mode: mode,
                                 onEvent: react, onProgress: { progress = $0 }, onComplete: finished)
                }
            }
            .id("\(item.id)-\(attempt)-\(mode.rawValue)")
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .kidCard(DS.board, radius: 32)
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if leftHanded { actionButtons }
            MascotView(mood: mood, message: message, size: 56, bubbleTrailing: !leftHanded)
                .frame(maxWidth: .infinity, alignment: leftHanded ? .trailing : .leading)
            if !leftHanded { actionButtons }
        }
        .frame(minHeight: 84)
    }

    private var sidePanel: some View {
        VStack(spacing: 16) {
            MascotView(mood: mood, message: message, size: 90, bubbleTrailing: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let image = item.imageName, UIImage(named: image) != nil {
                Image(image).resizable().scaledToFit()
                    .frame(maxHeight: 180)
                    .padding(12)
                    .kidCard()
            }
            Text(item.text)
                .font(DS.display(96))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .kidCard(color.opacity(0.12))
            Spacer()
            actionButtons
        }
        .frame(width: 280)
    }

    @ViewBuilder private var actionButtons: some View {
        HStack(spacing: 10) {
            CircleIconButton(systemName: "arrow.counterclockwise", color: DS.orange, size: 60, label: "Start again") {
                restart()
            }
            if mode == .free {
                Button(action: checkFreeWriting) {
                    Label("Check", systemImage: "checkmark.seal.fill")
                        .font(DS.font(.headline))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 60)
                        .background(Capsule().fill(freeModel.hasInk ? DS.green : DS.inkSoft.opacity(0.4)))
                }
                .buttonStyle(KidButtonStyle())
                .disabled(!freeModel.hasInk)
            }
        }
    }

    private func completionCard(_ r: Result) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Text(r.stars == 0 ? "Almost! Try again" : (r.stars == 3 ? "Perfect!" : "Great job!"))
                    .font(DS.font(.largeTitle))
                    .foregroundColor(DS.ink)
                StarRow(filled: r.stars, size: 44)
                    .scaleEffect(result == nil ? 0.3 : 1)
                if let score = r.score {
                    Text("Your writing scored \(score)%")
                        .font(DS.font(.headline, weight: .bold)).foregroundColor(DS.inkSoft)
                }
                HStack(spacing: 12) {
                    BigButton(title: "Again", icon: "arrow.counterclockwise", color: DS.orange, filled: false) {
                        restart()
                    }
                    if hasNext {
                        BigButton(title: "Next", icon: "arrow.right", color: DS.green, action: goNext)
                    } else {
                        BigButton(title: "Done", icon: "checkmark", color: DS.green) { dismiss() }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 560)
            .kidCard(DS.surface, radius: 34)
            .padding(16)
        }
    }

    // MARK: Flow

    private func startItem(speak: Bool) {
        progress = 0
        result = nil
        freeModel.clear()
        mood = .idle
        switch mode {
        case .guided: message = "Start at the green dot!"
        case .faded: message = "Follow the dots on your own!"
        case .free: message = "Write \(item.text) by yourself!"
        }
        if speak {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { Speaker.shared.say(item) }
        }
    }

    private func restart() {
        attempt += 1
        startItem(speak: false)
    }

    private func goNext() {
        InterstitialAdManager.shared.showAdIfAppropriate {
            guard hasNext else { return }
            index += 1
            attempt += 1
            startItem(speak: true)
        }
    }

    private func react(_ event: TraceEngine.Event) {
        switch event {
        case .strokeDone:
            mood = .happy
            message = ["Super!", "Nice line!", "Keep going!", "Wow!"].randomElement()
        case .offPath:
            mood = .oops
            message = "Oops! Back on the road"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { if mood == .oops { mood = .idle } }
        case .started:
            if mood != .happy { mood = .idle; message = "That's it!" }
        default:
            break
        }
    }

    private func finished(mistakes: Int) {
        let stars = TraceTheme.stars(mistakes: mistakes)
        complete(stars: stars, slips: mistakes, score: nil)
    }

    private func checkFreeWriting() {
        let score = freeModel.check(against: glyph)
        let stars = FreeWriteModel.stars(for: score)
        if stars == 0 {
            mood = .thinking
            message = "Look at the green letter and try again!"
            withAnimation { result = Result(stars: 0, score: score) }
            return
        }
        complete(stars: stars, slips: 0, score: score)
    }

    private func complete(stars: Int, slips: Int, score: Int?) {
        progress = 1
        mood = .cheer
        message = "You did it!"
        confetti += 1
        TraceFeedback.shared.celebrate()
        let badges = store.recordTrace(item: item, stars: stars, slips: slips, mode: mode, freeScore: score)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { Speaker.shared.say(item) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { result = Result(stars: stars, score: score) }
            if !badges.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation { newBadges = badges } }
            }
        }
    }
}
