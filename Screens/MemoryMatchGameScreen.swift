import SwiftUI

struct MemoryCard: Identifiable {
    let id = UUID()
    let letter: Letter
    var isFaceUp = false
    var isMatched = false
}

struct MemoryMatchGameScreen: View {
    @State private var cards: [MemoryCard] = []
    @State private var indexOfOneAndOnlyFaceUpCard: Int?
    @State private var moves = 0
    @State private var isGameOver = false

    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    // On iPad: larger minimum so each card is still finger-friendly; on iPhone: 80 pt
    private var cellMin: CGFloat { hSizeClass == .regular ? 100 : 80 }

    var columns: [GridItem] { [ GridItem(.adaptive(minimum: cellMin), spacing: 16) ] }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "E0C3FC"), Color(hex: "8EC5FC")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("Moves: \(moves)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Game Board — fills the full width on iPad (no 430 cap)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        CardView(card: card, cellMin: cellMin)
                            .onTapGesture {
                                choose(card: card, at: index)
                            }
                    }
                }
                .padding(24)
                
                Spacer()
            }

            
            // Game Over Overlay
            if isGameOver {
                VStack(spacing: 20) {
                    Text("You Won!")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text("Total Moves: \(moves)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button(action: setupGame) {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(Color(hex: "8EC5FC"))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(30)
                            .shadow(radius: 5)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.6))
                .ignoresSafeArea()
            }
        }
        .navigationTitle("Memory Match")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setupGame)
    }
    
    func setupGame() {
        let allLetters = DataRepository.shared.vowels + DataRepository.shared.consonants
        let shuffledLetters = allLetters.shuffled().prefix(8) // 8 unique letters
        
        var newCards: [MemoryCard] = []
        for letter in shuffledLetters {
            newCards.append(MemoryCard(letter: letter))
            newCards.append(MemoryCard(letter: letter)) // Add pair
        }
        
        cards = newCards.shuffled()
        moves = 0
        isGameOver = false
        indexOfOneAndOnlyFaceUpCard = nil
    }
    
    func choose(card: MemoryCard, at index: Int) {
        // Prevent tapping matched or already face-up cards
        if !cards[index].isFaceUp && !cards[index].isMatched {
            if let potentialMatchIndex = indexOfOneAndOnlyFaceUpCard {
                // We have one card face up. Check for a match.
                if cards[index].letter.id == cards[potentialMatchIndex].letter.id {
                    // Match found!
                    cards[index].isMatched = true
                    cards[potentialMatchIndex].isMatched = true
                    
                    if moves % 5 == 0 {
                        InterstitialAdManager.shared.showAdIfAppropriate {}
                    }
                }
                cards[index].isFaceUp = true
                indexOfOneAndOnlyFaceUpCard = nil
                moves += 1
                
                // Check if game is over
                if cards.allSatisfy({ $0.isMatched }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isGameOver = true
                        }
                    }
                }
                
            } else {
                // Either no cards or two cards are face up.
                // Flip all unmatched cards face down.
                for i in cards.indices {
                    if !cards[i].isMatched {
                        cards[i].isFaceUp = false
                    }
                }
                cards[index].isFaceUp = true
                indexOfOneAndOnlyFaceUpCard = index
            }
        }
    }
}

struct CardView: View {
    let card: MemoryCard
    var cellMin: CGFloat = 80

    var body: some View {
        ZStack {
            // Front (Face Up)
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(card.isMatched ? Color(hex: "A8E6CF") : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Text(card.letter.char)
                    .font(.system(size: cellMin * 0.38, weight: .bold))
                    .foregroundColor(Color(hex: "333333"))
            }
            .rotation3DEffect(Angle(degrees: 180), axis: (x: 0, y: 1, z: 0)) // Counter-rotate the front
            .opacity(card.isFaceUp || card.isMatched ? 1 : 0)
            
            // Back (Face Down)
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(colors: [Color(hex: "FF9A9E"), Color(hex: "FECFEF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .opacity(card.isFaceUp || card.isMatched ? 0 : 1)
        }
        .frame(height: cellMin)
        .rotation3DEffect(Angle(degrees: card.isFaceUp || card.isMatched ? 180 : 0), axis: (x: 0.0, y: 1.0, z: 0.0))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: card.isFaceUp)
    }
}
