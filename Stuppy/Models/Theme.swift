import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Brand Colors
    static let primaryPurple = Color(hex: "6366F1") // Modern purple
    static let primaryBlue = Color(hex: "3B82F6")   // Vibrant blue
    static let accentOrange = Color(hex: "F97316")  // Warm orange
    static let accentPink = Color(hex: "EC4899")    // Modern pink
    static let accentTeal = Color(hex: "14B8A6")    // Fresh teal
    static let accentGreen = Color(hex: "10B981")   // Success green

    // Neutral Colors
    static let neutralGray = Color(hex: "6B7280")
    static let lightGray = Color(hex: "F3F4F6")
    static let darkGray = Color(hex: "374151")

    // Background Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryPurple, primaryBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accentOrange, accentPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white, lightGray],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkCardGradient = LinearGradient(
        colors: [Color(hex: "1F2937"), Color(hex: "111827")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Semantic Colors
    static let success = accentGreen
    static let warning = accentOrange
    static let error = Color(hex: "EF4444")
    static let info = primaryBlue

    // Initialize from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false

    init() {
        // Detect system theme
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }

    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }

    // Dynamic colors based on theme
    var backgroundColor: Color {
        isDarkMode ? Color(hex: "0F172A") : Color.white
    }

    var secondaryBackgroundColor: Color {
        isDarkMode ? Color(hex: "1E293B") : Color(hex: "F8FAFC")
    }

    var cardBackgroundColor: Color {
        isDarkMode ? Color(hex: "1F2937") : Color.white
    }
  

    var cardGradient: LinearGradient {
        isDarkMode ? Color.darkCardGradient : Color.cardGradient
    }

    var textPrimaryColor: Color {
        isDarkMode ? Color.white : Color(hex: "1F2937")
    }

    var textSecondaryColor: Color {
        isDarkMode ? Color(hex: "9CA3AF") : Color(hex: "6B7280")
    }

    var borderColor: Color {
        isDarkMode ? Color(hex: "374151") : Color(hex: "E5E7EB")
    }

    var shadowColor: Color {
        isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

// MARK: - Custom Modifiers
struct GlassMorphismCard: ViewModifier {
    @EnvironmentObject var theme: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.borderColor, lineWidth: 1)
                    )
                    .shadow(color: theme.shadowColor, radius: 10, x: 0, y: 5)
            )
    }
}

struct AnimatedButton: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
}

extension View {
    func glassMorphismCard() -> some View {
        modifier(GlassMorphismCard())
    }

    func animatedButton() -> some View {
        modifier(AnimatedButton())
    }
}
