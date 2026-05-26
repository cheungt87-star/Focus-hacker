@testable import FocusHacker
import SwiftUI
import XCTest

final class FocusSessionScreenTests: XCTestCase {
    func testExpertCarouselDescriptionLine() {
        XCTAssertEqual(
            FocusSessionPresets.expert.carouselDescriptionLine,
            "50 min · 10 min break · 3 cycles"
        )
    }

    func testClassicCarouselDescriptionLine() {
        XCTAssertEqual(
            FocusSessionPresets.classic.carouselDescriptionLine,
            "25 min · 5 min break · 4 cycles"
        )
    }

    func testPaletteLightModeTokens() {
        let palette = FocusSessionScreenPalette.resolve(for: .light)
        XCTAssertEqual(colorHex(palette.accent), 0x16A34A)
        XCTAssertEqual(colorHex(palette.bgScreen), 0xEAEAEA)
        XCTAssertEqual(colorHex(palette.bgTimer), 0xEAEAEA)
        XCTAssertEqual(colorHex(palette.ctaForeground), 0xFFFFFF)
    }

    func testPaletteDarkModeTokens() {
        let palette = FocusSessionScreenPalette.resolve(for: .dark)
        XCTAssertEqual(colorHex(palette.accent), 0x4ADE80)
        XCTAssertEqual(colorHex(palette.bgScreen), 0x111316)
        XCTAssertEqual(colorAlpha(palette.bgTimer), 0, accuracy: 0.01)
        XCTAssertEqual(colorHex(palette.ctaForeground), 0x0A1F0D)
    }

    func testPopoverLayoutMaxWidthAccountsForPadding() {
        XCTAssertEqual(
            FocusSessionScreenLayout.menuBarPopover.maxWidth,
            MenuBarPopoverLayout.width - DesignSpacing.spacing5 * 2
        )
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
}
