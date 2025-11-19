import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var showingDataManagement = false
    @Published var showingNotificationSettings = false
    @Published var showingAbout = false
    @Published var showingExportOptions = false
    
    private var subscriptionManager: SubscriptionManager?
    
    init(subscriptionManager: SubscriptionManager? = nil) {
        self.subscriptionManager = subscriptionManager
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    func toggleDataManagement() {
        showingDataManagement.toggle()
    }
    
    func toggleNotificationSettings() {
        showingNotificationSettings.toggle()
    }
    
    func toggleAbout() {
        showingAbout.toggle()
    }
    
    func toggleExportOptions() {
        showingExportOptions.toggle()
    }
    
    func clearAllData() {
        subscriptionManager?.clearAllSubscriptions()
    }
    
    func exportData() {
        // Implementation for data export
    }
    
    func importData() {
        // Implementation for data import
    }
}