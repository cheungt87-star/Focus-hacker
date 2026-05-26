@testable import FocusHacker
import SwiftUI
import XCTest

final class AppearancePreferenceTests: XCTestCase {
    func testDefaultPreferenceIsSystem() {
        let suiteName = "tests.appearancePreference.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected dedicated UserDefaults suite.")
            return
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: userDefaults, appGroupSuiteName: nil)

        XCTAssertEqual(store.appearancePreference, .system)

        store.appearancePreference = .dark
        XCTAssertEqual(store.appearancePreference, .dark)

        store.appearancePreference = .light
        XCTAssertEqual(store.appearancePreference, .light)

        store.appearancePreference = .system
        XCTAssertEqual(store.appearancePreference, .system)

        userDefaults.removePersistentDomain(forName: suiteName)
    }

    func testSymbolNameMapping() {
        XCTAssertEqual(AppearancePreference.system.symbolName, "display")
        XCTAssertEqual(AppearancePreference.light.symbolName, "sun.max.fill")
        XCTAssertEqual(AppearancePreference.dark.symbolName, "moon.fill")
    }

    func testPreferredColorSchemeMapping() {
        XCTAssertNil(AppearancePreference.system.preferredColorScheme)
        XCTAssertEqual(AppearancePreference.light.preferredColorScheme, .light)
        XCTAssertEqual(AppearancePreference.dark.preferredColorScheme, .dark)
    }

    func testEffectiveModeLabel() {
        XCTAssertEqual(
            AppearancePreference.system.effectiveModeLabel(resolvedColorScheme: .light),
            "System (Light)"
        )
        XCTAssertEqual(
            AppearancePreference.system.effectiveModeLabel(resolvedColorScheme: .dark),
            "System (Dark)"
        )
        XCTAssertEqual(AppearancePreference.light.effectiveModeLabel(resolvedColorScheme: .light), "Light")
        XCTAssertEqual(AppearancePreference.dark.effectiveModeLabel(resolvedColorScheme: .dark), "Dark")
    }

    func testMacDSContrastPairsMeetWCAGAA() {
        let pairs: [(UInt32, UInt32, String)] = [
            (0x1A1A1A, 0xFFFFFF, "textPrimary on cardBackground (light)"),
            (0x5C5C5C, 0xFAFAFA, "textSecondary on backgroundPrimary (light)"),
            (0xF5F5F5, 0x2C2C2E, "textPrimary on cardBackground (dark)"),
            (0xA8A8A8, 0x1C1C1E, "textSecondary on backgroundPrimary (dark)"),
        ]

        for (foreground, background, label) in pairs {
            let ratio = contrastRatio(foregroundHex: foreground, backgroundHex: background)
            XCTAssertGreaterThanOrEqual(ratio, 4.5, label)
        }
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
