//
//  ContentView.swift
//  Stuby
//
//  Created by apple on 17.09.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager
    @ObservedObject private var navigationManager = NavigationManager.shared
    @ObservedObject private var killedAppNav = KilledAppNavigationManager.shared
    @State private var previousTab = 0
    @State private var showingAddSubscription = false
    @State private var subscriptionListPath = NavigationPath()
    @State private var pendingNavigationSubscriptionId: UUID?
    @State private var lastNavigatedSubscriptionId: UUID?
    @State private var lastNavigationTime: Date?

    var body: some View {
        ZStack {
            ZStack {
                // Main content area - extends to full screen
                ZStack {
                    Group {
                        switch navigationManager.selectedTab {
                        case 0:
                            NavigationStack {
                                DashboardView(subscriptionManager: subscriptionManager)
                                    .id("dashboard-\(navigationManager.selectedTab)")
                            }
                        case 1:
                            NavigationStack(path: $subscriptionListPath) {
                                SubscriptionListView(subscriptionManager: subscriptionManager, navigationPath: $subscriptionListPath)
                                    .id("subscriptions-\(navigationManager.selectedTab)")
                            }
                        case 2:
                            NavigationStack {
                                AnalyticsView(subscriptionManager: subscriptionManager)
                                    .id("analytics-\(navigationManager.selectedTab)")
                            }
                        case 3:
                            NavigationStack {
                                SettingsView()
                                    .id("settings-\(navigationManager.selectedTab)")
                            }
                        default:
                            NavigationStack {
                                DashboardView(subscriptionManager: subscriptionManager)
                                    .id("dashboard-\(navigationManager.selectedTab)")
                            }
                        }
                    }
                    .transition(currentTransition)
                    .id(navigationManager.selectedTab)
                }
                .ignoresSafeArea(.all) // Extend to full screen

            // Custom Tab Bar overlay
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $navigationManager.selectedTab, onTabChange: handleTabChange)
                    .frame(height: 70)
            }
            .zIndex(1)

            // Center Add Button overlay - brought to front
            VStack {
                Spacer()
                CenterAddButton {
                    showingAddSubscription = true
                }
                .offset(y: -60) // Position so bottom half overlaps tab bar
            }
            .zIndex(2) // Highest priority
        }
        .fullScreenCover(isPresented: $showingAddSubscription) {
            AddEditSubscriptionView(subscriptionManager: subscriptionManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            subscriptionManager.refreshSubscriptions()
        }
        .onChange(of: killedAppNav.shouldSwitchToSubscriptionsTab) { shouldSwitch in
            if shouldSwitch, let subscriptionId = killedAppNav.shouldNavigateToSubscription {
                print("🎯 ContentView: KilledAppNav requests tab switch for \(subscriptionId)")
                handleKilledAppNavigation(subscriptionId: subscriptionId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("KilledAppNavigateToSubscription"))) { notification in
            if let subscriptionId = notification.userInfo?["subscriptionId"] as? UUID {
                print("🚀 ContentView: Killed app navigation to subscription \(subscriptionId)")
                
                // FIX: Prevent double navigation by checking recent navigation
                if let lastId = lastNavigatedSubscriptionId, lastId == subscriptionId,
                   let lastTime = lastNavigationTime, Date().timeIntervalSince(lastTime) < 3 {
                    print("⚠️ ContentView: Already navigated to \(subscriptionId) recently, skipping duplicate")
                    return
                }
                
                handleKilledAppNavigation(subscriptionId: subscriptionId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToSubscription"))) { notification in
            if let subscriptionId = notification.userInfo?["subscriptionId"] as? UUID {
                print("📱 ContentView: Direct navigation to subscription \(subscriptionId)")
                print("📱 ContentView: Current tab: \(navigationManager.selectedTab)")
                
                // FIX: Enhanced double navigation prevention
                if let lastId = lastNavigatedSubscriptionId, lastId == subscriptionId,
                   let lastTime = lastNavigationTime, Date().timeIntervalSince(lastTime) < 3 {
                    print("⚠️ ContentView: Already navigated to \(subscriptionId) recently, skipping duplicate")
                    return
                }
                
                // Check if we're already navigating to this subscription
                if let pendingId = pendingNavigationSubscriptionId, pendingId == subscriptionId {
                    print("⚠️ ContentView: Already processing navigation to \(subscriptionId), skipping")
                    return
                }
                
                // Make sure we're on the subscriptions tab
                print("🎯 ContentView: Switching to subscriptions tab...")
                navigationManager.selectedTab = 1
                print("🎯 ContentView: Tab switched to: \(navigationManager.selectedTab)")
                
                // Function to attempt navigation
                func attemptNavigation() {
                    if let subscription = subscriptionManager.subscriptions.first(where: { $0.id == subscriptionId }) {
                        print("✅ ContentView: Found subscription \(subscription.name), navigating...")
                        
                        // Clear pending navigation
                        pendingNavigationSubscriptionId = nil
                        
                        // Track navigation to prevent duplicates
                        lastNavigatedSubscriptionId = subscriptionId
                        lastNavigationTime = Date()
                        
                        // Clear existing path
                        subscriptionListPath.removeLast(subscriptionListPath.count)
                        
                        // Add subscription to path with small delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.subscriptionListPath.append(subscription)
                            print("✅ ContentView: Navigation completed to \(subscription.name)")
                            
                            // Clear ALL pending navigation after successful navigation (longer delay for killed app)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                KilledAppNavigationManager.shared.clearAllPendingNavigation()
                                print("🧹 ContentView: Cleared ALL pending navigation after successful navigation")
                            }
                        }
                    } else {
                        print("❌ ContentView: Subscription \(subscriptionId) not found, subscriptions count: \(subscriptionManager.subscriptions.count)")
                        // Store pending navigation for when subscriptions are loaded
                        pendingNavigationSubscriptionId = subscriptionId
                    }
                }
                
                // If subscriptions are already loaded, navigate immediately
                if !subscriptionManager.subscriptions.isEmpty {
                    attemptNavigation()
                } else {
                    // If subscriptions not loaded yet, force refresh and store pending navigation
                    print("⏳ ContentView: Subscriptions not loaded yet, forcing refresh...")
                    pendingNavigationSubscriptionId = subscriptionId
                    
                    // Force refresh subscriptions for killed app scenarios
                    subscriptionManager.refreshSubscriptions()
                    
                    // Try multiple times with increasing delays
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !subscriptionManager.subscriptions.isEmpty {
                            attemptNavigation()
                        } else {
                            print("⏳ ContentView: Subscriptions still not loaded, trying again...")
                            // Force reload from UserDefaults
                            subscriptionManager.loadSubscriptionsFromStorage()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if !subscriptionManager.subscriptions.isEmpty {
                                    attemptNavigation()
                                } else {
                                    print("⏳ ContentView: Final attempt...")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        attemptNavigation()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onReceive(subscriptionManager.$subscriptions) { subscriptions in
            // Check for pending navigation when subscriptions are loaded
            print("📊 ContentView: Subscriptions changed - count: \(subscriptions.count), pending: \(String(describing: pendingNavigationSubscriptionId))")
            
            if !subscriptions.isEmpty, let pendingId = pendingNavigationSubscriptionId {
                if let subscription = subscriptions.first(where: { $0.id == pendingId }) {
                    print("🔄 ContentView: Executing pending navigation to \(subscription.name)")
                    
                    // Clear pending navigation
                    pendingNavigationSubscriptionId = nil
                    
                    // Track navigation to prevent duplicates
                    lastNavigatedSubscriptionId = pendingId
                    lastNavigationTime = Date()
                    
                    // Ensure we're on the right tab
                    navigationManager.selectedTab = 1
                    
                    // Clear existing path and navigate
                    subscriptionListPath.removeLast(subscriptionListPath.count)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.subscriptionListPath.append(subscription)
                        print("✅ ContentView: Pending navigation completed to \(subscription.name)")
                        
                        // Clear ALL pending navigation after successful navigation (longer delay for killed app)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            KilledAppNavigationManager.shared.clearAllPendingNavigation()
                            print("🧹 ContentView: Cleared ALL pending navigation after successful pending navigation")
                        }
                    }
                } else {
                    print("❌ ContentView: Pending subscription \(pendingId) not found in loaded subscriptions")
                    pendingNavigationSubscriptionId = nil
                }
            }
        }
        .onAppear {
            print("📱 ContentView: onAppear called")
            // Check for any pending navigation from UserDefaults on view appear
            checkForPendingNavigationOnAppear()
        }
        .onOpenURL { url in
            print("📱 ContentView отримав URL: \(url)")
            // Deep links handled at app level now
        }
        }
    }

    private var currentTransition: AnyTransition {
        let isMovingRight = navigationManager.selectedTab > previousTab

        return .asymmetric(
            insertion: .move(edge: isMovingRight ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingRight ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func handleTabChange(newTab: Int) {
        // If modals are presented, dismiss them immediately and disable animation
        let hasActiveModals = showingAddSubscription
        
        // Clear navigation path when switching away from subscriptions tab
        if navigationManager.selectedTab == 1 && newTab != 1 {
            subscriptionListPath.removeLast(subscriptionListPath.count)
        }
        
        if hasActiveModals {
            // Disable animation temporarily when dismissing modals
            withAnimation(.none) {
                showingAddSubscription = false
            }
            
            // Delay tab change to allow modal dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    previousTab = navigationManager.selectedTab
                    navigationManager.selectedTab = newTab
                }
            }
        } else {
            // Normal tab change with animation
            previousTab = navigationManager.selectedTab
            navigationManager.selectedTab = newTab
        }
    }
    
    private func handleKilledAppNavigation(subscriptionId: UUID) {
        print("🎯 ContentView: Handling killed app navigation to \(subscriptionId)")

        // Switch to subscriptions tab
        navigationManager.selectedTab = 1
        print("🎯 ContentView: Switched to subscriptions tab")

        // Clear any existing navigation path
        subscriptionListPath.removeLast(subscriptionListPath.count)

        // Function to attempt navigation
        func attemptNavigation(retryCount: Int = 0) {
            if let subscription = subscriptionManager.subscriptions.first(where: { $0.id == subscriptionId }) {
                print("✅ ContentView: Found subscription \(subscription.name), navigating...")

                // Track navigation to prevent duplicates
                lastNavigatedSubscriptionId = subscriptionId
                lastNavigationTime = Date()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.subscriptionListPath.append(subscription)
                    print("✅ ContentView: Killed app navigation completed to \(subscription.name)")

                    // Clear the killed app navigation after successful navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        KilledAppNavigationManager.shared.clearAllPendingNavigation()
                        print("🧹 ContentView: Cleared ALL killed app navigation data")
                    }
                }
            } else if retryCount < 3 {
                // Subscription not found yet, retry after loading
                print("⏳ ContentView: Subscription not found, retry \(retryCount + 1)/3...")
                subscriptionManager.loadSubscriptionsFromStorage()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    attemptNavigation(retryCount: retryCount + 1)
                }
            } else {
                print("❌ ContentView: Subscription not found after 3 retries")
                KilledAppNavigationManager.shared.clearAllPendingNavigation()
            }
        }

        // Start navigation attempt
        attemptNavigation()
    }
    
    private func checkForPendingNavigationOnAppear() {
        print("🔍 ContentView: checkForPendingNavigationOnAppear called")
        
        // Check killed app navigation first
        if let subscriptionId = killedAppNav.shouldNavigateToSubscription {
            print("🎯 ContentView: Found killed app navigation for \(subscriptionId)")
            handleKilledAppNavigation(subscriptionId: subscriptionId)
            return
        }
        
        // FALLBACK: Check other UserDefaults sources manually
        var fallbackSubscriptionId: UUID?
        
        // Check LastNotificationTapSubscriptionId
        if let uuidString = UserDefaults.standard.string(forKey: "LastNotificationTapSubscriptionId"),
           let subscriptionId = UUID(uuidString: uuidString) {
            if let timestamp = UserDefaults.standard.object(forKey: "LastNotificationTapTimestamp") as? TimeInterval {
                let age = Date().timeIntervalSince1970 - timestamp
                if age < 7200 { // 2 години
                    print("🔄 ContentView: Found fallback navigation from notification tap: \(subscriptionId)")
                    fallbackSubscriptionId = subscriptionId
                }
            }
        }
        
        // Check PendingNavigationSubscriptionId if first fallback failed
        if fallbackSubscriptionId == nil,
           let uuidString = UserDefaults.standard.string(forKey: "PendingNavigationSubscriptionId"),
           let subscriptionId = UUID(uuidString: uuidString) {
            if let timestamp = UserDefaults.standard.object(forKey: "PendingNavigationTimestamp") as? TimeInterval {
                let age = Date().timeIntervalSince1970 - timestamp
                if age < 7200 { // 2 години
                    print("🔄 ContentView: Found fallback navigation from SimpleRouter: \(subscriptionId)")
                    fallbackSubscriptionId = subscriptionId
                }
            }
        }
        
        if let subscriptionId = fallbackSubscriptionId {
            print("🚨 ContentView: Using fallback navigation for \(subscriptionId)")
            // Set it in KilledAppNav and execute
            killedAppNav.setPendingNavigation(subscriptionId: subscriptionId)
            handleKilledAppNavigation(subscriptionId: subscriptionId)
        } else {
            print("ℹ️ ContentView: No navigation found in any source, staying on dashboard")
            navigationManager.selectedTab = 0
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
