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

            LazyVStack(spacing: 12) {
                ForEach(subscriptions) { subscription in
                    NavigationLink(
                        destination: SubscriptionDetailView(
                            subscription: subscription,
                            subscriptionManager: subscriptionManager
                        )
                    ) {
                        AnimatedSubscriptionRow(subscription: subscription)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
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