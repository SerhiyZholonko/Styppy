import SwiftUI

struct SubscriptionDetailView: View {
    let subscription: Subscription
    @ObservedObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel: SubscriptionDetailViewModel
    
    init(subscription: Subscription, subscriptionManager: SubscriptionManager) {
        self.subscription = subscription
        self.subscriptionManager = subscriptionManager
        self._viewModel = StateObject(wrappedValue: SubscriptionDetailViewModel(subscription: subscription, subscriptionManager: subscriptionManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: subscription.category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(subscription.category.color)
                        .frame(width: 100, height: 100)
                        .background(subscription.category.color.opacity(0.1))
                        .cornerRadius(20)

                    Text(subscription.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(subscription.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }

                // Price Information
                VStack(spacing: 16) {
                    PriceCard(
                        title: "Current Price",
                        price: subscription.price,
                        period: subscription.billingCycle.rawValue,
                        color: subscription.category.color
                    )

                    HStack(spacing: 12) {
                        SmallPriceCard(
                            title: "Monthly",
                            price: subscription.monthlyPrice
                        )

                        SmallPriceCard(
                            title: "Yearly",
                            price: subscription.yearlyPrice
                        )
                    }
                }

                // Billing Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Billing Information")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        InfoRow(
                            label: "Next billing date",
                            value: subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted)
                        )

                        InfoRow(
                            label: "Days until renewal",
                            value: subscription.isOverdue ? "Overdue" : "\(subscription.daysUntilNextBilling) days"
                        )

                        InfoRow(
                            label: "Billing cycle",
                            value: subscription.billingCycle.rawValue
                        )

                        InfoRow(
                            label: "Status",
                            value: subscription.isActive ? "Active" : "Inactive"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Notes
                if !subscription.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(subscription.notes)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        var updatedSubscription = subscription
                        updatedSubscription.updateNextBillingDate()
                        subscriptionManager.updateSubscription(updatedSubscription)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Mark as Renewed")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button {
                        subscriptionManager.toggleSubscriptionStatus(subscription)
                    } label: {
                        HStack {
                            Image(systemName: subscription.isActive ? "pause.circle" : "play.circle")
                            Text(subscription.isActive ? "Pause Subscription" : "Resume Subscription")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(subscription.isActive ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    viewModel.toggleEditSheet()
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingEditSheet) {
            AddEditSubscriptionView(
                subscriptionManager: subscriptionManager,
                subscription: subscription
            )
        }
        .onAppear {
            viewModel.refreshSubscription()
        }
    }
}

struct PriceCard: View {
    let title: String
    let price: Double
    let period: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(String(format: "$%.2f", price))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text("per \(period.lowercased())")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SmallPriceCard: View {
    let title: String
    let price: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "$%.2f", price))
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        SubscriptionDetailView(
            subscription: Subscription(
                name: "Netflix",
                price: 15.99,
                billingCycle: .monthly,
                category: .streaming,
                notes: "Family plan for 4 users"
            ),
            subscriptionManager: SubscriptionManager()
        )
    }
}
