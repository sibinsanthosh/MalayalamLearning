import SwiftUI
import Foundation
// helper available from Components/UIHelpers.swift

struct AppButton: View {
    let text: String
    let color: Color
    let textColor: Color
    let action: () -> Void
    
    init(text: String, containerColor: Color = .blue, contentColor: Color = .white, action: @escaping () -> Void) {
        self.text = text
        self.color = containerColor
        self.textColor = contentColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56 * min(max(UIScreen.main.bounds.width / 375.0, 1.0), 2.0))
                .background(color)
                .cornerRadius(12)
                .shadow(radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
