import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showingCalendar = false
    
    private var subscriptionManager: SubscriptionManager
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }
    
    var upcomingNotificationsCount: Int {
        let calendar = Calendar.current
        let today = Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return subscriptionManager.activeSubscriptions.filter { subscription in
            subscription.nextBillingDate >= today && 
            subscription.nextBillingDate <= nextWeek &&
            !subscription.isPaidForCurrentMonth
        }.count
    }
    
    var totalMonthlySpending: Double {
        subscriptionManager.totalUnpaidCurrentMonthSpending
    }
    
    var totalYearlySpending: Double {
        subscriptionManager.totalYearlySpending
    }
    
    var activeSubscriptionsCount: Int {
        subscriptionManager.activeSubscriptions.count
    }
    
    var upcomingSubscriptionsCount: Int {
        subscriptionManager.upcomingSubscriptions.count
    }
    
    var overdueSubscriptions: [Subscription] {
        subscriptionManager.overdueSubscriptions
    }
    
    var upcomingSubscriptions: [Subscription] {
        subscriptionManager.upcomingSubscriptions
    }
    
    var recentActiveSubscriptions: [Subscription] {
        Array(subscriptionManager.activeSubscriptions.prefix(5))
    }
    
    var hasActiveSubscriptions: Bool {
        !subscriptionManager.activeSubscriptions.isEmpty
    }
    
    var hasOverdueSubscriptions: Bool {
        !overdueSubscriptions.isEmpty
    }
    
    var hasUpcomingSubscriptions: Bool {
        !upcomingSubscriptions.isEmpty
    }
    
    func toggleCalendar() {
        showingCalendar.toggle()
    }
}