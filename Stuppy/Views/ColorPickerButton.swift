import SwiftUI

// MARK: - Custom Color Picker Button
struct ColorPickerButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Background circle with subtle shadow
                    Circle()
                        .fill(Color(stringColor: color))
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: Color(stringColor: color).opacity(0.3),
                            radius: isSelected ? 6 : 3,
                            x: 0,
                            y: isSelected ? 3 : 1
                        )
                    
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: 50, height: 50)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            .frame(width: 44, height: 44)
                    }
                    
                    // Selection checkmark
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                
                // Color name label
                Text(color.capitalized)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
    HStack {
        ColorPickerButton(color: "blue", isSelected: true) {}
        ColorPickerButton(color: "red", isSelected: false) {}
        ColorPickerButton(color: "green", isSelected: false) {}
    }
    .padding()
}