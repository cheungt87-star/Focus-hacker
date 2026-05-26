import SwiftUI

/// Light/dark tokens for the Focus Session card (`focus-session-ui-prompt.md`).
struct FocusSessionScreenPalette: Equatable {
    let bgScreen: Color
    let bgSelector: Color
    let bgCyclePill: Color
    /// Timer band background; clear in dark mode.
    let bgTimer: Color
    let borderSelector: Color
    let borderStats: Color
    let borderScreen: Color?

    let textTitle: Color
    let textSubtitle: Color
    let textLabel: Color
    let textTimer: Color
    let textUpNext: Color
    let textStatsLabel: Color
    let textStatsValue: Color

    let accent: Color
    let accentColon: Color

    let ctaBackground: Color
    let ctaForeground: Color

    static func resolve(for colorScheme: ColorScheme) -> FocusSessionScreenPalette {
        switch colorScheme {
        case .dark:
            return FocusSessionScreenPalette(
                bgScreen: Color(hex: 0x111316),
                bgSelector: Color(hex: 0x0D1F13),
                bgCyclePill: Color(hex: 0x1A1D22),
                bgTimer: .clear,
                borderSelector: Color(hex: 0x4ADE80),
                borderStats: Color(hex: 0x1E2128),
                borderScreen: nil,
                textTitle: Color(hex: 0xF1F5F9),
                textSubtitle: Color(hex: 0x6EE7A0),
                textLabel: Color(hex: 0x666666),
                textTimer: Color(hex: 0xF1F5F9),
                textUpNext: Color(hex: 0x64748B),
                textStatsLabel: Color(hex: 0x4A5568),
                textStatsValue: Color(hex: 0x64748B),
                accent: Color(hex: 0x4ADE80),
                accentColon: Color(hex: 0x4ADE80).opacity(0.8),
                ctaBackground: Color(hex: 0x4ADE80),
                ctaForeground: Color(hex: 0x0A1F0D)
            )
        case .light:
            fallthrough
        @unknown default:
            return FocusSessionScreenPalette(
                bgScreen: Color(hex: 0xEAEAEA),
                bgSelector: Color(hex: 0xF0FAF3),
                bgCyclePill: Color(hex: 0xE8F5EC),
                bgTimer: Color(hex: 0xEAEAEA),
                borderSelector: Color(hex: 0x16A34A),
                borderStats: Color(hex: 0xE2E8E2),
                borderScreen: Color(hex: 0xE2E8E2),
                textTitle: Color(hex: 0x1A1A1A),
                textSubtitle: Color(hex: 0x16A34A),
                textLabel: Color(hex: 0x9AA89A),
                textTimer: Color(hex: 0x111827),
                textUpNext: Color(hex: 0x94A3B8),
                textStatsLabel: Color(hex: 0xB0BEC5),
                textStatsValue: Color(hex: 0x94A3B8),
                accent: Color(hex: 0x16A34A),
                accentColon: Color(hex: 0x16A34A),
                ctaBackground: Color(hex: 0x16A34A),
                ctaForeground: Color.white
            )
        }
    }
}

private struct FocusSessionScreenPaletteKey: EnvironmentKey {
    static let defaultValue = FocusSessionScreenPalette.resolve(for: .light)
}

extension EnvironmentValues {
    var focusSessionScreenPalette: FocusSessionScreenPalette {
        get { self[FocusSessionScreenPaletteKey.self] }
        set { self[FocusSessionScreenPaletteKey.self] = newValue }
    }
}
