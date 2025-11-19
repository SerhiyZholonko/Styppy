import SwiftUI

struct CategoryBreakdownRow: View {
    let category: SubscriptionCategory
    let amount: Double
    let percentage: Double
    let subscriptionCount: Int

    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        HStack(spacing: isIPad ? 16 : 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: isIPad ? 36 : 28, height: isIPad ? 36 : 28)
                
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: isIPad ? 4 : 2) {
                Text(category.rawValue)
                    .font(.system(size: isIPad ? 18 : 16, weight: .medium))
                    .foregroundColor(.primary)

                Text("\(subscriptionCount) subscription\(subscriptionCount == 1 ? "" : "s")")
                    .font(.system(size: isIPad ? 14 : 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: isIPad ? 4 : 2) {
                Text(String(format: "$%.2f", amount))
                    .font(.system(size: isIPad ? 18 : 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, isIPad ? 8 : 6)
                    .padding(.vertical, isIPad ? 4 : 2)
                    .background(category.color.opacity(0.1))
                    .cornerRadius(isIPad ? 8 : 6)
            }
        }
        .padding(.vertical, isIPad ? 12 : 8)
    }
}