import Foundation
import SwiftUI

enum BillingCycle: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var days: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        }
    }
}

enum RepetitionType: String, CaseIterable, Codable {
    case disabled = "Disabled"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var description: String {
        switch self {
        case .disabled: return "No auto-renewal"
        case .monthly: return "Auto-renew monthly"
        case .yearly: return "Auto-renew yearly"
        }
    }
}

enum SubscriptionCategory: String, CaseIterable, Codable {
    case streaming = "Streaming"
    case music = "Music"
    case productivity = "Productivity"
    case fitness = "Fitness"
    case gaming = "Gaming"
    case news = "News"
    case storage = "Storage"
    case communication = "Communication"
    case finance = "Finance"
    case other = "Other"

    var icon: String {
        switch self {
        case .streaming: return "tv"
        case .music: return "music.note"
        case .productivity: return "briefcase"
        case .fitness: return "figure.walk"
        case .gaming: return "gamecontroller"
        case .news: return "newspaper"
        case .storage: return "internaldrive"
        case .communication: return "message"
        case .finance: return "creditcard"
        case .other: return "app"
        }
    }

    var color: Color {
        switch self {
        case .streaming: return .red
        case .music: return .purple
        case .productivity: return .blue
        case .fitness: return .green
        case .gaming: return .orange
        case .news: return .indigo
        case .storage: return .gray
        case .communication: return .teal
        case .finance: return .mint
        case .other: return .brown
        }
    }
}

struct Subscription: Identifiable, Codable {
    let id: UUID
    var name: String
    var price: Double
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var nextBillingDate: Date
    var isActive: Bool
    var notes: String
    var color: String
    var repetitionType: RepetitionType
    var isPaidForCurrentMonth: Bool

    init(id: UUID = UUID(), name: String = "", price: Double = 0.0, billingCycle: BillingCycle = .monthly, category: SubscriptionCategory = .other, nextBillingDate: Date = Date(), isActive: Bool = true, notes: String = "", color: String = "blue", repetitionType: RepetitionType = .monthly, isPaidForCurrentMonth: Bool = false) {
        self.id = id
        self.name = name
        self.price = price
        self.billingCycle = billingCycle
        self.category = category
        self.nextBillingDate = nextBillingDate
        self.isActive = isActive
        self.notes = notes
        self.color = color
        self.repetitionType = repetitionType
        self.isPaidForCurrentMonth = isPaidForCurrentMonth
    }

    var monthlyPrice: Double {
        switch billingCycle {
        case .weekly: return price * 4.33
        case .monthly: return price
        case .quarterly: return price / 3
        case .yearly: return price / 12
        }
    }
    
    // Price for the current month - yearly subscriptions only count in their billing month
    var currentMonthPrice: Double {
        switch billingCycle {
        case .weekly: return price * 4.33
        case .monthly: return price
        case .quarterly: return price / 3
        case .yearly:
            // Only include yearly subscription cost in the month when it's due
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())
            let billingMonth = calendar.component(.month, from: nextBillingDate)
            let billingYear = calendar.component(.year, from: nextBillingDate)
            
            // Check if this is the billing month and year
            if currentMonth == billingMonth && currentYear == billingYear {
                return price
            } else {
                return 0.0
            }
        }
    }
    
    var unpaidCurrentMonthPrice: Double {
        if isPaidForCurrentMonth {
            return 0.0
        }
        
        // Check if the next billing date is in the current calendar month
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let billingMonth = calendar.component(.month, from: nextBillingDate)
        let billingYear = calendar.component(.year, from: nextBillingDate)
        
        // Only include if billing is in the current month and year
        guard currentMonth == billingMonth && currentYear == billingYear else {
            return 0.0
        }
        
        switch billingCycle {
        case .weekly:
            return price * 4.33
        case .monthly:
            return price
        case .quarterly:
            return price / 3
        case .yearly:
            return price
        }
    }
    
    var unpaidMonthlyPrice: Double {
        return isPaidForCurrentMonth ? 0.0 : monthlyPrice
    }

    var yearlyPrice: Double {
        return monthlyPrice * 12
    }

    var daysUntilNextBilling: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
        return max(0, days)
    }

    var isOverdue: Bool {
        return nextBillingDate < Date()
    }

    mutating func updateNextBillingDate() {
        guard repetitionType != .disabled else { return }

        let calendar = Calendar.current

        switch repetitionType {
        case .disabled:
            break
        case .monthly:
            nextBillingDate = calendar.date(byAdding: .month, value: 1, to: nextBillingDate) ?? nextBillingDate
        case .yearly:
            nextBillingDate = calendar.date(byAdding: .year, value: 1, to: nextBillingDate) ?? nextBillingDate
        }
    }
    
    mutating func markAsPaid() {
        isPaidForCurrentMonth = true
    }
    
    mutating func resetPaymentStatus() {
        isPaidForCurrentMonth = false
    }
    
    var needsPaymentReset: Bool {
        let calendar = Calendar.current
        let lastDayOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: calendar.dateInterval(of: .month, for: Date())!.start)!
        return isPaidForCurrentMonth && nextBillingDate <= lastDayOfPreviousMonth
    }
}