import Foundation
import SwiftUI

class SubscriptionDetailViewModel: ObservableObject {
    @Published var showingEditSheet = false
    @Published var showingDeleteAlert = false
    @Published var showingCalendarView = false
    
    private var subscription: Subscription
    private var subscriptionManager: SubscriptionManager
    
    init(subscription: Subscription, subscriptionManager: SubscriptionManager) {
        self.subscription = subscription
        self.subscriptionManager = subscriptionManager
    }
    
    var subscriptionName: String {
        subscription.name
    }
    
    var subscriptionPrice: String {
        String(format: "$%.2f", subscription.price)
    }
    
    var subscriptionCategory: SubscriptionCategory {
        subscription.category
    }
    
    var billingCycle: BillingCycle {
        subscription.billingCycle
    }
    
    var nextBillingDate: Date {
        subscription.nextBillingDate
    }
    
    var formattedNextBillingDate: String {
        subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    var daysUntilNextBilling: Int {
        subscription.daysUntilNextBilling
    }
    
    var monthlyEquivalent: String {
        String(format: "$%.2f", subscription.monthlyPrice)
    }
    
    var yearlyEquivalent: String {
        String(format: "$%.2f", subscription.monthlyPrice * 12)
    }
    
    var notes: String {
        subscription.notes
    }
    
    var isActive: Bool {
        subscription.isActive
    }
    
    var isOverdue: Bool {
        subscription.isOverdue
    }
    
    var statusColor: Color {
        if !subscription.isActive {
            return .gray
        } else if subscription.isOverdue {
            return .red
        } else if subscription.daysUntilNextBilling <= 3 {
            return .orange
        } else {
            return .green
        }
    }
    
    var statusText: String {
        if !subscription.isActive {
            return "Inactive"
        } else if subscription.isOverdue {
            return "Overdue"
        } else if subscription.daysUntilNextBilling <= 3 {
            return "Due Soon"
        } else {
            return "Active"
        }
    }
    
    func toggleSubscriptionStatus() {
        subscriptionManager.toggleSubscriptionStatus(subscription)
    }
    
    func deleteSubscription() {
        subscriptionManager.deleteSubscription(subscription)
    }
    
    func toggleEditSheet() {
        showingEditSheet.toggle()
    }
    
    func toggleDeleteAlert() {
        showingDeleteAlert.toggle()
    }
    
    func toggleCalendarView() {
        showingCalendarView.toggle()
    }
    
    func refreshSubscription() {
        if let updatedSubscription = subscriptionManager.subscriptions.first(where: { $0.id == subscription.id }) {
            subscription = updatedSubscription
        }
    }
}