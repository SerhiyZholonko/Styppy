import SwiftUI

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    var isIPad: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: isIPad ? 8 : 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: isIPad ? 14 : 12))
                        .foregroundColor(isSelected ? .white : .primaryPurple)
                }
                Text(title)
                    .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, isIPad ? 20 : 12)
            .padding(.vertical, isIPad ? 12 : 8)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                    .fill(isSelected ? Color.primaryPurple : Color(.systemGray6))
                    .shadow(
                        color: isSelected ? .primaryPurple.opacity(0.3) : .clear,
                        radius: isSelected ? (isIPad ? 8 : 4) : 0,
                        x: 0,
                        y: isSelected ? (isIPad ? 4 : 2) : 0
                    )
            )
            .foregroundColor(
                isSelected ? .white : .primary
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}