import SwiftUI

// MARK: - Theme (iOS 18 Liquid Glass)
enum Theme {
    static let accent = Color(red: 0.04, green: 0.52, blue: 1.0) // #0A84FF
    static let background = Color(.systemGroupedBackground)
    static let cardRadius: CGFloat = 22
    static let glassStroke = Color.white.opacity(0.35)
    static let glassShadow = Color.black.opacity(0.12)

    // Glass gradients like iOS 18 control center
    static let glassGradient = LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let accentGradient = LinearGradient(colors: [Color(red:0.04,green:0.52,blue:1), Color(red:0.35,green:0.34,blue:1)], startPoint: .topLeading, endPoint: .bottomTrailing)
}
