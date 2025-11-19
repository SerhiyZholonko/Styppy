import SwiftUI

struct CategoryChartBar: View {
    let category: SubscriptionCategory
    let amount: Double
    let totalAmount: Double
    let isIPad: Bool
    
    var percentage: Double {
        totalAmount > 0 ? amount / totalAmount : 0
    }
    
    var body: some View {
        HStack(spacing: isIPad ? 16 : 12) {
            // Category Info
            HStack(spacing: isIPad ? 12 : 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: isIPad ? 8 : 6)
                        .fill(category.color.opacity(0.15))
                        .frame(width: isIPad ? 32 : 24, height: isIPad ? 32 : 24)
                    
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold))
                }
                
                Text(category.rawValue)
                    .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: isIPad ? 140 : 100, alignment: .leading)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: isIPad ? 28 : 20)
                    
                    // Progress
                    if percentage > 0 {
                        RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                            .fill(
                                LinearGradient(
                                    colors: [category.color, category.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: min(geometry.size.width * CGFloat(percentage), geometry.size.width),
                                height: isIPad ? 28 : 20
                            )
                            .animation(.easeInOut(duration: 0.8), value: percentage)
                    }
                }
            }
            .frame(height: isIPad ? 28 : 20)

            // Amount
            Text(String(format: "$%.0f", amount))
                .font(.system(size: isIPad ? 16 : 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: isIPad ? 70 : 50, alignment: .trailing)
        }
        .padding(.vertical, isIPad ? 8 : 4)
    }
}