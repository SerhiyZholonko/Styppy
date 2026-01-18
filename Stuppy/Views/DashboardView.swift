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
                    // Welcome Header (відновлено оригінальний)
                    WelcomeHeader(
                        notificationCount: viewModel.upcomingNotificationsCount,
                        onNotificationTap: {
                            viewModel.showingCalendar = true
                        }
                    )

                    // Summary Cards (відновлено оригінальний)
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

                    // Overdue Subscriptions (оригінальний дизайн з оптимізованою навігацією)
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

                    // Upcoming Renewals (оригінальний дизайн з оптимізованою навігацією)
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

                    // Recent Subscriptions (оригінальний дизайн з оптимізованою навігацією)
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
                                    NavigationLink(destination: SubscriptionDetailView(subscription: subscription, subscriptionManager: subscriptionManager)) {
                                        DashboardSubscriptionRowContent(subscription: subscription)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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

                    // Empty state (оригінальний дизайн)
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
        .onAppear {
            // Reset sheet states when view appears from tab change
            showingMonthlyDetail = false
            showingYearlyDetail = false  
            showingActiveDetail = false
            showingDueSoonDetail = false
            viewModel.showingCalendar = false
        }
    }
}

// MARK: - Dashboard Subscription Row Content
struct DashboardSubscriptionRowContent: View {
    let subscription: Subscription
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: subscription.category.icon)
                .font(.title2)
                .foregroundColor(subscription.category.color)
                .frame(width: 32, height: 32)
                .background(subscription.category.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Text(subscription.billingCycle.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 3, height: 3)

                    Text(subscription.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", subscription.price))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    // Payment status indicator
                    if subscription.isPaidForCurrentMonth {
                        Text("Paid")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else if subscription.isOverdue {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    } else if subscription.daysUntilRenewal <= 3 {
                        Text("\(subscription.daysUntilRenewal) days")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("\(subscription.daysUntilRenewal) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
