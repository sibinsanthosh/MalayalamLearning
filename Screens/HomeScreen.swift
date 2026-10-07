import SwiftUI

struct HomeScreen: View {
    @StateObject var viewModel: MainViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var body: some View {
        if hSizeClass == .regular {
            IPadHomeScreen(viewModel: viewModel)
        } else {
            IPhoneHomeScreen(viewModel: viewModel)
        }
    }
}

// MARK: - ==========================================
// MARK: - 100% ORIGINAL IPHONE EXPERIENCE
// MARK: - ==========================================

struct IPhoneHomeScreen: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background Colors
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color(hex: "7BD4F8"), Color(hex: "B7E9F9")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geo.size.height * 0.45)
                        
                        ZStack(alignment: .top) {
                            Color(hex: "5FA926")
                            Rectangle()
                                .fill(Color(hex: "4D8A1C"))
                                .frame(width: 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .ignoresSafeArea()
                
                // Clouds
                GeometryReader { geo in
                    Circle().fill(Color.white.opacity(0.8)).frame(width: 100).position(x: 50, y: 50)
                    Circle().fill(Color.white.opacity(0.8)).frame(width: 150).position(x: 100, y: 70)
                    Circle().fill(Color.white.opacity(0.8)).frame(width: 120).position(x: 170, y: 40)
                }
                .ignoresSafeArea()
                
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        HeaderSection(viewModel: viewModel)
                            .padding(.top, 10)
                            .padding(.horizontal, 20)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Alphabet Card
                                NavigationLink(destination: AlphabetGridScreen(viewModel: viewModel)) {
                                    AlphabetCardView()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Games and Stories Row
                                HStack(spacing: 16) {
                                    NavigationLink(destination: GameSelectScreen(viewModel: viewModel)) {
                                        GameCardView()
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    NavigationLink(destination: StorySelectScreen(viewModel: viewModel)) {
                                        StoryCardView()
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Dictionary Card
                                NavigationLink(destination: DictionaryScreen()) {
                                    DictionaryCardView(isVertical: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Motivation pill
                                HStack {
                                    Image(systemName: "star.fill").foregroundColor(.yellow)
                                    Text("Keep learning, shine bright!")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(hex: "555555"))
                                    Image(systemName: "sparkles").foregroundColor(.yellow)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 24)
                                .background(Color.white)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                                .padding(.bottom, 20)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: 430)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - ==========================================
// MARK: - COMPLETE IPAD REDESIGN (TABLET HUB)
// MARK: - ==========================================

struct IPadHomeScreen: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Full-bleed landscape background
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color(hex: "68CEF8"), Color(hex: "BCEBF9")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geo.size.height * 0.28)
                        
                        ZStack(alignment: .top) {
                            LinearGradient(
                                colors: [Color(hex: "5CA824"), Color(hex: "428216")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Decorative tree trunk
                            Rectangle()
                                .fill(Color(hex: "3A6D14"))
                                .frame(width: 50)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Landscape clouds — shallow & spread wide
                    Group {
                        Circle().fill(Color.white.opacity(0.85)).frame(width: 110).position(x: 80, y: 40)
                        Circle().fill(Color.white.opacity(0.75)).frame(width: 160).position(x: 180, y: 65)
                        Circle().fill(Color.white.opacity(0.8)).frame(width: 130).position(x: geo.size.width * 0.38, y: 35)
                        Circle().fill(Color.white.opacity(0.7)).frame(width: 150).position(x: geo.size.width - 220, y: 55)
                        Circle().fill(Color.white.opacity(0.85)).frame(width: 110).position(x: geo.size.width - 100, y: 75)
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    // Top Bar: Mascot Appu, Gamification Stats
                    IPadTopBar(viewModel: viewModel)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // 1. Hero Deck: Interactive Alphabet Garden (full width)
                            IPadAlphabetHeroCard(viewModel: viewModel)
                            
                            // 2. 2×2 Activity Grid (Games, Stories, Dictionary, Daily Practice)
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ],
                                spacing: 16
                            ) {
                                NavigationLink(destination: GameSelectScreen(viewModel: viewModel)) {
                                    IPadGamesDeckCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                NavigationLink(destination: StorySelectScreen(viewModel: viewModel)) {
                                    IPadStoriesDeckCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                NavigationLink(destination: DictionaryScreen()) {
                                    IPadDictionaryDeckCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                NavigationLink(destination: AlphabetGridScreen(viewModel: viewModel)) {
                                    IPadDailyPracticeDeckCard(viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // 3. Bottom Progress Banner
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill").foregroundColor(.yellow)
                                Text("Keep learning, shine bright! • നന്നായി പഠിക്കൂ, തിളങ്ങി നിൽക്കൂ!")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(hex: "444444"))
                                Image(systemName: "sparkles").foregroundColor(.yellow)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 28)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 28)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}


// MARK: - iPad Top Bar
struct IPadTopBar: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Mascot Appu & Greeting Button
            Button(action: {
                viewModel.playSound("pop")
            }) {
                HStack(spacing: 12) {
                    // Appu Avatar
                    Image("mascot_appu")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 2)
                    
                    Text("👋 നമസ്കാരം!")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(Color(hex: "4A2E73"))
                    
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Color(hex: "8A6AF1"))
                        .font(.system(size: 18))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.92))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Right: Streak, Points & Share
            HStack(spacing: 12) {
                // Streak
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 20))
                    Text("\(viewModel.progress.streak) Days")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "FF6B35"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.92))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                // Points
                HStack(spacing: 6) {
                    Text("⭐")
                        .font(.system(size: 20))
                    Text("\(viewModel.progress.points) Pts")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "B78103"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.92))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                // Share
                ShareLink(item: URL(string: "https://apps.apple.com/in/app/learn-malayalam-easy/id6759353287")!) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.black)
                                .font(.system(size: 15, weight: .bold))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
}

struct IPadNavPill: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "333333"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - iPad Alphabet Hero Card with Interactive Quick Letter Ribbon
struct IPadAlphabetHeroCard: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient Background
            LinearGradient(
                colors: [Color(hex: "CA5BFF"), Color(hex: "7929F5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative background letters
            HStack {
                Spacer()
                Text("അ")
                    .font(.system(size: 160, weight: .bold))
                    .foregroundColor(.white.opacity(0.08))
                Text("ക")
                    .font(.system(size: 160, weight: .bold))
                    .foregroundColor(.white.opacity(0.08))
            }
            .offset(y: 20)
            
            VStack(alignment: .leading, spacing: 10) {
                // Top Header row
                HStack(alignment: .center, spacing: 20) {
                    // 3D Letter Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "5A1090"))
                            .frame(width: 80, height: 66)
                            .offset(y: 5)
                        
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "7B1FA2"))
                            .frame(width: 80, height: 66)
                        
                        Text("അ")
                            .font(.system(size: 42, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("Alphabet Garden • അക്ഷരത്തോട്ടം")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Image(systemName: "sparkle")
                                .foregroundColor(.yellow)
                        }
                        
                        Text("Explore 13 Vowels and 36 Consonants with authentic native pronunciation and live tracing studio")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Enter Garden Button
                    NavigationLink(destination: AlphabetGridScreen(viewModel: viewModel)) {
                        HStack(spacing: 8) {
                            Text("Enter Studio")
                                .font(.system(size: 15, weight: .bold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(Color(hex: "7929F5"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                
                // Quick-Letter Auditory Ribbon
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("TAP ANY LETTER TO LISTEN:")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.0)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.vowels + viewModel.consonants.prefix(12), id: \.id) { letter in
                                Button(action: {
                                    viewModel.playSound(letter.sound)
                                }) {
                                    VStack(spacing: 2) {
                                        Text(letter.char)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(letter.transliteration)
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                    .frame(width: 48, height: 50)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            // Trailing spacer to prevent last letter clipping
                            Color.clear.frame(width: 24, height: 50)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .frame(minHeight: 180)
        .cornerRadius(26)
        .shadow(color: Color(hex: "7929F5").opacity(0.4), radius: 12, x: 0, y: 8)
    }
}

// MARK: - iPad Games Pavilion Deck Card
struct IPadGamesDeckCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "FFA84A"), Color(hex: "FF6536")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 52, height: 52)
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("5 GAMES")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Games Zone • കളികൾ")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Fun mini-games to build rapid recognition")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Game Preview Pills
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        IPadMiniTag(text: "🎈 Balloon Pop")
                        IPadMiniTag(text: "🃏 Memory Match")
                    }
                    HStack(spacing: 6) {
                        IPadMiniTag(text: "❓ Letter Quiz")
                        IPadMiniTag(text: "🖐️ Catch It")
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("Play Games")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "FF6536"))
                        )
                        .shadow(radius: 3)
                }
            }
            .padding(20)
        }
        .frame(height: 240)
        .cornerRadius(24)
        .shadow(color: Color(hex: "FF6536").opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

// MARK: - iPad Stories Deck Card
struct IPadStoriesDeckCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "FF4081"), Color(hex: "D500F9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 52, height: 52)
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("5 STORIES")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storybook Castle • കഥകൾ")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Engaging illustrated tales with moral lessons")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Story Preview Chips
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        IPadMiniTag(text: "🦅 ദാഹിച്ച കാക്ക")
                        IPadMiniTag(text: "🐜 ഉറുമ്പും പ്രാവും")
                    }
                    HStack(spacing: 6) {
                        IPadMiniTag(text: "🐢 മുയലും ആമയും")
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("Read Stories")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "D500F9"))
                        )
                        .shadow(radius: 3)
                }
            }
            .padding(20)
        }
        .frame(height: 240)
        .cornerRadius(24)
        .shadow(color: Color(hex: "D500F9").opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

// MARK: - iPad Dictionary Deck Card
struct IPadDictionaryDeckCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "38C7F8"), Color(hex: "0277BD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 52, height: 52)
                        Image(systemName: "character.book.closed.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("10,000+ WORDS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dictionary • നിഘണ്ടു")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text("English to Malayalam search & definitions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Word of the Day preview card
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORD OF THE DAY")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 8) {
                        Text("സൂര്യൻ")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Text("• Sun")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                HStack {
                    Text("Search Dictionary")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "0277BD"))
                        )
                        .shadow(radius: 3)
                }
            }
            .padding(20)
        }
        .frame(height: 240)
        .cornerRadius(24)
        .shadow(color: Color(hex: "0277BD").opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

// MARK: - iPad Daily Practice Deck Card (4th slot in 2×2 grid)
struct IPadDailyPracticeDeckCard: View {
    @ObservedObject var viewModel: MainViewModel
    
    private var letterOfDay: Letter {
        let all = viewModel.vowels + viewModel.consonants
        let dayIndex = Calendar.current.component(.day, from: Date()) % all.count
        return all[dayIndex]
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "11C7A0"), Color(hex: "0A7E6A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative large letter watermark
            Text(letterOfDay.char)
                .font(.system(size: 160, weight: .black))
                .foregroundColor(.white.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 52, height: 52)
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("DAILY PRACTICE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tracing Studio • ലിഖന ശാല")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Trace letters with your finger or Apple Pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Letter of the Day preview
                HStack(spacing: 12) {
                    Text("TODAY:")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 8) {
                        Text(letterOfDay.char)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text("• \(letterOfDay.transliteration)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                HStack {
                    Text("Open Studio")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "0A7E6A"))
                        )
                        .shadow(radius: 3)
                }
            }
            .padding(20)
        }
        .frame(height: 240)
        .cornerRadius(24)
        .shadow(color: Color(hex: "0A7E6A").opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

struct IPadMiniTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
    }
}


struct HeaderSection: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var body: some View {
        ZStack(alignment: .top) {
            // Greeting in center
            Button(action: {
                viewModel.playSound("pop")
            }) {
                HStack(spacing: 8) {
                    Text("👋")
                        .font(.system(size: 32))
                    Text("നമസ്കാരം!")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(Color(hex: "4A2E73"))
                    
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Color(hex: "8A6AF1"))
                        .font(.system(size: 20))
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.9))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 14)
            
            // Sun with Settings/Share on Top Right
            HStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Image(systemName: "sun.max.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        // Eyes and smile
                        VStack(spacing: 2) {
                            HStack(spacing: 12) {
                                Circle().fill(Color.black).frame(width: 6, height: 6)
                                Circle().fill(Color.black).frame(width: 6, height: 6)
                            }
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addQuadCurve(to: CGPoint(x: 16, y: 0), control: CGPoint(x: 8, y: 8))
                            }
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 16, height: 8)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 10)
                    
                    ShareLink(item: URL(string: "https://apps.apple.com/in/app/learn-malayalam-easy/id6759353287")!) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.black)
                                    .font(.system(size: 14, weight: .bold))
                            )
                            .shadow(radius: 2)
                    }
                    .offset(x: 10, y: -10)
                }
            }
        }
        .frame(height: hSizeClass == .regular ? 100 : 120)
        .padding(.bottom, 16)
    }
}

struct AlphabetCardView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            LinearGradient(colors: [Color(hex: "D570FF"), Color(hex: "8F40FF")], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            // Floating background letters
            Text("അ")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white.opacity(0.12))
                .offset(x: -10, y: -40)
            
            Text("ഇ")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white.opacity(0.12))
                .offset(x: 200, y: -60)
            
            Text("ഉ")
                .font(.system(size: 70, weight: .bold))
                .foregroundColor(.white.opacity(0.12))
                .offset(x: 150, y: 40)
            
            if hSizeClass == .regular {
                Text("ഋ")
                    .font(.system(size: 65, weight: .bold))
                    .foregroundColor(.white.opacity(0.12))
                    .offset(x: 360, y: -40)
                
                Text("ക")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundColor(.white.opacity(0.12))
                    .offset(x: 500, y: 30)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // The 3D Letter button
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "6A1B9A"))
                        .frame(width: 96, height: 76)
                        .offset(y: 6)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "8E24AA"))
                        .frame(width: 96, height: 76)
                    
                    Text("അ")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                }
                .padding(.top, 18)
                .padding(.leading, 20)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alphabet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Learn letters")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.leading, 20)
                .padding(.bottom, 18)
            }
            
            // Star
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.yellow)
                .shadow(radius: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(20)
            
            // Next button
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "8F40FF"))
                )
                .shadow(radius: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(20)
        }
        .frame(height: hSizeClass == .regular ? 180 : 220)
        .cornerRadius(24)
        .shadow(color: Color(hex: "8F40FF").opacity(0.4), radius: 10, x: 0, y: 8)
    }
}

struct GameCardView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: "FFB74D"), Color(hex: "FF7043")], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(alignment: .center, spacing: 8) {
                // Controller Icon
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    .padding(.top, 16)
                
                VStack(spacing: 2) {
                    Text("Games")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Play & Learn")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "FF7043"))
                    )
                    .shadow(radius: 4)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            
            // Star
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(.yellow)
                .shadow(radius: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(12)
        }
        .frame(height: hSizeClass == .regular ? 180 : 190)
        .cornerRadius(20)
        .shadow(color: Color(hex: "FF7043").opacity(0.35), radius: 8, x: 0, y: 5)
    }
}

struct StoryCardView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: "FF4081"), Color(hex: "E040FB")], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(alignment: .center, spacing: 8) {
                // Book Icon
                ZStack {
                    Image(systemName: "book.closed.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color(hex: "6200EA"))
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 15))
                        .offset(x: 4, y: -4)
                }
                .padding(.top, 16)
                
                VStack(spacing: 2) {
                    Text("Stories")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Read & Enjoy")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "E040FB"))
                    )
                    .shadow(radius: 4)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            
            // Star
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(.yellow)
                .shadow(radius: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(12)
        }
        .frame(height: hSizeClass == .regular ? 180 : 190)
        .cornerRadius(20)
        .shadow(color: Color(hex: "E040FB").opacity(0.35), radius: 8, x: 0, y: 5)
    }
}

struct DictionaryCardView: View {
    var isVertical: Bool = false
    
    var body: some View {
        if isVertical {
            verticalCard
        } else {
            horizontalCard
        }
    }
    
    // Vertical card used on iPad in the 3-column row
    private var verticalCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: "4FC3F7"), Color(hex: "0288D1")], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(alignment: .center, spacing: 8) {
                // Book/Dictionary Icon
                Image(systemName: "character.book.closed.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    .padding(.top, 16)
                
                VStack(spacing: 2) {
                    Text("Dictionary")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Search & Learn")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "0288D1"))
                    )
                    .shadow(radius: 4)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            
            // Star
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(.yellow)
                .shadow(radius: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(12)
        }
        .frame(height: 180)
        .cornerRadius(20)
        .shadow(color: Color(hex: "0288D1").opacity(0.35), radius: 8, x: 0, y: 5)
    }
    
    // Horizontal card used on iPhone
    private var horizontalCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: "4FC3F7"), Color(hex: "0288D1")], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            // Background icon
            Image(systemName: "character.book.closed.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white.opacity(0.12))
                .offset(x: 180, y: -20)
                
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dictionary")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Search & Learn words")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "0288D1"))
                    )
                    .shadow(radius: 4)
                    .padding(.trailing, 20)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
        }
        .cornerRadius(20)
        .shadow(color: Color(hex: "0288D1").opacity(0.4), radius: 8, x: 0, y: 6)
    }
}

// Extension for Hex Color
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double((rgbValue & 0x0000FF)) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
