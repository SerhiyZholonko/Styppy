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
                    InteractiveSubscriptionSectionRow(
                        subscription: subscription,
                        subscriptionManager: subscriptionManager
                    )
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

// MARK: - Interactive Subscription Section Row
struct InteractiveSubscriptionSectionRow: View {
    let subscription: Subscription
    let subscriptionManager: SubscriptionManager
    
    @State private var showingDetail = false
    
    var body: some View {
        AnimatedSubscriptionRow(subscription: subscription)
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            .navigationDestination(isPresented: $showingDetail) {
                SubscriptionDetailView(
                    subscription: subscription,
                    subscriptionManager: subscriptionManager
                )
            }
    }
}

