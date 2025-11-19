import SwiftUI

struct StatisticRow: View {
    let label: String
    let value: String

    var body: some View {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        HStack {
            Text(label)
                .font(.system(size: isIPad ? 16 : 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Text(value)
                .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.vertical, isIPad ? 8 : 4)
    }
}