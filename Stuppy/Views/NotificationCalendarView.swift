import SwiftUI

struct NotificationCalendarView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager
    @Binding var isPresented: Bool
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            // Header
            HStack {
                Button("Close") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.primaryPurple)

                Spacer()

                Text("Payment Calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimaryColor)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentMonth = Date()
                    }
                }) {
                    Text("Today")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primaryPurple)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(theme.cardBackgroundColor)

            Divider()
                .background(theme.borderColor)

            ScrollView {
                VStack(spacing: 24) {
                    // Calendar Controls
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textPrimaryColor)
                                .frame(width: 32, height: 32)
                                .background(theme.secondaryBackgroundColor)
                                .cornerRadius(8)
                        }

                        Spacer()

                        Text(dateFormatter.string(from: currentMonth))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimaryColor)

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textPrimaryColor)
                                .frame(width: 32, height: 32)
                                .background(theme.secondaryBackgroundColor)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Calendar Grid
                    CalendarGridView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        subscriptionManager: subscriptionManager
                    )
                    .padding(.horizontal, 20)

                    // Subscription List for Selected Date
                    if !subscriptionsForSelectedDate.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Payments on \(selectedDate, formatter: dayFormatter)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(theme.textPrimaryColor)
                                Spacer()
                            }

                            LazyVStack(spacing: 12) {
                                ForEach(subscriptionsForSelectedDate) { subscription in
                                    NavigationLink(value: subscription) {
                                        CalendarSubscriptionRow(subscription: subscription)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(20)
                        .glassMorphismCard()
                        .padding(.horizontal, 20)
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Legend")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textPrimaryColor)

                        VStack(spacing: 12) {
                            HStack(spacing: 24) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.primaryPurple)
                                        .frame(width: 12, height: 12)
                                    Text("Payment Due")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.textSecondaryColor)
                                }

                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.error)
                                        .frame(width: 12, height: 12)
                                    Text("Overdue")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.textSecondaryColor)
                                }

                                Spacer()
                            }

                            HStack(spacing: 24) {
                                HStack(spacing: 8) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.accentTeal)
                                    Text("Auto-Renewal")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.textSecondaryColor)
                                }

                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.warning)
                                    Text("No Auto-Renewal")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.textSecondaryColor)
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .glassMorphismCard()
                    .padding(.horizontal, 20)

                    // Bottom padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 20)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .background(theme.backgroundColor)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: theme.shadowColor, radius: 20, x: 0, y: -5)
        .navigationDestination(for: Subscription.self) { subscription in
            SubscriptionDetailView(
                subscription: subscription,
                subscriptionManager: subscriptionManager
            )
        }
        }
    }

    private var subscriptionsForSelectedDate: [Subscription] {
        subscriptionManager.activeSubscriptions.filter { subscription in
            hasSubscriptionOnDate(subscription, date: selectedDate)
        }
    }

    private func hasSubscriptionOnDate(_ subscription: Subscription, date: Date) -> Bool {
        // Check exact billing date
        if calendar.isDate(subscription.nextBillingDate, inSameDayAs: date) {
            return true
        }

        // For disabled auto-renewal, only check the exact next billing date
        guard subscription.repetitionType != .disabled else { return false }
        
        // Also check if subscription is active
        guard subscription.isActive else { return false }

        let startDate = subscription.nextBillingDate
        let targetDate = date

        // Only check dates within reasonable future range (1 year)
        let oneYearLater = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        guard targetDate <= oneYearLater else { return false }

        // Calculate all future payment dates for this subscription
        var currentDate = startDate
        var loopCount = 0
        let maxLoops = 365 // Prevent infinite loops

        while currentDate <= targetDate && loopCount < maxLoops {
            if calendar.isDate(currentDate, inSameDayAs: targetDate) {
                return true
            }

            // Move to next repetition date based on repetition type
            switch subscription.repetitionType {
            case .monthly:
                guard let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            case .yearly:
                guard let nextDate = calendar.date(byAdding: .year, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            case .disabled:
                break
            }

            loopCount += 1
            
            // Safety check to prevent infinite loops
            if loopCount >= maxLoops {
                break
            }
        }

        return false
    }

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

struct CalendarGridView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    @ObservedObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Day headers
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { dayName in
                Text(dayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            // Calendar days
            ForEach(calendarDays, id: \.self) { date in
                CalendarDayView(
                    date: date,
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    subscriptionManager: subscriptionManager
                )
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentMonth)
    }

    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end) else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(inside: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }
}

struct CalendarDayView: View {
    let date: Date
    let currentMonth: Date
    @Binding var selectedDate: Date
    @ObservedObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var theme: ThemeManager

    private let calendar = Calendar.current

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
        }) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)

                if hasPayments {
                    Circle()
                        .fill(paymentIndicatorColor)
                        .frame(width: 6, height: 6)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var hasPayments: Bool {
        subscriptionManager.activeSubscriptions.contains { subscription in
            hasSubscriptionOnDate(subscription, date: date)
        }
    }

    private func hasSubscriptionOnDate(_ subscription: Subscription, date: Date) -> Bool {
        // Check exact billing date
        if calendar.isDate(subscription.nextBillingDate, inSameDayAs: date) {
            return true
        }

        // For disabled auto-renewal, only check the exact next billing date
        guard subscription.repetitionType != .disabled else { return false }
        
        // Also check if subscription is active
        guard subscription.isActive else { return false }

        let startDate = subscription.nextBillingDate
        let targetDate = date

        // Only check dates within reasonable future range (1 year)
        let oneYearLater = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        guard targetDate <= oneYearLater else { return false }

        // Calculate all future payment dates for this subscription
        var currentDate = startDate
        var loopCount = 0
        let maxLoops = 365 // Prevent infinite loops

        while currentDate <= targetDate && loopCount < maxLoops {
            if calendar.isDate(currentDate, inSameDayAs: targetDate) {
                return true
            }

            // Move to next repetition date based on repetition type
            switch subscription.repetitionType {
            case .monthly:
                guard let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            case .yearly:
                guard let nextDate = calendar.date(byAdding: .year, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            case .disabled:
                break
            }

            loopCount += 1
            
            // Safety check to prevent infinite loops
            if loopCount >= maxLoops {
                break
            }
        }

        return false
    }

    private var hasOverduePayments: Bool {
        subscriptionManager.activeSubscriptions.contains { subscription in
            calendar.isDate(subscription.nextBillingDate, inSameDayAs: date) && subscription.isOverdue
        }
    }

    private var textColor: Color {
        if !isInCurrentMonth {
            return theme.textSecondaryColor.opacity(0.5)
        } else if isSelected {
            return .white
        } else if isToday {
            return Color.primaryPurple
        } else {
            return theme.textPrimaryColor
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.primaryPurple
        } else if isToday {
            return Color.primaryPurple.opacity(0.2)
        } else if hasPayments {
            return Color.accentOrange.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var paymentIndicatorColor: Color {
        if hasOverduePayments {
            return Color.error
        } else {
            return Color.primaryPurple
        }
    }
}

struct CalendarSubscriptionRow: View {
    let subscription: Subscription
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(subscription.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: subscription.category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(subscription.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimaryColor)

                HStack(spacing: 8) {
                    Text(subscription.billingCycle.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondaryColor)

                    if subscription.repetitionType != .disabled {
                        Image(systemName: "repeat")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.accentTeal)

                        Text(subscription.repetitionType.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.accentTeal)
                    } else {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.warning)

                        Text("No Auto-Renewal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.warning)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", subscription.price))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(subscription.isOverdue ? Color.error : theme.textPrimaryColor)

                if subscription.isOverdue {
                    Text("Overdue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.error)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(startingAfter: interval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NotificationCalendarView(
        subscriptionManager: SubscriptionManager(),
        isPresented: .constant(true)
    )
    .environmentObject(ThemeManager())
}