import SwiftUI

struct DashboardCard: View {
    let title: String
    let iconName: String
    let color1: Color
    let color2: Color
    let action: () -> Void
    
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var cardHeight: CGFloat {
        hSizeClass == .regular ? 160 : 130 * min(max(UIScreen.main.bounds.width / 375.0, 1.0), 2.0)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing)
                
                // Translucent big icon
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white.opacity(0.2))
                    .offset(x: 20, y: 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                
                VStack(alignment: .leading) {
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: cardHeight)
            .cornerRadius(24)
            .shadow(radius: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - iPad Layout Constants & Helpers

/// Maximum content width for iPad screens where a column layout is preferred.
let iPadContentMaxWidth: CGFloat = 700

/// Maximum content width for game screens on iPad where a narrower column
/// keeps interactive elements (buttons, grids) at a comfortable size.
let iPadGameContentMaxWidth: CGFloat = 640

/// Small helper to scale sizes proportionally based on reference width
func scaled(_ base: CGFloat) -> CGFloat {
    let reference: CGFloat = 375.0
    let screenW = UIScreen.main.bounds.width
    let scale = min(max(screenW / reference, 1.0), 2.0)
    return base * scale
}

