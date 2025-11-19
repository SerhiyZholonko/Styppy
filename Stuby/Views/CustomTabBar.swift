import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var onTabChange: ((Int) -> Void)?
    @EnvironmentObject var theme: ThemeManager
    @State private var tabOffset: CGFloat = 0
    @State private var isTabBarPressed = false

    let tabs = [
        TabItem(icon: "house.fill", title: "Dashboard", tag: 0),
        TabItem(icon: "list.bullet", title: "Subscriptions", tag: 1),
        TabItem(icon: "chart.bar.fill", title: "Analytics", tag: 2),
        TabItem(icon: "gearshape.fill", title: "Settings", tag: 3)
    ]

    var body: some View {
        ZStack {
            // Tab bar background with semicircular cutout and 3D volume effect
            CustomTabBarBackground()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.cardBackgroundColor,
                            theme.cardBackgroundColor.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Inner highlight for 3D effect
                    CustomTabBarBackground()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.isDarkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.8),
                                    theme.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .offset(y: -1)
                )
                .overlay(
                    // Border
                    CustomTabBarBackground()
                        .stroke(theme.borderColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: theme.shadowColor.opacity(0.3), radius: 8, x: 0, y: -2) // Top shadow for depth
                .shadow(color: theme.shadowColor, radius: isTabBarPressed ? 10 : 20, x: 0, y: isTabBarPressed ? 4 : 8) // Main shadow with animation
                .scaleEffect(isTabBarPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTabBarPressed)

            HStack(spacing: 0) {
                // All four tabs evenly distributed
                ForEach(tabs, id: \.tag) { tab in
                    TabButton(
                        tab: tab,
                        selectedTab: $selectedTab,
                        theme: theme,
                        onPress: { pressed in
                            isTabBarPressed = pressed
                        },
                        onTabChange: onTabChange
                    )
                    .offset(y: 4) // Move regular tabs down slightly
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

struct TabButton: View {
    let tab: TabItem
    @Binding var selectedTab: Int
    let theme: ThemeManager
    let onPress: (Bool) -> Void
    var onTabChange: ((Int) -> Void)?
    @State private var isPressed = false

    var isSelected: Bool {
        selectedTab == tab.tag
    }

    var body: some View {
        Button(action: {
            // Use callback if available, otherwise use binding
            if let onTabChange = onTabChange {
                onTabChange(tab.tag)
            } else {
                selectedTab = tab.tag
            }

            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Background circle - always present
                    Circle()
                        .fill(isSelected ? Color.primaryPurple : (isPressed ? Color.primaryPurple.opacity(0.3) : Color.clear))
                        .frame(width: 40, height: 40)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : theme.textSecondaryColor)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)

                Text(tab.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? Color.primaryPurple : theme.textSecondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = pressing
                onPress(pressing) // Trigger tab bar animation
            }
        }, perform: {})
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

// MARK: - Center Add Button
struct CenterAddButton: View {
    let action: () -> Void
    @EnvironmentObject var theme: ThemeManager
    @State private var isPressed = false
    @State private var isBouncing = false

    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                // Trigger bounce animation
                withAnimation(.spring(response: 0.6, dampingFraction: 0.3)) {
                    isBouncing = true
                }

                // Reset bounce after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isBouncing = false
                    }
                }

                // Trigger action
                action()
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }) {

                ZStack {
                    // Background circle - matches other buttons
                    Circle()
                        .fill(isPressed ? Color.primaryPurple : theme.cardBackgroundColor)
                        .overlay(
                            Circle()
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                        .frame(width: 75, height: 75)
                        .shadow(color: theme.shadowColor, radius: 22, x: 0, y: 5)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)

                    Image(systemName: "plus")
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundColor(isPressed ? .white : theme.textPrimaryColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.9 : (isBouncing ? 1.3 : 1.0)) // Bounce effect when clicked
            .offset(y: isPressed ? -3 : 0) // Jump effect
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            .animation(.spring(response: 0.6, dampingFraction: 0.3), value: isBouncing)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = pressing
                }
            }, perform: {})

//            Text("Add")
//                .font(.system(size: 9, weight: .medium))
//                .foregroundColor(Color.primaryPurple)
//                .lineLimit(1)
//                .minimumScaleFactor(0.7)
//                .scaleEffect(isPressed ? 0.9 : 1.0)
//                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Tab Bar Background Shape
struct CustomTabBarBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius: CGFloat = 20
        let cutoutRadius: CGFloat = 40
        let cutoutCenter = CGPoint(x: rect.midX, y: rect.minY)

        // Start from top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

        // Top-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Top edge to cutout start
        let cutoutStartX = cutoutCenter.x - cutoutRadius
        let cutoutEndX = cutoutCenter.x + cutoutRadius
        path.addLine(to: CGPoint(x: cutoutStartX, y: rect.minY))

        // Shallow arc cutout (less deep than semicircle)
        let cutoutDepth: CGFloat = 30 // Doubled depth from 15 to 30 pixels

        // Create shallow arc using quadratic curve
        let controlPoint = CGPoint(x: cutoutCenter.x, y: cutoutCenter.y + cutoutDepth)
        path.addQuadCurve(to: CGPoint(x: cutoutEndX, y: rect.minY), control: controlPoint)

        // Top edge from cutout end
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))

        // Top-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))

        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge back to start
        path.closeSubpath()

        return path
    }
}

// MARK: - Floating Action Button (kept for compatibility)
struct FloatingActionButton: View {
    let action: () -> Void
    @EnvironmentObject var theme: ThemeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }) {
            ZStack {
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentOrange.opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .rotationEffect(.degrees(isPressed ? 135 : 0))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

//#Preview {
//    VStack {
//        Spacer()
//        CustomTabBar(selectedTab: .constant(0))
//            .environmentObject(ThemeManager())
//    }
//    .background(Color.lightGray)
//}
#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
