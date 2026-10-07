import SwiftUI

struct WordMatchGameScreen: View {
    @State private var allLetters: [Letter] = []
    @State private var currentQuestion: Letter?
    @State private var options: [Letter] = []
    @State private var score = 0
    @State private var questionCount = 0
    @State private var showFeedback = false
    @State private var feedbackIsCorrect = false
    @State private var isGameOver = false
    
    @Environment(\.horizontalSizeClass) private var hSizeClass

    let totalQuestions = 10
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "FDFBFB"), Color(hex: "EBEDEE")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Centre content column on iPad so buttons don't stretch too wide
            HStack {
                Spacer()
                gameContent
                    .frame(maxWidth: hSizeClass == .regular ? iPadGameContentMaxWidth : .infinity)
                Spacer()
            }
        }
        .navigationTitle("Word Match")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setupGame)
    }

    @ViewBuilder
    private var gameContent: some View {
            if isGameOver {
                VStack(spacing: 30) {
                    Text("Game Over!")
                        .font(.system(size: 45, weight: .heavy))
                        .foregroundColor(Color(hex: "333333"))
                    
                    Text("Score: \(score) / \(totalQuestions)")
                        .font(.title)
                        .bold()
                        .foregroundColor(Color(hex: "333333"))
                    
                    Button(action: setupGame) {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color(hex: "A18CD1"))
                            .cornerRadius(30)
                            .shadow(radius: 5)
                    }
                }
            } else if let question = currentQuestion {
                ZStack {
                    VStack(spacing: 30) {
                        HStack {
                            Text("Question \(questionCount)/\(totalQuestions)")
                                .font(.headline)
                                .foregroundColor(Color(hex: "555555"))
                            Spacer()
                            Text("Score: \(score)")
                                .font(.headline)
                                .foregroundColor(Color(hex: "555555"))
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        
                        Text("Which letter starts this word?")
                            .font(.headline)
                            .foregroundColor(Color(hex: "555555"))
                        
                        Text(question.exampleEn)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(Color(hex: "333333"))
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 30)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(options) { option in
                                Button(action: {
                                    checkAnswer(option)
                                }) {
                                    Text(option.char)
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(Color(hex: "FBC2EB"))
                                        .cornerRadius(20)
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                                }
                                .disabled(showFeedback)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                    
                    if showFeedback {
                        VStack {
                            Image(systemName: feedbackIsCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(feedbackIsCorrect ? .green : .red)
                                .background(Circle().fill(Color.white))
                                .transition(.scale)
                        }
                    }
                }
            }
    }

    
    func setupGame() {
        allLetters = DataRepository.shared.vowels + DataRepository.shared.consonants
        score = 0
        questionCount = 0
        isGameOver = false
        nextQuestion()
    }
    
    func nextQuestion() {
        questionCount += 1
        if questionCount > totalQuestions {
            isGameOver = true
            return
        }
        
        showFeedback = false
        currentQuestion = allLetters.randomElement()!
        
        var newOptions = [currentQuestion!]
        while newOptions.count < 4 {
            let random = allLetters.randomElement()!
            if !newOptions.contains(where: { $0.id == random.id }) {
                newOptions.append(random)
            }
        }
        options = newOptions.shuffled()
    }
    
    func checkAnswer(_ selected: Letter) {
        showFeedback = true
        if selected.id == currentQuestion?.id {
            feedbackIsCorrect = true
            score += 1
        } else {
            feedbackIsCorrect = false
        }
        
        if questionCount % 3 == 0 {
            InterstitialAdManager.shared.showAdIfAppropriate {}
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                nextQuestion()
            }
        }
    }
}
