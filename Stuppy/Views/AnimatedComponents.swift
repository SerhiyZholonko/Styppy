import SwiftUI

// MARK: - Animated Summary Card
struct AnimatedSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    @State private var isVisible = false
    @State private var iconScale = 0.0
    @State private var valueOffset = 30.0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .scaleEffect(iconScale)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .offset(y: valueOffset)
                    .opacity(isVisible ? 1 : 0)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .glassMorphismCard()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
                valueOffset = 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
            }
        }
    }
}

// MARK: - Animated Subscription Row
struct AnimatedSubscriptionRow: View {
    let subscription: Subscription
    @State private var isVisible = false
    @State private var slideOffset: CGFloat = 50
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            // Category indicator with animation
            ZStack {
                Circle()
                    .fill(subscription.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(subscription.category.color)
                    .frame(width: 20, height: 20)

                Image(systemName: subscription.category.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimaryColor)

                HStack(spacing: 8) {

                    // Repetition indicator
                    if subscription.repetitionType != .disabled {
                        HStack(spacing: 2) {
                            Image(systemName: "repeat")
                                .font(.system(size: 10))
                            Text(subscription.repetitionType.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.accentTeal)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentTeal.opacity(0.1))
                        .cornerRadius(4)
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 10))
                            Text("No Renewal")
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.warning)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.warning.opacity(0.1))
                        .cornerRadius(4)
                    }

                    if subscription.isPaidForCurrentMonth {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Paid")
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentGreen.opacity(0.1))
                        .cornerRadius(4)
                    } else if subscription.isOverdue {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("Overdue")
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.error.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", subscription.price))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimaryColor)

                if !subscription.isOverdue {
                    Text("\(subscription.daysUntilNextBilling) days")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondaryColor)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(theme.cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: theme.shadowColor, radius: 5, x: 0, y: 2)
        .offset(x: slideOffset)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                slideOffset = 0
            }
        }
    }
}

// MARK: - Animated Loading View
struct AnimatedLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.primaryPurple.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.primaryGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
            }
            .scaleEffect(scale)

            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - Animated Empty State
struct AnimatedEmptyState: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: (() -> Void)?
    @State private var isVisible = false
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.lightGray)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.neutralGray)
                    .offset(y: bounceOffset)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primaryGradient)
                    .cornerRadius(25)
                    .shadow(color: Color.primaryPurple.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .animatedButton()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bounceOffset = -10
            }
        }
    }
}

// MARK: - Animated Progress Bar
struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color
    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.2))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(width: geometry.size.width * animatedProgress, height: 8)
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedProgress)
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Pulse Animation Modifier
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}
