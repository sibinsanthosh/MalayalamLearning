import SwiftUI

struct Balloon: Identifiable {
    let id = UUID()
    let letter: Letter
    var xOffset: CGFloat
    var yOffset: CGFloat
    let color: Color
    let speed: Double
    var isPopped: Bool = false
}

struct BalloonPopGameScreen: View {
    @ObservedObject var viewModel: MainViewModel
    
    @State private var balloons: [Balloon] = []
    @State private var timer: Timer? = nil
    @State private var spawnerTimer: Timer? = nil
    @State private var screenHeight: CGFloat = 800
    @State private var screenWidth: CGFloat = 400
    
    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow]
    
    var allLetters: [Letter] {
        viewModel.vowels + viewModel.consonants
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky background
                LinearGradient(colors: [Color.blue.opacity(0.2), Color.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ForEach(balloons) { balloon in
                    if !balloon.isPopped {
                        BalloonView(balloon: balloon)
                            .position(x: balloon.xOffset, y: balloon.yOffset)
                            .onTapGesture {
                                popBalloon(balloon)
                            }
                    }
                }
            }
            .onAppear {
                screenHeight = geometry.size.height
                screenWidth = geometry.size.width
                startGame()
            }
            .onDisappear {
                stopGame()
            }
        }
        .navigationTitle("Balloon Pop")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startGame() {
        // Game loop for moving balloons
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            updateBalloons()
        }
        
        // Spawner loop
        spawnerTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            spawnBalloon()
        }
    }
    
    private func stopGame() {
        timer?.invalidate()
        timer = nil
        spawnerTimer?.invalidate()
        spawnerTimer = nil
    }
    
    private func spawnBalloon() {
        guard !allLetters.isEmpty else { return }
        
        let randomLetter = allLetters.randomElement()!
        let balloonWidth: CGFloat = 90
        let padding: CGFloat = balloonWidth / 2
        let randomX = CGFloat.random(in: padding...(screenWidth - padding))
        let randomColor = colors.randomElement()!
        let randomSpeed = Double.random(in: 2.0...5.0)
        
        let newBalloon = Balloon(
            letter: randomLetter,
            xOffset: randomX,
            yOffset: screenHeight + 100, // start below screen
            color: randomColor,
            speed: randomSpeed
        )
        
        balloons.append(newBalloon)
    }
    
    private func updateBalloons() {
        for i in balloons.indices.reversed() {
            balloons[i].yOffset -= balloons[i].speed
            
            // Remove if off screen top
            if balloons[i].yOffset < -150 {
                balloons.remove(at: i)
            }
        }
    }
    
    private func popBalloon(_ balloon: Balloon) {
        if let index = balloons.firstIndex(where: { $0.id == balloon.id }) {
            balloons[index].isPopped = true
            viewModel.playSound(balloon.letter.sound)
            viewModel.addPoints(1)
            
            // Haptic feedback
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
        }
    }
}

struct BalloonView: View {
    let balloon: Balloon
    
    var body: some View {
        VStack(spacing: -5) {
            ZStack {
                // Balloon body
                Ellipse()
                    .fill(
                        RadialGradient(gradient: Gradient(colors: [balloon.color.opacity(0.6), balloon.color]), center: .topLeading, startRadius: 10, endRadius: 60)
                    )
                    .frame(width: 90, height: 110)
                    .shadow(color: balloon.color.opacity(0.4), radius: 5, x: 0, y: 5)
                
                // Highlight
                Ellipse()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 20, height: 35)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -20, y: -25)
                
                // Letter
                Text(balloon.letter.char)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 1, y: 1)
            }
            
            // Tail
            Image(systemName: "triangle.fill")
                .resizable()
                .frame(width: 15, height: 15)
                .foregroundColor(balloon.color)
            
            // String
            Rectangle()
                .fill(Color.gray)
                .frame(width: 2, height: 40)
        }
    }
}
