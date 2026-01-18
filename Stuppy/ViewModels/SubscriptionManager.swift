import Foundation
import SwiftUI

class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []

    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let subscriptionsKey = "SavedSubscriptions"
    private let localBackupKey = "SavedSubscriptions_LocalBackup"

    init() {
        setupiCloudSync()
        loadSubscriptions()
        migrateFromUserDefaults()
        migrateExistingData()
        processAutoRenewals()
        processPaymentStatusReset()
    }

    // MARK: - iCloud Sync Setup

    private func setupiCloudSync() {
        // Listen for iCloud changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        // Sync with iCloud
        iCloudStore.synchronize()
    }

    @objc private func iCloudDidUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        print("☁️ iCloud sync update received, reason: \(changeReason)")

        // Handle different change reasons
        switch changeReason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // Data changed on another device or initial sync
            DispatchQueue.main.async {
                self.loadSubscriptions()
                self.updateNotifications()
                print("☁️ Subscriptions synced from iCloud: \(self.subscriptions.count) items")
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("⚠️ iCloud storage quota exceeded")
        case NSUbiquitousKeyValueStoreAccountChange:
            print("☁️ iCloud account changed, reloading data")
            DispatchQueue.main.async {
                self.loadSubscriptions()
            }
        default:
            break
        }
    }

    // Migrate data from UserDefaults to iCloud (one-time migration)
    private func migrateFromUserDefaults() {
        let userDefaults = UserDefaults.standard
        let migrationKey = "iCloudMigrationCompleted"

        // Check if migration already done
        if userDefaults.bool(forKey: migrationKey) {
            return
        }

        // Check if there's data in UserDefaults to migrate
        if let oldData = userDefaults.data(forKey: subscriptionsKey) {
            print("☁️ Migrating data from UserDefaults to iCloud...")

            // Only migrate if iCloud is empty
            if iCloudStore.data(forKey: subscriptionsKey) == nil {
                iCloudStore.set(oldData, forKey: subscriptionsKey)
                iCloudStore.synchronize()
                print("☁️ Migration to iCloud completed")
            }

            // Mark migration as completed
            userDefaults.set(true, forKey: migrationKey)
        }
    }

    func refreshSubscriptions() {
        print("🔄 refreshSubscriptions викликано")
        iCloudStore.synchronize()
        processAutoRenewals()
        processPaymentStatusReset()
    }

    // Public method to force load subscriptions from storage
    func loadSubscriptionsFromStorage() {
        print("💾 loadSubscriptionsFromStorage: Force loading from iCloud...")
        iCloudStore.synchronize()
        loadSubscriptions()
        print("💾 loadSubscriptionsFromStorage: Loaded \(subscriptions.count) subscriptions")
    }

    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveSubscriptions()
        updateNotifications()
    }

    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            saveSubscriptions()
            updateNotifications()
        }
    }

    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()
        updateNotifications()
    }

    func toggleSubscriptionStatus(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index].isActive.toggle()
            saveSubscriptions()
            updateNotifications()
        }
    }

    func markSubscriptionAsPaid(_ subscription: Subscription) {
        print("💰 markSubscriptionAsPaid викликано для: \(subscription.name)")
        print("📊 ID підписки: \(subscription.id)")
        print("📊 Cycle: \(subscription.billingCycle.rawValue)")
        print("📊 RepetitionType: \(subscription.repetitionType)")

        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            print("✅ Знайдено підписку в індексі: \(index)")

            subscriptions[index].markAsPaid()
            print("✅ Позначено як оплачене")

            // Auto-renew subscription when marked as paid
            if subscriptions[index].repetitionType != .disabled {
                print("🔄 Оновлення дати наступного платежу...")
                subscriptions[index].updateNextBillingDate()
                // Reset payment status for the new billing period
                subscriptions[index].resetPaymentStatus()
                print("✅ Дата оновлена")
            }
            saveSubscriptions()
            updateNotifications()
            print("💾 Дані збережено")
        } else {
            print("❌ Підписка не знайдена в списку!")
            print("📋 Доступні підписки:")
            for (i, sub) in subscriptions.enumerated() {
                print("  \(i): \(sub.name) (\(sub.id))")
            }
        }
    }

    func togglePaymentStatus(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            if subscriptions[index].isPaidForCurrentMonth {
                subscriptions[index].resetPaymentStatus()
            } else {
                subscriptions[index].markAsPaid()
                // Auto-renew subscription when marked as paid
                if subscriptions[index].repetitionType != .disabled {
                    subscriptions[index].updateNextBillingDate()
                    // Reset payment status for the new billing period
                    subscriptions[index].resetPaymentStatus()
                }
            }
            saveSubscriptions()
            updateNotifications()
        }
    }

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    var upcomingSubscriptions: [Subscription] {
        activeSubscriptions
            .filter { $0.daysUntilNextBilling <= 7 && !$0.isOverdue && !$0.isPaidForCurrentMonth }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    var overdueSubscriptions: [Subscription] {
        activeSubscriptions.filter { $0.isOverdue }
    }

    var totalMonthlySpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyPrice }
    }

    // Total spending for current month - includes yearly subscriptions only when they're due
    var totalCurrentMonthSpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.currentMonthPrice }
    }

    // Total unpaid amount for current month
    var totalUnpaidCurrentMonthSpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.unpaidCurrentMonthPrice }
    }

    // Total unpaid monthly spending (normalized to monthly)
    var totalUnpaidMonthlySpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.unpaidMonthlyPrice }
    }

    var totalYearlySpending: Double {
        activeSubscriptions.reduce(0) { $0 + $1.yearlyPrice }
    }

    func subscriptions(for category: SubscriptionCategory) -> [Subscription] {
        activeSubscriptions.filter { $0.category == category }
    }

    func monthlySpending(for category: SubscriptionCategory) -> Double {
        subscriptions(for: category).reduce(0) { $0 + $1.monthlyPrice }
    }

    func currentMonthSpending(for category: SubscriptionCategory) -> Double {
        subscriptions(for: category).reduce(0) { $0 + $1.currentMonthPrice }
    }

    func unpaidMonthlySpending(for category: SubscriptionCategory) -> Double {
        subscriptions(for: category).reduce(0) { $0 + $1.unpaidMonthlyPrice }
    }

    func unpaidCurrentMonthSpending(for category: SubscriptionCategory) -> Double {
        subscriptions(for: category).reduce(0) { $0 + $1.unpaidCurrentMonthPrice }
    }

    func clearAllSubscriptions() {
        subscriptions.removeAll()
        saveSubscriptions()
    }

    func processAutoRenewals() {
        var hasChanges = false

        for i in subscriptions.indices {
            let subscription = subscriptions[i]

            // Process auto-renewal when subscription is overdue OR when 1 day remains
            if subscription.isActive &&
               subscription.repetitionType != .disabled &&
               (subscription.isOverdue || subscription.daysUntilNextBilling <= 1) {

                print("🔄 Auto-renewal для \(subscription.name): днів до оплати - \(subscription.daysUntilNextBilling)")
                subscriptions[i].updateNextBillingDate()
                // Reset payment status when auto-renewing
                subscriptions[i].resetPaymentStatus()
                hasChanges = true
            }
        }

        if hasChanges {
            saveSubscriptions()
        }
    }

    var subscriptionsWithoutAutoRenewal: [Subscription] {
        activeSubscriptions.filter { $0.repetitionType == .disabled }
    }

    var autoRenewingSubscriptions: [Subscription] {
        activeSubscriptions.filter { $0.repetitionType != .disabled }
    }

    func processPaymentStatusReset() {
        var hasChanges = false

        for i in subscriptions.indices {
            if subscriptions[i].needsPaymentReset {
                subscriptions[i].resetPaymentStatus()
                hasChanges = true
            }
        }

        if hasChanges {
            saveSubscriptions()
        }
    }

    // MARK: - Storage (iCloud + Local Backup)

    private func saveSubscriptions() {
        do {
            let data = try JSONEncoder().encode(subscriptions)

            // Save to iCloud
            iCloudStore.set(data, forKey: subscriptionsKey)
            iCloudStore.synchronize()

            // Also save local backup
            UserDefaults.standard.set(data, forKey: localBackupKey)

            print("☁️ Saved \(subscriptions.count) subscriptions to iCloud")
        } catch {
            print("Failed to save subscriptions: \(error)")
        }
    }

    private func loadSubscriptions() {
        // Try to load from iCloud first
        if let data = iCloudStore.data(forKey: subscriptionsKey) {
            do {
                subscriptions = try JSONDecoder().decode([Subscription].self, from: data)
                print("☁️ Loaded \(subscriptions.count) subscriptions from iCloud")
                return
            } catch {
                print("Failed to load from iCloud: \(error)")
            }
        }

        // Fallback to local backup
        if let data = UserDefaults.standard.data(forKey: localBackupKey) {
            do {
                subscriptions = try JSONDecoder().decode([Subscription].self, from: data)
                print("💾 Loaded \(subscriptions.count) subscriptions from local backup")

                // Sync to iCloud
                saveSubscriptions()
                return
            } catch {
                print("Failed to load from local backup: \(error)")
            }
        }

        print("ℹ️ No subscriptions found in storage")
    }

    private func migrateExistingData() {
        var hasChanges = false
        let calendar = Calendar.current
        let defaultReminderTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

        for i in subscriptions.indices {
            let subscription = subscriptions[i]
            var needsUpdate = false
            var updatedSubscription = subscription

            // Fix Adobe Creative Cloud billing cycle
            if subscription.name == "Adobe Creative Cloud" &&
               subscription.billingCycle == .monthly &&
               subscription.repetitionType == .yearly {
                updatedSubscription.billingCycle = .yearly
                needsUpdate = true
            }

            if needsUpdate {
                subscriptions[i] = updatedSubscription
                hasChanges = true
            }
        }

        if hasChanges {
            saveSubscriptions()
            print("✅ Migrated existing subscription data")
        }
    }

    // MARK: - Notification Management

    private func updateNotifications() {
        // Update notifications after any subscription changes
        NotificationManager.shared.scheduleAllNotifications(subscriptions: activeSubscriptions)
    }

    func scheduleNotificationsForAllSubscriptions() {
        NotificationManager.shared.scheduleAllNotifications(subscriptions: activeSubscriptions)
    }

    func rescheduleNotifications() {
        updateNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
