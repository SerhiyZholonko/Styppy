import Foundation
import SwiftUI

class SubscriptionListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory: SubscriptionCategory?
    @Published var showingAddSubscription = false
    
    private var subscriptionManager: SubscriptionManager
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }
    
    var filteredSubscriptions: [Subscription] {
        var subscriptions = subscriptionManager.activeSubscriptions

        if !searchText.isEmpty {
            subscriptions = subscriptions.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let category = selectedCategory {
            subscriptions = subscriptions.filter { $0.category == category }
        }

        return subscriptions.sorted { $0.name < $1.name }
    }
    
    var hasFilteredSubscriptions: Bool {
        !filteredSubscriptions.isEmpty
    }
    
    var allCategories: [SubscriptionCategory] {
        SubscriptionCategory.allCases
    }
    
    func selectCategory(_ category: SubscriptionCategory) {
        selectedCategory = selectedCategory == category ? nil : category
    }
    
    func clearCategoryFilter() {
        selectedCategory = nil
    }
    
    func deleteSubscriptions(at offsets: IndexSet) {
        for index in offsets {
            let subscription = filteredSubscriptions[index]
            subscriptionManager.deleteSubscription(subscription)
        }
    }
    
    func toggleAddSubscription() {
        showingAddSubscription.toggle()
    }
}