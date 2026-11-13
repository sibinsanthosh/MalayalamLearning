import SwiftUI

/// Where a tap in the Alphabet Garden leads.
enum GardenRoute: Hashable {
    case detail(Letter)
    case trace([TraceItem], Int)
}

struct AlphabetGridScreen: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject private var store = ProgressStore.shared
    @State private var tab: Tab = .path
    @State private var route: GardenRoute?
    @State private var signConsonant = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    enum Tab: String, CaseIterable, Identifiable {
        case path, vowels, consonants, signs, chillu, numbers
        var id: String { rawValue }
        var title: String {
            switch self {
            case .path: return "Path"
            case .vowels: return "അ Vowels"
            case .consonants: return "ക Consonants"
            case .signs: return "കാ Signs"
            case .chillu: return "ൻ Chillu"
            case .numbers: return "൧ Numbers"
            }
        }
    }

    private var tileSize: CGFloat { hSizeClass == .regular ? 120 : 98 }
    private var columns: [GridItem] { [GridItem(.adaptive(minimum: tileSize), spacing: 14)] }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(spacing: 12) {
                KidTopBar(title: "Alphabet Garden", subtitle: "\(store.tracedCount(of: Curriculum.letters))/49 letters traced",
                          onBack: { dismiss() }) {
                    ProgressRing(progress: store.goalProgress, color: DS.green, lineWidth: 6) {
                        Text("\(store.today.traced)/\(store.settings.dailyGoal)")
                            .font(DS.font(.caption)).foregroundColor(DS.ink)
                    }
                    .frame(width: 52, height: 52)
                    .accessibilityLabel("Daily goal: \(store.today.traced) of \(store.settings.dailyGoal)")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                tabBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        practiceRow
                        content
                    }
                    .padding(16)
                    .frame(maxWidth: 1000)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $route) { r in
            switch r {
            case .detail(let letter): LetterDetailScreen(viewModel: viewModel, letter: letter)
            case .trace(let items, let start): TracingScreen(items: items, startIndex: start)
            }
        }
    }

    // MARK: Tabs

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tab.allCases) { t in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { tab = t }
                    } label: {
                        Text(t.title)
                            .font(DS.font(.headline))
                            .foregroundColor(tab == t ? .white : DS.ink)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 48)
                            .background(Capsule().fill(tab == t ? DS.purple : DS.surface))
                            .shadow(color: .black.opacity(tab == t ? 0 : 0.06), radius: 0, x: 0, y: 3)
                    }
                    .buttonStyle(KidButtonStyle())
                    .accessibilityAddTraits(tab == t ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder private var practiceRow: some View {
        let weak = store.needsPractice(from: Curriculum.letters)
        if !weak.isEmpty && (tab == .path || tab == .vowels || tab == .consonants) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Needs a little practice", systemImage: "sparkles")
                    .font(DS.font(.headline)).foregroundColor(DS.orange)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(weak.enumerated()), id: \.element.id) { i, item in
                            Button { route = .trace(weak, i) } label: {
                                Text(item.text)
                                    .font(DS.display(30))
                                    .foregroundColor(DS.orange)
                                    .frame(width: 64, height: 64)
                                    .kidCard(DS.orange.opacity(0.12), radius: 18)
                            }
                            .buttonStyle(KidButtonStyle())
                            .accessibilityLabel("Practise \(item.title)")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .path: pathView
        case .vowels: letterGrid(Curriculum.vowels, letters: viewModel.vowels)
        case .consonants: letterGrid(Curriculum.consonants, letters: viewModel.consonants)
        case .signs: signsView
        case .chillu: traceGrid(Curriculum.chillu, intro: "Chillu letters are consonants that end a word without a vowel sound.")
        case .numbers: traceGrid(Curriculum.numbers, intro: "Malayalam has its own digits. Trace them and count along!")
        }
    }

    // MARK: Grids

    private func letterGrid(_ items: [TraceItem], letters: [Letter]) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                Button {
                    if let letter = letters.first(where: { $0.char == item.text }) { route = .detail(letter) }
                } label: {
                    LetterTile(item: item, color: DS.color(for: i), stars: store.stars(for: item.id), size: tileSize)
                }
                .buttonStyle(KidButtonStyle())
            }
        }
    }

    private func traceGrid(_ items: [TraceItem], intro: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(intro).font(DS.font(.body, weight: .semibold)).foregroundColor(DS.inkSoft)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    Button { route = .trace(items, i) } label: {
                        LetterTile(item: item, color: DS.color(for: i), stars: store.stars(for: item.id), size: tileSize)
                    }
                    .buttonStyle(KidButtonStyle())
                }
            }
        }
    }

    private var signsView: some View {
        let consonants = Curriculum.consonants
        let base = consonants[min(signConsonant, consonants.count - 1)]
        let combos = Curriculum.combos(for: base)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Add a vowel sign to a consonant to make a new sound. Pick a letter:")
                .font(DS.font(.body, weight: .semibold)).foregroundColor(DS.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(consonants.enumerated()), id: \.element.id) { i, c in
                        Button { withAnimation { signConsonant = i } } label: {
                            Text(c.text)
                                .font(DS.display(28))
                                .foregroundColor(i == signConsonant ? .white : DS.ink)
                                .frame(width: 56, height: 56)
                                .background(RoundedRectangle(cornerRadius: 16).fill(i == signConsonant ? DS.pink : DS.surface))
                        }
                        .buttonStyle(KidButtonStyle())
                        .accessibilityLabel(c.title)
                    }
                }
                .padding(.vertical, 4)
            }
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(combos.enumerated()), id: \.element.id) { i, item in
                    Button { route = .trace(combos, i) } label: {
                        LetterTile(item: item, color: DS.color(for: i), stars: store.stars(for: item.id), size: tileSize)
                    }
                    .buttonStyle(KidButtonStyle())
                }
            }
            BigButton(title: "Trace all \(combos.count)", icon: "pencil.and.outline", color: DS.pink) {
                route = .trace(combos, 0)
            }
        }
    }

    // MARK: Learning path

    private var pathView: some View {
        let path = Curriculum.pathItems
        let next = store.nextPathItem
        return VStack(alignment: .leading, spacing: 16) {
            if let next, let start = path.firstIndex(of: next) {
                Button { route = .trace(path, start) } label: {
                    HStack(spacing: 16) {
                        Text(next.text).font(DS.display(56)).foregroundColor(.white)
                            .frame(width: 88, height: 88)
                            .background(Circle().fill(.white.opacity(0.22)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next up").font(DS.font(.subheadline)).foregroundColor(.white.opacity(0.85))
                            Text("Trace \(next.title)").font(DS.font(.title2)).foregroundColor(.white)
                            Text("Easy letters first, tricky ones later").font(DS.font(.footnote, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "play.circle.fill").font(.system(size: 44)).foregroundColor(.white)
                    }
                    .padding(18)
                    .kidCard(DS.green, radius: 28)
                }
                .buttonStyle(KidButtonStyle())
            }
            ForEach(Curriculum.stages) { stage in
                let items = stage.letters.compactMap(Curriculum.letter)
                let done = store.tracedCount(of: items)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(stage.id)").font(DS.font(.headline)).foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(done == items.count ? DS.green : DS.purple))
                        Text(stage.name).font(DS.font(.title3)).foregroundColor(DS.ink)
                        Spacer()
                        if done == items.count {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(DS.green).font(.title2)
                        } else {
                            Text("\(done)/\(items.count)").font(DS.font(.subheadline)).foregroundColor(DS.inkSoft)
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items) { item in
                                Button { route = .trace(path, path.firstIndex(of: item) ?? 0) } label: {
                                    LetterTile(item: item, color: DS.color(for: stage.id), stars: store.stars(for: item.id),
                                               size: 84, highlight: item == next)
                                }
                                .buttonStyle(KidButtonStyle())
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                    }
                }
                .padding(14)
                .kidCard()
            }
        }
    }
}

/// A letter tile with its best star rating.
struct LetterTile: View {
    let item: TraceItem
    let color: Color
    let stars: Int
    var size: CGFloat = 98
    var highlight = false

    var body: some View {
        VStack(spacing: 2) {
            Text(item.text)
                .font(DS.display(size * 0.4))
                .foregroundColor(stars > 0 ? .white : color)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(item.title)
                .font(DS.font(.caption, weight: .bold))
                .foregroundColor(stars > 0 ? .white.opacity(0.9) : DS.inkSoft)
                .lineLimit(1)
            StarRow(filled: stars, size: size * 0.11)
        }
        .padding(6)
        .frame(width: size, height: size * 1.05)
        .background(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(stars > 0 ? color : DS.surface)
                .shadow(color: (stars > 0 ? color : Color.black).opacity(0.25), radius: 0, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(highlight ? DS.yellow : color.opacity(stars > 0 ? 0 : 0.5), lineWidth: highlight ? 4 : 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title), \(stars) stars")
    }
}

// MARK: - ==========================================
// MARK: - IPAD MASTER-DETAIL ALPHABET STUDIO
// MARK: - ==========================================

struct IPadAlphabetStudioView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedCategory: Int = 0 // 0: Vowels, 1: Consonants, 2: All
    @State private var activeLetter: Letter?
    
    // Tracing state
    @State private var progress: Double = 0.0
    @State private var showReward: Bool = false
    /// Changing this rebuilds the tracing board from scratch.
    @State private var traceAttempt = 0
    
    private var currentLettersList: [Letter] {
        switch selectedCategory {
        case 0: return viewModel.vowels
        case 1: return viewModel.consonants
        default: return viewModel.vowels + viewModel.consonants
        }
    }
    
    private var displayedLetter: Letter {
        if let active = activeLetter {
            return active
        }
        return viewModel.vowels.first ?? Letter(id: "v1", char: "അ", transliteration: "A", example: "അമ്മ", exampleEn: "Amma (Mother)", imageName: "v1", category: "vowel")
    }
    
    private var accentColor: Color {
        let colors: [Color] = [.orange, .blue, .pink, .purple, .green, Color(hex: "FF6536")]
        let index = abs(displayedLetter.id.hashValue) % colors.count
        return colors[index]
    }
    
    let pastelColors: [Color] = [
        Color(hex: "FFC107"), Color(hex: "03A9F4"), Color(hex: "E91E63"),
        Color(hex: "FF9800"), Color(hex: "4CAF50"), Color(hex: "3F51B5")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // ── LEFT PANE: Letter Gallery & Selector (40% width) ───────
            VStack(spacing: 16) {
                // Category Selector
                HStack(spacing: 6) {
                    categoryButton(title: "Vowels (13)", index: 0)
                    categoryButton(title: "Consonants (36)", index: 1)
                    categoryButton(title: "All (49)", index: 2)
                }
                .padding(6)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Multi-Column Letter Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 12)], spacing: 12) {
                        ForEach(Array(currentLettersList.enumerated()), id: \.element.id) { index, letter in
                            let isSelected = displayedLetter.id == letter.id
                            Button(action: {
                                selectLetter(letter)
                            }) {
                                VStack(spacing: 4) {
                                    Text(letter.char)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(isSelected ? .white : Color(hex: "2D2D2D"))
                                    Text(letter.transliteration)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                                    StarRow(filled: ProgressStore.shared.stars(for: letter.char), size: 9)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 88)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "8F40FF"), Color(hex: "6200EA")],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: Color(hex: "8F40FF").opacity(0.45), radius: 8, x: 0, y: 4)
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        }
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
            .frame(width: 380)
            .background(Color(hex: "F4F6F9"))
            
            Divider()
            
            // ── RIGHT PANE: Interactive Studio Workbench (60% width) ───
            VStack(spacing: 16) {
                // Top Workbench Header: Stepper & Sound
                HStack {
                    // Category & Index
                    HStack(spacing: 8) {
                        Text(displayedLetter.category.uppercased())
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.15))
                            .cornerRadius(10)
                        
                        Text(displayedLetter.transliteration)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Audio Pronunciation Button
                    Button(action: {
                        viewModel.playSound(displayedLetter.sound)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 18))
                            Text("Listen")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .cornerRadius(20)
                        .shadow(color: accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Previous / Next Stepper
                    HStack(spacing: 6) {
                        Button(action: stepPrevious) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: stepNext) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Bilingual Artwork & Example Showcase Card
                HStack(spacing: 24) {
                    // Huge 3D Letter Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(accentColor.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(accentColor, lineWidth: 3))
                        
                        Text(displayedLetter.char)
                            .font(.system(size: 96, weight: .black))
                            .foregroundColor(accentColor)
                    }
                    .frame(width: 140, height: 140)
                    
                    // Illustrated Example
                    Button(action: {
                        viewModel.playSound(displayedLetter.sound)
                    }) {
                        HStack(spacing: 16) {
                            Image(displayedLetter.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                                .cornerRadius(16)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(displayedLetter.example)
                                    .font(.system(size: 30, weight: .heavy))
                                    .foregroundColor(Color(hex: "222222"))
                                
                                Text(displayedLetter.exampleEn)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 12))
                                    Text("Tap artwork to hear")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(accentColor)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                
                // Live Integrated Tracing Pad
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Interactive Tracing Pad • വിരലുകൊണ്ട് എഴുതി പഠിക്കൂ")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "333333"))
                            Text("Trace the guide letter with your finger or stylus")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Progress
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(accentColor)
                        
                        // Reset
                        Button(action: clearTracing) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .bold))
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Fullscreen mode link
                        NavigationLink(destination: TracingScreen(viewModel: viewModel, letter: displayedLetter)) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Full Screen")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
                        .padding(.horizontal, 24)
                    
                    // The Canvas
                    TracingBoard(
                        glyph: TraceGlyph.make(for: displayedLetter.char),
                        color: accentColor,
                        onProgress: { progress = $0 },
                        onComplete: { mistakes in
                            progress = 1.0
                            ProgressStore.shared.recordTrace(item: TraceItem(letter: displayedLetter),
                                                             stars: TraceTheme.stars(mistakes: mistakes),
                                                             slips: mistakes, mode: .guided)
                            TraceFeedback.shared.celebrate()
                            Speaker.shared.say(TraceItem(letter: displayedLetter))
                            showReward = true
                        }
                    )
                    .id("\(displayedLetter.id)-\(traceAttempt)")
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }
            .background(Color(hex: "FAFAFC"))
        }
        .environment(\.colorScheme, .light)
        .tracksLearningTime()
        .navigationTitle("Alphabet Studio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if activeLetter == nil {
                activeLetter = viewModel.vowels.first
            }
        }
    }
    
    // MARK: - Helpers
    private func categoryButton(title: String, index: Int) -> some View {
        let isSelected = selectedCategory == index
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = index
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .white : Color(hex: "666666"))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    isSelected ?
                        LinearGradient(colors: [Color(hex: "8F40FF"), Color(hex: "CA5BFF")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func selectLetter(_ letter: Letter) {
        activeLetter = letter
        clearTracing()
        Speaker.shared.say(TraceItem(letter: letter))
    }
    
    private func clearTracing() {
        progress = 0.0
        showReward = false
        traceAttempt += 1
    }
    
    private func stepNext() {
        let list = currentLettersList
        if let idx = list.firstIndex(where: { $0.id == displayedLetter.id }), idx + 1 < list.count {
            selectLetter(list[idx + 1])
        }
    }
    
    private func stepPrevious() {
        let list = currentLettersList
        if let idx = list.firstIndex(where: { $0.id == displayedLetter.id }), idx > 0 {
            selectLetter(list[idx - 1])
        }
    }
}
