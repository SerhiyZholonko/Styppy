import Foundation
import SwiftUI

// Simple Router for notification-based navigation
class SimpleRouter: ObservableObject {
    static let shared = SimpleRouter()
    
    @Published var selectedTab: Int = 0
    @Published var pendingSubscriptionId: UUID?
    
    private let pendingNavigationKey = "PendingNavigationSubscriptionId"
    private let pendingNavigationSourceKey = "PendingNavigationSource"
    private let pendingNavigationTimestampKey = "PendingNavigationTimestamp"
    
    // Navigation state tracking to prevent duplicate navigation
    private var navigationInProgress = false
    private var lastNavigatedSubscriptionId: UUID?
    private var lastNavigationTime: Date?
    
    private init() {
        // Clean up old UserDefaults first
        cleanupOldNavigationData()
        
        // Restore pending navigation from UserDefaults
        restorePendingNavigation()
        
        // If no valid navigation was restored, make sure we start on dashboard
        if pendingSubscriptionId == nil {
            selectedTab = 0
            print("🏠 SimpleRouter: No pending navigation found, defaulting to dashboard tab")
        }
    }
    
    private func cleanupOldNavigationData() {
        // Remove only OLD navigation-related UserDefaults, NOT our current ones
        let keysToClean = [
            "PendingNotificationNavigation",
            "LastScheduledNotification", 
            "ExpectedNotificationNavigation",
            "LastNotificationInfo",
            "NotificationLaunchIntent"
        ]
        
        for key in keysToClean {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🧹 SimpleRouter: Cleaned up old navigation data (kept current pending navigation)")
    }
    
    // Handle notification tap
    func handleNotificationTap(subscriptionId: UUID) {
        print("🔔 SimpleRouter: Handling notification tap for subscription \(subscriptionId)")
        
        // Store pending subscription ID
        pendingSubscriptionId = subscriptionId
        savePendingNavigation(subscriptionId: subscriptionId, source: "notification_tap")
        
        // Switch to subscriptions tab
        selectedTab = 1
        
        DispatchQueue.main.async {
            self.executePendingNavigation()
        }
    }
    
    // Execute pending navigation
    func executePendingNavigation() {
        guard let subscriptionId = pendingSubscriptionId else { return }
        
        print("⚡ SimpleRouter: Executing pending navigation for \(subscriptionId)")
        
        // Simple duplicate check - only block if navigated to same subscription in last 2 seconds
        if let lastTime = lastNavigationTime,
           Date().timeIntervalSince(lastTime) < 2 {
            print("⚠️ SimpleRouter: Recent navigation detected, skipping duplicate")
            return
        }
        
        // Update last navigation time
        lastNavigationTime = Date()
        
        // Use legacy NavigationManager for actual navigation
        NavigationManager.shared.selectedTab = selectedTab
        
        // Send navigation signal
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToSubscription"),
                object: nil,
                userInfo: ["subscriptionId": subscriptionId]
            )
            print("✅ SimpleRouter: Navigation signal sent for \(subscriptionId)")
        }
    }
    
    // Clear pending navigation
    func clearPendingNavigation() {
        print("🧹 SimpleRouter: Clearing pending navigation")
        pendingSubscriptionId = nil
        UserDefaults.standard.removeObject(forKey: pendingNavigationKey)
        UserDefaults.standard.removeObject(forKey: pendingNavigationSourceKey)
        UserDefaults.standard.removeObject(forKey: pendingNavigationTimestampKey)
        print("🧹 SimpleRouter: Cleared pending navigation successfully")
    }
    
    // Force reset to dashboard (when navigation fails)
    func resetToDashboard() {
        print("🔄 SimpleRouter: Forcing reset to dashboard")
        clearPendingNavigation()
        selectedTab = 0
        NavigationManager.shared.selectedTab = 0
        print("✅ SimpleRouter: Reset to dashboard completed")
    }
    
    // Tab selection
    func selectTab(_ tabIndex: Int) {
        print("🎯 SimpleRouter: selectTab called with index: \(tabIndex)")
        print("📊 SimpleRouter: Current selectedTab: \(selectedTab) -> \(tabIndex)")
        selectedTab = tabIndex
        NavigationManager.shared.selectedTab = tabIndex
    }
    
    // Check if there's a valid pending navigation from notification
    func hasValidNotificationNavigation() -> Bool {
        // Simple check: if we have a pending subscription ID, it's valid
        let isValid = pendingSubscriptionId != nil
        print("🔍 SimpleRouter: hasValidNotificationNavigation = \(isValid)")
        return isValid
    }
    
    // MARK: - Persistence
    
    private func savePendingNavigation(subscriptionId: UUID, source: String) {
        UserDefaults.standard.set(subscriptionId.uuidString, forKey: pendingNavigationKey)
        UserDefaults.standard.set(source, forKey: pendingNavigationSourceKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: pendingNavigationTimestampKey)
        print("💾 SimpleRouter: Saved pending navigation for \(subscriptionId) from source: \(source)")
    }
    
    private func restorePendingNavigation() {
        print("🔍 SimpleRouter: Checking for saved pending navigation...")
        print("🔍 SimpleRouter: pendingNavigationKey = \(pendingNavigationKey)")
        
        if let uuidString = UserDefaults.standard.string(forKey: pendingNavigationKey) {
            print("🔍 SimpleRouter: Found saved UUID string: \(uuidString)")
            
            if let subscriptionId = UUID(uuidString: uuidString) {
                print("🔍 SimpleRouter: Successfully parsed UUID: \(subscriptionId)")
                
                // Check if it's recent (within 24 hours for killed app scenarios)
                if let timestamp = UserDefaults.standard.object(forKey: pendingNavigationTimestampKey) as? TimeInterval {
                    let age = Date().timeIntervalSince1970 - timestamp
                    print("🔍 SimpleRouter: Found timestamp, age: \(age) seconds (\(age/3600) hours)")
                    
                    if age < 86400 { // 24 hours
                        pendingSubscriptionId = subscriptionId
                        selectedTab = 1 // Make sure we're on the right tab
                        print("🔄 SimpleRouter: Restored pending navigation for \(subscriptionId)")
                        print("🔄 SimpleRouter: Set selectedTab to: \(selectedTab)")
                        return
                    } else {
                        print("⏰ SimpleRouter: Navigation data too old (\(age) seconds / \(age/3600) hours)")
                        // For notification-based navigation, allow even old data (user might tap notification later)
                        if let source = UserDefaults.standard.string(forKey: pendingNavigationSourceKey),
                           source == "notification_tap" {
                            print("🔔 SimpleRouter: But this is from notification tap, allowing old navigation")
                            pendingSubscriptionId = subscriptionId
                            selectedTab = 1
                            print("🔄 SimpleRouter: Restored old pending navigation for \(subscriptionId)")
                            return
                        } else {
                            print("🧹 SimpleRouter: Not from notification, clearing old data")
                        }
                    }
                } else {
                    print("❌ SimpleRouter: No timestamp found, assuming fresh navigation")
                    // If no timestamp, assume it's recent (for killed app scenarios)
                    pendingSubscriptionId = subscriptionId
                    selectedTab = 1
                    print("🔄 SimpleRouter: Restored pending navigation for \(subscriptionId) (no timestamp)")
                    return
                }
            } else {
                print("❌ SimpleRouter: Failed to parse UUID from string: \(uuidString)")
            }
            
            // Clear old navigation data
            clearPendingNavigation()
        } else {
            print("ℹ️ SimpleRouter: No saved UUID string found")
        }
        print("ℹ️ SimpleRouter: No valid pending navigation to restore")
    }
    
    // Force execute pending navigation (for app startup)
    func handleAppLaunchNavigation() {
        print("🚀 SimpleRouter: handleAppLaunchNavigation called")
        print("🚀 SimpleRouter: Current pendingSubscriptionId: \(String(describing: pendingSubscriptionId))")
        
        guard let subscriptionId = pendingSubscriptionId else { 
            print("ℹ️ SimpleRouter: No pending navigation - staying on default tab")
            // Make sure we're on dashboard tab if no navigation needed
            selectedTab = 0
            NavigationManager.shared.selectedTab = 0
            return 
        }
        
        print("🚀 SimpleRouter: Handling app launch navigation for \(subscriptionId)")
        
        // Switch to subscriptions tab and sync with NavigationManager
        selectedTab = 1
        NavigationManager.shared.selectedTab = 1
        print("🚀 SimpleRouter: Set selectedTab to 1, NavigationManager.selectedTab to 1")
        
        // Force execution of navigation immediately and also with delay as backup
        print("🚀 SimpleRouter: Executing navigation immediately...")
        executePendingNavigation()
        
        // Execute navigation with delay for UI loading as backup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🚀 SimpleRouter: Executing pending navigation after delay (backup)...")
            if self.pendingSubscriptionId != nil {
                self.executePendingNavigation()
            } else {
                print("⚠️ SimpleRouter: Backup navigation cancelled - pending navigation already cleared")
            }
        }
        
        // Safety timeout - if navigation doesn't complete in 10 seconds, clear everything
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.pendingSubscriptionId != nil {
                print("⏰ SimpleRouter: Navigation timeout reached, clearing pending navigation")
                print("⏰ SimpleRouter: Returning to dashboard tab")
                self.clearPendingNavigation()
                self.selectedTab = 0
                NavigationManager.shared.selectedTab = 0
            }
        }
    }
}