//
//  StubyApp.swift
//  Stuby
//
//  Created by apple on 17.09.2025.
//

import SwiftUI
import UserNotifications

@main
struct StubyApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    notificationManager.requestPermission()
                }
        }
    }
}
