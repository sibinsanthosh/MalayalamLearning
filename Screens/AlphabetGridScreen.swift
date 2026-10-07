import SwiftUI

struct AlphabetGridScreen: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedTab = 0
    @State private var selectedLetter: Letter?

    @Environment(\.horizontalSizeClass) private var hSizeClass

    /// Minimum card size: slightly larger on iPad so more columns appear naturally
    private var cellMin: CGFloat { hSizeClass == .regular ? 120 : 100 }

    var columns: [GridItem] { [GridItem(.adaptive(minimum: cellMin), spacing: 14)] }

    // Pastel colors for cards
    let pastelColors: [Color] = [
        Color(hex: "FFC107"),
        Color(hex: "03A9F4"),
        Color(hex: "E91E63"),
        Color(hex: "FF9800"),
        Color(hex: "4CAF50"),
        Color(hex: "3F51B5")
    ]

    var body: some View {
        if hSizeClass == .regular {
            IPadAlphabetStudioView(viewModel: viewModel)
        } else {
            iPhoneAlphabetView
        }
    }

    private var iPhoneAlphabetView: some View {
        ZStack {
            Color(hex: "F7F7F7").ignoresSafeArea()

            VStack {
                // Custom Segmented Control
                HStack(spacing: 0) {
                    SegmentButton(title: "Vowels", isSelected: selectedTab == 0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 0 }
                    }
                    SegmentButton(title: "Consonants", isSelected: selectedTab == 1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 1 }
                    }
                }
                .padding(4)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                .frame(maxWidth: 430)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        let letters = selectedTab == 0 ? viewModel.vowels : viewModel.consonants

                        ForEach(Array(letters.enumerated()), id: \.element.id) { index, letter in
                            Button(action: {
                                InterstitialAdManager.shared.showAdIfAppropriate {
                                    selectedLetter = letter
                                }
                            }) {
                                LetterCardView(
                                    char: letter.char,
                                    color: pastelColors[index % pastelColors.count],
                                    size: 100
                                )
                            }
                        }
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .navigationTitle("Alphabet Garden")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedLetter) { letter in
            LetterDetailScreen(viewModel: viewModel, letter: letter)
        }
    }
    
    struct LetterCardView: View {
        let char: String
        let color: Color
        var size: CGFloat = 100

        var body: some View {
            VStack {
                Text(char)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .background(color)
            .cornerRadius(16)
            .shadow(radius: 2)
        }
    }
    
    struct SegmentButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 18, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: "888888"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            if isSelected {
                                LinearGradient(
                                    colors: [Color(hex: "FF9A9E"), Color(hex: "FECFEF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(25)
                                .shadow(color: Color(hex: "FF9A9E").opacity(0.5), radius: 6, x: 0, y: 3)
                            } else {
                                Color.clear
                            }
                        }
                    )
            }
        }
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
    @State private var paths: [Path] = []
    @State private var currentPath = Path()
    @State private var progress: CGFloat = 0.0
    @State private var visitedQuadrants = Set<Int>()
    @State private var totalDistance: CGFloat = 0.0
    @State private var lastPoint: CGPoint? = nil
    @State private var showReward: Bool = false
    
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
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 76)
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
                    GeometryReader { geo in
                        ZStack {
                            // Guide Letter behind
                            Text(displayedLetter.char)
                                .font(.system(size: 1000, weight: .bold))
                                .minimumScaleFactor(0.01)
                                .lineLimit(1)
                                .foregroundColor(Color.gray.opacity(0.18))
                                .frame(width: geo.size.width * 0.92, height: geo.size.height * 0.86)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                            
                            // Live Drawing
                            Canvas { context, size in
                                for path in paths {
                                    context.stroke(path, with: .color(accentColor), lineWidth: 12)
                                }
                                context.stroke(currentPath, with: .color(accentColor), lineWidth: 12)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        handleTracingDrag(point: value.location, size: geo.size)
                                    }
                                    .onEnded { _ in
                                        paths.append(currentPath)
                                        currentPath = Path()
                                        lastPoint = nil
                                        if progress >= 0.95 {
                                            progress = 1.0
                                            viewModel.addPoints(10)
                                            showReward = true
                                        }
                                    }
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(hex: "FAFAFC"))
        }
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
        viewModel.playSound(letter.sound)
    }
    
    private func clearTracing() {
        paths = []
        currentPath = Path()
        progress = 0.0
        visitedQuadrants.removeAll()
        totalDistance = 0.0
        lastPoint = nil
        showReward = false
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
    
    private func handleTracingDrag(point: CGPoint, size: CGSize) {
        let width = size.width
        let height = size.height
        let centerX = width / 2
        let centerY = height / 2
        
        let minX = width * 0.03
        let maxX = width * 0.97
        let minY = height * 0.03
        let maxY = height * 0.97
        
        guard point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY else { return }
        
        if currentPath.isEmpty {
            currentPath.move(to: point)
            lastPoint = point
        } else {
            currentPath.addLine(to: point)
            if let last = lastPoint {
                let dist = sqrt(pow(point.x - last.x, 2) + pow(point.y - last.y, 2))
                totalDistance += dist
            }
            lastPoint = point
        }
        
        let quad: Int
        if point.x < centerX {
            quad = point.y < centerY ? 1 : 3
        } else {
            quad = point.y < centerY ? 2 : 4
        }
        visitedQuadrants.insert(quad)
        
        let targetDistance = (width + height) * 1.0
        let distanceRatio = min(totalDistance / targetDistance, 1.0)
        let quadrantRatio = CGFloat(visitedQuadrants.count) / 4.0
        progress = distanceRatio * quadrantRatio
    }
}
