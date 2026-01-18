import SwiftUI

struct SubscriptionSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let borderColor: Color
    let count: Int
    let subscriptions: [Subscription]
    let subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimaryColor)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(iconColor)
                    .cornerRadius(12)
            }

            List {
                ForEach(subscriptions) { subscription in
                    NavigationLink(destination: SubscriptionDetailView(subscription: subscription, subscriptionManager: subscriptionManager)) {
                        SubscriptionSectionRowContent(subscription: subscription)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            subscriptionManager.deleteSubscription(subscription)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        
                        Button {
                            subscriptionManager.togglePaymentStatus(subscription)
                        } label: {
                            Label(subscription.isPaidForCurrentMonth ? "Mark Unpaid" : "Mark Paid", 
                                  systemImage: subscription.isPaidForCurrentMonth ? "xmark.circle" : "checkmark.circle")
                        }
                        .tint(subscription.isPaidForCurrentMonth ? .orange : .green)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let subscription = subscriptions[index]
                        subscriptionManager.deleteSubscription(subscription)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .frame(height: CGFloat(subscriptions.count * 80))
            .scrollDisabled(true)
        }
        .padding(20)
        .background(theme.cardBackgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Subscription Section Row Content
struct SubscriptionSectionRowContent: View {
    let subscription: Subscription
    
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
                    .foregroundColor(.primary)

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
                    .foregroundColor(.primary)

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
                }
            }
        }
        .padding(.vertical, 4)
    }
}

