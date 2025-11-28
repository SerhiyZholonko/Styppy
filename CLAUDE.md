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
  - **Models/**: Data models (`Subscription.swift`, `Theme.swift` with enums for billing cycles and categories)
  - **ViewModels/**: Business logic layer with specialized view models
    - `SubscriptionManager.swift` - Central ObservableObject for subscription state
    - `DashboardViewModel.swift`, `AnalyticsViewModel.swift`, etc. - Feature-specific view models
  - **Views/**: SwiftUI views organized by functionality
    - **Components/**: Reusable UI components following single responsibility principle
  - **Services/**: Utility services (`NotificationManager.swift` for local notifications)
  - **Extensions/**: Swift extensions (`Color+String.swift` for theme system)

### Core Architecture Pattern
**MVVM (Model-View-ViewModel)** with SwiftUI:
- **Models**: 
  - `Subscription` with billing cycle and category enums (`BillingCycle`, `SubscriptionCategory`, `RepetitionType`)
  - `ThemeManager` for light/dark mode theming
- **ViewModels**: 
  - `SubscriptionManager` - Central ObservableObject acting as single source of truth
  - Feature-specific ViewModels: `DashboardViewModel`, `AnalyticsViewModel`, `AddEditSubscriptionViewModel`, etc.
- **Views**: SwiftUI views with proper ownership patterns
  - `@StateObject` for view model ownership
  - `@ObservedObject` for dependency injection
  - `@EnvironmentObject` for theme management
- **Services**: `NotificationManager` singleton for UNUserNotificationCenter management

### Key Features
- **Tab-based Navigation**: Dashboard, Subscriptions List, Analytics, Settings
- **Data Persistence**: UserDefaults with JSON encoding/decoding
- **Local Notifications**: UNUserNotificationCenter for renewal reminders
- **Sample Data**: Auto-populated with Netflix, Spotify, Adobe Creative Cloud examples
- **Category System**: 10 predefined categories with colors and SF Symbols icons
- **Billing Cycles**: Weekly, Monthly, Quarterly, Yearly with automatic calculations

### Data Flow & State Management
1. **Central State**: `SubscriptionManager` acts as single source of truth for subscription data
2. **Reactive Updates**: Views observe manager through `@ObservedObject` or `@StateObject` 
3. **Persistence**: Manager automatically persists data to UserDefaults using JSON encoding on every mutation
4. **Side Effects**: `NotificationManager` schedules/cancels notifications based on subscription changes
5. **Computed Properties**: Manager provides derived data (monthly/yearly totals, upcoming renewals, category breakdowns)
6. **Auto-Processing**: Automatic handling of subscription renewals and payment status resets on app launch

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
- **Pure Native**: No CocoaPods, SPM, or external dependencies - pure SwiftUI/Foundation implementation
- **SwiftUI Previews**: All major views include `PreviewProvider` for live development
- **State Management**: Uses `@StateObject` for view model ownership, `@ObservedObject` for dependency injection
- **Data Persistence**: UserDefaults with Codable protocol - simple but effective for subscription data
- **Custom UI**: Custom tab bar with center floating action button and glassmorphism design patterns
- **iPad Optimization**: Full-screen analytics with adaptive layouts for landscape/portrait orientations
- **Responsive Design**: Device-specific spacing, fonts, and component sizing
- **Enhanced Components**: Animated progress bars, interactive charts, and improved visual hierarchy

### Development Workflow
```bash
# Open project in Xcode
open Stuppy.xcodeproj

# Use SwiftUI Previews for rapid development
# Each major view has preview providers for instant feedback

# For development builds, use Xcode's built-in simulator
# No additional setup required - pure native implementation

# Common debugging commands
xcodebuild -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 15' -showBuildSettings

# Check code coverage (if enabled)
xcodebuild test -project Stuppy.xcodeproj -scheme Stuppy -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
```

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
- **Payment Tracking**: Current month spending with paid/unpaid status tracking
- **Overdue Handling**: Automatic detection and processing of overdue subscriptions

### Architecture Documentation
The project includes PlantUML architecture diagrams:
- **Stuby_MVVM_Architecture.puml**: Complete MVVM data flow and relationships
- **Stuby_UI_Components.puml**: UI component composition and reusable elements

These diagrams provide visual documentation of:
- Model relationships and enums
- ViewModel dependencies and data flow
- View-ViewModel bindings using SwiftUI property wrappers
- Component reusability patterns
- Service integrations

### Development Patterns
- **Single Responsibility**: Each ViewModel handles a specific feature area
- **Dependency Injection**: ViewModels receive SubscriptionManager as dependency
- **Reactive Programming**: `@Published` properties trigger automatic UI updates
- **Computed Properties**: Extensive use for derived data calculations
- **Error Handling**: Graceful fallbacks in JSON encoding/decoding operations
- **Migration Logic**: Built-in data migration for existing user data

### Testing and Quality Assurance
- **SwiftUI Previews**: Primary development tool for component testing and UI validation
- **Manual Testing**: Current approach using Xcode simulator across iPhone/iPad devices
- **No Unit Tests**: Opportunity for improvement - ViewModels are designed for testability
- **Architecture**: Clean separation enables easy unit testing of business logic
- **Error Handling**: Defensive programming with graceful fallbacks throughout data layer

### Performance Considerations
- **Reactive Updates**: SwiftUI only rebuilds affected UI components through `@Published` bindings
- **Lazy Loading**: Components use appropriate lazy evaluation where beneficial
- **Memory Management**: Proper use of weak references and ObservableObject patterns
- **Data Persistence**: Simple UserDefaults approach suitable for subscription data volume
- **Sample Data**: Lightweight initialization with automatic cleanup of development data

### Common Debugging Tips
- **SwiftUI Previews**: Primary tool for UI development and debugging
- **Xcode Console**: Monitor subscription state changes and auto-renewal processing
- **UserDefaults**: Data persisted as JSON - can be inspected via debugger or console
- **Notification Testing**: Use iOS Simulator's notification testing features
- **State Observation**: Use `@Published` property breakpoints to track data flow
- **Memory Leaks**: Monitor for retain cycles in ObservableObject relationships