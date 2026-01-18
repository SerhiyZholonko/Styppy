import Foundation
import SwiftUI

// Простий менеджер для навігації при killed app
class KilledAppNavigationManager: ObservableObject {
    static let shared = KilledAppNavigationManager()
    
    @Published var shouldNavigateToSubscription: UUID?
    @Published var shouldSwitchToSubscriptionsTab = false
    
    private let userDefaultsKey = "KilledAppPendingSubscription"
    
    private init() {}
    
    // Зберегти навігацію для killed app сценарію
    func setPendingNavigation(subscriptionId: UUID) {
        print("🎯 KilledAppNav: Setting pending navigation for \(subscriptionId)")
        
        shouldNavigateToSubscription = subscriptionId
        shouldSwitchToSubscriptionsTab = true
        
        // Зберегти в UserDefaults для killed app
        UserDefaults.standard.set(subscriptionId.uuidString, forKey: userDefaultsKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "\(userDefaultsKey)_timestamp")
        
        print("💾 KilledAppNav: Saved to UserDefaults")
    }
    
    // Відновити навігацію після app restart
    func restorePendingNavigation() {
        print("🔄 KilledAppNav: Checking for pending navigation...")
        
        var subscriptionId: UUID?
        var timestamp: TimeInterval?
        var source: String = "unknown"
        
        // Try multiple sources for maximum reliability
        
        // 1. Check primary KilledAppNav storage
        if let uuidString = UserDefaults.standard.string(forKey: userDefaultsKey),
           let id = UUID(uuidString: uuidString) {
            subscriptionId = id
            timestamp = UserDefaults.standard.object(forKey: "\(userDefaultsKey)_timestamp") as? TimeInterval
            source = "killedAppNav"
            print("📍 KilledAppNav: Found navigation in primary storage")
        }
        
        // 2. Check LastNotificationTap storage (from NotificationDelegate)
        if subscriptionId == nil,
           let uuidString = UserDefaults.standard.string(forKey: "LastNotificationTapSubscriptionId"),
           let id = UUID(uuidString: uuidString) {
            subscriptionId = id
            timestamp = UserDefaults.standard.object(forKey: "LastNotificationTapTimestamp") as? TimeInterval
            source = "notificationTap"
            print("📍 KilledAppNav: Found navigation in notification tap storage")
        }
        
        // 3. Check SimpleRouter storage
        if subscriptionId == nil,
           let uuidString = UserDefaults.standard.string(forKey: "PendingNavigationSubscriptionId"),
           let id = UUID(uuidString: uuidString) {
            subscriptionId = id
            timestamp = UserDefaults.standard.object(forKey: "PendingNavigationTimestamp") as? TimeInterval
            source = "simpleRouter"
            print("📍 KilledAppNav: Found navigation in SimpleRouter storage")
        }
        
        // 4. Check legacy notification storage
        if subscriptionId == nil,
           let navigationData = UserDefaults.standard.dictionary(forKey: "PendingNotificationNavigation"),
           let uuidString = navigationData["subscriptionId"] as? String,
           let id = UUID(uuidString: uuidString) {
            subscriptionId = id
            timestamp = navigationData["timestamp"] as? TimeInterval
            source = "legacyNotification"
            print("📍 KilledAppNav: Found navigation in legacy notification storage")
        }
        
        guard let finalSubscriptionId = subscriptionId else {
            print("ℹ️ KilledAppNav: No pending navigation found in any storage")
            return
        }
        
        // Перевірити timestamp (не старше 2 годин для killed app scenarios)
        if let ts = timestamp {
            let age = Date().timeIntervalSince1970 - ts
            if age > 7200 { // 2 години
                print("⏰ KilledAppNav: Pending navigation too old (\(age/60) minutes), clearing")
                clearAllPendingNavigation()
                return
            }
            print("⏰ KilledAppNav: Navigation age: \(age/60) minutes (source: \(source))")
        } else {
            print("⏰ KilledAppNav: No timestamp found, assuming recent navigation")
        }
        
        print("✅ KilledAppNav: Restored pending navigation for \(finalSubscriptionId) from \(source)")
        shouldNavigateToSubscription = finalSubscriptionId
        shouldSwitchToSubscriptionsTab = true
    }
    
    // Очистити навігацію
    func clearPendingNavigation() {
        print("🧹 KilledAppNav: Clearing pending navigation")
        shouldNavigateToSubscription = nil
        shouldSwitchToSubscriptionsTab = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "\(userDefaultsKey)_timestamp")
    }
    
    // Очистити всі джерела навігації
    func clearAllPendingNavigation() {
        print("🧹 KilledAppNav: Clearing ALL pending navigation sources")
        shouldNavigateToSubscription = nil
        shouldSwitchToSubscriptionsTab = false
        
        // Clear all possible storage locations
        let keysToRemove = [
            userDefaultsKey,
            "\(userDefaultsKey)_timestamp",
            "LastNotificationTapSubscriptionId",
            "LastNotificationTapTimestamp", 
            "LastNotificationTapSource",
            "PendingNavigationSubscriptionId",
            "PendingNavigationSource",
            "PendingNavigationTimestamp",
            "PendingNotificationNavigation",
            "LastScheduledNotification",
            "ExpectedNotificationNavigation"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🧹 KilledAppNav: Cleared \(keysToRemove.count) UserDefaults keys")
    }
    
    // Виконати навігацію
    func executePendingNavigation() {
        guard let subscriptionId = shouldNavigateToSubscription else {
            print("ℹ️ KilledAppNav: No pending navigation to execute")
            return
        }
        
        print("🚀 KilledAppNav: Executing navigation for \(subscriptionId)")
        
        // Відправити сигнал навігації
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("KilledAppNavigateToSubscription"),
                object: nil,
                userInfo: ["subscriptionId": subscriptionId]
            )
        }
    }
}