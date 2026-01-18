//
//  StubyApp.swift
//  Stuby
//
//  Created by apple on 17.09.2025.
//

import SwiftUI
import UserNotifications
import UIKit

@main
struct StubyApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var simpleRouter = SimpleRouter.shared
    @StateObject private var killedAppNav = KilledAppNavigationManager.shared
    
    // AppDelegate for handling notifications and deep links
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        setupNotificationDelegate()
        registerURLScheme()
    }
    
    private func registerURLScheme() {
        // Register URL scheme programmatically for iOS 17+
        // This is a workaround since INFOPLIST_KEY doesn't work for complex structures
        if let bundleID = Bundle.main.bundleIdentifier {
            print("🔗 Bundle ID: \(bundleID) - URL scheme 'stuppy' will be handled programmatically")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    notificationManager.requestPermission()
                    setupNotificationObservers()
                    // Clear badge and delivered notifications when app opens
                    notificationManager.clearBadge()
                    notificationManager.clearAllDeliveredNotifications()
                    
                    // Don't clear pending navigation immediately - it might be needed for killed app scenario
                    // simpleRouter.clearPendingNavigation() // Moved to after navigation attempts
                    
                    // NEW SIMPLE APPROACH: Check for killed app navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🚀 StubyApp: Starting killed app navigation check...")
                        
                        // Force load subscriptions first
                        if subscriptionManager.subscriptions.isEmpty {
                            print("📊 StubyApp: Loading subscriptions from storage...")
                            subscriptionManager.loadSubscriptionsFromStorage()
                        }
                        
                        // Check for killed app navigation
                        killedAppNav.restorePendingNavigation()
                        
                        if killedAppNav.shouldNavigateToSubscription != nil {
                            print("🎯 StubyApp: Found killed app navigation, executing...")
                            // Small delay to ensure UI is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                killedAppNav.executePendingNavigation()
                            }
                        } else {
                            print("✅ StubyApp: No killed app navigation, staying on dashboard")
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Clear badge and delivered notifications when app becomes active
                    notificationManager.clearBadge()
                    notificationManager.clearAllDeliveredNotifications()
                }
                .onOpenURL { url in
                    print("🔗 StubyApp received URL: \(url)")
                    print("🔗 URL scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil")")
                    print("🔗 URL pathComponents: \(url.pathComponents)")
                    
                    // Handle deep link using SimpleRouter (extract subscription ID from URL)
                    if url.scheme == "stuppy" && url.host == "subscription" {
                        let pathComponents = url.pathComponents
                        if pathComponents.count >= 2,
                           let subscriptionId = UUID(uuidString: pathComponents[1]) {
                            print("✅ Successfully parsed subscription ID: \(subscriptionId)")
                            print("🎯 Navigating to subscription via KilledAppNavigationManager...")
                            // FIX: Use KilledAppNavigationManager instead of SimpleRouter
                            KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                KilledAppNavigationManager.shared.executePendingNavigation()
                            }
                        } else {
                            print("❌ Failed to parse subscription ID from URL")
                        }
                    } else {
                        print("❌ URL doesn't match expected format (stuppy://subscription/...)")
                    }
                }
                .onContinueUserActivity("com.stuppy.viewSubscription") { userActivity in
                    print("🔄 Continuing user activity: \(userActivity.activityType)")
                    
                    if let subscriptionIdString = userActivity.userInfo?["subscriptionId"] as? String,
                       let subscriptionId = UUID(uuidString: subscriptionIdString) {
                        print("✅ Restored navigation from NSUserActivity: \(subscriptionId)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // FIX: Use KilledAppNavigationManager instead of SimpleRouter
                            KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
                            KilledAppNavigationManager.shared.executePendingNavigation()
                        }
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    private func setupNotificationObservers() {
        // Listen for notification to mark subscription as paid
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MarkSubscriptionAsPaid"),
            object: nil,
            queue: .main
        ) { notification in
            if let subscriptionId = notification.userInfo?["subscriptionId"] as? UUID {
                print("💰 StubyApp: Позначення як оплачене для ID: \(subscriptionId)")
                markSubscriptionAsPaid(subscriptionId: subscriptionId)
            } else {
                print("❌ StubyApp: Неможливо отримати ID підписки")
            }
        }
        
        // Listen for direct navigation requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToSubscription"),
            object: nil,
            queue: .main
        ) { notification in
            print("📱 StubyApp: Received direct navigation request")
            if let subscriptionId = notification.userInfo?["subscriptionId"] as? UUID {
                print("📱 StubyApp: Navigating to subscription \(subscriptionId)")
                // Just switch tab - ContentView will handle the actual navigation
                DispatchQueue.main.async {
                    NavigationManager.shared.selectedTab = 1
                }
            }
        }
    }
    
    private func markSubscriptionAsPaid(subscriptionId: UUID) {
        if let subscription = subscriptionManager.subscriptions.first(where: { $0.id == subscriptionId }) {
            subscriptionManager.markSubscriptionAsPaid(subscription)
        }
    }
    
    
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    override init() {
        super.init()
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        print("🔔 NotificationDelegate received action: \(actionIdentifier)")
        
        // Clear badge when user interacts with notification
        NotificationManager.shared.clearBadge()
        
        // Handle default tap on notification (when user taps notification body)
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            // User tapped the notification itself - navigate to subscription details
            if let subscriptionIdString = userInfo["subscriptionId"] as? String,
               let subscriptionId = UUID(uuidString: subscriptionIdString) {
                print("📱 NotificationDelegate: User tapped notification - opening subscription: \(subscriptionId)")
                
                // ENHANCED: Save to multiple UserDefaults keys for maximum reliability
                UserDefaults.standard.set(subscriptionIdString, forKey: "LastNotificationTapSubscriptionId")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "LastNotificationTapTimestamp")
                UserDefaults.standard.set("notification_tap", forKey: "LastNotificationTapSource")
                
                // Also save to SimpleRouter for consistency
                UserDefaults.standard.set(subscriptionIdString, forKey: "PendingNavigationSubscriptionId")
                UserDefaults.standard.set("notification_tap", forKey: "PendingNavigationSource")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "PendingNavigationTimestamp")
                
                // Use KilledAppNavigationManager as primary method
                KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
                
                // Execute pending navigation with delay to let UI settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    KilledAppNavigationManager.shared.executePendingNavigation()
                }
                
                print("✅ NotificationDelegate: Saved navigation data to multiple locations")
                print("📋 NotificationDelegate: Handled via KilledAppNavigationManager")
            }
        } else {
            // Handle action buttons
            NotificationManager.shared.handleNotificationAction(
                actionIdentifier: actionIdentifier,
                userInfo: userInfo,
                completion: completionHandler
            )
        }
        
        completionHandler()
    }
    
    // Fallback method to check delivered notifications for app launch
    private func checkDeliveredNotificationsForLaunch() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("📋 StubyApp: Found \(notifications.count) delivered notifications")
            
            // Look for recent notifications (last 10 minutes)
            let recentNotifications = notifications.filter { notification in
                let deliveryDate = notification.date
                let timeSinceDelivery = Date().timeIntervalSince(deliveryDate)
                return timeSinceDelivery < 600 // 10 minutes
            }
            
            print("📋 StubyApp: Found \(recentNotifications.count) recent notifications")
            
            // Sort by delivery date, most recent first
            let sortedNotifications = recentNotifications.sorted { $0.date > $1.date }
            
            for notification in sortedNotifications {
                let userInfo = notification.request.content.userInfo
                
                if let subscriptionIdString = userInfo["subscriptionId"] as? String,
                   let subscriptionId = UUID(uuidString: subscriptionIdString) {
                    
                    let timeSinceDelivery = Date().timeIntervalSince(notification.date)
                    print("🎯 StubyApp: Found potential trigger notification for \(subscriptionId)")
                    print("🎯 StubyApp: Delivered \(Int(timeSinceDelivery)) seconds ago")
                    
                    // Use this notification for navigation
                    DispatchQueue.main.async {
                        print("🚀 StubyApp: Using delivered notification for navigation")
                        // FIX: Use KilledAppNavigationManager instead of SimpleRouter
                        KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
                        KilledAppNavigationManager.shared.executePendingNavigation()
                    }
                    
                    break // Only handle the most recent one
                }
            }
        }
    }
    
}
