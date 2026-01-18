import Foundation
import SwiftUI

// NavigationManager - Updated to work with SimpleRouter
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedTab: Int = 0
    @Published var subscriptionToShow: UUID? = nil
    @Published var shouldShowSubscriptionDetail: Bool = false
    @Published var pendingSubscriptionId: UUID? = nil
    
    private init() {}
    
    // Navigation to specific subscription (used by SimpleRouter)
    func navigateToSubscription(id: UUID) {
        print("🔗 NavigationManager: Navigating to subscription \(id)")
        
        // Store the subscription ID
        subscriptionToShow = id
        shouldShowSubscriptionDetail = true
        
        print("✅ Navigation state set for subscription: \(id)")
    }
    
    // Simple tab switching for legacy support
    func selectTab(_ tabIndex: Int) {
        selectedTab = tabIndex
    }
    
    // Clear all navigation state
    func resetNavigationState() {
        subscriptionToShow = nil
        shouldShowSubscriptionDetail = false
        pendingSubscriptionId = nil
    }
}