import SwiftUI

// MARK: - Monthly Payment Detail View
struct MonthlyPaymentDetailView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var unpaidSubscriptions: [Subscription] {
        subscriptionManager.activeSubscriptions.filter { 
            !$0.isPaidForCurrentMonth && $0.unpaidCurrentMonthPrice > 0 
        }
    }
    
    var paidSubscriptions: [Subscription] {
        subscriptionManager.activeSubscriptions.filter { 
            $0.isPaidForCurrentMonth && $0.currentMonthPrice > 0 
        }
    }
    
    var paymentProgress: Double {
        let total = subscriptionManager.totalCurrentMonthSpending
        let paid = total - subscriptionManager.totalUnpaidCurrentMonthSpending
        return total > 0 ? (paid / total) * 100 : 100
    }
    
    var nextMonthSubscriptions: [Subscription] {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let nextMonthComponents = calendar.dateComponents([.year, .month], from: nextMonth)
        
        return subscriptionManager.activeSubscriptions.filter { subscription in
            let billingComponents = calendar.dateComponents([.year, .month], from: subscription.nextBillingDate)
            return billingComponents.year == nextMonthComponents.year && 
                   billingComponents.month == nextMonthComponents.month
        }.sorted { $0.price > $1.price }
    }
    
    var nextMonthTotal: Double {
        nextMonthSubscriptions.reduce(0) { $0 + $1.price }
    }
    
    var averageSubscriptionCost: Double {
        let activeSubscriptions = subscriptionManager.activeSubscriptions
        return activeSubscriptions.isEmpty ? 0 : subscriptionManager.totalMonthlySpending / Double(activeSubscriptions.count)
    }
    
    var mostExpensiveCategory: SubscriptionCategory {
        let categorySpending = Dictionary(grouping: subscriptionManager.activeSubscriptions) { $0.category }
            .mapValues { subscriptions in
                subscriptions.reduce(0) { $0 + $1.monthlyPrice }
            }
        
        return categorySpending.max(by: { $0.value < $1.value })?.key ?? .other
    }
    
    var daysUntilNextPayment: Int {
        let nextPayment = subscriptionManager.upcomingSubscriptions.first?.nextBillingDate ?? Date()
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextPayment).day ?? 0
        return max(0, days)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Summary
                    VStack(spacing: 16) {
                        Text("Monthly Payment Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimaryColor)
                        
                        // Current Month Totals
                        HStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Unpaid This Month")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "$%.2f", subscriptionManager.totalUnpaidCurrentMonthSpending))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(theme.cardBackgroundColor)
                            .cornerRadius(12)
                            
                            VStack(spacing: 8) {
                                Text("Paid This Month")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "$%.2f", subscriptionManager.totalCurrentMonthSpending - subscriptionManager.totalUnpaidCurrentMonthSpending))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(theme.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                        
                        // Additional Statistics
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total This Month")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "$%.2f", subscriptionManager.totalCurrentMonthSpending))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Monthly Average")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "$%.2f", subscriptionManager.totalMonthlySpending))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Subscriptions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(subscriptionManager.activeSubscriptions.count)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Payment Progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.0f%%", paymentProgress))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(paymentProgress >= 100 ? .green : .orange)
                                }
                            }
                            
                            // Progress Bar
                            ProgressView(value: min(paymentProgress / 100.0, 1.0))
                                .progressViewStyle(LinearProgressViewStyle(tint: paymentProgress >= 100 ? .green : .orange))
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Unpaid Subscriptions
                    if !unpaidSubscriptions.isEmpty {
                        SubscriptionSection(
                            title: "Unpaid This Month",
                            icon: "exclamationmark.circle.fill",
                            iconColor: .red,
                            borderColor: .red,
                            count: unpaidSubscriptions.count,
                            subscriptions: unpaidSubscriptions,
                            subscriptionManager: subscriptionManager
                        )
                    }
                    
                    // Paid Subscriptions
                    if !paidSubscriptions.isEmpty {
                        SubscriptionSection(
                            title: "Already Paid",
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            borderColor: .green,
                            count: paidSubscriptions.count,
                            subscriptions: paidSubscriptions,
                            subscriptionManager: subscriptionManager
                        )
                    }
                    
                    // Next Month Preview
                    if !nextMonthSubscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                Text("Next Month Preview")
                                    .font(.headline)
                                    .foregroundColor(theme.textPrimaryColor)
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f", nextMonthTotal))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("\(nextMonthSubscriptions.count) subscription\(nextMonthSubscriptions.count == 1 ? "" : "s") due next month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Show top 3 most expensive next month
                            ForEach(nextMonthSubscriptions.prefix(3)) { subscription in
                                HStack {
                                    Circle()
                                        .fill(subscription.category.color)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(subscription.name)
                                        .font(.subheadline)
                                        .foregroundColor(theme.textPrimaryColor)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", subscription.price))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if nextMonthSubscriptions.count > 3 {
                                Text("+ \(nextMonthSubscriptions.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 16)
                            }
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.blue, lineWidth: 1)
                                .opacity(0.3)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Spending Insights
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            Text("Spending Insights")
                                .font(.headline)
                                .foregroundColor(theme.textPrimaryColor)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Average per subscription")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f", averageSubscriptionCost))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Most expensive category")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(mostExpensiveCategory.color)
                                        .frame(width: 8, height: 8)
                                    Text(mostExpensiveCategory.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            HStack {
                                Text("Days until next payment")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(daysUntilNextPayment) days")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(daysUntilNextPayment <= 3 ? .red : .primary)
                            }
                        }
                    }
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.purple, lineWidth: 1)
                            .opacity(0.3)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Yearly Total Detail View
struct YearlyTotalDetailView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var subscriptionsByCategory: [SubscriptionCategory: [Subscription]] {
        Dictionary(grouping: subscriptionManager.activeSubscriptions) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Summary
                    VStack(spacing: 16) {
                        Text("Yearly Spending Breakdown")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimaryColor)
                        
                        VStack(spacing: 8) {
                            Text("Total Yearly Cost")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", subscriptionManager.totalYearlySpending))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Category Breakdown
                    ForEach(subscriptionsByCategory.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                        let subscriptions = subscriptionsByCategory[category] ?? []
                        let yearlyTotal = subscriptions.reduce(0) { $0 + $1.yearlyPrice }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                    .font(.title2)
                                
                                Text(category.rawValue)
                                    .font(.headline)
                                    .foregroundColor(theme.textPrimaryColor)
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f/year", yearlyTotal))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            ForEach(subscriptions) { subscription in
                                HStack {
                                    Text(subscription.name)
                                        .foregroundColor(theme.textPrimaryColor)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", subscription.yearlyPrice))
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                                .padding(.leading, 32)
                            }
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Active Subscriptions Detail View
struct ActiveSubscriptionsDetailView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var subscriptionsByCategory: [SubscriptionCategory: [Subscription]] {
        Dictionary(grouping: subscriptionManager.activeSubscriptions) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Summary
                    VStack(spacing: 16) {
                        Text("Active Subscriptions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimaryColor)
                        
                        VStack(spacing: 8) {
                            Text("Total Active")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(subscriptionManager.activeSubscriptions.count)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Category Sections
                    ForEach(subscriptionsByCategory.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                        let subscriptions = subscriptionsByCategory[category] ?? []
                        
                        SubscriptionSection(
                            title: category.rawValue,
                            icon: category.icon,
                            iconColor: category.color,
                            borderColor: category.color,
                            count: subscriptions.count,
                            subscriptions: subscriptions,
                            subscriptionManager: subscriptionManager
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Due Soon Detail View
struct DueSoonDetailView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var upcomingSubscriptions: [Subscription] {
        subscriptionManager.upcomingSubscriptions
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Summary
                    VStack(spacing: 16) {
                        Text("Upcoming Renewals")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimaryColor)
                        
                        VStack(spacing: 8) {
                            Text("Due in Next 7 Days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(upcomingSubscriptions.count)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Upcoming Subscriptions List
                    if !upcomingSubscriptions.isEmpty {
                        SubscriptionSection(
                            title: "Upcoming Renewals",
                            icon: "clock.fill",
                            iconColor: .orange,
                            borderColor: .orange,
                            count: upcomingSubscriptions.count,
                            subscriptions: upcomingSubscriptions,
                            subscriptionManager: subscriptionManager
                        )
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("No upcoming renewals")
                                .font(.headline)
                                .foregroundColor(theme.textPrimaryColor)
                            
                            Text("All your subscriptions are up to date for the next 7 days.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}