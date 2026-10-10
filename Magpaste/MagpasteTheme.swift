import SwiftUI
import AppKit

extension Color {
    /// Convenience hex initializer, e.g. `Color(hex: "F4F5F7")`.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Encodes this color back to a hex string, e.g. for persisting a
    /// user-picked `ColorPicker` selection.
    func toHexString() -> String {
        let nsColor = NSColor(self)
        let rgbColor = nsColor.usingColorSpace(.deviceRGB) ?? nsColor.usingColorSpace(.sRGB) ?? nsColor
        let r = Int((rgbColor.redComponent * 255).rounded())
        let g = Int((rgbColor.greenComponent * 255).rounded())
        let b = Int((rgbColor.blueComponent * 255).rounded())
        return String(format: "%02X%02X%02X", r, g, b)
    }

    /// A darker, more saturated variant of this color — pairs with the
    /// color itself the way MagpasteTheme's own accents pair with their
    /// "Ink" variant (e.g. wingBlue -> wingBlueInk), so any arbitrary
    /// user-picked section color still reads clearly as header text.
    func darkened(by fraction: CGFloat = 0.55) -> Color {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newBrightness = max(brightness * fraction, 0.15)
        let newSaturation = min(saturation * 1.15, 1.0)
        return Color(hue: hue, saturation: newSaturation, brightness: newBrightness)
    }
}

/// Color palette pulled from the Eurasian magpie: a mostly white/near-white
/// bird, with iridescent silvery-blue sheen on the wing feathers and a
/// bronze-green sheen on the tail. Deliberately light and low-contrast so
/// the panel sits quietly on the desktop instead of reading as a dark block
/// on top of the rest of macOS.
enum MagpasteTheme {
    // Base surfaces
    static let panelBackground = Color(hex: "F4F5F7")
    static let cardBackground = Color(hex: "FFFFFF")
    static let cardBorder = Color(hex: "E1E3E7")
    static let divider = Color(hex: "EDEEEF")

    // Wing — silvery blue. Used for links and the primary interactive accent.
    static let wingBlue = Color(hex: "4A85B8")
    static let wingBlueTint = Color(hex: "DCEBF6")
    static let wingBlueInk = Color(hex: "1D4E6E")

    // Tail — bronze/iridescent green. Used as the secondary accent.
    static let tailGreen = Color(hex: "2E9670")
    static let tailGreenTint = Color(hex: "D8F0E4")
    static let tailGreenInk = Color(hex: "155C40")

    // Neutral — plain text clips.
    static let neutralTint = Color(hex: "EEEFF1")
    static let neutralInk = Color(hex: "2A2C2F")

    // Text
    static let textPrimary = Color(hex: "2A2C2F")
    static let textSecondary = Color(hex: "5A5D62")
    static let textMuted = Color(hex: "9A9DA2")

    /// Starting point for a newly created section's color — picked at
    /// random so sections are visually distinct by default, while staying
    /// within the app's palette instead of a jarring pure-random RGB value.
    static let sectionPalette: [Color] = [
        Color(hex: "4A85B8"), // wing blue
        Color(hex: "2E9670"), // tail green
        Color(hex: "9B59B6"), // plum
        Color(hex: "E0954C"), // amber
        Color(hex: "D9668B"), // rose
        Color(hex: "3FA7A0"), // teal
        Color(hex: "C0555A"), // coral
        Color(hex: "6C7BD1"), // indigo
    ]
}
