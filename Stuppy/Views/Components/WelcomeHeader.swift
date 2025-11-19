import SwiftUI

struct WelcomeHeader: View {
    @EnvironmentObject var theme: ThemeManager
    let notificationCount: Int
    let onNotificationTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimaryColor)

                    Text("Here's your subscription overview")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondaryColor)
                }

                Spacer()

                // Notification Bell
                Button(action: onNotificationTap) {
                    ZStack {
                        Circle()
                            .fill(theme.cardBackgroundColor)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.shadowColor, radius: 5, x: 0, y: 2)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(notificationCount > 0 ? Color.accentOrange : theme.textPrimaryColor)

                        // Notification badge
                        if notificationCount > 0 {
                            Circle()
                                .fill(Color.error)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(min(notificationCount, 9))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 12, y: -12)
                        }
                    }
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: false)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}