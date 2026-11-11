import SwiftUI

struct StoryDetailScreen: View {
    let story: Story
    /// Injected by StorySelectScreen — calls NavigationLink's isActive = false
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var envDismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var currentPage: Int = 0
    @StateObject private var reader = ReadAlongController()

    private var totalPages: Int { story.pages.count }
    private var isLastPage: Bool { currentPage == totalPages - 1 }

    var body: some View {
        ZStack(alignment: .top) {
            // ── Background gradient ─────────────────────────────────────
            LinearGradient(
                colors: [Color(hex: "FF9A3C"), Color(hex: "FF6B6B"), Color(hex: "FF8FAB")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Main content (pushed below top bar) ─────────────────────
            if hSizeClass == .regular {
                // iPad: image on the left, text card on the right
                iPadContent
                    .padding(.top, 72)
            } else {
                // iPhone: original stacked layout
                iPhoneContent
                    .padding(.top, 72)
            }

            // ── Independent Top Bar (Floating on top) ────────────────────
            HStack(spacing: 12) {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                Text(story.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "7B2300"))
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .light)
        .tracksLearningTime()
        .onChange(of: currentPage) { _, _ in reader.stop() }
        .onDisappear { reader.stop() }
    }

    // MARK: – iPhone layout (original)
    private var iPhoneContent: some View {
        VStack(spacing: 0) {
            storyImageCard
                .padding(.horizontal, 16)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

            storyTextCard
                .padding(.horizontal, 12)
                .padding(.top, 14)

            navigationRow
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
        }
        .gesture(swipeBackGesture)
        .gesture(pageSwipeGesture)
    }

    // MARK: – iPad layout (Authentic Two-Page Open Book Spread)
    private var iPadContent: some View {
        VStack(spacing: 16) {
            // The Open Book Container
            HStack(spacing: 0) {
                // ── LEFT PAGE: Full Illustration Spread ─────────────────────
                ZStack {
                    Color(hex: "FCFAF6")
                    
                    VStack {
                        if UIImage(named: story.pages[currentPage].imageName) != nil {
                            Image(story.pages[currentPage].imageName)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                                .padding(24)
                        } else {
                            ZStack {
                                Color(hex: "FFE0B2")
                                Image(systemName: "photo")
                                    .font(.system(size: 80))
                                    .foregroundColor(Color(hex: "FFAB40").opacity(0.5))
                            }
                            .cornerRadius(16)
                            .padding(24)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay(
                    // Inner spine shadow on the right edge of left page
                    LinearGradient(
                        colors: [Color.black.opacity(0.12), Color.clear],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .frame(width: 20)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                )
                
                // ── BOOK SPINE DIVIDER ──────────────────────────────────────
                Rectangle()
                    .fill(Color(hex: "D8D0C5"))
                    .frame(width: 4)
                    .shadow(color: .black.opacity(0.15), radius: 3)
                
                // ── RIGHT PAGE: Story Text & Controls ───────────────────────
                ZStack {
                    Color(hex: "FCFAF6")
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Top Header of page
                        HStack {
                            Text(story.titleEn.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "A1887F"))
                                .tracking(1.2)
                            
                            Spacer()
                            
                            Text("Page \(currentPage + 1) of \(totalPages)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "8D6E63"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: "EFEBE9"))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 28)
                        
                        // Story Text ScrollView
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                readAlongButton
                                ReadAlongText(text: story.pages[currentPage].text, reader: reader,
                                              fontSize: 32, alignment: .leading)
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                        }
                        .id(currentPage)
                        
                        Spacer()
                        
                        // Bottom Navigation Controls
                        HStack {
                            // Previous Page Button
                            Button(action: {
                                if currentPage > 0 {
                                    withAnimation(.easeInOut(duration: 0.25)) { currentPage -= 1 }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(currentPage > 0 ? Color(hex: "FF6B35") : Color.gray.opacity(0.4))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }
                            .disabled(currentPage == 0)
                            
                            Spacer()
                            
                            // Page dots
                            HStack(spacing: 8) {
                                ForEach(0..<totalPages, id: \.self) { i in
                                    Circle()
                                        .fill(i == currentPage ? Color(hex: "FF6B35") : Color(hex: "D7CCC8"))
                                        .frame(width: i == currentPage ? 10 : 7, height: i == currentPage ? 10 : 7)
                                }
                            }
                            
                            Spacer()
                            
                            // Next or Finish Button
                            Button(action: {
                                if isLastPage {
                                    goBack()
                                } else {
                                    withAnimation(.easeInOut(duration: 0.25)) { currentPage += 1 }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(isLastPage ? "Finish Story" : "Next Page")
                                    Image(systemName: isLastPage ? "checkmark" : "chevron.right")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "FF6B35"), Color(hex: "FF8E53")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(hex: "FF6B35").opacity(0.35), radius: 6, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay(
                    // Inner spine shadow on the left edge of right page
                    LinearGradient(
                        colors: [Color.black.opacity(0.12), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            }
            .background(Color(hex: "FCFAF6"))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .gesture(swipeBackGesture)
        .gesture(pageSwipeGesture)
    }

    // MARK: – Shared sub-views

    private var storyImageCard: some View {
        ZStack(alignment: .topTrailing) {
            if UIImage(named: story.pages[currentPage].imageName) != nil {
                GeometryReader { geo in
                    Image(story.pages[currentPage].imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .frame(height: 240)
                .cornerRadius(20)
            } else {
                ZStack {
                    Color(hex: "FFE0B2")
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "FFAB40").opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .cornerRadius(20)
            }
        }
    }

    private var storyTextCard: some View {
        ScrollView {
            VStack(spacing: 14) {
                readAlongButton
                ReadAlongText(text: story.pages[currentPage].text, reader: reader,
                              fontSize: 26, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .id(currentPage)
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
    }

    private var navigationRow: some View {
        HStack {
            HStack(spacing: 7) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage
                              ? Color.white
                              : Color.white.opacity(0.4))
                        .frame(width: i == currentPage ? 10 : 7,
                               height: i == currentPage ? 10 : 7)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }

            Spacer()

            Button {
                if isLastPage {
                    goBack()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage += 1
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    Image(systemName: isLastPage ? "checkmark" : "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "FF6B35"))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: – Gestures
    private var swipeBackGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                if value.translation.width > 80 { goBack() }
            }
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                if value.translation.width < -40, !isLastPage {
                    withAnimation { currentPage += 1 }
                } else if value.translation.width > 40, currentPage > 0 {
                    withAnimation { currentPage -= 1 }
                }
            }
    }

    private var readAlongButton: some View {
        Button {
            if reader.isReading { reader.stop() } else { reader.read(story.pages[currentPage].text) }
        } label: {
            Label(reader.isReading ? "Stop" : "Read along", systemImage: reader.isReading ? "stop.fill" : "play.fill")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(minHeight: 46)
                .background(Capsule().fill(Color(hex: "FF6B35")))
        }
        .buttonStyle(KidButtonStyle())
    }

    private func goBack() {
        reader.stop()
        if isLastPage { ProgressStore.shared.recordStoryRead(story.id) }
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            envDismiss()
        }
    }
}



// MARK: - Read-along

/// Steps through a page word by word, highlighting each one (and speaking it when a
/// Malayalam voice is installed on the device).
@MainActor
final class ReadAlongController: ObservableObject {
    @Published var current: Int?
    @Published var isReading = false
    private var task: Task<Void, Never>?

    static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
    }

    func read(_ text: String, from start: Int = 0) {
        stop()
        let words = Self.words(text)
        isReading = true
        task = Task { [weak self] in
            for i in start..<words.count {
                guard let self, !Task.isCancelled else { return }
                self.current = i
                let spoken = Speaker.shared.sayMalayalam(words[i].trimmingCharacters(in: .punctuationCharacters), rate: 0.4)
                let seconds = (spoken ? 0.5 : 0.35) + 0.08 * Double(words[i].count)
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
            guard let self, !Task.isCancelled else { return }
            self.isReading = false
            try? await Task.sleep(nanoseconds: 600_000_000)
            if !self.isReading { self.current = nil }
        }
    }

    func tap(_ index: Int, word: String) {
        stop()
        current = index
        Haptics.tap()
        Speaker.shared.sayMalayalam(word.trimmingCharacters(in: .punctuationCharacters), rate: 0.4)
    }

    func stop() {
        task?.cancel()
        task = nil
        isReading = false
    }
}

struct ReadAlongText: View {
    let text: String
    @ObservedObject var reader: ReadAlongController
    var fontSize: CGFloat
    var alignment: HorizontalAlignment

    var body: some View {
        let words = ReadAlongController.words(text)
        WordFlow(alignment: alignment, spacing: fontSize * 0.28, lineSpacing: fontSize * 0.35) {
            ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                let on = reader.current == i
                Text(word)
                    .font(.system(size: fontSize, weight: on ? .bold : .medium))
                    .foregroundColor(on ? Color(hex: "7B2300") : Color(hex: "2D2D2D"))
                    .padding(.horizontal, 4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(on ? Color(hex: "FFD54F") : .clear))
                    .scaleEffect(on ? 1.08 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: on)
                    .onTapGesture { reader.tap(i, word: word) }
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
    }
}

/// Wraps children onto lines like text.
struct WordFlow: Layout {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = alignment == .leading ? bounds.minX : bounds.minX + (bounds.width - row.width) / 2
            for i in row.indices {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let r = rows.count - 1
            rows[r].width += rows[r].indices.isEmpty ? size.width : size.width + spacing
            rows[r].height = max(rows[r].height, size.height)
            rows[r].indices.append(i)
        }
        return rows
    }
}
