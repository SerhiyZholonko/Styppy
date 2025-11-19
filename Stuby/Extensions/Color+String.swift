import SwiftUI

extension Color {
    init(stringColor: String) {
        switch stringColor.lowercased() {
        case "blue": self = .blue
        case "red": self = .red
        case "green": self = .green
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "yellow": self = .yellow
        case "indigo": self = .indigo
        case "teal": self = .teal
        case "mint": self = .mint
        default: self = .blue
        }
    }
}