import SwiftUI

struct GameSelectScreen: View {
    @ObservedObject var viewModel: MainViewModel
    
    @Environment(\.horizontalSizeClass) private var hSizeClass

    /// 3 columns on iPad, 2 on iPhone
    private var columns: [GridItem] {
        let count = hSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    /// Cap card height on iPad so they don't stretch too tall in a wider grid
    private var cardHeight: CGFloat { hSizeClass == .regular ? 160 : 130 }

    var body: some View {
        if hSizeClass == .regular {
            IPadGameSelectView(viewModel: viewModel)
        } else {
            iPhoneGameSelectView
        }
    }

    private var iPhoneGameSelectView: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "FFFDE7"), Color(hex: "E0F7FA")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    NavigationLink(destination: BalloonPopGameScreen(viewModel: viewModel)) {
                        DashboardCard(
                            title: "Balloon Pop",
                            iconName: "circle.fill",
                            color1: Color(hex: "FF9A9E"),
                            color2: Color(hex: "FECFEF"),
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }
                    
                    NavigationLink(destination: MemoryMatchGameScreen()) {
                        DashboardCard(
                            title: "Memory Match",
                            iconName: "square.grid.2x2.fill",
                            color1: Color(hex: "A18CD1"),
                            color2: Color(hex: "FBC2EB"),
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }
                    
                    NavigationLink(destination: LetterQuizGameScreen()) {
                        DashboardCard(
                            title: "Letter Quiz",
                            iconName: "questionmark.circle.fill",
                            color1: Color(hex: "84FAB0"),
                            color2: Color(hex: "8FD3F4"),
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }
                    
                    NavigationLink(destination: WordMatchGameScreen()) {
                        DashboardCard(
                            title: "Word Match",
                            iconName: "text.book.closed.fill",
                            color1: Color(hex: "FF9A9E"),
                            color2: Color(hex: "FECFEF"),
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }
                    
                    NavigationLink(destination: CatchTheLetterGameScreen()) {
                        DashboardCard(
                            title: "Catch It!",
                            iconName: "hand.tap.fill",
                            color1: Color(hex: "F6D365"),
                            color2: Color(hex: "FDA085"),
                            action: {}
                        )
                        .allowsHitTesting(false)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Games")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ==========================================
// MARK: - IPAD GAMES ARENA VIEW
// MARK: - ==========================================

struct IPadGameSelectView: View {
    @ObservedObject var viewModel: MainViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]
    
    var body: some View {
        ZStack {
            // Tablet playground background
            LinearGradient(
                colors: [Color(hex: "FFF8E1"), Color(hex: "E1F5FE")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Games Arena • കളിയരങ്ങ്")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(Color(hex: "2E1C0C"))
                            Text("Play interactive educational mini-games to practice listening and vocabulary")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "6D4C41"))
                        }
                        
                        Spacer()
                        
                        // Points Banner
                        HStack(spacing: 8) {
                            Text("⭐")
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TOTAL POINTS")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.secondary)
                                Text("\(viewModel.progress.points) Pts")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(Color(hex: "B78103"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    // 3-Column Games Grid
                    LazyVGrid(columns: columns, spacing: 24) {
                        NavigationLink(destination: BalloonPopGameScreen(viewModel: viewModel)) {
                            IPadGameCard(
                                title: "Balloon Pop",
                                titleMl: "ബലൂൺ പൊട്ടിക്കൽ",
                                subtitle: "Pop floating letter balloons to hear sounds and earn stars",
                                skillTag: "Auditory Learning",
                                iconName: "balloon.fill",
                                systemIconFallback: "circle.fill",
                                colors: [Color(hex: "FF6584"), Color(hex: "FF8E53")]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: MemoryMatchGameScreen()) {
                            IPadGameCard(
                                title: "Memory Match",
                                titleMl: "ഓർമ്മക്കളി",
                                subtitle: "Flip and match pairs of Malayalam letters to test memory",
                                skillTag: "Visual Recall",
                                iconName: "square.grid.2x2.fill",
                                systemIconFallback: "square.grid.2x2.fill",
                                colors: [Color(hex: "7928CA"), Color(hex: "FF0080")]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: LetterQuizGameScreen()) {
                            IPadGameCard(
                                title: "Letter Quiz",
                                titleMl: "അക്ഷര ക്വിസ്",
                                subtitle: "Listen to the letter pronunciation and choose the right character",
                                skillTag: "Listening Quiz",
                                iconName: "questionmark.circle.fill",
                                systemIconFallback: "questionmark.circle.fill",
                                colors: [Color(hex: "00B4D8"), Color(hex: "0077B6")]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: WordMatchGameScreen()) {
                            IPadGameCard(
                                title: "Word Match",
                                titleMl: "വാക്കു കളി",
                                subtitle: "Identify the starting Malayalam letter for each illustrated word",
                                skillTag: "Vocabulary",
                                iconName: "character.book.closed.fill",
                                systemIconFallback: "book.fill",
                                colors: [Color(hex: "0575E6"), Color(hex: "00F260")]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: CatchTheLetterGameScreen()) {
                            IPadGameCard(
                                title: "Catch It!",
                                titleMl: "പിടിക്കാം",
                                subtitle: "Tap falling letters quickly before they touch the ground",
                                skillTag: "Speed & Reflexes",
                                iconName: "hand.tap.fill",
                                systemIconFallback: "hand.tap.fill",
                                colors: [Color(hex: "F7971E"), Color(hex: "FFD200")]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Games Arena")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IPadGameCard: View {
    let title: String
    let titleMl: String
    let subtitle: String
    let skillTag: String
    let iconName: String
    let systemIconFallback: String
    let colors: [Color]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: iconName)
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(skillTag)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("• \(titleMl)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack {
                    Text("Play Now")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(colors[0])
                        )
                        .shadow(radius: 3)
                }
            }
            .padding(22)
        }
        .frame(height: 250)
        .cornerRadius(24)
        .shadow(color: colors[0].opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

