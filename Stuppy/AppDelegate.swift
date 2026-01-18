import UIKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🚀 AppDelegate: App finished launching")
        print("🚀 AppDelegate: Launch options keys: \(launchOptions?.keys.map { $0.rawValue } ?? [])")
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Check all possible launch scenarios
        var handledNotification = false
        
        // Check if app was launched from notification
        if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
            print("🔔 AppDelegate: App launched from remote notification: \(notification)")
            handleNotificationLaunch(userInfo: notification)
            handledNotification = true
        }
        
        if let localNotification = launchOptions?[.localNotification] as? [String: Any] {
            print("🔔 AppDelegate: App launched from local notification: \(localNotification)")
            handleNotificationLaunch(userInfo: localNotification)
            handledNotification = true
        }
        
        // Check for URL launch
        if let url = launchOptions?[.url] as? URL {
            print("🔗 AppDelegate: App launched from URL: \(url)")
        }
        
        if !handledNotification {
            print("ℹ️ AppDelegate: App launched normally (not from notification)")
            
            // Fallback: Check delivered notifications for potential app launch trigger
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkDeliveredNotificationsAsLaunchTrigger()
            }
        }
        
        return true
    }
    
    // Handle notification when app is launched from terminated state
    private func handleNotificationLaunch(userInfo: [String: Any]) {
        guard let subscriptionIdString = userInfo["subscriptionId"] as? String,
              let subscriptionId = UUID(uuidString: subscriptionIdString) else {
            print("❌ AppDelegate: Invalid subscription ID in notification")
            return
        }
        
        print("📱 AppDelegate: Handling notification launch for subscription: \(subscriptionId)")
        
        // FIX: Use ONLY KilledAppNavigationManager to prevent conflicts
        KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
    }
    
    
    
    
    
    
    // Handle URL scheme (deep links) - now deprecated, but kept for compatibility
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("🔗 AppDelegate: Received URL: \(url) - Redirecting to Router")
        
        // Extract subscription ID from URL and use Router
        if url.scheme == "stuppy" && url.host == "subscription" {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 2,
               let subscriptionId = UUID(uuidString: pathComponents[1]) {
                SimpleRouter.shared.handleNotificationTap(subscriptionId: subscriptionId)
                return true
            }
        }
        
        return false
    }
    
    // Handle universal links (if needed in future)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            print("🌐 AppDelegate: Received universal link: \(url) - Redirecting to Router")
            
            // Extract subscription ID and use Router
            if url.host?.contains("subscription") == true {
                let pathComponents = url.pathComponents
                if pathComponents.count >= 2,
                   let subscriptionId = UUID(uuidString: pathComponents[1]) {
                    SimpleRouter.shared.handleNotificationTap(subscriptionId: subscriptionId)
                    return true
                }
            }
        }
        
        return false
    }
    
    // Fallback method to check if app was launched by tapping a notification
    private func checkDeliveredNotificationsAsLaunchTrigger() {
        print("🔍 AppDelegate: Checking delivered notifications as potential launch trigger")
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("🔍 AppDelegate: Found \(notifications.count) total delivered notifications")
            
            // Look for very recent notifications (last 30 seconds - likely app launch trigger)
            let veryRecentNotifications = notifications.filter { notification in
                let deliveryDate = notification.date
                let timeSinceDelivery = Date().timeIntervalSince(deliveryDate)
                return timeSinceDelivery < 30 // 30 seconds
            }
            
            print("🔍 AppDelegate: Found \(veryRecentNotifications.count) very recent notifications")
            
            for notification in veryRecentNotifications {
                let userInfo = notification.request.content.userInfo
                
                if let subscriptionIdString = userInfo["subscriptionId"] as? String,
                   let subscriptionId = UUID(uuidString: subscriptionIdString) {
                    
                    let timeSinceDelivery = Date().timeIntervalSince(notification.date)
                    print("🎯 AppDelegate: Found very recent notification for \(subscriptionId)")
                    print("🎯 AppDelegate: Delivered \(Int(timeSinceDelivery)) seconds ago")
                    
                    // This might be our launch trigger
                    print("🚀 AppDelegate: Using this notification as launch trigger")
                    // FIX: Use direct KilledAppNavigationManager instead of handleNotificationLaunch
                    KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
                    
                    break
                }
            }
        }
    }
    
    // Handle background app refresh
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("⏸️ AppDelegate: App entered background")
        // Save any pending data if needed
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("▶️ AppDelegate: App will enter foreground")
        NotificationManager.shared.clearBadge()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("✅ AppDelegate: App became active")
        NotificationManager.shared.clearBadge()
    }
    
    
}

