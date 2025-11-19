import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private init() {}

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

    func scheduleNotification(for subscription: Subscription, daysBefore: Int = 1) {
        guard subscription.isActive else { return }

        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewal Reminder"
        content.body = "\(subscription.name) will renew in \(daysBefore) day\(daysBefore == 1 ? "" : "s") for $\(String(format: "%.2f", subscription.price))"
        content.sound = UNNotificationSound.default
        content.badge = 1

        // Calculate notification date
        let calendar = Calendar.current
        let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: subscription.nextBillingDate)

        guard let notificationDate = notificationDate,
              notificationDate > Date() else {
            return
        }

        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let identifier = "subscription_\(subscription.id.uuidString)_\(daysBefore)days"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
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

        // Schedule new notifications
        for subscription in subscriptions where subscription.isActive {
            scheduleNotification(for: subscription, daysBefore: daysBefore)
        }
    }

    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}