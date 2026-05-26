import AppKit
import SwiftUI

// MARK: - Foundation palette (design-system-revised v2)

extension Color {
    static let fhColorEmber = Color(hex: 0xFF4757)
    static let fhColorEmberLight = Color(hex: 0xFF6B7A)
    static let fhColorCharcoal = Color(hex: 0x2F3542)
    static let fhColorMint = Color(hex: 0x00D2D3)
    static let fhColorMintLight = Color(hex: 0x00E5E6)
    static let fhColorCloud = Color(hex: 0xF0F4F8)
    static let fhColorRestPanel = Color(hex: 0xE8F1F7)
    static let fhColorGold = Color(hex: 0xFFD93D)
    static let fhColorPurple = Color(hex: 0xA55EEA)
    static let fhColorPowerBlue = Color(hex: 0x6C5CE7)
    static let fhColorSunny = Color(hex: 0xFDCB6E)
    /// Timer hero “work” slab (brutalist / high-contrast block UI).
    static let fhBrutalistLime = Color(hex: 0xC8FF3D)
    static let fhColorCoral = Color(hex: 0xFF7675)
    static let fhColorAqua = Color(hex: 0x00B894)
    static let fhColorDeep = Color(hex: 0x2F3542)
    static let fhColorMedium = Color(hex: 0x636E72)
    static let fhColorLight = Color(hex: 0xDFE6E9)
    static let fhColorWhite = Color(hex: 0xFFFFFF)
    static let fhColorDarkBg = Color(hex: 0x363A47)
    /// Timer slab footer strip (TimerPlus-style near-black bar).
    static let fhColorTimerFooter = Color(hex: 0x121212)

    // MARK: design-system.html foundation tokens (timer footer columns + up-next accents)

    /// HTML `--color-carbon`
    static let fhColorDSCarbon = Color(hex: 0x2C2C2E)
    /// HTML `--bg-surface`
    static let fhColorDSSurface = Color(hex: 0x363638)
    /// HTML `--color-stone`
    static let fhColorDSStone = Color(hex: 0x48484A)
    /// HTML `--color-ember` (distinct from app `fhColorEmber`)
    static let fhColorDSEmber = Color(hex: 0xF2622E)
    /// HTML `--color-slate`
    static let fhColorDSSlate = Color(hex: 0x2E86AB)
    /// HTML `--color-smoke`
    static let fhColorDSSmoke = Color(hex: 0x8E8E93)

    /// Timer slab “Up next” column — dark tints keyed to upcoming phase (readable with white caption).
    static let fhColorDSUpNextFocusBg = Color(hex: 0x1E3D2A)
    static let fhColorDSUpNextShortRestBg = Color(hex: 0x3A1F22)
    static let fhColorDSUpNextLongRestBg = Color(hex: 0x1E2D3D)

    static let fhColorSurface = Color(hex: 0x484F5A)
    static let fhColorRestBorder = Color(hex: 0xB8D9E8)
    static let fhColorRestTextPrimary = Color(hex: 0x1A2B35)
    static let fhColorRestTextSecondary = Color(hex: 0x4A6B7A)
    static let fhColorRestPlaceholder = Color(hex: 0x8AADBE)

    /// Legacy names kept for call sites; values updated to v2 where applicable.
    static let fhColorXpGold = fhColorGold
    static let fhColorXpDark = Color(hex: 0xC9A227)
    static let fhColorSlate = fhColorMint

    // MARK: Global shell (focus-default): sidebar, settings, chrome when not using `TimerChromeTheme.rest`

    static let fhBgApp = fhColorCharcoal
    static let fhBgPanel = fhColorDarkBg
    static let fhBgSurface = fhColorSurface
    static let fhBorderDefault = fhColorMedium
    static let fhTextPrimary = fhColorWhite
    static let fhTextSecondary = fhColorLight
    static let fhTextPlaceholder = fhColorMedium
    static let fhAccentPrimary = fhColorEmber
    static let fhAccentHover = fhColorEmberLight
    static let fhAccentTimer = fhColorEmber
}

// MARK: - Session chrome (maps to HTML `[data-mode="focus"]` / `[data-mode="rest"]`)

struct TimerChromeTheme: Equatable, Sendable {
    let bgApp: Color
    let bgPanel: Color
    let bgSurface: Color
    let borderDefault: Color
    let textPrimary: Color
    let textSecondary: Color
    let textPlaceholder: Color
    let accentPrimary: Color
    let accentHover: Color
    let slabHeaderBackground: Color
    let slabFooterBackground: Color
    let slabHeaderPrimaryForeground: Color
    let slabHeaderSecondaryForeground: Color
    let slabFooterPrimaryForeground: Color
    let slabFooterSecondaryForeground: Color

    var accentTimer: Color { accentPrimary }

    var inputFocusRingColor: Color { accentPrimary }

    init(sessionState: AppShellSessionState, colorScheme: ColorScheme) {
        let isDark = colorScheme == .dark
        let isRest = sessionState == .rest

        switch (isRest, isDark) {
        case (false, false):
            bgApp = .fhColorCharcoal
            bgPanel = .fhColorDarkBg
            bgSurface = .fhColorSurface
            borderDefault = .fhColorMedium
            textPrimary = .fhColorWhite
            textSecondary = .fhColorLight
            textPlaceholder = .fhColorMedium
            accentPrimary = .fhColorEmber
            accentHover = .fhColorEmberLight
            slabHeaderBackground = .fhColorCharcoal
            slabFooterBackground = .fhColorTimerFooter
            slabHeaderPrimaryForeground = .fhColorWhite
            slabHeaderSecondaryForeground = Color.white.opacity(0.72)
            slabFooterPrimaryForeground = .fhColorWhite
            slabFooterSecondaryForeground = Color.white.opacity(0.76)
        case (false, true):
            bgApp = Color(hex: 0x1A1D24)
            bgPanel = Color(hex: 0x252930)
            bgSurface = Color(hex: 0x3A4049)
            borderDefault = Color(hex: 0x4A4F58)
            textPrimary = .fhColorWhite
            textSecondary = Color(hex: 0xC8CDD3)
            textPlaceholder = Color(hex: 0x8A9199)
            accentPrimary = .fhColorEmber
            accentHover = .fhColorEmberLight
            slabHeaderBackground = Color(hex: 0x14171C)
            slabFooterBackground = Color(hex: 0x0A0A0A)
            slabHeaderPrimaryForeground = .fhColorWhite
            slabHeaderSecondaryForeground = Color.white.opacity(0.72)
            slabFooterPrimaryForeground = .fhColorWhite
            slabFooterSecondaryForeground = Color.white.opacity(0.76)
        case (true, false):
            bgApp = .fhColorCloud
            bgPanel = .fhColorRestPanel
            bgSurface = .fhColorWhite
            borderDefault = .fhColorRestBorder
            textPrimary = .fhColorRestTextPrimary
            textSecondary = .fhColorRestTextSecondary
            textPlaceholder = .fhColorRestPlaceholder
            accentPrimary = .fhColorMint
            accentHover = .fhColorMintLight
            slabHeaderBackground = .fhColorCharcoal
            slabFooterBackground = .fhColorTimerFooter
            slabHeaderPrimaryForeground = .fhColorWhite
            slabHeaderSecondaryForeground = Color.white.opacity(0.72)
            slabFooterPrimaryForeground = .fhColorWhite
            slabFooterSecondaryForeground = Color.white.opacity(0.76)
        case (true, true):
            bgApp = Color(hex: 0x1A2332)
            bgPanel = Color(hex: 0x222D3A)
            bgSurface = Color(hex: 0x2A3848)
            borderDefault = Color(hex: 0x3A5060)
            textPrimary = Color(hex: 0xE8F1F7)
            textSecondary = Color(hex: 0x8AADBE)
            textPlaceholder = Color(hex: 0x6A8A9A)
            accentPrimary = .fhColorMint
            accentHover = .fhColorMintLight
            slabHeaderBackground = Color(hex: 0x141C28)
            slabFooterBackground = Color(hex: 0x0A0A0A)
            slabHeaderPrimaryForeground = .fhColorWhite
            slabHeaderSecondaryForeground = Color.white.opacity(0.72)
            slabFooterPrimaryForeground = .fhColorWhite
            slabFooterSecondaryForeground = Color.white.opacity(0.76)
        }
    }
}

// MARK: - Typography (Inter + IBM Plex Mono when bundled; safe fallbacks)

enum FocusHackerFontFamily {
    /// PostScript / font file name for IBM Plex Mono Bold (add font to app bundle for exact match).
    static let ibmPlexMonoBold = "IBMPlexMono-Bold"
    static let interRegular = "Inter-Regular"
    static let interMedium = "Inter-Medium"
    static let interSemibold = "Inter-SemiBold"
}

extension Font {
    private static func customIfAvailable(_ name: String, size: CGFloat, fallback: Font) -> Font {
        #if os(macOS)
        if NSFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        }
        #endif
        return fallback
    }

    static var fhDisplay: Font {
        customIfAvailable(FocusHackerFontFamily.interSemibold, size: 48, fallback: .system(size: 48, weight: .bold, design: .default))
    }

    static var fhTitle: Font {
        customIfAvailable(FocusHackerFontFamily.interSemibold, size: 28, fallback: .system(size: 28, weight: .semibold, design: .default))
    }

    static var fhHeading: Font {
        customIfAvailable(FocusHackerFontFamily.interSemibold, size: 18, fallback: .system(size: 18, weight: .semibold, design: .default))
    }

    static var fhBody: Font {
        customIfAvailable(FocusHackerFontFamily.interRegular, size: 15, fallback: .system(size: 15, weight: .regular, design: .default))
    }

    static var fhCaption: Font {
        customIfAvailable(FocusHackerFontFamily.interRegular, size: 12, fallback: .system(size: 12, weight: .regular, design: .default))
    }

    /// Countdown digits; size typically 72…96 from layout.
    static func fhTimer(size: CGFloat) -> Font {
        customIfAvailable(
            FocusHackerFontFamily.ibmPlexMonoBold,
            size: size,
            fallback: .system(size: size, weight: .bold, design: .monospaced)
        )
    }

    static var fhTimer: Font { fhTimer(size: 80) }

    static var fhXp: Font {
        customIfAvailable(FocusHackerFontFamily.ibmPlexMonoBold, size: 22, fallback: .system(size: 22, weight: .semibold, design: .monospaced))
    }

    static var fhXpBadge: Font {
        customIfAvailable(FocusHackerFontFamily.ibmPlexMonoBold, size: 12, fallback: .system(size: 12, weight: .bold, design: .monospaced))
    }
}

// MARK: - Layout tokens

enum DesignSpacing {
    static let spacing1: CGFloat = 4
    static let spacing2: CGFloat = 8
    static let spacing3: CGFloat = 12
    static let spacing4: CGFloat = 16
    static let spacing5: CGFloat = 20
    static let spacing6: CGFloat = 24
    static let spacing8: CGFloat = 32
    static let spacing10: CGFloat = 40
    static let spacing12: CGFloat = 48
    static let spacing16: CGFloat = 64
}

enum DesignRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
}

enum FocusHackerMotion {
    static let easeFast = Animation.easeOut(duration: 0.15)
    static let easeNormal = Animation.easeInOut(duration: 0.3)
    static let easeSlow = Animation.easeInOut(duration: 0.5)
}

private struct TimerChromeThemeKey: EnvironmentKey {
    static let defaultValue = TimerChromeTheme(sessionState: .idle, colorScheme: .light)
}

extension EnvironmentValues {
    var timerChromeTheme: TimerChromeTheme {
        get { self[TimerChromeThemeKey.self] }
        set { self[TimerChromeThemeKey.self] = newValue }
    }
}

// MARK: - Brutalist timer controls (main window + menu bar popover)

struct TimerBrutalistPrimarySlabButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .heavy))
            .textCase(.uppercase)
            .tracking(0.65)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(fill.opacity(configuration.isPressed ? 0.9 : 1))
            )
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

struct TimerBrutalistOutlineButtonStyle: ButtonStyle {
    let theme: TimerChromeTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.55)
            .foregroundStyle(theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(theme.borderDefault.opacity(0.9), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 2).fill(Color.clear))
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

struct TimerBrutalistGhostButtonStyle: ButtonStyle {
    let theme: TimerChromeTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.45)
            .foregroundStyle(theme.textSecondary.opacity(configuration.isPressed ? 1 : 0.88))
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

// MARK: - WCAG 2.1 AA quick reference
//
// Minimum contrast ratios (foreground : background):
//   • Normal text (< 18pt / < 14pt bold): 4.5 : 1
//   • Large text  (≥ 18pt / ≥ 14pt bold): 3.0 : 1
//   • UI components & input borders:       3.0 : 1
//
// Avoid extremes in dark mode:
//   • Pure white (#FFF) on dark backgrounds exceeds ~15 : 1 — causes eye fatigue.
//     Use off-white (e.g. #E8E8E8) to stay in the 7–12 : 1 sweet spot.
//   • Pure black (#000) backgrounds cause halation on OLED. Prefer #1C1C1E or darker.
//
// Accent colour rule — one hex rarely works in both modes:
//   • Light mode: use a *darker, more saturated* value to achieve 4.5 : 1 on white cards.
//   • Dark mode:  use a *lighter, less saturated* value to avoid neon bloom on dark surfaces.
//   Define separate light/dark stops and swap via macDSAdaptive.
//
// Input fields:
//   • Do NOT use pure white (#FFF) fields on light-grey backgrounds — the ~15 : 1 jump
//     breaks visual hierarchy and causes eye fatigue. Aim for a warm elevated surface
//     (~2–4 lightness steps above the page background).
//   • Input borders must meet 3 : 1 against the surrounding surface (WCAG 1.4.11).
//
// Focus rings:
//   • Focus ring colour must be 3 : 1 against both the background AND the unfocused border.
//   • Minimum ring: 2 px solid, offset 2 px so it sits outside the component border.
//
// Sidebar separation:
//   • Without a visible border or background difference, sidebar and content read as
//     one flat surface. Minimum delta: ~6 lightness units (e.g. #F5F3F0 → #E6E4DC).
//
// Motion / reduced-motion:
//   • Always wrap animations in @media (prefers-reduced-motion: reduce) equivalents.
//     In SwiftUI, check AccessibilityReduceMotion and skip or shorten animations.

// MARK: - macOS design system (FocusHacker main app windows)

enum MacDS {
    enum Color {
        // Page background. Warm off-white avoids harsh pure-white glare.
        // Dark: #1C1C1E — standard macOS dark base, not pure black.
        static let backgroundPrimary = SwiftUI.Color.macDSAdaptive(light: 0xF0EEE8, dark: 0x1C1C1E)

        // Sidebar must be visibly darker than backgroundPrimary to create separation.
        // Light delta: F0EEE8 → E6E4DC (~6 lightness units). Dark: one step lighter than page.
        static let sidebarBackground = SwiftUI.Color.macDSAdaptive(light: 0xE6E4DC, dark: 0x252528)

        // 1A1A1A on F0EEE8 ≈ 15.2 : 1 (well above AA). F5F5F5 on 1C1C1E ≈ 14.2 : 1.
        static let textPrimary = SwiftUI.Color.macDSAdaptive(light: 0x1A1A1A, dark: 0xF5F5F5)

        // Readable secondary copy — WCAG AA at 12pt+.
        // 5C5C5C on FFFFFF ≈ 5.9 : 1. A8A8A8 on 1C1C1E ≈ 5.1 : 1.
        static let textSecondary = SwiftUI.Color.macDSAdaptive(light: 0x5C5C5C, dark: 0xA8A8A8)

        // Non-essential metadata only (timestamps, counts). NOT for instructional copy.
        // A8A8A8 on FFFFFF ≈ 2.3 : 1 — fails AA. Use only at 18pt+ or with a secondary cue.
        static let textTertiary = SwiftUI.Color.macDSAdaptive(light: 0xA8A8A8, dark: 0x6E6E6E)

        // Disabled state. Intentionally low contrast to signal non-interactivity.
        static let textDisabled = SwiftUI.Color.macDSAdaptive(light: 0x8A8A8A, dark: 0x5C5C5C)

        // White cards on warm-grey page create clear elevation depth.
        static let cardBackground = SwiftUI.Color.macDSAdaptive(light: 0xFFFFFF, dark: 0x2C2C2E)

        // Border: must hit 3 : 1 against adjacent surfaces (WCAG 1.4.11).
        static let border = SwiftUI.Color.macDSAdaptive(light: 0xD0D0D0, dark: 0x48484A)
        static let dividerLight = SwiftUI.Color.macDSAdaptive(light: 0xEFEFEF, dark: 0x3A3A3C)
        static let progressTrack = SwiftUI.Color.macDSAdaptive(light: 0xD4D4D4, dark: 0x3A3A3C)
        static let surfaceDisabled = SwiftUI.Color.macDSAdaptive(light: 0xE8E6E1, dark: 0x3A3A3C)

        // Primary accent — teal, split across modes (see WCAG note above).
        // Light 1E6B5E on FFFFFF ≈ 6.3 : 1 (AA ✓, approaches AAA). Deeper, avoids the neon clash.
        // Dark  3DA882 on 1C1C1E ≈ 5.5 : 1 (AA ✓). Desaturated to prevent bloom on dark backgrounds.
        static let accentTeal = SwiftUI.Color.macDSAdaptive(light: 0x1E6B5E, dark: 0x3DA882)

        // Hover / secondary teal. Used for hover states and progress rings.
        // Do NOT use accentTealLight as standalone text — fails AA at body sizes.
        static let accentTealLight = SwiftUI.Color.macDSAdaptive(light: 0x2A8A7A, dark: 0x4DB894)

        // Tint fills for selected states and tinted surfaces. Text on these must use accentTeal.
        static let accentTealLighter = SwiftUI.Color.macDSAdaptive(light: 0x4AB0A0, dark: 0x5DC4A8)
        static let accentTealLightest = SwiftUI.Color.macDSAdaptive(light: 0xC5E0D8, dark: 0x1E3D30)

        // Orange for paused state / warnings. F5A623 on white ≈ 2.5 : 1 — large text / icon only.
        static let accentOrange = SwiftUI.Color.macDSAdaptive(light: 0xC87A10, dark: 0xF5A623)

        // Purple for XP celebrations and level-ups.
        static let accentPurple = SwiftUI.Color.macDSAdaptive(light: 0xB896FF, dark: 0xC4A8FF)

        static let secondaryButtonBackground = SwiftUI.Color.macDSAdaptive(light: 0xE8E6DF, dark: 0x3A3A3C)
        static let pillBackground = SwiftUI.Color.macDSAdaptive(light: 0xE8E6E1, dark: 0x48484A)
        static let sidebarActiveBackground = SwiftUI.Color.macDSAdaptive(light: 0xDDDBD3, dark: 0x3A3A3C)

        static let heroGradientStart = SwiftUI.Color.macDSAdaptive(light: 0x1A1A1A, dark: 0x0D0D0D)
        static let heroGradientEnd = SwiftUI.Color.macDSAdaptive(light: 0x2A2A2A, dark: 0x1A1A1A)

        // Input fields: warm elevated surface — NOT pure white on light, NOT pure dark on dark.
        // Light F0EEE8 → inputs sit at F8F6F2 (visibly lifted without harsh white contrast).
        // Dark 2C2C2E is one elevation above the 1C1C1E page base.
        // Input border (#C8C6BF light, #48484A dark) must be 3 : 1 against the input surface.
        static let inputBackground = SwiftUI.Color.macDSAdaptive(light: 0xF8F6F2, dark: 0x2C2C2E)
        static let inputBorder = SwiftUI.Color.macDSAdaptive(light: 0xC8C6BF, dark: 0x48484A)

        // Destructive: light value deepened to pass 4.5 : 1 on white. C0392B on #FFF ≈ 5.1 : 1 ✓.
        static let destructive = SwiftUI.Color.macDSAdaptive(light: 0xC0392B, dark: 0xE74C3C)
    }

    enum Radius {
        static let standard: CGFloat = 8
        static let card: CGFloat = 12
        static let pill: CGFloat = 20
    }

    enum Layout {
        static let sidebarWidth: CGFloat = 240
        static let sidebarNavRowHeight: CGFloat = 44
    }

    enum Shadow {
        static let smRadius: CGFloat = 3
        static let smOpacity: Double = 0.08
        static let mdRadius: CGFloat = 8
        static let mdOpacity: Double = 0.12
        static let darkSmOpacity: Double = 0.25
        static let darkMdOpacity: Double = 0.35

        static func color(elevated: Bool) -> SwiftUI.Color {
            SwiftUI.Color.macDSAdaptiveOpacity(
                light: elevated ? mdOpacity : smOpacity,
                dark: elevated ? darkMdOpacity : darkSmOpacity
            )
        }
    }

    /// Scheme-explicit colors for `MenuBarExtra` and other surfaces that cannot use `MacDS.Color` adaptive providers.
    enum Resolved {
        static func backgroundPrimary(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xF0EEE8, dark: 0x1C1C1E, for: colorScheme)
        }

        static func textPrimary(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0x1A1A1A, dark: 0xF5F5F5, for: colorScheme)
        }

        static func textSecondary(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0x5C5C5C, dark: 0xA8A8A8, for: colorScheme)
        }

        static func textTertiary(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xA8A8A8, dark: 0x6E6E6E, for: colorScheme)
        }

        static func cardBackground(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xFFFFFF, dark: 0x2C2C2E, for: colorScheme)
        }

        static func border(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xD0D0D0, dark: 0x48484A, for: colorScheme)
        }

        static func accentTeal(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0x1E6B5E, dark: 0x3DA882, for: colorScheme)
        }

        static func accentTealLight(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0x2A8A7A, dark: 0x4DB894, for: colorScheme)
        }

        static func accentTealLightest(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xC5E0D8, dark: 0x1E3D30, for: colorScheme)
        }

        static func inputBackground(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xF8F6F2, dark: 0x2C2C2E, for: colorScheme)
        }

        static func inputBorder(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xC8C6BF, dark: 0x48484A, for: colorScheme)
        }

        static func pillBackground(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xE8E6E1, dark: 0x48484A, for: colorScheme)
        }

        static func surfaceDisabled(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xE8E6E1, dark: 0x3A3A3C, for: colorScheme)
        }

        /// Border for tinted teal cell surfaces (popover stat cards, preset carousel).
        static func accentTealCellBorder(for colorScheme: ColorScheme) -> SwiftUI.Color {
            SwiftUI.Color.macDSResolved(light: 0xA8D0C8, dark: 0x2A5048, for: colorScheme)
        }
    }
}

extension Font {
    static var macDSPageTitle: Font { .system(size: 28, weight: .bold) }
    static var macDSSectionHeading: Font { .system(size: 18, weight: .bold) }
    static var macDSCardTitle: Font { .system(size: 16, weight: .semibold) }
    static var macDSBody: Font { .system(size: 14, weight: .regular) }
    static var macDSLabel: Font { .system(size: 12, weight: .medium) }
    /// Helper / instructional copy on light cards (12pt, AA contrast with textSecondary).
    static var macDSHelper: Font { .system(size: 12, weight: .regular) }
    static var macDSCaption: Font { .system(size: 11, weight: .regular) }

    static func macDSTimerDigits(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

enum AppUISurface: Equatable, Sendable {
    case mainWindow
    case menuBarPopover
}

private struct AppUISurfaceKey: EnvironmentKey {
    static let defaultValue: AppUISurface = .mainWindow
}

private struct MenuBarExtraWindowKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var appUISurface: AppUISurface {
        get { self[AppUISurfaceKey.self] }
        set { self[AppUISurfaceKey.self] = newValue }
    }

    /// When true, action menus render in-window (required for `MenuBarExtra` popovers).
    var menuBarExtraWindow: Bool {
        get { self[MenuBarExtraWindowKey.self] }
        set { self[MenuBarExtraWindowKey.self] = newValue }
    }
}

/// Resolves form field colors for main-window (MacDS) vs menu bar popover (session chrome).
struct FormChromePalette: Equatable, Sendable {
    let textPrimary: Color
    let textSecondary: Color
    let bgSurface: Color
    let borderDefault: Color
    let inputFocusRingColor: Color

    static func resolve(surface: AppUISurface, timerChrome: TimerChromeTheme, colorScheme: ColorScheme = .light) -> FormChromePalette {
        switch surface {
        case .mainWindow:
            // bgSurface: warm elevated surface (not pure white) — avoids 15 : 1 contrast blast.
            // inputFocusRingColor: matches accentTeal split values — 6.3 : 1 light, 5.5 : 1 dark.
            // Focus ring should be rendered at 2 px with 2 px offset (see WCAG 2.4.11 — Focus Appearance).
            return FormChromePalette(
                textPrimary: MacDS.Resolved.textPrimary(for: colorScheme),
                textSecondary: MacDS.Resolved.textSecondary(for: colorScheme),
                bgSurface: MacDS.Resolved.inputBackground(for: colorScheme),
                borderDefault: MacDS.Resolved.inputBorder(for: colorScheme),
                inputFocusRingColor: MacDS.Resolved.accentTeal(for: colorScheme)
            )
        case .menuBarPopover:
            return FormChromePalette(
                textPrimary: timerChrome.textPrimary,
                textSecondary: timerChrome.textSecondary,
                bgSurface: timerChrome.bgSurface,
                borderDefault: timerChrome.borderDefault,
                inputFocusRingColor: timerChrome.inputFocusRingColor
            )
        }
    }
}

// MARK: - Timer metrics display (supporting numbers — not hero countdown)

enum TimerMetricsDisplayTypography {
    static let heroBandLabelSize: CGFloat = 9
    static let heroBandValueSize: CGFloat = 14
    static let valueWeight: Font.Weight = .semibold

    static func slabValueSize(for layout: TimerThreeRowSlabLayout) -> CGFloat {
        switch layout {
        case .mainWindow:
            return 13
        case .menuBarPopover:
            return 11
        }
    }
}

// MARK: - Timer slab appearance (layout-specific visuals)

struct TimerSlabAppearance: Equatable {
    let cornerRadius: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    let headerBackground: Color
    let headerPrimaryForeground: Color
    let headerSecondaryForeground: Color
    let heroBackground: Color
    let heroForeground: Color
    let footerBackground: Color
    let footerColumnCarbon: Color
    let footerColumnStone: Color
    let footerLabelTint: Color
    let footerPrimaryForeground: Color
    let footerSecondaryForeground: Color
    let upNextColumnBackground: Color
    let upNextAccent: Color
    let usesUppercaseLabels: Bool
    let usesBrutalistControls: Bool

    @MainActor
    static func make(layout: TimerThreeRowSlabLayout, viewModel: AppShellViewModel, colorScheme: ColorScheme = .light) -> TimerSlabAppearance {
        _ = layout
        _ = colorScheme
        return mainWindow(viewModel: viewModel)
    }

    @MainActor
    private static func mainWindow(viewModel: AppShellViewModel) -> TimerSlabAppearance {
        let heroAccent = mainWindowHeroAccent(
            sessionState: viewModel.state.sessionState,
            intervalPhase: viewModel.state.intervalPhase,
            isPaused: viewModel.state.isSessionPaused
        )
        return TimerSlabAppearance(
            cornerRadius: MacDS.Radius.card,
            strokeColor: MacDS.Color.border,
            strokeWidth: 1,
            headerBackground: MacDS.Color.heroGradientStart,
            headerPrimaryForeground: .white,
            headerSecondaryForeground: .white.opacity(0.72),
            heroBackground: heroAccent,
            heroForeground: .white,
            footerBackground: MacDS.Color.heroGradientEnd,
            footerColumnCarbon: MacDS.Color.heroGradientStart.opacity(0.85),
            footerColumnStone: MacDS.Color.heroGradientStart.opacity(0.7),
            footerLabelTint: .white.opacity(0.55),
            footerPrimaryForeground: .white,
            footerSecondaryForeground: .white.opacity(0.76),
            upNextColumnBackground: MacDS.Color.accentTeal.opacity(0.35),
            upNextAccent: MacDS.Color.accentTealLighter,
            usesUppercaseLabels: false,
            usesBrutalistControls: false
        )
    }

    private static func mainWindowHeroAccent(
        sessionState: AppShellSessionState,
        intervalPhase: TimerIntervalPhase?,
        isPaused: Bool
    ) -> Color {
        if isPaused {
            return MacDS.Color.accentOrange.opacity(0.85)
        }
        switch sessionState {
        case .idle:
            return MacDS.Color.accentTeal
        case .focus:
            return MacDS.Color.accentTeal
        case .rest:
            switch intervalPhase {
            case .shortRest:
                return MacDS.Color.accentTealLight
            case .longRest:
                return MacDS.Color.accentOrange.opacity(0.9)
            case .focus, .none:
                return MacDS.Color.accentTealLight
            }
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex & 0xFF0000) >> 16) / 255
        let green = Double((hex & 0x00FF00) >> 8) / 255
        let blue = Double(hex & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    static func macDSResolved(light: UInt32, dark: UInt32, for colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? dark : light)
    }

    static func macDSAdaptive(light: UInt32, dark: UInt32) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let hex = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(hex: hex)
        }))
        #else
        return Color(hex: light)
        #endif
    }

    static func macDSAdaptiveOpacity(light: Double, dark: Double) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let opacity = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor.black.withAlphaComponent(opacity)
        }))
        #else
        return Color.black.opacity(light)
        #endif
    }
}

#if os(macOS)
private extension NSColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hex & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
#endif

// MARK: - MacDS SwiftUI components (main app windows)

extension View {
    func macDSCardShadow(elevated: Bool = false) -> some View {
        shadow(
            color: MacDS.Shadow.color(elevated: elevated),
            radius: elevated ? MacDS.Shadow.mdRadius : MacDS.Shadow.smRadius,
            y: elevated ? 2 : 1
        )
    }

    func macDSPagePadding() -> some View {
        padding(DesignSpacing.spacing8)
    }

    /// Instructional and helper copy on light MacDS surfaces.
    func macDSHelperText() -> some View {
        font(.macDSHelper)
            .foregroundStyle(MacDS.Color.textSecondary)
    }
}

struct MacDSCard<Content: View>: View {
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(DesignSpacing.spacing5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: MacDS.Radius.card)
                    .fill(MacDS.Color.cardBackground)
            }
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.card)
                    .stroke(MacDS.Color.border, lineWidth: 1)
            )
            .macDSCardShadow(elevated: elevated)
    }
}

struct MacDSHeroCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(DesignSpacing.spacing8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [MacDS.Color.heroGradientStart, MacDS.Color.heroGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
            .macDSCardShadow()
    }
}

struct MacDSSectionHeader: View {
    let title: String
    var showsUnderline: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text(title)
                .font(.macDSSectionHeading)
                .foregroundStyle(MacDS.Color.textPrimary)
            if showsUnderline {
                Rectangle()
                    .fill(MacDS.Color.accentTeal)
                    .frame(height: 2)
                    .frame(maxWidth: 120)
            }
        }
    }
}

struct MacDSSidebarNavItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.spacing2) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MacDS.Color.accentTeal)
                        .frame(width: 3)
                } else {
                    Color.clear.frame(width: 3)
                }
                Label(title, systemImage: systemImage)
                    .font(.macDSBody.weight(isSelected ? .medium : .regular))
                    .foregroundStyle(
                        isSelected ? MacDS.Color.accentTeal : MacDS.Color.textPrimary.opacity(0.72)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DesignSpacing.spacing3)
            .frame(height: MacDS.Layout.sidebarNavRowHeight)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(isSelected ? MacDS.Color.sidebarActiveBackground : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MacDSTabBar<Tab: Hashable & Identifiable>: View where Tab: CaseIterable, Tab.AllCases: RandomAccessCollection {
    let tabs: Tab.AllCases
    @Binding var selection: Tab
    let title: (Tab) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs), id: \.id) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: DesignSpacing.spacing2) {
                        Text(title(tab))
                            .font(.macDSBody.weight(selection == tab ? .medium : .regular))
                            .foregroundStyle(
                                selection == tab
                                    ? MacDS.Color.textPrimary
                                    : MacDS.Color.textPrimary.opacity(0.62)
                            )
                        Rectangle()
                            .fill(selection == tab ? MacDS.Color.accentTeal : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSpacing.spacing3)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MacDS.Color.dividerLight)
                .frame(height: 1)
        }
    }
}

struct MacDSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.macDSBody.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(
                        configuration.isPressed
                            ? MacDS.Color.accentTealLight
                            : MacDS.Color.accentTeal
                    )
            )
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

struct MacDSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.macDSBody.weight(.medium))
            .foregroundStyle(MacDS.Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(MacDS.Color.secondaryButtonBackground.opacity(configuration.isPressed ? 0.9 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(MacDS.Color.border, lineWidth: 1)
            )
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

struct MacDSDestructiveOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MacDSDestructiveOutlineButtonLabel(configuration: configuration)
    }
}

private struct MacDSDestructiveOutlineButtonLabel: View {
    let configuration: ButtonStyle.Configuration
    @State private var isHovered = false

    private var fillOpacity: Double {
        if configuration.isPressed {
            return 0.12
        }
        if isHovered {
            return 0.08
        }
        return 0
    }

    var body: some View {
        configuration.label
            .font(.macDSBody.weight(.medium))
            .foregroundStyle(MacDS.Color.destructive)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(MacDS.Color.destructive.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(MacDS.Color.destructive, lineWidth: 1)
            )
            .onHover { isHovered = $0 }
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
            .animation(FocusHackerMotion.easeFast, value: isHovered)
    }
}

struct MacDSGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.macDSLabel)
            .foregroundStyle(
                MacDS.Color.textSecondary.opacity(configuration.isPressed ? 0.75 : 1)
            )
            .padding(.vertical, DesignSpacing.spacing2)
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

struct MacDSPillTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(MacDS.Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(MacDS.Color.pillBackground))
    }
}

struct MacDSProgressBar: View {
    let fraction: Double
    var tint: Color = MacDS.Color.accentTeal

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(MacDS.Color.progressTrack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(MacDS.Color.border, lineWidth: 1)
                    )
                RoundedRectangle(cornerRadius: 4)
                    .fill(tint)
                    .frame(width: max(0, geometry.size.width * min(1, max(0, fraction))))
            }
        }
        .frame(height: 8)
    }
}

struct MacDSCircularProgressRing: View {
    let fraction: Double
    let percentDisplay: Int
    var diameter: CGFloat = 112
    var lineWidth: CGFloat = 8
    var tint: Color = MacDS.Color.accentTeal
    var centerColor: Color = MacDS.Color.textPrimary
    var centerText: String? = nil

    private var clampedFraction: Double {
        min(1, max(0, fraction))
    }

    private var centerLabel: String {
        centerText ?? "\(percentDisplay)%"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(MacDS.Color.progressTrack, lineWidth: lineWidth)
                .overlay(
                    Circle()
                        .stroke(MacDS.Color.border, lineWidth: 1)
                )

            Circle()
                .trim(from: 0, to: clampedFraction)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(centerLabel)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(centerColor)
                .monospacedDigit()
        }
        .frame(width: diameter, height: diameter)
    }
}

struct MacDSTextField: View {
    let title: String
    @Binding var text: String
    var accessibilityLabel: String?

    @FocusState private var isFocused: Bool

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: .mainWindow, timerChrome: TimerChromeTheme(sessionState: .idle, colorScheme: .light))
    }

    var body: some View {
        TextField(title, text: $text)
            .textFieldStyle(.plain)
            .font(.macDSBody)
            .foregroundStyle(palette.textPrimary)
            .focused($isFocused)
            .labelsHidden()
            .accessibilityLabel(accessibilityLabel ?? title)
            .padding(.horizontal, DesignSpacing.spacing3)
            .padding(.vertical, DesignSpacing.spacing2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(palette.borderDefault, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .stroke(palette.inputFocusRingColor, lineWidth: 2)
                        .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - Popover menus (MacDS picker + timer chrome action menu)

fileprivate struct MacDSPopoverStyle: Equatable {
    let surface: AppUISurface
    let palette: FormChromePalette
    let timerChrome: TimerChromeTheme
    let panelBackground: Color
    let panelBorder: Color
    let selectedFill: Color
    let hoverBackground: Color

    static func resolve(
        surface: AppUISurface,
        timerChrome: TimerChromeTheme,
        colorScheme: ColorScheme
    ) -> MacDSPopoverStyle {
        MacDSPopoverStyle(
            surface: surface,
            palette: FormChromePalette.resolve(
                surface: surface,
                timerChrome: timerChrome,
                colorScheme: colorScheme
            ),
            timerChrome: timerChrome,
            panelBackground: MacDS.Resolved.cardBackground(for: colorScheme),
            panelBorder: MacDS.Resolved.border(for: colorScheme),
            selectedFill: MacDS.Resolved.accentTealLightest(for: colorScheme),
            hoverBackground: MacDS.Resolved.surfaceDisabled(for: colorScheme)
        )
    }

    var panelCornerRadius: CGFloat {
        MacDS.Radius.card
    }

    var selectedStroke: Color {
        palette.inputFocusRingColor
    }

    var rowCornerRadius: CGFloat {
        MacDS.Radius.standard - 2
    }
}

fileprivate struct MacDSPopoverPanel<Content: View>: View {
    let style: MacDSPopoverStyle
    var minWidth: CGFloat?
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(DesignSpacing.spacing2)
            .frame(minWidth: minWidth)
            .background(
                RoundedRectangle(cornerRadius: style.panelCornerRadius)
                    .fill(style.panelBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.panelCornerRadius)
                    .stroke(style.panelBorder, lineWidth: 1)
            )
            .modifier(MacDSPopoverPanelShadow(surface: style.surface))
    }
}

fileprivate struct MacDSPopoverPanelShadow: ViewModifier {
    let surface: AppUISurface

    func body(content: Content) -> some View {
        content.macDSCardShadow(elevated: true)
    }
}

fileprivate struct MacDSPopoverRow: View {
    let title: String
    let style: MacDSPopoverStyle
    var isSelected: Bool = false
    var isDestructive: Bool = false
    var showsCheckmark: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.spacing2) {
                Text(title)
                    .font(isSelected ? .macDSBody.weight(.semibold) : .macDSBody)
                    .foregroundStyle(titleColor)
                Spacer(minLength: 0)
                if showsCheckmark && isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(style.selectedStroke)
                }
            }
            .padding(.horizontal, DesignSpacing.spacing3)
            .padding(.vertical, DesignSpacing.spacing2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: style.rowCornerRadius))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var titleColor: Color {
        if isDestructive {
            return Color.fhColorCoral
        }
        if isSelected {
            return style.palette.textPrimary
        }
        return style.palette.textSecondary
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: style.rowCornerRadius)
                .fill(style.selectedFill)
                .overlay(
                    RoundedRectangle(cornerRadius: style.rowCornerRadius)
                        .stroke(style.selectedStroke, lineWidth: 1)
                )
        } else if isHovered {
            RoundedRectangle(cornerRadius: style.rowCornerRadius)
                .fill(style.hoverBackground)
        }
    }
}

struct MacDSMenuPicker<Option: Hashable>: View {
    let accessibilityTitle: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    var maxTriggerWidth: CGFloat? = 220

    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.timerChromeTheme) private var timerChrome
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPopoverPresented = false

    private var style: MacDSPopoverStyle {
        MacDSPopoverStyle.resolve(
            surface: appUISurface,
            timerChrome: timerChrome,
            colorScheme: colorScheme
        )
    }

    var body: some View {
        Button {
            isPopoverPresented.toggle()
        } label: {
            HStack(spacing: DesignSpacing.spacing2) {
                Text(label(selection))
                    .font(.macDSBody)
                    .foregroundStyle(style.palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.palette.textSecondary)
                    .rotationEffect(.degrees(isPopoverPresented ? 180 : 0))
                    .animation(FocusHackerMotion.easeFast, value: isPopoverPresented)
            }
            .padding(.horizontal, DesignSpacing.spacing3)
            .padding(.vertical, DesignSpacing.spacing2)
            .frame(maxWidth: maxTriggerWidth)
            .background(style.palette.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(
                        isPopoverPresented ? style.palette.inputFocusRingColor : style.palette.borderDefault,
                        lineWidth: isPopoverPresented ? 2 : 1
                    )
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(accessibilityTitle), \(label(selection))")
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            MacDSPopoverPanel(style: style, minWidth: maxTriggerWidth ?? 220) {
                VStack(spacing: DesignSpacing.spacing1) {
                    ForEach(options, id: \.self) { option in
                        MacDSPopoverRow(
                            title: label(option),
                            style: style,
                            isSelected: selection == option,
                            showsCheckmark: true
                        ) {
                            selection = option
                            isPopoverPresented = false
                        }
                    }
                }
            }
            .preferredColorScheme(colorScheme)
        }
    }
}

struct MacDSActionMenuItem: Identifiable {
    let id: String
    let title: String
    var role: ButtonRole?
    let action: () -> Void
}

struct MacDSActionMenu<Label: View>: View {
    let items: [MacDSActionMenuItem]
    let accessibilityTitle: String
  /// When set, the parent renders `MacDSInWindowActionMenuOverlay` (required for `MenuBarExtra` windows).
    var isPresented: Binding<Bool>?
    @ViewBuilder var label: () -> Label

    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.menuBarExtraWindow) private var menuBarExtraWindow
    @Environment(\.timerChromeTheme) private var timerChrome
    @Environment(\.colorScheme) private var colorScheme
    @State private var internalIsPresented = false

    private var presentationBinding: Binding<Bool> {
        isPresented ?? $internalIsPresented
    }

    var body: some View {
        Button {
            presentationBinding.wrappedValue.toggle()
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
        .popover(isPresented: popoverPresentationBinding, arrowEdge: .bottom) {
            MacDSActionMenuPanel(
                items: items,
                surface: appUISurface,
                timerChrome: timerChrome,
                isPresented: presentationBinding,
                colorScheme: colorScheme
            )
        }
    }

    /// Popover binding is only used on main-window surfaces; menubar uses in-window overlay from the parent.
    private var popoverPresentationBinding: Binding<Bool> {
        if menuBarExtraWindow {
            return .constant(false)
        }
        return presentationBinding
    }
}

/// In-window action menu for `MenuBarExtra` popovers — SwiftUI `.popover` is unreliable there.
struct MacDSInWindowActionMenuOverlay: View {
    @Binding var isPresented: Bool
    let items: [MacDSActionMenuItem]
    let timerChrome: TimerChromeTheme
    let colorScheme: ColorScheme

    private var style: MacDSPopoverStyle {
        MacDSPopoverStyle.resolve(
            surface: .mainWindow,
            timerChrome: timerChrome,
            colorScheme: colorScheme
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isPresented = false }

            MacDSActionMenuPanel(
                items: items,
                surface: .mainWindow,
                timerChrome: timerChrome,
                isPresented: $isPresented,
                colorScheme: colorScheme
            )
            .padding(.trailing, DesignSpacing.spacing4)
            .padding(.bottom, DesignSpacing.spacing4)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomTrailing)))
        .zIndex(2)
    }
}

struct MacDSActionMenuPanel: View {
    let items: [MacDSActionMenuItem]
    let surface: AppUISurface
    let timerChrome: TimerChromeTheme
    @Binding var isPresented: Bool
    let colorScheme: ColorScheme

    private var style: MacDSPopoverStyle {
        MacDSPopoverStyle.resolve(
            surface: surface,
            timerChrome: timerChrome,
            colorScheme: colorScheme
        )
    }

    var body: some View {
        MacDSPopoverPanel(style: style, minWidth: 160) {
            VStack(spacing: DesignSpacing.spacing1) {
                ForEach(items) { item in
                    MacDSPopoverRow(
                        title: item.title,
                        style: style,
                        isDestructive: item.role == .destructive
                    ) {
                        isPresented = false
                        item.action()
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct MacDSActionMenuTriggerButton: View {
    var isActive: Bool
    let accessibilityTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MacDS.Color.textPrimary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .fill(MacDS.Color.cardBackground.opacity(isActive ? 1 : 0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                        .stroke(
                            isActive ? MacDS.Color.accentTeal : MacDS.Color.border,
                            lineWidth: isActive ? 2 : 1
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }
}

struct MacDSIconButton: View {
    let systemName: String
    var role: ButtonRole?
    let accessibilityLabel: String
    let action: () -> Void
    var tint: Color = MacDS.Color.destructive

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint.opacity(0.9))
        }
        .buttonStyle(.borderless)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct MacDSResettableSectionRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let resetLabel: String
    @Binding var isPresented: Bool
    let confirmationTitle: String
    let confirmationDetail: String
    let confirmAction: () -> Void
    let content: Content

    init(
        title: String,
        subtitle: String?,
        resetLabel: String,
        isPresented: Binding<Bool>,
        confirmationTitle: String,
        confirmationDetail: String,
        confirmAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.resetLabel = resetLabel
        self._isPresented = isPresented
        self.confirmationTitle = confirmationTitle
        self.confirmationDetail = confirmationDetail
        self.confirmAction = confirmAction
        self.content = content()
    }

    var body: some View {
        MacDSCard {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
                HStack {
                    Text(title)
                        .font(.macDSCardTitle)
                        .foregroundStyle(MacDS.Color.textPrimary)
                    Spacer()
                    Button(resetLabel) { isPresented = true }
                        .buttonStyle(.plain)
                        .font(.macDSLabel.weight(.medium))
                        .foregroundStyle(MacDS.Color.accentTeal)
                        .padding(.horizontal, DesignSpacing.spacing2)
                        .padding(.vertical, DesignSpacing.spacing2)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                if let subtitle {
                    Text(subtitle)
                        .macDSHelperText()
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
        }
        .confirmationDialog(confirmationTitle, isPresented: $isPresented, titleVisibility: .visible) {
            Button("Reset", role: .destructive, action: confirmAction)
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.cancelAction)
        } message: {
            Text(confirmationDetail)
        }
    }
}

struct MacDSEndSessionConfirmationPanel: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isPresented = false }

            VStack(spacing: DesignSpacing.spacing4) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(MacDS.Color.accentOrange)
                    .accessibilityHidden(true)

                Text("End session?")
                    .font(.macDSCardTitle)
                    .foregroundStyle(MacDS.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Ending early forfeits all XP for this session. Continue?")
                    .macDSHelperText()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DesignSpacing.spacing3) {
                    Button("Cancel") { isPresented = false }
                        .buttonStyle(MacDSSecondaryButtonStyle())
                        .keyboardShortcut(.cancelAction)
                    Button("End session") { onConfirm() }
                        .buttonStyle(MacDSPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(DesignSpacing.spacing6)
            .frame(maxWidth: 320)
            .background(MacDS.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.card)
                    .stroke(MacDS.Color.border, lineWidth: 1)
            )
            .macDSCardShadow(elevated: true)
        }
        .onExitCommand { isPresented = false }
    }
}

struct MacDSSlabCompactPrimaryButtonStyle: ButtonStyle {
    var fontSize: CGFloat = 11

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .fill(
                        configuration.isPressed
                            ? MacDS.Color.accentTealLighter
                            : MacDS.Color.accentTealLight
                    )
            )
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

struct MacDSSlabCompactSecondaryButtonStyle: ButtonStyle {
    var fontSize: CGFloat = 11

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

#if DEBUG
@available(macOS 14.0, *)
#Preview("MacDSMenuPicker — light") {
    struct PreviewHost: View {
        @State private var voice = VoiceOption.crystal

        var body: some View {
            MacDSMenuPicker(
                accessibilityTitle: "Voice",
                selection: $voice,
                options: Array(VoiceOption.allCases),
                label: { $0.displayName }
            )
            .padding()
            .frame(width: 320)
            .background(MacDS.Color.backgroundPrimary)
            .environment(\.appUISurface, .mainWindow)
            .environment(\.timerChromeTheme, TimerChromeTheme(sessionState: .idle, colorScheme: .light))
            .preferredColorScheme(.light)
        }
    }
    return PreviewHost()
}

@available(macOS 14.0, *)
#Preview("MacDSMenuPicker — dark") {
    struct PreviewHost: View {
        @State private var voice = VoiceOption.jocko

        var body: some View {
            MacDSMenuPicker(
                accessibilityTitle: "Voice",
                selection: $voice,
                options: Array(VoiceOption.allCases),
                label: { $0.displayName }
            )
            .padding()
            .frame(width: 320)
            .background(MacDS.Color.backgroundPrimary)
            .environment(\.appUISurface, .mainWindow)
            .environment(\.timerChromeTheme, TimerChromeTheme(sessionState: .idle, colorScheme: .dark))
            .preferredColorScheme(.dark)
        }
    }
    return PreviewHost()
}

@available(macOS 14.0, *)
#Preview("MacDSActionMenu — focus dark") {
    struct PreviewHost: View {
        var body: some View {
            MacDSActionMenu(
                items: [
                    MacDSActionMenuItem(id: "quit", title: "Quit", role: .destructive) {}
                ],
                accessibilityTitle: "More options"
            ) {
                Label("More options", systemImage: "line.3.horizontal")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
            }
            .padding()
            .frame(width: 200)
            .background(TimerChromeTheme(sessionState: .focus, colorScheme: .dark).bgPanel)
            .environment(\.timerChromeTheme, TimerChromeTheme(sessionState: .focus, colorScheme: .dark))
            .preferredColorScheme(.dark)
        }
    }
    return PreviewHost()
}

@available(macOS 14.0, *)
#Preview("MacDSActionMenu — rest light") {
    struct PreviewHost: View {
        var body: some View {
            MacDSActionMenu(
                items: [
                    MacDSActionMenuItem(id: "quit", title: "Quit", role: .destructive) {}
                ],
                accessibilityTitle: "More options"
            ) {
                Label("More options", systemImage: "line.3.horizontal")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(TimerChromeTheme(sessionState: .rest, colorScheme: .light).textPrimary)
                    .frame(width: 32, height: 32)
            }
            .padding()
            .frame(width: 200)
            .background(TimerChromeTheme(sessionState: .rest, colorScheme: .light).bgPanel)
            .environment(\.timerChromeTheme, TimerChromeTheme(sessionState: .rest, colorScheme: .light))
            .preferredColorScheme(.light)
        }
    }
    return PreviewHost()
}
#endif
