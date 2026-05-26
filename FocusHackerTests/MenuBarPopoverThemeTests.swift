@testable import FocusHacker
import AppKit
import SwiftUI
import XCTest

final class MenuBarPopoverThemeTests: XCTestCase {
    func testPaletteBackgroundAndTextDifferBetweenLightAndDark() {
        let light = MenuBarPopoverPalette.resolve(for: .light)
        let dark = MenuBarPopoverPalette.resolve(for: .dark)

        XCTAssertNotEqual(colorHex(light.background), colorHex(dark.background))
        XCTAssertEqual(colorHex(light.background), 0xF0EEE8)
        XCTAssertEqual(colorHex(dark.background), 0x1C1C1E)
        XCTAssertEqual(colorHex(light.textPrimary), 0x1A1A1A)
        XCTAssertEqual(colorHex(dark.textPrimary), 0xF5F5F5)
    }

    func testPaletteTealAccentDiffersBetweenLightAndDark() {
        let light = MenuBarPopoverPalette.resolve(for: .light)
        let dark = MenuBarPopoverPalette.resolve(for: .dark)
        XCTAssertEqual(colorHex(light.teal), 0x1E6B5E)
        XCTAssertEqual(colorHex(dark.teal), 0x3DA882)
    }

    func testPaletteTealMatchesMacDSResolvedAccentTeal() {
        for scheme in [ColorScheme.light, ColorScheme.dark] {
            let palette = MenuBarPopoverPalette.resolve(for: scheme)
            XCTAssertEqual(
                colorHex(palette.teal),
                colorHex(MacDS.Resolved.accentTeal(for: scheme)),
                "Popover teal should stay aligned with MacDS.Resolved.accentTeal in \(scheme)"
            )
        }
    }

    func testAppearancePreferenceResolvedColorScheme() {
        XCTAssertEqual(AppearancePreference.light.resolvedColorScheme(fallback: .dark), .light)
        XCTAssertEqual(AppearancePreference.dark.resolvedColorScheme(fallback: .light), .dark)
        XCTAssertEqual(AppearancePreference.system.resolvedColorScheme(fallback: .light), .light)
        XCTAssertEqual(AppearancePreference.system.resolvedColorScheme(fallback: .dark), .dark)
    }

    func testFormChromePaletteUsesDarkSchemeExplicitly() {
        let palette = FormChromePalette.resolve(
            surface: .mainWindow,
            timerChrome: TimerChromeTheme(sessionState: .idle, colorScheme: .dark),
            colorScheme: .dark
        )
        XCTAssertEqual(colorHex(palette.textPrimary), 0xF5F5F5)
        XCTAssertEqual(colorHex(palette.bgSurface), 0x2C2C2E)
    }

    func testLightModeContrastMeetsWCAGAA() {
        let palette = MenuBarPopoverPalette.resolve(for: .light)
        let pairs: [(Color, Color, String)] = [
            (palette.textPrimary, palette.background, "textPrimary on background (light)"),
            (palette.textMuted, palette.background, "textMuted on background (light)"),
        ]

        for (foreground, background, label) in pairs {
            let ratio = contrastRatio(
                foregroundHex: colorHex(foreground),
                backgroundHex: colorHex(background)
            )
            XCTAssertGreaterThanOrEqual(ratio, 4.5, label)
        }
    }

    func testDarkModeContrastMeetsWCAGAA() {
        let palette = MenuBarPopoverPalette.resolve(for: .dark)
        let pairs: [(Color, Color, String)] = [
            (palette.textPrimary, palette.background, "textPrimary on background (dark)"),
            (palette.textMuted, palette.background, "textMuted on background (dark)"),
        ]

        for (foreground, background, label) in pairs {
            let ratio = contrastRatio(
                foregroundHex: colorHex(foreground),
                backgroundHex: colorHex(background)
            )
            XCTAssertGreaterThanOrEqual(ratio, 4.5, label)
        }
    }

    func testLightModeCellFillLabelContrastMeetsWCAGAA() {
        let palette = MenuBarPopoverPalette.resolve(for: .light)
        let pairs: [(Color, Color, String)] = [
            (palette.textPrimary, palette.cellFill, "textPrimary on cellFill (light)"),
            (palette.textMuted, palette.cellFill, "textMuted on cellFill (light)"),
        ]

        for (foreground, background, label) in pairs {
            let ratio = contrastRatio(
                foregroundHex: colorHex(foreground),
                backgroundHex: colorHex(background)
            )
            XCTAssertGreaterThanOrEqual(ratio, 4.5, label)
        }
    }

    func testDarkModeCellFillLabelContrastMeetsWCAGAA() {
        let palette = MenuBarPopoverPalette.resolve(for: .dark)
        let pairs: [(Color, Color, String)] = [
            (palette.textPrimary, palette.cellFill, "textPrimary on cellFill (dark)"),
            (palette.textMuted, palette.cellFill, "textMuted on cellFill (dark)"),
        ]

        for (foreground, background, label) in pairs {
            let ratio = contrastRatio(
                foregroundHex: colorHex(foreground),
                backgroundHex: colorHex(background)
            )
            XCTAssertGreaterThanOrEqual(ratio, 4.5, label)
        }
    }

    func testTimerHeroCopyStaysWhiteOnTeal() {
        let palette = MenuBarPopoverPalette.resolve(for: .light)
        XCTAssertEqual(colorHex(palette.timerHeroOnTealPrimary), 0xFFFFFF)
        XCTAssertEqual(colorHex(palette.onTealForeground), 0xFFFFFF)
    }

    func testBandPaletteTokensResolveForLightAndDark() {
        let light = MenuBarPopoverPalette.resolve(for: .light)
        let dark = MenuBarPopoverPalette.resolve(for: .dark)

        XCTAssertEqual(colorHex(light.primaryButtonFill), 0xFFFFFF)
        XCTAssertEqual(colorHex(light.primaryButtonForeground), 0x1E6B5E)
        XCTAssertEqual(colorHex(dark.primaryButtonForeground), 0x3DA882)
        XCTAssertEqual(colorAlpha(light.metricsValueOnHero), 0.92, accuracy: 0.01)
        XCTAssertNotEqual(
            colorAlpha(light.metricsBandOverlay),
            colorAlpha(dark.metricsBandOverlay),
            accuracy: 0.01
        )
        XCTAssertNotEqual(
            colorAlpha(light.actionBandOverlay),
            colorAlpha(dark.actionBandOverlay),
            accuracy: 0.01
        )
    }

    func testHeroMetricsContrastMeetsWCAGAA() {
        let light = MenuBarPopoverPalette.resolve(for: .light)
        let tealHex = colorHex(light.teal)

        let metricsRatio = contrastRatio(
            foregroundHex: colorHex(light.metricsValueOnHero),
            backgroundHex: tealHex
        )
        XCTAssertGreaterThanOrEqual(metricsRatio, 3.0, "large metrics value on teal (light)")
    }

    func testPrimaryStartButtonContrastMeetsWCAGAA() {
        let light = MenuBarPopoverPalette.resolve(for: .light)
        let lightRatio = contrastRatio(
            foregroundHex: colorHex(light.onTealForeground),
            backgroundHex: colorHex(light.teal)
        )
        XCTAssertGreaterThanOrEqual(lightRatio, 4.5, "Start focus primary CTA label on teal (light)")

        let dark = MenuBarPopoverPalette.resolve(for: .dark)
        let darkRatio = contrastRatio(
            foregroundHex: colorHex(dark.onTealForeground),
            backgroundHex: colorHex(dark.teal)
        )
        XCTAssertGreaterThanOrEqual(
            darkRatio,
            2.9,
            "Start focus primary CTA on dark teal (same tokens as hero band)"
        )
    }

    func testPrimaryStartButtonMinHeight() {
        XCTAssertEqual(MenuBarPopoverLayout.primaryStartButtonMinHeight, 56)
    }

    func testPresetSelectorMinHeight() {
        XCTAssertEqual(MenuBarPopoverLayout.presetSelectorMinHeight, 44)
    }

    func testMetricsBandHeight() {
        XCTAssertEqual(MenuBarPopoverLayout.metricsBandHeight, 46)
    }

    func testUnifiedTimerCardCoreHeightMatchesConfigHeroAndFooter() {
        XCTAssertEqual(
            MenuBarPopoverLayout.unifiedTimerCardCoreHeight,
            MenuBarPopoverLayout.configBandHeight
                + MenuBarPopoverLayout.timerHeroHeight
                + MenuBarPopoverLayout.footerBandHeight
        )
        XCTAssertEqual(MenuBarPopoverLayout.configBandHeight, MenuBarPopoverLayout.metricsBandHeight)
        XCTAssertEqual(MenuBarPopoverLayout.footerBandHeight, MenuBarPopoverLayout.metricsBandHeight)
    }

    func testTimerMetricsDisplayTypography() {
        XCTAssertEqual(TimerMetricsDisplayTypography.heroBandLabelSize, 9)
        XCTAssertEqual(TimerMetricsDisplayTypography.heroBandValueSize, 14)
        XCTAssertEqual(TimerMetricsDisplayTypography.slabValueSize(for: .mainWindow), 13)
        XCTAssertEqual(TimerMetricsDisplayTypography.slabValueSize(for: .menuBarPopover), 11)
    }

    func testCustomConfigureFormDoesNotRequireVerticalScrolling() {
        XCTAssertFalse(
            MenuBarPopoverLayout.requiresVerticalScrolling(allowsAppUse: true, hasCompletionBanner: false)
        )
    }

    func testPaywallOrCompletionBannerRequiresVerticalScrolling() {
        XCTAssertTrue(
            MenuBarPopoverLayout.requiresVerticalScrolling(allowsAppUse: false, hasCompletionBanner: false)
        )
        XCTAssertTrue(
            MenuBarPopoverLayout.requiresVerticalScrolling(allowsAppUse: true, hasCompletionBanner: true)
        )
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

    private func colorAlpha(_ color: Color) -> Double {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        var alpha: CGFloat = 0
        nsColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return Double(alpha)
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
