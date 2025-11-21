import SwiftUI

struct SubscriptionListRow: View {
    @State var subscription: Subscription
    let subscriptionManager: SubscriptionManager?
    @State private var isProcessing = false
    
    init(subscription: Subscription, subscriptionManager: SubscriptionManager? = nil) {
        self._subscription = State(initialValue: subscription)
        self.subscriptionManager = subscriptionManager
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: subscription.category.icon)
                .font(.title2)
                .foregroundColor(subscription.category.color)
                .frame(width: 32, height: 32)
                .background(subscription.category.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .fontWeight(.medium)

                HStack {
                    Text(subscription.billingCycle.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 3, height: 3)

                    Text(subscription.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", subscription.price))
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    // Payment status indicator
                    if subscription.isPaidForCurrentMonth {
                        Text("Paid")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else if subscription.isOverdue {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    } else if subscription.daysUntilNextBilling <= 3 {
                        Text("\(subscription.daysUntilNextBilling) days")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("\(subscription.daysUntilNextBilling) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Simple payment button
                    if let manager = subscriptionManager {
                        AnimatedPaymentButton(
                            isPaid: subscription.isPaidForCurrentMonth,
                            isProcessing: $isProcessing,
                            isAnimating: .constant(false),
                            showingCheckmark: .constant(false)
                        ) {
                            handlePaymentToggle(manager: manager)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func handlePaymentToggle(manager: SubscriptionManager) {
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Start processing state
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = true
        }
        
        // Process payment after delay to show processing state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            manager.togglePaymentStatus(subscription)
            // Update local state to reflect changes
            if let updatedSubscription = manager.subscriptions.first(where: { $0.id == subscription.id }) {
                subscription = updatedSubscription
            }
            
            // End processing state
            withAnimation(.easeInOut(duration: 0.5)) {
                isProcessing = false
            }
        }
    }
}

// MARK: - Simple Payment Button Component
struct AnimatedPaymentButton: View {
    let isPaid: Bool
    @Binding var isProcessing: Bool
    @Binding var isAnimating: Bool
    @Binding var showingCheckmark: Bool
    let action: () -> Void
    
    private var iconName: String {
        if isProcessing {
            return "circle.circle"
        } else if isPaid {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var iconColor: Color {
        if isPaid {
            return .green
        } else {
            return .secondary
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
                .scaleEffect(isProcessing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isProcessing)
                .animation(.easeInOut(duration: 0.5), value: isPaid)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isProcessing)
    }
}