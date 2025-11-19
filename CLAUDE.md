# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### iOS Development with SwiftUI

This is a native iOS SwiftUI subscription management application built with Xcode. The project targets iOS 18.5+ and uses Swift 5.0 with no external dependencies.

```bash
# Build the app
xcodebuild -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests (if tests are added)
xcodebuild test -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project Stuppy.xcodeproj -scheme Stuppy

# List available schemes and targets
xcodebuild -list -project Stuppy.xcodeproj

# Archive for distribution
xcodebuild archive -project Stuppy.xcodeproj -scheme Stuppy -archivePath ~/Desktop/Stuppy.xcarchive

# Build for device
xcodebuild -project Stuppy.xcodeproj -scheme Stuppy -destination 'generic/platform=iOS' build
```

## High-Level Architecture

### Application Purpose
Stuppy is a subscription management app that helps users track recurring subscriptions, monitor spending, and receive notifications for upcoming renewals.

### Project Structure
- **Stuppy.xcodeproj**: Main Xcode project file (no workspace or CocoaPods dependencies)
- **Stuppy/**: Main source code directory with MVVM architecture
  - **Models/**: Data models (`Subscription.swift` with enums for billing cycles and categories)
  - **ViewModels/**: Business logic (`SubscriptionManager.swift` using ObservableObject)
  - **Views/**: SwiftUI views organized by functionality
  - **Services/**: Utility services (`NotificationManager.swift` for local notifications)

### Core Architecture Pattern
**MVVM (Model-View-ViewModel)** with SwiftUI:
- **Models**: `Subscription`, `BillingCycle`, `SubscriptionCategory` enums
- **ViewModels**: `SubscriptionManager` (ObservableObject for state management)
- **Views**: SwiftUI views with `@StateObject` and `@ObservedObject` property wrappers
- **Services**: `NotificationManager` singleton for notification handling

### Key Features
- **Tab-based Navigation**: Dashboard, Subscriptions List, Analytics, Settings
- **Data Persistence**: UserDefaults with JSON encoding/decoding
- **Local Notifications**: UNUserNotificationCenter for renewal reminders
- **Sample Data**: Auto-populated with Netflix, Spotify, Adobe Creative Cloud examples
- **Category System**: 10 predefined categories with colors and SF Symbols icons
- **Billing Cycles**: Weekly, Monthly, Quarterly, Yearly with automatic calculations

### Data Flow
1. `SubscriptionManager` acts as single source of truth for subscription data
2. Views observe manager through `@ObservedObject` or `@StateObject`
3. Manager persists data to UserDefaults on every mutation
4. `NotificationManager` schedules/cancels notifications based on subscription changes
5. Computed properties provide derived data (monthly/yearly totals, upcoming renewals)

### View Hierarchy
- `StubyApp.swift`: App entry point with notification permission request
- `ContentView.swift`: TabView container with 4 main tabs
- `DashboardView.swift`: Overview with summary cards and subscription lists
- `SubscriptionListView.swift`: Complete list with CRUD operations
- `AnalyticsView.swift`: Spending analytics with iPad-optimized full-screen layout, adaptive design for landscape/portrait modes, enhanced category breakdowns and interactive charts
- `SettingsView.swift`: App settings and preferences
- `AddEditSubscriptionView.swift`: Form for creating/editing subscriptions
- `SubscriptionDetailView.swift`: Detailed view of individual subscriptions
- `NotificationCalendarView.swift`: Calendar view with payment date visualization
- `CustomTabBar.swift`: Custom tab bar with center floating action button
- `AnimatedComponents.swift`: Reusable animated UI components

### Key Configuration
- **Bundle Identifier**: `serhiiZholonko.com.Stuby`
- **iOS Deployment Target**: 18.5
- **Swift Version**: 5.0
- **SwiftUI Previews**: Enabled
- **User Notifications**: Required capability for renewal reminders
- **No External Dependencies**: Pure SwiftUI and Foundation implementation

### Theme System
- **ThemeManager**: ObservableObject handling light/dark mode switching
- **Color Extensions**: Custom brand colors with hex initialization
- **Glassmorphism**: Custom ViewModifier for modern card styling
- **Animated Components**: Reusable animated UI elements with custom tab bar

### Notification System
- **NotificationManager**: Singleton managing UNUserNotificationCenter
- **Permission Handling**: Automatic permission request on app launch
- **Scheduling Logic**: Notifications triggered 1 day before renewal by default
- **Dynamic Management**: Automatic cancellation/rescheduling on subscription changes

### Sample Data Structure
Default subscriptions include:
- Netflix (Streaming, $15.99/month)
- Spotify (Music, $9.99/month)
- Adobe Creative Cloud (Productivity, $52.99/month)

### Development Notes
- No CocoaPods or external package management
- Uses `@StateObject` for view model ownership
- UserDefaults persistence with Codable protocol
- Custom tab bar implementation with center floating action button
- Glassmorphism design patterns throughout UI
- **iPad Optimization**: Full-screen analytics with adaptive layouts for landscape/portrait orientations
- **Responsive Design**: Device-specific spacing, fonts, and component sizing
- **Enhanced Components**: Animated progress bars, interactive charts, and improved visual hierarchy

### Component Architecture
- **Views/Components/**: Reusable SwiftUI components following single responsibility principle
  - `SubscriptionCard`, `SubscriptionListRow`: Subscription display components
  - `AnalyticsCard`, `CategoryChartBar`: Analytics visualization components
  - `SummaryCardsSection`, `WelcomeHeader`: Dashboard layout components
  - `CategoryFilterButton`, `StatisticRow`: Interactive UI elements

### Auto-Renewal System
- **RepetitionType**: Enum for subscription renewal behavior (disabled, monthly, yearly)
- **Automatic Processing**: `processAutoRenewals()` updates overdue subscriptions on app launch
- **Smart Billing**: Subscriptions automatically advance next billing dates based on repetition type
- **Flexible Control**: Users can disable auto-renewal per subscription

### Data Calculations
- **Monthly/Yearly Conversion**: Automatic price normalization across all billing cycles
- **Smart Aggregation**: Total spending calculations consider only active subscriptions
- **Upcoming Logic**: 7-day window for upcoming renewals with overdue detection
- **Category Analytics**: Per-category spending breakdowns and subscription counts