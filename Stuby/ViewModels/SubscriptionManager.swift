import Foundation
import SwiftUI

class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []

    private let userDefaults = UserDefaults.standard
    private let subscriptionsKey = "SavedSubscriptions"

    init() {
        loadSubscriptions()
        migrateExistingData()
        addSampleData()
        processAutoRenewals()
    }

    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveSubscriptions()
    }

    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            saveSubscriptions()
        }
    }

    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()
    }

    func toggleSubscriptionStatus(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index].isActive.toggle()
            saveSubscriptions()
        }
    }

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    var upcomingSubscriptions: [Subscription] {
        activeSubscriptions
            .filter { $0.daysUntilNextBilling <= 7 && !$0.isOverdue }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    var overdueSubscriptions: [Subscription] {
        activeSubscriptions.filter { $0.isOverdue }
    }

    var totalMonthlySpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyPrice }
    }
    
    // Total spending for current month - includes yearly subscriptions only when they're due
    var totalCurrentMonthSpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.currentMonthPrice }
    }

    var totalYearlySpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.yearlyPrice }
    }

    func subscriptions(for category: SubscriptionCategory) -> [Subscription] {
        activeSubscriptions.filter { $0.category == category }
    }

    func monthlySpending(for category: SubscriptionCategory) -> Double {
        subscriptions(for: category).reduce(0) { $0 + $1.monthlyPrice }
    }
    
    func currentMonthSpending(for category: SubscriptionCategory) -> Double {
        subscriptions(for: category).reduce(0) { $0 + $1.currentMonthPrice }
    }
    
    func clearAllSubscriptions() {
        subscriptions.removeAll()
        saveSubscriptions()
    }

    func processAutoRenewals() {
        var hasChanges = false

        for i in subscriptions.indices {
            let subscription = subscriptions[i]

            if subscription.isActive &&
               subscription.repetitionType != .disabled &&
               subscription.isOverdue {

                subscriptions[i].updateNextBillingDate()
                hasChanges = true
            }
        }

        if hasChanges {
            saveSubscriptions()
        }
    }

    var subscriptionsWithoutAutoRenewal: [Subscription] {
        activeSubscriptions.filter { $0.repetitionType == .disabled }
    }

    var autoRenewingSubscriptions: [Subscription] {
        activeSubscriptions.filter { $0.repetitionType != .disabled }
    }

    private func saveSubscriptions() {
        do {
            let data = try JSONEncoder().encode(subscriptions)
            userDefaults.set(data, forKey: subscriptionsKey)
        } catch {
            print("Failed to save subscriptions: \(error)")
        }
    }

    private func loadSubscriptions() {
        guard let data = userDefaults.data(forKey: subscriptionsKey) else { return }
        do {
            subscriptions = try JSONDecoder().decode([Subscription].self, from: data)
        } catch {
            print("Failed to load subscriptions: \(error)")
        }
    }

    private func addSampleData() {
        guard subscriptions.isEmpty else { return }

        let sampleSubscriptions = [
            Subscription(
                name: "Netflix",
                price: 15.99,
                billingCycle: .monthly,
                category: .streaming,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                color: "red",
                repetitionType: .monthly
            ),
            Subscription(
                name: "Spotify",
                price: 9.99,
                billingCycle: .monthly,
                category: .music,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
                color: "green",
                repetitionType: .monthly
            ),
            Subscription(
                name: "Adobe Creative Cloud",
                price: 52.99,
                billingCycle: .yearly,
                category: .productivity,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                color: "purple",
                repetitionType: .yearly
            )
        ]

        subscriptions = sampleSubscriptions
        saveSubscriptions()
    }
    
    private func migrateExistingData() {
        var hasChanges = false
        
        for i in subscriptions.indices {
            let subscription = subscriptions[i]
            
            // Fix Adobe Creative Cloud billing cycle
            if subscription.name == "Adobe Creative Cloud" && 
               subscription.billingCycle == .monthly && 
               subscription.repetitionType == .yearly {
                subscriptions[i] = Subscription(
                    id: subscription.id,
                    name: subscription.name,
                    price: subscription.price,
                    billingCycle: .yearly,
                    category: subscription.category,
                    nextBillingDate: subscription.nextBillingDate,
                    isActive: subscription.isActive,
                    notes: subscription.notes,
                    color: subscription.color,
                    repetitionType: subscription.repetitionType
                )
                hasChanges = true
            }
        }
        
        if hasChanges {
            saveSubscriptions()
        }
    }
}
