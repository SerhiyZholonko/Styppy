import SwiftUI

struct SummaryCardsSection: View {
    let monthlyTotal: Double
    let yearlyTotal: Double
    let activeSubscriptionsCount: Int
    let dueSoonCount: Int
    let onMonthlyTotalTap: () -> Void
    let onYearlyTotalTap: () -> Void
    let onActiveSubscriptionsTap: () -> Void
    let onDueSoonTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: onMonthlyTotalTap) {
                    AnimatedSummaryCard(
                        title: "To Pay This Month",
                        value: String(format: "$%.2f", monthlyTotal),
                        icon: "creditcard.circle.fill",
                        gradient: Color.primaryGradient
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onYearlyTotalTap) {
                    AnimatedSummaryCard(
                        title: "Yearly Total",
                        value: String(format: "$%.2f", yearlyTotal),
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        gradient: Color.accentGradient
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack(spacing: 16) {
                Button(action: onActiveSubscriptionsTap) {
                    AnimatedSummaryCard(
                        title: "Active Subscriptions",
                        value: "\(activeSubscriptionsCount)",
                        icon: "checkmark.circle.fill",
                        gradient: LinearGradient(colors: [.accentTeal, .accentGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDueSoonTap) {
                    AnimatedSummaryCard(
                        title: "Due Soon",
                        value: "\(dueSoonCount)",
                        icon: "clock.circle.fill",
                        gradient: LinearGradient(colors: [.accentOrange, .accentPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}