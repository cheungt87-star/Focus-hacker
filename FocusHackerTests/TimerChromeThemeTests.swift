@testable import FocusHacker
import AppKit
import SwiftUI
import XCTest

final class TimerChromeThemeTests: XCTestCase {
    func testFocusLightUsesWarmCharcoalPalette() {
        let theme = TimerChromeTheme(sessionState: .focus, colorScheme: .light)
        XCTAssertEqual(themeHex(theme.bgApp), 0x2F3542)
        XCTAssertEqual(themeHex(theme.accentPrimary), 0xFF4757)
        XCTAssertEqual(themeHex(theme.textPrimary), 0xFFFFFF)
    }

    func testFocusDarkDeepensBackgrounds() {
        let theme = TimerChromeTheme(sessionState: .focus, colorScheme: .dark)
        XCTAssertEqual(themeHex(theme.bgApp), 0x1A1D24)
        XCTAssertEqual(themeHex(theme.bgPanel), 0x252930)
        XCTAssertEqual(themeHex(theme.accentPrimary), 0xFF4757)
    }

    func testRestLightUsesCoolCloudPalette() {
        let theme = TimerChromeTheme(sessionState: .rest, colorScheme: .light)
        XCTAssertEqual(themeHex(theme.bgApp), 0xF0F4F8)
        XCTAssertEqual(themeHex(theme.accentPrimary), 0x00D2D3)
        XCTAssertEqual(themeHex(theme.textPrimary), 0x1A2B35)
    }

    func testRestDarkUsesCoolDarkPalette() {
        let theme = TimerChromeTheme(sessionState: .rest, colorScheme: .dark)
        XCTAssertEqual(themeHex(theme.bgApp), 0x1A2332)
        XCTAssertEqual(themeHex(theme.bgPanel), 0x222D3A)
        XCTAssertEqual(themeHex(theme.textPrimary), 0xE8F1F7)
        XCTAssertEqual(themeHex(theme.accentPrimary), 0x00D2D3)
    }

    func testIdleMatchesFocusPalette() {
        let idle = TimerChromeTheme(sessionState: .idle, colorScheme: .light)
        let focus = TimerChromeTheme(sessionState: .focus, colorScheme: .light)
        XCTAssertEqual(themeHex(idle.bgApp), themeHex(focus.bgApp))
        XCTAssertEqual(themeHex(idle.accentPrimary), themeHex(focus.accentPrimary))
    }

    func testRestDarkTextMeetsContrastOnPanel() {
        let theme = TimerChromeTheme(sessionState: .rest, colorScheme: .dark)
        let ratio = contrastRatio(
            foregroundHex: themeHex(theme.textPrimary),
            backgroundHex: themeHex(theme.bgPanel)
        )
        XCTAssertGreaterThanOrEqual(ratio, 4.5)
    }

    private func themeHex(_ color: Color) -> UInt32 {
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
