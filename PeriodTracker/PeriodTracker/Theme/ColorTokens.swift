import SwiftUI

enum AppColor {
    // Backgrounds (near-black greens)
    static let background = Color(hex: 0x1A1F1A)
    static let surface = Color(hex: 0x242B24)
    static let surfaceElevated = Color(hex: 0x2D352D)

    // Text
    static let textPrimary = Color(hex: 0xE8EDE5)
    static let textSecondary = Color(hex: 0x8A9A82)
    static let textMuted = Color(hex: 0x5A6A52)

    // Accent
    static let accent = Color(hex: 0xA3C293)
    static let accentDim = Color(hex: 0x6B8A5E)

    // Period highlight
    static let periodGold = Color(hex: 0xC4A882)
    static let periodGoldDim = Color(hex: 0x8A7A5E)

    // Status
    static let error = Color(hex: 0xC2736B)
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
