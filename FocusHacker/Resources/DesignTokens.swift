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

enum TimerChromeTheme: Equatable, Sendable {
    case focus
    case rest

    init(sessionState: AppShellSessionState) {
        switch sessionState {
        case .idle, .focus:
            self = .focus
        case .rest:
            self = .rest
        }
    }

    var bgApp: Color {
        switch self {
        case .focus: return .fhColorCharcoal
        case .rest: return .fhColorCloud
        }
    }

    var bgPanel: Color {
        switch self {
        case .focus: return .fhColorDarkBg
        case .rest: return .fhColorRestPanel
        }
    }

    var bgSurface: Color {
        switch self {
        case .focus: return .fhColorSurface
        case .rest: return .fhColorWhite
        }
    }

    var borderDefault: Color {
        switch self {
        case .focus: return .fhColorMedium
        case .rest: return .fhColorRestBorder
        }
    }

    var textPrimary: Color {
        switch self {
        case .focus: return .fhColorWhite
        case .rest: return .fhColorRestTextPrimary
        }
    }

    var textSecondary: Color {
        switch self {
        case .focus: return .fhColorLight
        case .rest: return .fhColorRestTextSecondary
        }
    }

    var textPlaceholder: Color {
        switch self {
        case .focus: return .fhColorMedium
        case .rest: return .fhColorRestPlaceholder
        }
    }

    var accentPrimary: Color {
        switch self {
        case .focus: return .fhColorEmber
        case .rest: return .fhColorMint
        }
    }

    var accentHover: Color {
        switch self {
        case .focus: return .fhColorEmberLight
        case .rest: return .fhColorMintLight
        }
    }

    var accentTimer: Color {
        accentPrimary
    }

    var inputFocusRingColor: Color {
        switch self {
        case .focus: return .fhColorEmber
        case .rest: return .fhColorMint
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
    static let defaultValue: TimerChromeTheme = .focus
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

// MARK: - macOS design system (Wispr Flow — main app windows only)

enum MacDS {
    enum Color {
        static let backgroundPrimary = SwiftUI.Color(hex: 0xFAFAFA)
        static let sidebarBackground = SwiftUI.Color(hex: 0xF5F3F0)
        static let textPrimary = SwiftUI.Color(hex: 0x1A1A1A)
        /// Readable secondary copy on white — WCAG AA at 12pt+ (~5.8:1 on #FFFFFF).
        static let textSecondary = SwiftUI.Color(hex: 0x5C5C5C)
        /// Non-essential metadata only — not for instructional copy.
        static let textTertiary = SwiftUI.Color(hex: 0xA8A8A8)
        /// Disabled controls and inactive toggles on light surfaces.
        static let textDisabled = SwiftUI.Color(hex: 0x8A8A8A)
        static let cardBackground = SwiftUI.Color.white
        static let border = SwiftUI.Color(hex: 0xD0D0D0)
        static let dividerLight = SwiftUI.Color(hex: 0xEFEFEF)
        static let progressTrack = SwiftUI.Color(hex: 0xD4D4D4)
        static let surfaceDisabled = SwiftUI.Color(hex: 0xE8E6E1)
        static let accentTeal = SwiftUI.Color(hex: 0x2D7A7A)
        static let accentTealLight = SwiftUI.Color(hex: 0x4A9B9B)
        static let accentTealLighter = SwiftUI.Color(hex: 0x7AC5C5)
        static let accentTealLightest = SwiftUI.Color(hex: 0xC8E5E5)
        static let accentOrange = SwiftUI.Color(hex: 0xF5A623)
        static let accentPurple = SwiftUI.Color(hex: 0xB896FF)
        static let secondaryButtonBackground = SwiftUI.Color(hex: 0xF0EEE8)
        static let pillBackground = SwiftUI.Color(hex: 0xE8E6E1)
        static let sidebarActiveBackground = SwiftUI.Color(hex: 0xE8E6E1)
        static let heroGradientStart = SwiftUI.Color(hex: 0x1A1A1A)
        static let heroGradientEnd = SwiftUI.Color(hex: 0x2A2A2A)
        static let inputBackground = SwiftUI.Color(hex: 0xFAFAFA)
        static let destructive = SwiftUI.Color(hex: 0xC0392B)
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
    static let defaultValue: AppUISurface = .menuBarPopover
}

extension EnvironmentValues {
    var appUISurface: AppUISurface {
        get { self[AppUISurfaceKey.self] }
        set { self[AppUISurfaceKey.self] = newValue }
    }
}

/// Resolves form field colors for main-window (light MacDS) vs menu bar popover (session chrome).
struct FormChromePalette: Equatable, Sendable {
    let textPrimary: Color
    let textSecondary: Color
    let bgSurface: Color
    let borderDefault: Color
    let inputFocusRingColor: Color

    static func resolve(surface: AppUISurface, timerChrome: TimerChromeTheme) -> FormChromePalette {
        switch surface {
        case .mainWindow:
            return FormChromePalette(
                textPrimary: MacDS.Color.textPrimary,
                textSecondary: MacDS.Color.textSecondary,
                bgSurface: MacDS.Color.inputBackground,
                borderDefault: MacDS.Color.border,
                inputFocusRingColor: MacDS.Color.accentTeal
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
    static func make(layout: TimerThreeRowSlabLayout, viewModel: AppShellViewModel) -> TimerSlabAppearance {
        switch layout {
        case .menuBarPopover:
            return legacyPopover(viewModel: viewModel)
        case .mainWindow:
            return mainWindow(viewModel: viewModel)
        }
    }

    @MainActor
    private static func legacyPopover(viewModel: AppShellViewModel) -> TimerSlabAppearance {
        TimerSlabAppearance(
            cornerRadius: 2,
            strokeColor: .fhColorCharcoal,
            strokeWidth: 2,
            headerBackground: viewModel.timerSlabHeaderBackground,
            headerPrimaryForeground: viewModel.timerSlabHeaderPrimaryForeground,
            headerSecondaryForeground: viewModel.timerSlabHeaderSecondaryForeground,
            heroBackground: viewModel.heroBrutalistBlockBackground,
            heroForeground: viewModel.heroBrutalistBlockForeground,
            footerBackground: viewModel.timerSlabFooterBackground,
            footerColumnCarbon: .fhColorDSCarbon,
            footerColumnStone: .fhColorDSStone,
            footerLabelTint: .fhColorDSSmoke,
            footerPrimaryForeground: viewModel.timerSlabFooterPrimaryForeground,
            footerSecondaryForeground: viewModel.timerSlabFooterSecondaryForeground,
            upNextColumnBackground: viewModel.timerSlabUpNextColumnBackground,
            upNextAccent: viewModel.timerSlabRow3UpNextDetailColor,
            usesUppercaseLabels: true,
            usesBrutalistControls: true
        )
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
}

// MARK: - MacDS SwiftUI components (main app windows)

extension View {
    func macDSCardShadow(elevated: Bool = false) -> some View {
        shadow(
            color: .black.opacity(elevated ? MacDS.Shadow.mdOpacity : MacDS.Shadow.smOpacity),
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
            .background(MacDS.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.card))
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
                    .fill(MacDS.Color.textPrimary.opacity(configuration.isPressed ? 0.85 : 1))
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

    private var clampedFraction: Double {
        min(1, max(0, fraction))
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

            Text("\(percentDisplay)%")
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
        FormChromePalette.resolve(surface: .mainWindow, timerChrome: .focus)
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
                    .fill(MacDS.Color.textPrimary.opacity(configuration.isPressed ? 0.85 : 1))
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
