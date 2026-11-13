import SwiftUI
import UIKit

// MARK: - Colours

extension Color {
    /// Hex colour such as "FF8A3D" or "#FF8A3D".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: cleaned)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// A colour that switches between light and dark appearance.
    init(light: String, dark: String) {
        func ui(_ hex: String) -> UIColor { UIColor(Color(hex: hex)) }
        let l = ui(light), d = ui(dark)
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? d : l })
    }
}

/// The app's shared look: warm, rounded and playful, with light and dark variants.
enum DS {
    // Surfaces
    static let background = Color(light: "FFF7EA", dark: "17151F")
    static let surface = Color(light: "FFFFFF", dark: "262333")
    static let surfaceAlt = Color(light: "FFEFD6", dark: "312D42")
    static let board = Color(light: "FFFFFF", dark: "201D2B")

    // Text
    static let ink = Color(light: "3B2A5A", dark: "F4EFFF")
    static let inkSoft = Color(light: "7C6E92", dark: "B8AFCB")

    // Brand colours
    static let purple = Color(hex: "8A5CF6")
    static let orange = Color(hex: "FF8A3D")
    static let green = Color(hex: "34C38F")
    static let yellow = Color(hex: "FFC83D")
    static let sky = Color(hex: "4FB6F7")
    static let pink = Color(hex: "FF6FA5")
    static let teal = Color(hex: "1FC7B6")
    static let red = Color(hex: "F2655A")

    static let palette: [Color] = [orange, sky, pink, green, purple, teal, yellow, red]
    static func color(for index: Int) -> Color { palette[abs(index) % palette.count] }

    // Type: rounded, heavy, and scales with Dynamic Type.
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .heavy) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
    /// Fixed-size rounded font for big letters that should not reflow.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Smallest comfortable touch target for small hands.
    static let minTap: CGFloat = 60
}

// MARK: - Haptics

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let notify = UINotificationFeedbackGenerator()

    static func tap() {
        guard ProgressStore.shared.settings.hapticsOn else { return }
        light.impactOccurred(intensity: 0.7)
    }
    static func success() {
        guard ProgressStore.shared.settings.hapticsOn else { return }
        notify.notificationOccurred(.success)
    }
}

// MARK: - Buttons

/// Squishy press with a haptic tick.
struct KidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.tap() }
            }
    }
}

/// Large, chunky call-to-action button.
struct BigButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = DS.purple
    var filled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon).font(DS.font(.title3)) }
                Text(title).font(DS.font(.title3))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundColor(filled ? .white : color)
            .frame(maxWidth: .infinity, minHeight: DS.minTap)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(filled ? color : color.opacity(0.14))
                    .shadow(color: filled ? color.opacity(0.35) : .clear, radius: 0, x: 0, y: 5)
            )
        }
        .buttonStyle(KidButtonStyle())
    }
}

/// Round icon button (back, speaker, settings…).
struct CircleIconButton: View {
    let systemName: String
    var color: Color = DS.purple
    var size: CGFloat = 52
    var label: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(Circle().fill(DS.surface).shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 3))
        }
        .buttonStyle(KidButtonStyle())
        .accessibilityLabel(label.isEmpty ? systemName : label)
    }
}

// MARK: - Cards & bits

extension View {
    /// Soft "clay" card used across the app.
    func kidCard(_ fill: Color = DS.surface, radius: CGFloat = 26) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .shadow(color: .black.opacity(0.08), radius: 0, x: 0, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}

struct StarRow: View {
    let filled: Int
    var total = 3
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < filled ? "star.fill" : "star")
                    .font(.system(size: size, weight: .heavy))
                    .foregroundColor(i < filled ? DS.yellow : DS.inkSoft.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filled) of \(total) stars")
    }
}

struct ProgressRing<Label: View>: View {
    let progress: Double
    var color: Color = DS.green
    var lineWidth: CGFloat = 8
    @ViewBuilder var label: () -> Label

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            label()
        }
    }
}

/// Small pill for stats like a streak or points.
struct StatPill: View {
    /// SF Symbol name.
    let icon: String
    let text: String
    var color: Color = DS.orange

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(DS.font(.headline)).foregroundColor(color)
            Text(text).font(DS.font(.headline)).foregroundColor(DS.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(Capsule().fill(DS.surface).shadow(color: color.opacity(0.25), radius: 0, x: 0, y: 3))
    }
}

/// Standard top bar for kid screens: back, title, trailing actions.
struct KidTopBar<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    let onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left", label: "Back", action: onBack)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(DS.font(.title2)).foregroundColor(DS.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                if let subtitle {
                    Text(subtitle).font(DS.font(.subheadline, weight: .bold)).foregroundColor(DS.inkSoft)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
    }
}

extension KidTopBar where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, onBack: onBack) { EmptyView() }
    }
}
