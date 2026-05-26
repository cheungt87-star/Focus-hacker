@testable import FocusHacker
import AppKit
import SwiftUI
import XCTest

final class ProfileHeroPaletteTests: XCTestCase {
    func testPanelColorsAreIdenticalForLightAndDarkPageScheme() {
        let light = ProfileHeroPalette.resolve(for: .light)
        let dark = ProfileHeroPalette.resolve(for: .dark)

        XCTAssertEqual(colorHex(light.leftPanel), colorHex(dark.leftPanel))
        XCTAssertEqual(colorHex(light.leftPanel), 0x1C1C1E)
        XCTAssertEqual(colorHex(light.rightPanel), 0x111111)
        XCTAssertEqual(colorHex(light.statTile), 0x252527)
        XCTAssertEqual(colorHex(light.mutedLabel), 0xA8A8A8)
        XCTAssertEqual(colorHex(light.progressLabel), 0xA8A8A8)
        XCTAssertEqual(colorHex(light.primaryText), 0xFFFFFF)
    }

    func testCardBorderDiffersBetweenLightAndDarkPageScheme() {
        let light = ProfileHeroPalette.resolve(for: .light)
        let dark = ProfileHeroPalette.resolve(for: .dark)

        XCTAssertEqual(colorHex(light.cardBorder), 0x1E6B5E)
        XCTAssertEqual(colorAlpha(light.cardBorder), 1, accuracy: 0.01)
        XCTAssertEqual(colorHex(dark.cardBorder), 0x3DA882)
        XCTAssertEqual(colorAlpha(dark.cardBorder), 1, accuracy: 0.01)
    }

    func testCardBorderMatchesMacDSResolvedAccentTeal() {
        for scheme: ColorScheme in [.light, .dark] {
            let palette = ProfileHeroPalette.resolve(for: scheme)
            XCTAssertEqual(
                colorHex(palette.cardBorder),
                colorHex(MacDS.Resolved.accentTeal(for: scheme)),
                "cardBorder for \(scheme)"
            )
        }
    }

    func testCardBorderWidth() {
        XCTAssertEqual(ProfileHeroPalette.cardBorderWidth, 3)
    }

    func testDarkPageCardBorderContrastOnLeftPanelMeetsNonTextMinimum() {
        let dark = ProfileHeroPalette.resolve(for: .dark)
        let ratio = contrastRatio(
            foregroundHex: colorHex(dark.cardBorder),
            backgroundHex: colorHex(dark.leftPanel)
        )
        XCTAssertGreaterThanOrEqual(ratio, 3.0, "dark page cardBorder on leftPanel")
    }

    func testDarkCardLabelContrastMeetsWCAGAA() {
        let palette = ProfileHeroPalette.resolve(for: .light)
        let pairs: [(Color, Color, String)] = [
            (palette.mutedLabel, palette.statTile, "mutedLabel on statTile"),
            (palette.primaryText, palette.leftPanel, "primaryText on leftPanel"),
            (palette.progressLabel, palette.leftPanel, "progressLabel on leftPanel"),
        ]

        for (foreground, background, label) in pairs {
            let ratio = contrastRatio(
                foregroundHex: colorHex(foreground),
                backgroundHex: colorHex(background)
            )
            XCTAssertGreaterThanOrEqual(ratio, 4.5, label)
        }
    }

    private func colorAlpha(_ color: Color) -> Double {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        var alpha: CGFloat = 0
        nsColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return Double(alpha)
    }

    private func colorHex(_ color: Color) -> UInt32 {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = UInt32(round(red * 255))
        let g = UInt32(round(green * 255))
        let b = UInt32(round(blue * 255))
        return (r << 16) | (g << 8) | b
    }

    private func contrastRatio(foregroundHex: UInt32, backgroundHex: UInt32) -> Double {
        let foreground = relativeLuminance(hex: foregroundHex)
        let background = relativeLuminance(hex: backgroundHex)
        let lighter = max(foreground, background)
        let darker = min(foreground, background)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(hex: UInt32) -> Double {
        func channel(_ value: UInt32) -> Double {
            let normalized = Double(value) / 255
            if normalized <= 0.03928 {
                return normalized / 12.92
            }
            return pow((normalized + 0.055) / 1.055, 2.4)
        }

        let red = channel((hex & 0xFF0000) >> 16)
        let green = channel((hex & 0x00FF00) >> 8)
        let blue = channel(hex & 0x0000FF)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}
