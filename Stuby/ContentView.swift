//
//  ContentView.swift
//  Stuby
//
//  Created by apple on 17.09.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @EnvironmentObject var theme: ThemeManager
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showingAddSubscription = false

    var body: some View {
        ZStack {
            // Main content area - extends to full screen
            ZStack {
                Group {
                    switch selectedTab {
                    case 0:
                        DashboardView(subscriptionManager: subscriptionManager)
                    case 1:
                        SubscriptionListView(subscriptionManager: subscriptionManager)
                    case 2:
                        AnalyticsView(subscriptionManager: subscriptionManager)
                    case 3:
                        SettingsView()
                    default:
                        DashboardView(subscriptionManager: subscriptionManager)
                    }
                }
                .transition(currentTransition)
                .id(selectedTab)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedTab)
            .ignoresSafeArea(.all) // Extend to full screen

            // Custom Tab Bar overlay
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, onTabChange: handleTabChange)
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
    }

    private var currentTransition: AnyTransition {
        let isMovingRight = selectedTab > previousTab

        return .asymmetric(
            insertion: .move(edge: isMovingRight ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingRight ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func handleTabChange(newTab: Int) {
        previousTab = selectedTab
        selectedTab = newTab
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
