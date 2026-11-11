import SwiftUI

struct LetterDetailScreen: View {
    @ObservedObject var viewModel: MainViewModel
    let letter: Letter

    @ObservedObject private var store = ProgressStore.shared
    @State private var route: GardenRoute?
    @State private var pictureIn = false
    @State private var wiggle = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var item: TraceItem { TraceItem(letter: letter) }
    private var group: [Letter] { letter.category == "vowel" ? viewModel.vowels : viewModel.consonants }
    private var index: Int { group.firstIndex(of: letter) ?? 0 }
    private var color: Color { DS.color(for: index) }
    private var wide: Bool { hSizeClass == .regular }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(spacing: 0) {
                KidTopBar(title: "\(letter.char)  \(letter.transliteration)",
                          subtitle: letter.category == "vowel" ? "Vowel • സ്വരം" : "Consonant • വ്യഞ്ജനം",
                          onBack: { dismiss() }) {
                    StarRow(filled: store.stars(for: letter.char), size: 18)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        if wide {
                            HStack(alignment: .top, spacing: 20) { letterCard; pictureCard }
                        } else {
                            letterCard
                            pictureCard
                        }
                        if letter.category == "consonant" { signsPreview }
                    }
                    .padding(16)
                    .frame(maxWidth: wide ? 900 : 520)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        // Pinned action: always visible, never under the ad banner.
        .safeAreaInset(edge: .bottom) {
            BigButton(title: "Trace \(letter.char)", icon: "pencil.and.outline", color: color) {
                route = .trace(group.map(TraceItem.init(letter:)), index)
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(DS.background.opacity(0.95))
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $route) { r in
            switch r {
            case .detail(let l): LetterDetailScreen(viewModel: viewModel, letter: l)
            case .trace(let items, let start): TracingScreen(items: items, startIndex: start)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.15)) { pictureIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { Speaker.shared.say(item) }
        }
    }

    private var letterCard: some View {
        Button { Speaker.shared.say(item) } label: {
            VStack(spacing: 6) {
                Text(letter.char)
                    .font(DS.display(wide ? 150 : 128))
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity)
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Say \(letter.transliteration)")
                }
                .font(DS.font(.headline))
                .foregroundColor(color)
                .padding(.bottom, 10)
            }
            .padding(.vertical, 12)
            .kidCard(color.opacity(0.12), radius: 34)
        }
        .buttonStyle(KidButtonStyle())
        .accessibilityLabel("Hear \(letter.transliteration)")
    }

    private var pictureCard: some View {
        Button {
            wiggle += 1
            Speaker.shared.say(item)
        } label: {
            VStack(spacing: 10) {
                Image(letter.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: wide ? 240 : 200)
                    .scaleEffect(pictureIn ? 1 : 0.4)
                    .opacity(pictureIn ? 1 : 0)
                    .modifier(Wiggle(animatableData: CGFloat(wiggle)))
                    .animation(.easeOut(duration: 0.6), value: wiggle)
                Text(letter.example)
                    .font(DS.display(34))
                    .foregroundColor(DS.ink)
                Text(letter.exampleEn)
                    .font(DS.font(.title3, weight: .bold))
                    .foregroundColor(DS.inkSoft)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .kidCard(radius: 30)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "hand.tap.fill")
                    .font(.title3).foregroundColor(.white)
                    .padding(10).background(Circle().fill(color))
                    .padding(12)
            }
        }
        .buttonStyle(KidButtonStyle())
        .accessibilityLabel("\(letter.example), \(letter.exampleEn). Tap to hear.")
    }

    private var signsPreview: some View {
        let combos = Curriculum.combos(for: item)
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(letter.char) with vowel signs").font(DS.font(.title3)).foregroundColor(DS.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(combos.enumerated()), id: \.element.id) { i, c in
                        Button { route = .trace(combos, i) } label: {
                            VStack(spacing: 2) {
                                Text(c.text).font(DS.display(30)).foregroundColor(DS.ink)
                                Text(c.title).font(DS.font(.caption, weight: .bold)).foregroundColor(DS.inkSoft)
                            }
                            .frame(width: 70, height: 76)
                            .kidCard(DS.surfaceAlt, radius: 18)
                        }
                        .buttonStyle(KidButtonStyle())
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .kidCard()
    }
}

/// Playful side-to-side wiggle each time the value steps up by one.
struct Wiggle: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let phase = animatableData - animatableData.rounded(.down)
        let angle = sin(phase * .pi * 6) * (1 - phase) * 0.12
        let t = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
            .rotated(by: angle)
            .translatedBy(x: -size.width / 2, y: -size.height / 2)
        return ProjectionTransform(t)
    }
}
