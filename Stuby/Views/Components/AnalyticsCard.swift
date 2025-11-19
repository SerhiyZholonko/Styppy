import SwiftUI

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        VStack(spacing: isIPad ? 16 : 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: isIPad ? 60 : 44, height: isIPad ? 60 : 44)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: isIPad ? 24 : 18, weight: .semibold))
            }

            VStack(spacing: isIPad ? 8 : 4) {
                Text(value)
                    .font(.system(size: isIPad ? 32 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: isIPad ? 14 : 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isIPad ? 160 : 120)
        .padding(isIPad ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: isIPad ? 12 : 8, x: 0, y: isIPad ? 6 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
    }
}