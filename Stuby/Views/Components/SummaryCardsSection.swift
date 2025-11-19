import SwiftUI

struct SummaryCardsSection: View {
    let monthlyTotal: Double
    let yearlyTotal: Double
    let activeSubscriptionsCount: Int
    let dueSoonCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AnimatedSummaryCard(
                    title: "Monthly Total",
                    value: String(format: "$%.2f", monthlyTotal),
                    icon: "calendar.circle.fill",
                    gradient: Color.primaryGradient
                )

                AnimatedSummaryCard(
                    title: "Yearly Total",
                    value: String(format: "$%.2f", yearlyTotal),
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    gradient: Color.accentGradient
                )
            }

            HStack(spacing: 16) {
                AnimatedSummaryCard(
                    title: "Active Subscriptions",
                    value: "\(activeSubscriptionsCount)",
                    icon: "checkmark.circle.fill",
                    gradient: LinearGradient(colors: [.accentTeal, .accentGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                AnimatedSummaryCard(
                    title: "Due Soon",
                    value: "\(dueSoonCount)",
                    icon: "clock.circle.fill",
                    gradient: LinearGradient(colors: [.accentOrange, .accentPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
        }
        .padding(.horizontal, 20)
    }
}