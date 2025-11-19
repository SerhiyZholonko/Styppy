import SwiftUI

struct UpcomingRenewalRow: View {
    let subscription: Subscription

    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        HStack(spacing: isIPad ? 16 : 12) {
            ZStack {
                Circle()
                    .fill(subscription.category.color.opacity(0.15))
                    .frame(width: isIPad ? 36 : 28, height: isIPad ? 36 : 28)
                
                Image(systemName: subscription.category.icon)
                    .foregroundColor(subscription.category.color)
                    .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: isIPad ? 4 : 2) {
                Text(subscription.name)
                    .font(.system(size: isIPad ? 18 : 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: isIPad ? 14 : 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: isIPad ? 4 : 2) {
                Text(String(format: "$%.2f", subscription.price))
                    .font(.system(size: isIPad ? 18 : 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: isIPad ? 12 : 10))
                        .foregroundColor(subscription.daysUntilNextBilling <= 3 ? .orange : .secondary)
                    
                    Text("\(subscription.daysUntilNextBilling) days")
                        .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                        .foregroundColor(subscription.daysUntilNextBilling <= 3 ? .orange : .secondary)
                }
                .padding(.horizontal, isIPad ? 8 : 6)
                .padding(.vertical, isIPad ? 4 : 2)
                .background((subscription.daysUntilNextBilling <= 3 ? Color.orange : Color.secondary).opacity(0.1))
                .cornerRadius(isIPad ? 8 : 6)
            }
        }
        .padding(.vertical, isIPad ? 12 : 8)
    }
}