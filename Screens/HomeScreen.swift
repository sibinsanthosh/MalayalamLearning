import SwiftUI

/// The playground: an animated Kerala scene with Appu the elephant and big picture tiles.
struct HomeScreen: View {
    @StateObject var viewModel: MainViewModel
    @ObservedObject private var store = ProgressStore.shared
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var appuWaving = false
    @State private var lineIndex = 0
    @State private var appeared = false

    private var wide: Bool { hSizeClass == .regular }

    private var appuLines: [String] {
        [
            "Hi \(store.active.name)! I'm Appu.",
            "Let's trace a letter together!",
            "Tap a picture to play.",
            "You're doing great!",
            "Can you find ആ for ആന?",
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KeralaScene()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: wide ? 20 : 16) {
                        topRow
                        HomeProgressStrip(compact: !wide)
                        if wide {
                            HStack(alignment: .center, spacing: 20) {
                                appuHero.frame(maxWidth: 420)
                                ContinueLearningCard()
                            }
                        } else {
                            appuHero
                            ContinueLearningCard()
                        }
                        tiles
                    }
                    .padding(.horizontal, wide ? 32 : 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: wide ? 1100 : 520)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { appeared = true }
            }
        }
    }

    // MARK: Header

    private var topRow: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.playSound("pop")
                wave()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("നമസ്കാരം!")
                        .font(DS.display(wide ? 38 : 32))
                        .foregroundColor(Color(hex: "4A2E73"))
                    Text("Let's learn Malayalam")
                        .font(DS.font(.subheadline, weight: .bold))
                        .foregroundColor(Color(hex: "7C6E92"))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 4))
            }
            .buttonStyle(KidButtonStyle())
            .accessibilityLabel("Namaskaram! Let's learn Malayalam")

            Spacer(minLength: 0)
        }
        .environment(\.colorScheme, .light)
    }

    // MARK: Appu

    private var appuHero: some View {
        HStack(alignment: .center, spacing: 4) {
            Button(action: wave) {
                AppuView(mood: appuWaving ? .happy : .idle, waving: appuWaving)
                    .frame(width: wide ? 150 : 124, height: wide ? 150 : 124)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .modifier(JumpEffect(progress: appuWaving ? 1 : 0))
                    .animation(.spring(response: 0.5, dampingFraction: 0.55), value: appuWaving)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Appu the elephant. Tap to say hello.")

            Text(appuLines[lineIndex % appuLines.count])
                .font(DS.font(.headline))
                .foregroundColor(Color(hex: "3B2A5A"))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(SpeechBubble().fill(.white).shadow(color: .black.opacity(0.1), radius: 0, x: 0, y: 4))
                .id(lineIndex)
                .transition(.scale(scale: 0.6, anchor: .leading).combined(with: .opacity))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .environment(\.colorScheme, .light)
    }

    private func wave() {
        guard !appuWaving else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            appuWaving = true
            lineIndex += 1
        }
        Haptics.tap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { appuWaving = false }
    }

    // MARK: Tiles

    private var tiles: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: wide ? 3 : 2)
        return LazyVGrid(columns: columns, spacing: 16) {
            tile(0, "Alphabet", "അക്ഷരങ്ങൾ", [Color(hex: "B26BFF"), Color(hex: "7A4DF2")],
                 AlphabetGridScreen(viewModel: viewModel)) { LetterBlocksArt() }
            tile(1, "Games", "കളികൾ", [Color(hex: "FFB347"), Color(hex: "FF7A45")],
                 GameSelectScreen(viewModel: viewModel)) { BalloonsArt() }
            tile(2, "Stories", "കഥകൾ", [Color(hex: "FF7EB3"), Color(hex: "F2509A")],
                 StorySelectScreen(viewModel: viewModel)) { StoryBookArt() }
            tile(3, "Words", "വാക്കുകൾ", [Color(hex: "5CC8FF"), Color(hex: "2C8EE8")],
                 DictionaryScreen()) { WordSearchArt() }
            if wide {
                tile(4, "Tracing Studio", "എഴുതാം", [Color(hex: "3ED6B5"), Color(hex: "13A08A")],
                     IPadAlphabetStudioView(viewModel: viewModel)) { PencilArt() }
            }
        }
    }

    private func tile<Destination: View, Art: View>(
        _ index: Int, _ title: String, _ titleMl: String, _ colors: [Color],
        _ destination: Destination, @ViewBuilder art: () -> Art
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                art()
                    .frame(height: wide ? 130 : 104)
                    .frame(maxWidth: .infinity)
                Text(title)
                    .font(DS.font(.title2))
                    .foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(titleMl)
                    .font(DS.font(.subheadline, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: colors[1].opacity(0.55), radius: 0, x: 0, y: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 3)
            )
            .offset(y: appeared ? 0 : 60)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.08 * Double(index)), value: appeared)
        }
        .buttonStyle(KidButtonStyle())
        .accessibilityLabel("\(title), \(titleMl)")
    }
}

/// Rounded bubble with a little tail pointing left at Appu.
struct SpeechBubble: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(roundedRect: r, cornerRadius: 18, style: .continuous)
        p.move(to: CGPoint(x: r.minX + 2, y: r.midY - 8))
        p.addLine(to: CGPoint(x: r.minX - 10, y: r.midY + 4))
        p.addLine(to: CGPoint(x: r.minX + 4, y: r.midY + 8))
        p.closeSubpath()
        return p
    }
}
