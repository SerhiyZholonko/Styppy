import SwiftUI

struct SubscriptionListRow: View {
    let subscription: Subscription
    let subscriptionManager: SubscriptionManager?
    
    init(subscription: Subscription, subscriptionManager: SubscriptionManager? = nil) {
        self.subscription = subscription
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
                    
                    // Payment toggle button
                    if let manager = subscriptionManager {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                manager.togglePaymentStatus(subscription)
                            }
                        }) {
                            Image(systemName: subscription.isPaidForCurrentMonth ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(subscription.isPaidForCurrentMonth ? .green : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}