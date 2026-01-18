import SwiftUI

struct SubscriptionDetailView: View {
    let subscription: Subscription
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    @State private var showingEditSheet = false
    
    // Оптимізація: використовуємо прямо дані замість ViewModel для простих обчислень
    private var currentSubscription: Subscription {
        subscriptionManager.subscriptions.first { $0.id == subscription.id } ?? subscription
    }

    var body: some View {
        ScrollView {
            Color.clear
                .onAppear {
                    print("🎯 SubscriptionDetailView: Appeared for subscription \(subscription.name) (\(subscription.id))")
                }
                .frame(height: 0)
            LazyVStack(spacing: 20) {
                // Спрощений Header
                VStack(spacing: 12) {
                    Image(systemName: currentSubscription.category.icon)
                        .font(.system(size: 50))
                        .foregroundColor(currentSubscription.category.color)
                        .frame(width: 80, height: 80)
                        .background(currentSubscription.category.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text(currentSubscription.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(currentSubscription.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
                .padding(.top, 10)

                // Спрощена Price Information
                VStack(spacing: 12) {
                    // Основна ціна
                    VStack(spacing: 4) {
                        Text("Current Price")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.2f", currentSubscription.price))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(currentSubscription.category.color)
                        Text("per \(currentSubscription.billingCycle.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(currentSubscription.category.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Додаткові ціни
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Text("Monthly")
                                .font(.caption2)
                            Text(String(format: "$%.2f", currentSubscription.monthlyPrice))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(spacing: 2) {
                            Text("Yearly")
                                .font(.caption2)
                            Text(String(format: "$%.2f", currentSubscription.yearlyPrice))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Спрощена Billing Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Billing Info")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 6) {
                        HStack {
                            Text("Next billing:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currentSubscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Days until renewal:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currentSubscription.isOverdue ? "Overdue" : "\(currentSubscription.daysUntilRenewal) days")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(currentSubscription.isOverdue ? .red : .primary)
                        }
                        
                        HStack {
                            Text("Status:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currentSubscription.isActive ? "Active" : "Inactive")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(currentSubscription.isActive ? .green : .gray)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Спрощені Notes
                if !currentSubscription.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(currentSubscription.notes)
                            .font(.caption)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Спрощені Actions
                VStack(spacing: 8) {
                    Button {
                        var updatedSubscription = currentSubscription
                        updatedSubscription.updateNextBillingDate()
                        subscriptionManager.updateSubscription(updatedSubscription)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Mark as Paid")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(spacing: 8) {
                        Button {
                            subscriptionManager.toggleSubscriptionStatus(currentSubscription)
                        } label: {
                            HStack {
                                Image(systemName: currentSubscription.isActive ? "pause" : "play")
                                    .font(.caption2)
                                Text(currentSubscription.isActive ? "Pause" : "Resume")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(currentSubscription.isActive ? Color.orange : Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Button {
                            subscriptionManager.deleteSubscription(currentSubscription)
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.caption2)
                                Text("Delete")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .background(Color(.systemBackground))
        .navigationTitle(currentSubscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingEditSheet) {
            AddEditSubscriptionView(
                subscriptionManager: subscriptionManager,
                subscription: currentSubscription
            )
        }
        .onAppear {
            print("📱 SubscriptionDetailView appeared for: \(currentSubscription.name) (ID: \(currentSubscription.id))")
        }
        .onDisappear {
            print("📱 SubscriptionDetailView disappeared for: \(currentSubscription.name)")
        }
    }
}
