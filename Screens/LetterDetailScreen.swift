import SwiftUI

struct LetterDetailScreen: View {
    @ObservedObject var viewModel: MainViewModel
    let letter: Letter

    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    // Compute accent color based on ID hash (simplified logic)
    var accentColor: Color {
        let colors: [Color] = [.orange, .blue, .pink, .purple, .green, .yellow]
        let index = abs(letter.id.hashValue) % colors.count
        return colors[index]
    }

    /// Max content width: wider on iPad for a roomier layout
    private var contentMaxWidth: CGFloat {
        hSizeClass == .regular ? iPadContentMaxWidth : 430
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F7F7F7").ignoresSafeArea()
            
            ScrollView {
                // Center content and constrain width
                HStack {
                    Spacer()
                    VStack(spacing: 24) {
                    
                    // Letter Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(accentColor, lineWidth: 2)
                            .background(RoundedRectangle(cornerRadius: 32).fill(accentColor.opacity(0.18)))
                        
                        Text(letter.char)
                            .font(.system(size: hSizeClass == .regular ? 110 : 100, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    .frame(width: hSizeClass == .regular ? 220 : 200,
                           height: hSizeClass == .regular ? 220 : 200)
                    .padding(.top, 24)
                    
                    // Transliteration
                    Text(letter.transliteration)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                    
                    // Image Card (Clickable/Tappable with floating speaker badge)
                    Button(action: {
                        viewModel.playSound(letter.sound)
                    }) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(radius: 2)
                            
                            // Image name from repo
                            Image(letter.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: hSizeClass == .regular ? 240 : 200)
                                .clipped()
                                .cornerRadius(20)
                                .frame(maxWidth: .infinity)
                            
                            // Floating speaker badge
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(accentColor)
                                .clipShape(Circle())
                                .shadow(color: accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
                                .padding(12)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: hSizeClass == .regular ? 240 : 200)
                    .padding(.horizontal)
                    
                    // Example Text
                    Text("\(letter.example) • \(letter.exampleEn)")
                        .font(.title3)
                        .foregroundColor(.black)
                    
                    Spacer(minLength: 20)
                    
                    // Trace Button
                    NavigationLink(destination: TracingScreen(viewModel: viewModel, letter: letter)) {
                        Text("Trace Letter")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 4, y: 2)
                    }
                    .padding(24)
                    }
                    .frame(maxWidth: contentMaxWidth)
                    Spacer()
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

