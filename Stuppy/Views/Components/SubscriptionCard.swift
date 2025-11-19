import SwiftUI

struct SubscriptionCard: View {
    let subscription: Subscription
    var isIPad: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            // Header with icon and status
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                        .fill(subscription.category.color.opacity(0.15))
                        .frame(width: isIPad ? 60 : 48, height: isIPad ? 60 : 48)
                    
                    Image(systemName: subscription.category.icon)
                        .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                        .foregroundColor(subscription.category.color)
                }
                
                Spacer()
                
                // Status indicator
                VStack(alignment: .trailing, spacing: 4) {
                    if subscription.isOverdue {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: isIPad ? 12 : 10))
                                .foregroundColor(.red)
                            
                            Text("Overdue")
                                .font(.system(size: isIPad ? 12 : 10, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, isIPad ? 10 : 8)
                        .padding(.vertical, isIPad ? 6 : 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(isIPad ? 8 : 6)
                    } else if subscription.daysUntilNextBilling <= 3 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: isIPad ? 12 : 10))
                                .foregroundColor(.orange)
                            
                            Text("\(subscription.daysUntilNextBilling) days")
                                .font(.system(size: isIPad ? 12 : 10, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, isIPad ? 10 : 8)
                        .padding(.vertical, isIPad ? 6 : 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(isIPad ? 8 : 6)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: isIPad ? 12 : 10))
                                .foregroundColor(.green)
                            
                            Text("Active")
                                .font(.system(size: isIPad ? 12 : 10, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, isIPad ? 10 : 8)
                        .padding(.vertical, isIPad ? 6 : 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(isIPad ? 8 : 6)
                    }
                }
            }
            
            // Subscription details
            VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
                Text(subscription.name)
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: isIPad ? 12 : 8) {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: isIPad ? 12 : 10))
                            .foregroundColor(subscription.category.color)
                        
                        Text(subscription.category.rawValue)
                            .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                            .foregroundColor(subscription.category.color)
                    }
                    
                    Spacer()
                    
                    // Billing cycle
                    Text(subscription.billingCycle.rawValue)
                        .font(.system(size: isIPad ? 14 : 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, isIPad ? 8 : 6)
                        .padding(.vertical, isIPad ? 4 : 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(isIPad ? 6 : 4)
                }
            }
            
            Spacer()
            
            // Price and next billing
            VStack(alignment: .leading, spacing: isIPad ? 8 : 6) {
                HStack {
                    Text(String(format: "$%.2f", subscription.price))
                        .font(.system(size: isIPad ? 28 : 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next billing")
                            .font(.system(size: isIPad ? 12 : 10))
                            .foregroundColor(.secondary)
                        
                        Text(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                // Progress bar for days until billing
                if !subscription.isOverdue {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Days remaining")
                                .font(.system(size: isIPad ? 12 : 10))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(subscription.daysUntilNextBilling)")
                                .font(.system(size: isIPad ? 12 : 10, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: isIPad ? 8 : 6)
                                
                                RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                                    .fill(
                                        LinearGradient(
                                            colors: subscription.daysUntilNextBilling <= 3 
                                                ? [.orange, .red] 
                                                : [subscription.category.color, subscription.category.color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * max(0.1, min(1.0, Double(subscription.daysUntilNextBilling) / 30.0)),
                                        height: isIPad ? 8 : 6
                                    )
                            }
                        }
                        .frame(height: isIPad ? 8 : 6)
                    }
                }
            }
        }
        .padding(isIPad ? 24 : 20)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: isIPad ? 12 : 8, x: 0, y: isIPad ? 6 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .stroke(subscription.category.color.opacity(0.1), lineWidth: 1)
        )
        .frame(height: isIPad ? 240 : 200)
    }
}

// Extension for chunking array into groups
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}