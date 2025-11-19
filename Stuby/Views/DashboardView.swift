import SwiftUI

struct DashboardView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var viewModel: DashboardViewModel
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(subscriptionManager: subscriptionManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Welcome Header
                    WelcomeHeader(
                        notificationCount: viewModel.upcomingNotificationsCount,
                        onNotificationTap: {
                            viewModel.showingCalendar = true
                        }
                    )

                    // Summary Cards
                    SummaryCardsSection(
                        monthlyTotal: viewModel.totalMonthlySpending,
                        yearlyTotal: viewModel.totalYearlySpending,
                        activeSubscriptionsCount: viewModel.activeSubscriptionsCount,
                        dueSoonCount: viewModel.upcomingSubscriptionsCount
                    )

                    // Overdue Subscriptions
                    if viewModel.hasOverdueSubscriptions {
                        SubscriptionSection(
                            title: "Overdue Subscriptions",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .error,
                            borderColor: .error,
                            count: viewModel.overdueSubscriptions.count,
                            subscriptions: viewModel.overdueSubscriptions,
                            subscriptionManager: subscriptionManager
                        )
                    }

                    // Upcoming Renewals
                    if viewModel.hasUpcomingSubscriptions {
                        SubscriptionSection(
                            title: "Upcoming Renewals",
                            icon: "clock.fill",
                            iconColor: .warning,
                            borderColor: .warning,
                            count: viewModel.upcomingSubscriptions.count,
                            subscriptions: viewModel.upcomingSubscriptions,
                            subscriptionManager: subscriptionManager
                        )
                    }

                    // Recent Subscriptions
                    if viewModel.hasActiveSubscriptions {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.primaryPurple.opacity(0.2))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primaryPurple)
                                }

                                Text("Recent Subscriptions")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(theme.textPrimaryColor)

                                Spacer()
                            }

                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.recentActiveSubscriptions) { subscription in
                                    NavigationLink(
                                        destination: SubscriptionDetailView(
                                            subscription: subscription,
                                            subscriptionManager: subscriptionManager
                                        )
                                    ) {
                                        AnimatedSubscriptionRow(subscription: subscription)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(20)
                        .glassMorphismCard()
                        .padding(.horizontal, 20)
                    }

                    // Empty state
                    if !viewModel.hasActiveSubscriptions {
                        AnimatedEmptyState(
                            title: "No Subscriptions Yet",
                            subtitle: "Add your first subscription to start tracking your spending and get renewal reminders.",
                            icon: "creditcard.circle",
                            action: nil
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 40)
                    }

                    // Bottom padding for floating action button
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.vertical, 10)
            }
            .background(Color.clear)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $viewModel.showingCalendar) {
            NotificationCalendarView(
                subscriptionManager: subscriptionManager,
                isPresented: $viewModel.showingCalendar
            )
        }
    }

}

#Preview {
    DashboardView(subscriptionManager: SubscriptionManager())
        .environmentObject(ThemeManager())
}