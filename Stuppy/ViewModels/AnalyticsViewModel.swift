import Foundation
import SwiftUI

class AnalyticsViewModel: ObservableObject {
    @Published var selectedPeriod: AnalyticsPeriod = .month
    
    private var subscriptionManager: SubscriptionManager
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }
    
    var totalSpending: Double {
        selectedPeriod == .month ? 
        subscriptionManager.totalCurrentMonthSpending : 
        subscriptionManager.totalYearlySpending
    }
    
    var activeSubscriptionsCount: Int {
        subscriptionManager.activeSubscriptions.count
    }
    
    var hasActiveSubscriptions: Bool {
        !subscriptionManager.activeSubscriptions.isEmpty
    }
    
    var categoryData: [CategoryData] {
        SubscriptionCategory.allCases.compactMap { category in
            let amount = selectedPeriod == .month ?
                subscriptionManager.currentMonthSpending(for: category) :
                subscriptionManager.monthlySpending(for: category) * 12
            return amount > 0 ? CategoryData(category: category, amount: amount) : nil
        }.sorted { $0.amount > $1.amount }
    }
    
    var upcomingSubscriptions: [Subscription] {
        subscriptionManager.upcomingSubscriptions
    }
    
    var hasUpcomingSubscriptions: Bool {
        !upcomingSubscriptions.isEmpty
    }
    
    var mostExpensiveSubscription: String {
        subscriptionManager.activeSubscriptions
            .max { $0.monthlyPrice < $1.monthlyPrice }?.name ?? "N/A"
    }

    var cheapestSubscription: String {
        subscriptionManager.activeSubscriptions
            .min { $0.monthlyPrice < $1.monthlyPrice }?.name ?? "N/A"
    }

    var mostCommonBillingCycle: String {
        let cycles = subscriptionManager.activeSubscriptions.map { $0.billingCycle }
        let counts = Dictionary(grouping: cycles) { $0 }.mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key.rawValue ?? "N/A"
    }

    var mostCommonCategory: String {
        let categories = subscriptionManager.activeSubscriptions.map { $0.category }
        let counts = Dictionary(grouping: categories) { $0 }.mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key.rawValue ?? "N/A"
    }
    
    var averageMonthlyCost: Double {
        subscriptionManager.totalCurrentMonthSpending / Double(max(1, subscriptionManager.activeSubscriptions.count))
    }
    
    func subscriptionCount(for category: SubscriptionCategory) -> Int {
        subscriptionManager.subscriptions(for: category).count
    }
    
    func percentage(for amount: Double) -> Double {
        amount / totalSpending * 100
    }
}

enum AnalyticsPeriod: String, CaseIterable {
    case month = "Month"
    case year = "Year"
}

struct CategoryData {
    let category: SubscriptionCategory
    let amount: Double
}