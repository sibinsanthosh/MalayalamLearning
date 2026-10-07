import SwiftUI

struct FallingLetter: Identifiable {
    let id = UUID()
    let letter: Letter
    var xPosition: CGFloat
    var yPosition: CGFloat
    var isPopped: Bool = false
    var isWrong: Bool = false
}

struct CatchTheLetterGameScreen: View {
    @State private var allLetters: [Letter] = []
    @State private var targetLetter: Letter?
    @State private var fallingLetters: [FallingLetter] = []
    @State private var score = 0
    @State private var lives = 3
    @State private var isGameOver = false
    @State private var timer: Timer?
    @State private var fallSpeed: CGFloat = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(hex: "A1C4FD"), Color(hex: "C2E9FB")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if isGameOver {
                    VStack(spacing: 30) {
                        Text("Game Over!")
                            .font(.system(size: 45, weight: .heavy))
                            .foregroundColor(Color(hex: "333333"))
                        
                        Text("Final Score: \(score)")
                            .font(.title)
                            .bold()
                            .foregroundColor(Color(hex: "333333"))
                        
                        Button(action: {
                            setupGame()
                            startGameLoop(in: geometry)
                        }) {
                            Text("Play Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(Color(hex: "4CAF50"))
                                .cornerRadius(30)
                                .shadow(radius: 5)
                        }
                    }
                } else {
                    // Game HUD
                    VStack {
                        HStack {
                            Text("Score: \(score)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                            Text("Lives: \(lives)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        
                        if let target = targetLetter {
                            HStack {
                                Text("Catch: ")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text(target.char)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Color(hex: "FFC107"))
                            }
                            .padding(.top, 10)
                        }
                        Spacer()
                    }
                    .zIndex(1)
                    
                    // Falling Objects
                    ForEach(fallingLetters) { falling in
                        if !falling.isPopped {
                            Text(falling.letter.char)
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(falling.isWrong ? .red : .white)
                                .position(x: falling.xPosition, y: falling.yPosition)
                                .onTapGesture {
                                    handleTap(on: falling)
                                }
                        }
                    }
                }
            }
            .onAppear {
                setupGame()
                startGameLoop(in: geometry)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .navigationTitle("Catch The Letter")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func setupGame() {
        allLetters = DataRepository.shared.vowels + DataRepository.shared.consonants
        score = 0
        lives = 3
        fallSpeed = 2.0
        fallingLetters = []
        isGameOver = false
        targetLetter = allLetters.randomElement()
    }
    
    func startGameLoop(in geometry: GeometryProxy) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard !isGameOver else { return }
            
            // Move letters down
            for i in fallingLetters.indices {
                fallingLetters[i].yPosition += fallSpeed
            }
            
            // Remove off-screen letters
            if let first = fallingLetters.first, first.yPosition > geometry.size.height + 50 {
                // If they missed a target letter, lose a life
                if first.letter.id == targetLetter?.id && !first.isPopped {
                    lives -= 1
                    if lives <= 0 {
                        endGame()
                    }
                }
                fallingLetters.removeFirst()
            }
            
            // Spawn new letters randomly
            if Int.random(in: 0...40) == 0 {
                spawnLetter(in: geometry)
            }
        }
    }
    
    func spawnLetter(in geometry: GeometryProxy) {
        // 30% chance to spawn the target letter, 70% chance for a random one
        let letter = (Int.random(in: 1...10) <= 3) ? targetLetter! : allLetters.randomElement()!
        
        let newLetter = FallingLetter(
            letter: letter,
            xPosition: CGFloat.random(in: 50...(geometry.size.width - 50)),
            yPosition: -50
        )
        fallingLetters.append(newLetter)
    }
    
    func handleTap(on falling: FallingLetter) {
        if let index = fallingLetters.firstIndex(where: { $0.id == falling.id }) {
            if falling.letter.id == targetLetter?.id {
                // Correct!
                fallingLetters[index].isPopped = true
                score += 10
                
                // Increase speed every 50 points
                if score % 50 == 0 && score > 0 {
                    fallSpeed += 0.5
                    targetLetter = allLetters.randomElement() // Change target!
                }
            } else {
                // Wrong!
                fallingLetters[index].isWrong = true
                lives -= 1
                if lives <= 0 {
                    endGame()
                }
            }
        }
    }
    
    func endGame() {
        isGameOver = true
        timer?.invalidate()
        InterstitialAdManager.shared.showAdIfAppropriate {}
    }
}
