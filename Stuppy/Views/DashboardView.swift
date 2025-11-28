import SwiftUI

struct DashboardView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var viewModel: DashboardViewModel
    
    @State private var showingMonthlyDetail = false
    @State private var showingYearlyDetail = false
    @State private var showingActiveDetail = false
    @State private var showingDueSoonDetail = false
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(subscriptionManager: subscriptionManager))
    }

    var body: some View {
        NavigationStack {
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
                        dueSoonCount: viewModel.upcomingSubscriptionsCount,
                        onMonthlyTotalTap: { showingMonthlyDetail = true },
                        onYearlyTotalTap: { showingYearlyDetail = true },
                        onActiveSubscriptionsTap: { showingActiveDetail = true },
                        onDueSoonTap: { showingDueSoonDetail = true }
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

                            List {
                                ForEach(viewModel.recentActiveSubscriptions) { subscription in
                                    InteractiveDashboardSubscriptionRow(
                                        subscription: subscription,
                                        subscriptionManager: subscriptionManager
                                    )
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            subscriptionManager.deleteSubscription(subscription)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        
                                        Button {
                                            subscriptionManager.togglePaymentStatus(subscription)
                                        } label: {
                                            Label(subscription.isPaidForCurrentMonth ? "Mark Unpaid" : "Mark Paid", 
                                                  systemImage: subscription.isPaidForCurrentMonth ? "xmark.circle" : "checkmark.circle")
                                        }
                                        .tint(subscription.isPaidForCurrentMonth ? .orange : .green)
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let subscription = viewModel.recentActiveSubscriptions[index]
                                        subscriptionManager.deleteSubscription(subscription)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .frame(height: CGFloat(viewModel.recentActiveSubscriptions.count * 80))
                            .scrollDisabled(true)
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
        .fullScreenCover(isPresented: $viewModel.showingCalendar) {
            NotificationCalendarView(
                subscriptionManager: subscriptionManager,
                isPresented: $viewModel.showingCalendar
            )
        }
        .sheet(isPresented: $showingMonthlyDetail) {
            MonthlyPaymentDetailView(subscriptionManager: subscriptionManager)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showingYearlyDetail) {
            YearlyTotalDetailView(subscriptionManager: subscriptionManager)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showingActiveDetail) {
            ActiveSubscriptionsDetailView(subscriptionManager: subscriptionManager)
                .environmentObject(theme)
        }
        .sheet(isPresented: $showingDueSoonDetail) {
            DueSoonDetailView(subscriptionManager: subscriptionManager)
                .environmentObject(theme)
        }
    }

}



// MARK: - Interactive Dashboard Subscription Row
struct InteractiveDashboardSubscriptionRow: View {
    let subscription: Subscription
    let subscriptionManager: SubscriptionManager
    
    @State private var showingDetail = false
    
    var body: some View {
        AnimatedSubscriptionRow(subscription: subscription)
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            .navigationDestination(isPresented: $showingDetail) {
                SubscriptionDetailView(
                    subscription: subscription,
                    subscriptionManager: subscriptionManager
                )
            }
    }
}


#Preview {
    DashboardView(subscriptionManager: SubscriptionManager())
        .environmentObject(ThemeManager())
}
