import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationDays") private var notificationDays = 1
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    headerSection
                    appearanceSection
                    notificationsSection
                    aboutSection
                    bottomPadding
                }
                .padding(.vertical, 10)
            }
            .background(Color.clear)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimaryColor)
                Spacer()
            }
            Text("Customize your experience")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondaryColor)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "paintbrush.fill", title: "Appearance", color: .primaryPurple)

            VStack(spacing: 16) {
                darkModeRow
                Divider().background(theme.borderColor)
                currencyRow
            }
        }
        .padding(20)
        .glassMorphismCard()
        .padding(.horizontal, 20)
    }

    private var darkModeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dark Mode")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor)
                Text("Toggle between light and dark themes")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(theme.textSecondaryColor)
            }
            Spacer()
            Button(action: { theme.toggleTheme() }) {
                CustomToggleView(isDarkMode: theme.isDarkMode)
            }
            .animatedButton()
        }
    }

    private var currencyRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Currency")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor)
                Text("Choose your preferred currency")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(theme.textSecondaryColor)
            }
            Spacer()
            currencyMenu
        }
    }

    private var currencyMenu: some View {
        Menu {
            Button("$ USD") { currencySymbol = "$" }
            Button("€ EUR") { currencySymbol = "€" }
            Button("£ GBP") { currencySymbol = "£" }
            Button("¥ JPY") { currencySymbol = "¥" }
        } label: {
            HStack(spacing: 8) {
                Text(currencySymbol + " " + getCurrencyName(for: currencySymbol))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondaryColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(8)
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "bell.fill", title: "Notifications", color: .accentOrange)

            VStack(spacing: 16) {
                notificationToggleRow
                if notificationsEnabled {
                    Divider().background(theme.borderColor)
                    notificationTimingSection
                }
            }
        }
        .padding(20)
        .glassMorphismCard()
        .padding(.horizontal, 20)
    }

    private var notificationToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Payment Reminders")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor)
                Text("Get notified before payments are due")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(theme.textSecondaryColor)
            }
            Spacer()
            Toggle("", isOn: $notificationsEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.primaryPurple))
        }
    }

    private var notificationTimingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder Timing")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textPrimaryColor)

            HStack(spacing: 12) {
                ForEach([1, 3, 7], id: \.self) { days in
                    timingButton(days: days)
                }
                Spacer()
            }
        }
    }

    private func timingButton(days: Int) -> some View {
        Button(action: { notificationDays = days }) {
            Text("\(days) day\(days > 1 ? "s" : "")")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(notificationDays == days ? .white : theme.textSecondaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(notificationDays == days ? Color.primaryPurple : theme.secondaryBackgroundColor)
                )
        }
        .animatedButton()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "info.circle.fill", title: "About", color: .accentTeal)

            VStack(spacing: 12) {
                versionRow
                Divider().background(theme.borderColor)
                privacyLink
                Divider().background(theme.borderColor)
                termsLink
            }
        }
        .padding(20)
        .glassMorphismCard()
        .padding(.horizontal, 20)
    }

    private var versionRow: some View {
        HStack {
            Text("Version")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textPrimaryColor)
            Spacer()
            Text("1.0.0")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(theme.textSecondaryColor)
        }
    }

    private var privacyLink: some View {
        Link(destination: URL(string: "https://example.com/privacy")!) {
            HStack {
                Text("Privacy Policy")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondaryColor)
            }
        }
    }

    private var termsLink: some View {
        Link(destination: URL(string: "https://example.com/terms")!) {
            HStack {
                Text("Terms of Service")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondaryColor)
            }
        }
    }


    private var bottomPadding: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 100)
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimaryColor)
            Spacer()
        }
    }

    private func getCurrencyName(for symbol: String) -> String {
        switch symbol {
        case "$": return "USD"
        case "€": return "EUR"
        case "£": return "GBP"
        case "¥": return "JPY"
        default: return "USD"
        }
    }
}

struct CustomToggleView: View {
    let isDarkMode: Bool

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 25)
                .fill(toggleBackgroundColor)
                .frame(width: 50, height: 30)

            // Moving circle
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .offset(x: isDarkMode ? 10 : -10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDarkMode)
        }
    }

    private var toggleBackgroundColor: Color {
        if isDarkMode {
            return Color.primaryPurple
        } else {
            return Color.neutralGray.opacity(0.3)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
