import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel: AnalyticsViewModel
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        self._viewModel = StateObject(wrappedValue: AnalyticsViewModel(subscriptionManager: subscriptionManager))
    }

    var body: some View {
        GeometryReader { geometry in
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            let screenWidth = geometry.size.width
            let isLandscape = screenWidth > geometry.size.height
            
            NavigationView {
                ScrollView {
                    LazyVStack(spacing: isIPad ? 32 : 24) {
                        // Header with Period Selector
                        VStack(spacing: isIPad ? 24 : 16) {
                            HStack {
                                Text("Analytics")
                                    .font(.system(size: isIPad ? 42 : 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Picker("Period", selection: $viewModel.selectedPeriod) {
                                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                                        Text(period.rawValue).tag(period)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(maxWidth: isIPad ? 300 : 200)
                            }
                            .padding(.horizontal, isIPad ? 40 : 20)
                            
                            // Summary Cards Grid
                            if isIPad {
                                // iPad layout - 4 cards in a row or 2x2 grid
                                if isLandscape {
                                    HStack(spacing: 24) {
                                        AnalyticsCard(
                                            title: "Total \(viewModel.selectedPeriod.rawValue)",
                                            value: String(format: "$%.2f", viewModel.totalSpending),
                                            icon: "dollarsign.circle.fill",
                                            color: .green
                                        )
                                        
                                        AnalyticsCard(
                                            title: "Active Subscriptions",
                                            value: "\(viewModel.activeSubscriptionsCount)",
                                            icon: "checkmark.circle.fill",
                                            color: .blue
                                        )
                                        
                                        AnalyticsCard(
                                            title: "Average Monthly",
                                            value: String(format: "$%.2f", viewModel.averageMonthlyCost),
                                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                                            color: .purple
                                        )
                                        
                                        AnalyticsCard(
                                            title: "Categories",
                                            value: "\(viewModel.categoryData.count)",
                                            icon: "square.grid.3x3.fill",
                                            color: .orange
                                        )
                                    }
                                    .padding(.horizontal, 40)
                                } else {
                                    VStack(spacing: 20) {
                                        HStack(spacing: 24) {
                                            AnalyticsCard(
                                                title: "Total \(viewModel.selectedPeriod.rawValue)",
                                                value: String(format: "$%.2f", viewModel.totalSpending),
                                                icon: "dollarsign.circle.fill",
                                                color: .green
                                            )
                                            
                                            AnalyticsCard(
                                                title: "Active Subscriptions",
                                                value: "\(viewModel.activeSubscriptionsCount)",
                                                icon: "checkmark.circle.fill",
                                                color: .blue
                                            )
                                        }
                                        
                                        HStack(spacing: 24) {
                                            AnalyticsCard(
                                                title: "Average Monthly",
                                                value: String(format: "$%.2f", viewModel.averageMonthlyCost),
                                                icon: "chart.line.uptrend.xyaxis.circle.fill",
                                                color: .purple
                                            )
                                            
                                            AnalyticsCard(
                                                title: "Categories",
                                                value: "\(viewModel.categoryData.count)",
                                                icon: "square.grid.3x3.fill",
                                                color: .orange
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 40)
                                }
                            } else {
                                // iPhone layout - 2 cards in a row
                                VStack(spacing: 16) {
                                    HStack(spacing: 12) {
                                        AnalyticsCard(
                                            title: "Total \(viewModel.selectedPeriod.rawValue)",
                                            value: String(format: "$%.2f", viewModel.totalSpending),
                                            icon: "dollarsign.circle.fill",
                                            color: .green
                                        )
                                        
                                        AnalyticsCard(
                                            title: "Active",
                                            value: "\(viewModel.activeSubscriptionsCount)",
                                            icon: "checkmark.circle.fill",
                                            color: .blue
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Main Content Area
                        if viewModel.hasActiveSubscriptions {
                            if isIPad && isLandscape {
                                // iPad Landscape Layout - Side by side
                                HStack(alignment: .top, spacing: 32) {
                                    // Left Column - Chart
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Spending by Category")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(viewModel.categoryData, id: \.category) { item in
                                                CategoryChartBar(
                                                    category: item.category,
                                                    amount: item.amount,
                                                    totalAmount: viewModel.totalSpending,
                                                    isIPad: true
                                                )
                                            }
                                        }
                                        .padding(24)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(16)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    // Right Column - Breakdown & Statistics
                                    VStack(alignment: .leading, spacing: 24) {
                                        // Category Breakdown
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Category Breakdown")
                                                .font(.title2)
                                                .fontWeight(.semibold)

                                            LazyVStack(spacing: 12) {
                                                ForEach(viewModel.categoryData, id: \.category) { item in
                                                    CategoryBreakdownRow(
                                                        category: item.category,
                                                        amount: item.amount,
                                                        percentage: viewModel.percentage(for: item.amount),
                                                        subscriptionCount: viewModel.subscriptionCount(for: item.category)
                                                    )
                                                }
                                            }
                                            .padding(20)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(16)
                                        }
                                        
                                        // Statistics
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Statistics")
                                                .font(.title2)
                                                .fontWeight(.semibold)

                                            VStack(spacing: 12) {
                                                StatisticRow(
                                                    label: "Most expensive",
                                                    value: viewModel.mostExpensiveSubscription
                                                )

                                                StatisticRow(
                                                    label: "Cheapest",
                                                    value: viewModel.cheapestSubscription
                                                )

                                                StatisticRow(
                                                    label: "Most common billing cycle",
                                                    value: viewModel.mostCommonBillingCycle
                                                )

                                                StatisticRow(
                                                    label: "Most common category",
                                                    value: viewModel.mostCommonCategory
                                                )
                                            }
                                            .padding(20)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(16)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 40)
                            } else {
                                // iPad Portrait & iPhone Layout - Vertical Stack
                                VStack(spacing: isIPad ? 32 : 24) {
                                    // Spending by Category Chart
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Spending by Category")
                                            .font(isIPad ? .title2 : .headline)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, isIPad ? 40 : 20)

                                        VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
                                            ForEach(viewModel.categoryData, id: \.category) { item in
                                                CategoryChartBar(
                                                    category: item.category,
                                                    amount: item.amount,
                                                    totalAmount: viewModel.totalSpending,
                                                    isIPad: isIPad
                                                )
                                            }
                                        }
                                        .frame(height: isIPad ? 400 : 300)
                                        .padding(isIPad ? 24 : 16)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(isIPad ? 16 : 12)
                                        .padding(.horizontal, isIPad ? 40 : 20)
                                    }

                                    // Category Breakdown List
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Category Breakdown")
                                            .font(isIPad ? .title2 : .headline)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, isIPad ? 40 : 20)

                                        LazyVStack(spacing: isIPad ? 12 : 8) {
                                            ForEach(viewModel.categoryData, id: \.category) { item in
                                                CategoryBreakdownRow(
                                                    category: item.category,
                                                    amount: item.amount,
                                                    percentage: viewModel.percentage(for: item.amount),
                                                    subscriptionCount: viewModel.subscriptionCount(for: item.category)
                                                )
                                            }
                                        }
                                        .padding(isIPad ? 24 : 16)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(isIPad ? 16 : 12)
                                        .padding(.horizontal, isIPad ? 40 : 20)
                                    }

                                    // Upcoming Renewals Timeline
                                    if viewModel.hasUpcomingSubscriptions {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Upcoming Renewals")
                                                .font(isIPad ? .title2 : .headline)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, isIPad ? 40 : 20)

                                            VStack(spacing: isIPad ? 12 : 8) {
                                                ForEach(viewModel.upcomingSubscriptions) { subscription in
                                                    UpcomingRenewalRow(subscription: subscription)
                                                }
                                            }
                                            .padding(isIPad ? 24 : 16)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(isIPad ? 16 : 12)
                                            .padding(.horizontal, isIPad ? 40 : 20)
                                        }
                                    }

                                    // Statistics
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Statistics")
                                            .font(isIPad ? .title2 : .headline)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, isIPad ? 40 : 20)

                                        VStack(spacing: isIPad ? 12 : 8) {
                                            StatisticRow(
                                                label: "Average monthly cost",
                                                value: String(format: "$%.2f", viewModel.averageMonthlyCost)
                                            )

                                            StatisticRow(
                                                label: "Most expensive",
                                                value: viewModel.mostExpensiveSubscription
                                            )

                                            StatisticRow(
                                                label: "Cheapest",
                                                value: viewModel.cheapestSubscription
                                            )

                                            StatisticRow(
                                                label: "Most common billing cycle",
                                                value: viewModel.mostCommonBillingCycle
                                            )

                                            StatisticRow(
                                                label: "Most common category",
                                                value: viewModel.mostCommonCategory
                                            )
                                        }
                                        .padding(isIPad ? 24 : 16)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(isIPad ? 16 : 12)
                                        .padding(.horizontal, isIPad ? 40 : 20)
                                    }
                                }
                            }
                        } else {
                            // Empty State
                            VStack(spacing: isIPad ? 24 : 16) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: isIPad ? 80 : 60))
                                    .foregroundColor(.gray)

                                Text("No data available")
                                    .font(isIPad ? .largeTitle : .title2)
                                    .fontWeight(.medium)

                                Text("Add some subscriptions to see analytics")
                                    .font(isIPad ? .title3 : .body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, isIPad ? 60 : 40)
                            .padding(.horizontal, isIPad ? 40 : 20)
                        }
                    }
                    .padding(.vertical, isIPad ? 40 : 20)
                    .padding(.bottom, 100) // Add extra padding to avoid tab bar overlap
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

}

#Preview {
    AnalyticsView(subscriptionManager: SubscriptionManager())
}