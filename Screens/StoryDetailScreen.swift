import SwiftUI

struct StoryDetailScreen: View {
    let story: Story
    /// Injected by StorySelectScreen — calls NavigationLink's isActive = false
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var envDismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var currentPage: Int = 0

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
                                Text(story.pages[currentPage].text)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(Color(hex: "2D2D2D"))
                                    .lineSpacing(10)
                                    .multilineTextAlignment(.leading)
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
                                    Text(isLastPage ? "Finish Story 🎉" : "Next Page")
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
            Text(story.pages[currentPage].text)
                .font(.system(size: 26, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "2D2D2D"))
                .lineSpacing(8)
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
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

    private func goBack() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            envDismiss()
        }
    }
}

