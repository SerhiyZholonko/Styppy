# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### iOS Development with SwiftUI

This is a pure native iOS SwiftUI subscription management app built with Xcode. The project targets iOS 18.5+ and uses Swift with no external dependencies.

```bash
# Build the app (use available simulators)
xcodebuild -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 15' build
# Alternative simulators if iPhone 15 unavailable:
# xcodebuild -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (currently no test target configured)
# xcodebuild test -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 15'

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
- **Stuppy/**: Main source code directory organized in MVVM architecture
  - **Models/**: Data models with enums (`Subscription.swift`, `Theme.swift`)
  - **ViewModels/**: Business logic layer with specialized view models
  - **Views/**: SwiftUI views organized by functionality with reusable components
  - **Services/**: Utility services (`NotificationManager.swift`)
  - **Extensions/**: Swift extensions for enhanced functionality

### Architecture Pattern
**MVVM (Model-View-ViewModel)** with SwiftUI:
- **Models**: `Subscription` with `BillingCycle`, `SubscriptionCategory`, `RepetitionType` enums
- **ViewModels**: `SubscriptionManager` as central ObservableObject + feature-specific ViewModels
- **Views**: SwiftUI views with proper ownership (`@StateObject`, `@ObservedObject`, `@EnvironmentObject`)
- **Services**: `NotificationManager` singleton for UNUserNotificationCenter

### Key Configuration
- **Bundle Identifier**: `serhiiZholonko.com.Stuby`
- **iOS Deployment Target**: 18.5
- **Device Support**: Universal app (iPhone and iPad)
- **Swift Version**: Latest with Xcode 16.4
- **No External Dependencies**: Pure SwiftUI and Foundation implementation
- **Deep Linking**: Custom URL scheme `stuppy://` configured
- **Background Modes**: Remote notifications, background app refresh, background processing
- **User Activity**: `com.stuppy.viewSubscription` for Handoff support

### Data Flow & State Management
1. **Central State**: `SubscriptionManager` acts as single source of truth
2. **Reactive Updates**: Views observe manager through `@Published` properties
3. **Persistence**: UserDefaults with JSON encoding/decoding on every mutation
4. **Side Effects**: `NotificationManager` schedules notifications based on subscription changes
5. **Auto-Processing**: Automatic renewal handling and payment status resets on app launch
6. **Debug Mode**: In DEBUG builds, sample data is recreated on each app launch and auto-renewals can be disabled for testing

### View Hierarchy
- `StubyApp.swift`: App entry point with notification permissions and routing setup
- `ContentView.swift`: TabView container with custom tab bar
- Main tabs: `DashboardView`, `SubscriptionListView`, `AnalyticsView`, `SettingsView`
- Modal views: `AddEditSubscriptionView`, `SubscriptionDetailView`, `NotificationCalendarView`
- **Views/Components/**: Reusable UI components following single responsibility principle
- **Routing System**: Dual navigation with `SimpleRouter` (primary) and legacy `NavigationManager`

### Core Features
- **Tab-based Navigation**: Dashboard, Subscriptions List, Analytics, Settings
- **Data Persistence**: UserDefaults with JSON encoding/decoding
- **Local Notifications**: UNUserNotificationCenter for renewal reminders
- **Auto-Renewal System**: `RepetitionType` enum for subscription behavior
- **Category System**: 10 predefined categories with SF Symbols icons
- **Theme Support**: Light/dark mode with `ThemeManager`

### Sample Data Structure
Auto-populated with default subscriptions:
- Netflix (Streaming, $15.99/month)
- Spotify (Music, $9.99/month)
- Adobe Creative Cloud (Productivity, $52.99/month)

### Development Notes
- **Pure Native**: No CocoaPods, SPM, or external dependencies
- **SwiftUI Previews**: All major views include `PreviewProvider` for live development
- **State Management**: Uses `@StateObject` for ownership, `@ObservedObject` for injection
- **Custom UI**: Custom tab bar with center floating action button and glassmorphism design
- **PlantUML Documentation**: Architecture diagrams in `Stuby_MVVM_Architecture.puml` and `Stuby_UI_Components.puml`
- **Navigation Management**: Each view has unique `.id()` modifiers to prevent navigation stack issues when switching tabs
- **Deep Linking**: Supports `stuppy://` scheme for external navigation to subscription details
- **Notification Actions**: Interactive notifications with "Mark as Paid", "View Details", and "Snooze" actions
- **Debug Features**: Automatic sample data recreation in DEBUG builds with test notification scheduling

### Development Workflow
```bash
# Open project in Xcode
open Stuppy.xcodeproj

# Use SwiftUI Previews for rapid development
# Each major view has preview providers for instant feedback

# For development builds, use Xcode's built-in simulator
# No additional setup required - pure native implementation
```

### Component Architecture
- **Reusable Components**: Following single responsibility principle in Views/Components/
- **MVVM Separation**: Clean separation enables easy unit testing of business logic  
- **Reactive Programming**: Extensive use of `@Published` for automatic UI updates
- **Error Handling**: Defensive programming with graceful fallbacks throughout data layer

### Navigation & State Management Considerations
- **Dual Navigation System**: 
  - **SimpleRouter** (Services/SimpleRouter.swift): Primary notification-based routing with persistence
  - **NavigationManager** (ViewModels/NavigationManager.swift): Legacy navigation support
- **Tab Navigation**: `ContentView` manages tab switching with unique view IDs to prevent navigation stack issues
- **Modal State Reset**: Modal states (`showingAddSubscription`, sheet presentations) are reset on tab changes and view appearances
- **NavigationStack Isolation**: Each main view (Dashboard, SubscriptionList, Analytics, Settings) has its own NavigationStack
- **Transition Animations**: Custom asymmetric transitions for tab switching with proper edge detection
- **Deep Link Handling**: `SimpleRouter` handles `stuppy://` URLs with UserDefaults persistence for notification-driven navigation

### Key Subscription Models
- **BillingCycle**: Weekly(7), Monthly(30), Quarterly(90), Yearly(365) days
- **RepetitionType**: Disabled, Monthly, Yearly auto-renewal options
- **SubscriptionCategory**: 10 predefined categories (Streaming, Music, Productivity, etc.) with SF Symbols icons
- **Auto-Renewal Logic**: Processes subscriptions based on RepetitionType and billing cycles
- **Payment Status**: `isPaidForCurrentMonth` tracks payment state with automatic reset logic
- **URL Scheme**: `stuppy://subscription/{uuid}` for deep linking to specific subscriptions

### Advanced Features
- **Smart Price Calculation**: Different pricing models for current month vs monthly normalized spending
- **Auto-Renewal Processing**: Automatic date advancement when subscriptions are due (unless disabled in debug mode)
- **Payment Status Reset**: Automatic reset of payment flags when moving to new billing periods
- **Overdue Detection**: Built-in logic for identifying and handling overdue subscriptions
- **Category-Based Analytics**: Spending breakdown and filtering by subscription categories
- **Interactive Notifications**: Rich notifications with action buttons for quick subscription management

### Testing & Debug Mode
- **No Unit Test Target**: Project currently has no formal test target configured
- **Debug Testing Features**:
  - **Sample Data**: Auto-generated test subscriptions (Netflix, Spotify, Adobe) in DEBUG builds
  - **Test Notifications**: Immediate test notifications scheduled 5 seconds after app launch in DEBUG
  - **Auto-Renewal Control**: `disableAutoRenewalsForTesting` flag to prevent automatic date progression during testing
  - **Data Reset**: `resetTestData()` function to recreate clean test environment with specific billing dates
  - **NotificationTestView**: Manual testing view for notification functionality

### Recent Architecture Additions
- **Services/SimpleRouter.swift**: New notification-based routing system with UserDefaults persistence
- **AppDelegate.swift**: UIApplicationDelegate integration for improved notification handling
- **Routing Coordination**: SimpleRouter coordinates with legacy NavigationManager for seamless navigation
- **Background Processing**: Enhanced notification handling with background modes support

### Current Development Status
- **Active Branch**: `improveApp` (recent commits focus on payment tracking and UI details)
- **Recent Features**: Payment status marking, detailed subscription views, analytics improvements
- **Architecture Status**: Well-established MVVM structure with clean separation of concerns
- **Navigation Evolution**: Transitioning from legacy NavigationManager to SimpleRouter for better notification support