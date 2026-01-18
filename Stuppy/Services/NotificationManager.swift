import Foundation
import UserNotifications
import SwiftUI
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // Notification action identifiers
    static let markAsPaidActionID = "MARK_AS_PAID_ACTION"
    static let viewDetailsActionID = "VIEW_DETAILS_ACTION"
    static let snoozeActionID = "SNOOZE_ACTION"
    
    // Notification category identifier
    static let subscriptionCategoryID = "SUBSCRIPTION_RENEWAL_CATEGORY"

    private init() {
        setupNotificationCategories()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Create notification actions with URL scheme support
        let markAsPaidAction = UNNotificationAction(
            identifier: NotificationManager.markAsPaidActionID,
            title: "Позначити як оплачене",
            options: [.foreground]
        )
        
        let viewDetailsAction = UNNotificationAction(
            identifier: NotificationManager.viewDetailsActionID,
            title: "Переглянути деталі",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationManager.snoozeActionID,
            title: "Нагадати пізніше",
            options: []
        )
        
        // Create notification category
        let subscriptionCategory = UNNotificationCategory(
            identifier: NotificationManager.subscriptionCategoryID,
            actions: [markAsPaidAction, viewDetailsAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([subscriptionCategory])
    }
    
    func scheduleNotification(for subscription: Subscription, daysBefore: Int = 1, totalActiveSubscriptions: Int = 1) {
        guard subscription.isActive else { return }

        let content = UNMutableNotificationContent()
        
        // Rich notification content
        content.title = "💳 Нагадування про підписку"
        content.subtitle = subscription.name
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "uk_UA")
        
        let priceText = String(format: "%.2f", subscription.price)
        let billingCycleText = subscription.billingCycle.rawValue.lowercased()
        let renewalDateText = formatter.string(from: subscription.nextBillingDate)
        
        content.body = """
        💰 Вартість: $\(priceText) (\(billingCycleText))
        📅 Наступна дата: \(renewalDateText)
        📊 Категорія: \(subscription.category.rawValue)
        
        Підписка буде автоматично продовжена через \(daysBefore) \(daysBefore == 1 ? "день" : "днів").
        """
        
        // Звук сповіщення - використовуємо стандартний звук
        content.sound = UNNotificationSound.default
        
        // Встановлюємо бейдж на основі кількості активних підписок
        content.badge = NSNumber(value: totalActiveSubscriptions)
        
        // Додаємо важливість для iOS
        content.interruptionLevel = .active
        content.categoryIdentifier = NotificationManager.subscriptionCategoryID
        
        // Add custom user info for handling actions and deep linking
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "subscriptionName": subscription.name,
            "subscriptionPrice": subscription.price,
            "nextBillingDate": subscription.nextBillingDate.timeIntervalSince1970,
            "deepLinkURL": "stuppy://subscription/\(subscription.id.uuidString)"
        ]
        
        // Add notification icon based on subscription category
        if let iconAttachment = createNotificationAttachment(for: subscription) {
            content.attachments = [iconAttachment]
        }

        // Calculate notification date using subscription's reminder time
        let calendar = Calendar.current
        let notificationBaseDate = calendar.date(byAdding: .day, value: -daysBefore, to: subscription.nextBillingDate)

        guard let notificationBaseDate = notificationBaseDate else {
            print("❌ Error: Unable to calculate notification base date")
            return
        }

        // Комбінуємо дату нагадування з часом з reminderTime
        let reminderTimeComponents = calendar.dateComponents([.hour, .minute], from: subscription.reminderTime)
        let notificationDate = calendar.date(bySettingHour: reminderTimeComponents.hour ?? 9, 
                                           minute: reminderTimeComponents.minute ?? 0, 
                                           second: 0, 
                                           of: notificationBaseDate)

        guard let finalNotificationDate = notificationDate,
              finalNotificationDate > Date() else {
            print("❌ Error: Notification date \(notificationDate?.description ?? "nil") is in the past")
            return
        }

        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalNotificationDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let identifier = "subscription_\(subscription.id.uuidString)_\(daysBefore)days"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Save expected navigation for killed app scenarios
        let expectedNavigation = [
            "subscriptionId": subscription.id.uuidString,
            "notificationTime": finalNotificationDate.timeIntervalSince1970,
            "notificationIdentifier": identifier
        ] as [String: Any]
        UserDefaults.standard.set(expectedNavigation, forKey: "ExpectedNotificationNavigation")

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                let timeFormatter = DateFormatter()
                timeFormatter.dateStyle = .short
                timeFormatter.timeStyle = .short
                print("✅ Notification scheduled for \(timeFormatter.string(from: finalNotificationDate)) with expected navigation saved")
            }
        }
    }

    func cancelNotification(for subscription: Subscription) {
        let identifierPattern = "subscription_\(subscription.id.uuidString)"

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.contains(identifierPattern) }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }

    func scheduleAllNotifications(subscriptions: [Subscription], daysBefore: Int = 1) {
        // Cancel all existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Get active subscriptions that need notifications
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        
        // Schedule new notifications with proper badge count
        for (index, subscription) in activeSubscriptions.enumerated() {
            // Use index + 1 as badge count for incremental numbering
            scheduleNotification(for: subscription, daysBefore: daysBefore, totalActiveSubscriptions: index + 1)
        }
    }

    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func clearBadge() {
        // Clear the app badge number only
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            } else {
                print("Badge cleared successfully")
            }
        }
        
        // Don't remove all delivered notifications - let user manage them individually
        // UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func clearAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🧹 All delivered notifications cleared")
    }
    
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🧹 All pending notifications cleared")
    }
    
    func clearNotificationsForSubscription(_ subscriptionId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request -> String? in
                if let userInfo = request.content.userInfo as? [String: Any],
                   let notificationSubscriptionId = userInfo["subscriptionId"] as? String,
                   notificationSubscriptionId == subscriptionId.uuidString {
                    return request.identifier
                }
                return nil
            }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
                print("🧹 Removed \(identifiersToRemove.count) pending notifications for subscription \(subscriptionId)")
            }
        }
        
        // Also clear delivered notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications.compactMap { notification -> String? in
                if let userInfo = notification.request.content.userInfo as? [String: Any],
                   let notificationSubscriptionId = userInfo["subscriptionId"] as? String,
                   notificationSubscriptionId == subscriptionId.uuidString {
                    return notification.request.identifier
                }
                return nil
            }
            
            if !identifiersToRemove.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
                print("🧹 Removed \(identifiersToRemove.count) delivered notifications for subscription \(subscriptionId)")
            }
        }
    }
    
    private func createNotificationAttachment(for subscription: Subscription) -> UNNotificationAttachment? {
        // Create a custom notification icon based on subscription category
        let iconName = getIconName(for: subscription.category)
        let image = generateNotificationImage(iconName: iconName, subscription: subscription)
        
        guard let imageData = image.pngData() else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(subscription.id.uuidString)_icon.png")
        
        do {
            try imageData.write(to: tempURL)
            let attachment = try UNNotificationAttachment(identifier: "subscription-icon", url: tempURL, options: nil)
            return attachment
        } catch {
            print("Error creating notification attachment: \(error)")
            return nil
        }
    }
    
    private func getIconName(for category: SubscriptionCategory) -> String {
        switch category {
        case .streaming: return "tv.circle.fill"
        case .music: return "music.note.circle.fill"
        case .productivity: return "briefcase.circle.fill"
        case .fitness: return "figure.run.circle.fill"
        case .gaming: return "gamecontroller.fill"
        case .news: return "newspaper.circle.fill"
        case .storage: return "icloud.circle.fill"
        case .communication: return "message.circle.fill"
        case .finance: return "creditcard.circle.fill"
        case .other: return "app.circle.fill"
        }
    }
    
    private func generateNotificationImage(iconName: String, subscription: Subscription) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background circle
            UIColor.systemBlue.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            // Icon
            let iconSize = CGSize(width: 60, height: 60)
            let iconOrigin = CGPoint(x: (size.width - iconSize.width) / 2, y: (size.height - iconSize.height) / 2)
            
            if let iconImage = UIImage(systemName: iconName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)) {
                UIColor.white.setFill()
                iconImage.draw(in: CGRect(origin: iconOrigin, size: iconSize), blendMode: .normal, alpha: 1.0)
            }
        }
    }
    
    func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let subscriptionIdString = userInfo["subscriptionId"] as? String,
              let subscriptionId = UUID(uuidString: subscriptionIdString) else {
            completion()
            return
        }
        
        switch actionIdentifier {
        case NotificationManager.markAsPaidActionID:
            handleMarkAsPaid(subscriptionId: subscriptionId)
        case NotificationManager.viewDetailsActionID:
            handleViewDetails(subscriptionId: subscriptionId)
        case NotificationManager.snoozeActionID:
            handleSnooze(subscriptionId: subscriptionId, userInfo: userInfo)
        default:
            break
        }
        
        completion()
    }
    
    private func handleMarkAsPaid(subscriptionId: UUID) {
        // Post notification to update subscription status
        NotificationCenter.default.post(
            name: NSNotification.Name("MarkSubscriptionAsPaid"),
            object: nil,
            userInfo: ["subscriptionId": subscriptionId]
        )
    }
    
    private func handleViewDetails(subscriptionId: UUID) {
        print("🔍 HandleViewDetails викликано для ID: \(subscriptionId)")
        
        // ENHANCED: Save navigation data to MULTIPLE UserDefaults keys for redundancy
        let navigationData = [
            "subscriptionId": subscriptionId.uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "source": "notification_action"
        ] as [String: Any]
        
        // Save to multiple keys for better reliability
        UserDefaults.standard.set(navigationData, forKey: "PendingNotificationNavigation")
        UserDefaults.standard.set(subscriptionId.uuidString, forKey: "LastNotificationSubscriptionId")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "LastNotificationTimestamp")
        
        // ENHANCED: Save to KilledAppNavigationManager immediately
        KilledAppNavigationManager.shared.setPendingNavigation(subscriptionId: subscriptionId)
        
        // Try URL scheme approach for terminated app scenarios
        let urlString = "stuppy://subscription/\(subscriptionId.uuidString)"
        if let url = URL(string: urlString) {
            print("🔗 Opening URL scheme: \(urlString)")
            UIApplication.shared.open(url, options: [:]) { success in
                print("🔗 URL scheme result: \(success)")
                if !success {
                    print("❌ URL scheme failed, relying on UserDefaults navigation")
                }
            }
        }
        
        // Try direct navigation for backgrounded app (fallback)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SimpleRouter.shared.handleNotificationTap(subscriptionId: subscriptionId)
        }
    }
    
    private func handleSnooze(subscriptionId: UUID, userInfo: [AnyHashable: Any]) {
        guard let subscriptionName = userInfo["subscriptionName"] as? String,
              let subscriptionPrice = userInfo["subscriptionPrice"] as? Double,
              let _ = userInfo["nextBillingDate"] as? TimeInterval else {
            return
        }
        
        // Schedule a new notification for tomorrow
        let content = UNMutableNotificationContent()
        content.title = "🔔 Повторне нагадування"
        content.subtitle = subscriptionName
        content.body = "Нагадуємо про підписку вартістю $\(String(format: "%.2f", subscriptionPrice))"
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1) // Snoozed notification gets badge 1
        content.categoryIdentifier = NotificationManager.subscriptionCategoryID
        content.userInfo = userInfo
        
        // Schedule for tomorrow at the same time
        let calendar = Calendar.current
        let snoozeDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: snoozeDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "subscription_\(subscriptionId.uuidString)_snoozed"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snoozed notification: \(error)")
            }
        }
    }
    
    // Public method for snoozing notification (called from AppDelegate)
    func snoozeNotification(for subscriptionId: UUID) {
        print("😴 Snoozing notification for subscription: \(subscriptionId)")
        
        // For now, we'll schedule a simple snooze notification for 24 hours later
        // In a real app, you might want to get the subscription details and create a proper notification
        let content = UNMutableNotificationContent()
        content.title = "🔔 Повторне нагадування"
        content.body = "Нагадуємо про вашу підписку"
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = NotificationManager.subscriptionCategoryID
        content.userInfo = ["subscriptionId": subscriptionId.uuidString]
        
        // Schedule for 24 hours later
        let triggerDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "subscription_\(subscriptionId.uuidString)_snoozed_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling snooze notification: \(error)")
            } else {
                print("✅ Snooze notification scheduled for: \(triggerDate)")
            }
        }
    }
    
    #if DEBUG
    func scheduleTestNotification(subscriptionManager: SubscriptionManager? = nil) {
        print("📅 Планування тестового повідомлення через 1 хвилину...")
        
        // Create or get a test subscription
        let testSubscription = createTestSubscription(subscriptionManager: subscriptionManager)
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Тестове сповіщення"
        content.subtitle = testSubscription.name
        content.body = "Це тестове сповіщення для перевірки навігації. Натисніть щоб відкрити деталі підписки."
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = NotificationManager.subscriptionCategoryID
        
        content.userInfo = [
            "subscriptionId": testSubscription.id.uuidString,
            "subscriptionName": testSubscription.name,
            "subscriptionPrice": testSubscription.price,
            "nextBillingDate": testSubscription.nextBillingDate.timeIntervalSince1970,
            "deepLinkURL": "stuppy://subscription/\(testSubscription.id.uuidString)"
        ]
        
        // Schedule for 1 minute from now
        let triggerDate = Date().addingTimeInterval(60) // 60 seconds = 1 minute
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "test_notification_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Помилка планування тестового сповіщення: \(error.localizedDescription)")
                } else {
                    print("✅ Тестове сповіщення заплановано на \(triggerDate)")
                    print("📋 Підписка для тестування: \(testSubscription.name) (ID: \(testSubscription.id))")
                }
            }
        }
    }
    
    private func createTestSubscription(subscriptionManager: SubscriptionManager?) -> Subscription {
        // Try to use existing subscription first
        if let manager = subscriptionManager,
           let existingSubscription = manager.subscriptions.first {
            print("✅ Використовується існуюча підписка: \(existingSubscription.name)")
            return existingSubscription
        }
        
        // Create a test subscription if none exists
        let testSubscription = Subscription(
            id: UUID(),
            name: "🧪 Test Netflix",
            price: 15.99,
            billingCycle: .monthly,
            category: .streaming,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            isActive: true,
            notes: "Тестова підписка для перевірки сповіщень",
            color: "red",
            repetitionType: .monthly,
            isPaidForCurrentMonth: false
        )
        
        // Add to subscription manager if available
        subscriptionManager?.addSubscription(testSubscription)
        print("📝 Створена тестова підписка: \(testSubscription.name)")
        
        return testSubscription
    }
    #endif
}