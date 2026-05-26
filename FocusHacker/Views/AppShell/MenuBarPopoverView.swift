import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: AppShellViewModel
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService
    let openFullWindow: () -> Void
    let presentPaywall: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var systemAppearanceRefreshToken = 0

    private var timerConfigurationEnabled: Bool {
        viewModel.state.sessionState == .idle
    }

    private var effectiveColorScheme: ColorScheme {
        viewModel.appearancePreference.resolvedColorScheme(fallback: colorScheme)
    }

    private var popoverPalette: MenuBarPopoverPalette {
        MenuBarPopoverPalette.resolve(for: effectiveColorScheme)
    }

    private var sessionChrome: TimerChromeTheme {
        TimerChromeTheme(sessionState: viewModel.state.sessionState, colorScheme: effectiveColorScheme)
    }

    var body: some View {
        ZStack {
            popoverChromeContent
            if viewModel.showsEndSessionConfirmation {
                MacDSEndSessionConfirmationPanel(
                    isPresented: $viewModel.showsEndSessionConfirmation,
                    onConfirm: { viewModel.confirmEndSession() }
                )
                .preferredColorScheme(effectiveColorScheme)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(1)
            }
        }
        .animation(FocusHackerMotion.easeFast, value: viewModel.showsEndSessionConfirmation)
        .environment(\.appUISurface, .mainWindow)
        .environment(\.menuBarExtraWindow, true)
        .environment(\.timerChromeTheme, sessionChrome)
        .environment(\.menuBarPopoverPalette, popoverPalette)
        .preferredColorScheme(viewModel.appearancePreference.preferredColorScheme)
        .id("\(viewModel.appearancePreference.rawValue)-\(systemAppearanceRefreshToken)")
        .onChange(of: viewModel.appearancePreference) { preference in
            MenuBarExtraAppearanceController.apply(preference: preference)
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("AppleInterfaceThemeChangedNotification")
            )
        ) { _ in
            guard viewModel.appearancePreference == .system else { return }
            systemAppearanceRefreshToken += 1
            MenuBarExtraAppearanceController.apply(preference: .system)
        }
        .onAppear {
            MenuBarExtraAppearanceController.apply(preference: viewModel.appearancePreference)
            MenuBarExtraPanelController.beginOutsideClickMonitoring()
        }
        .onDisappear {
            MenuBarExtraPanelController.stopOutsideClickMonitoring()
        }
    }

    /// Only lock/banner stacks can exceed a comfortable panel height; preset and custom configure layouts expand the window instead.
    private var popoverRequiresScrolling: Bool {
        MenuBarPopoverLayout.requiresVerticalScrolling(
            allowsAppUse: purchaseEntitlements.evaluation.allowsAppUse,
            hasCompletionBanner: viewModel.completionBannerText != nil
        )
    }

    private var popoverChromeContent: some View {
        Group {
            if popoverRequiresScrolling {
                ScrollView(.vertical, showsIndicators: true) {
                    popoverBody
                }
                .frame(maxHeight: MenuBarPopoverLayout.maxScrollableHeight)
            } else {
                popoverBody
            }
        }
        .frame(width: MenuBarPopoverLayout.width)
        .fixedSize(horizontal: false, vertical: !popoverRequiresScrolling)
        .background(MenuBarExtraWindowSizeFitter())
        .background(popoverPalette.background)
        .onAppear {
            viewModel.restoreFocusPresetSelectionIfNeeded()
        }
    }

    private var popoverBody: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing5) {
            if !purchaseEntitlements.evaluation.allowsAppUse {
                paywallLockSection
            }

            if let completionBannerText = viewModel.completionBannerText {
                completionBanner(completionBannerText)
            }

            FocusSessionScreenView(
                viewModel: viewModel,
                layout: .menuBarPopover,
                configurationEnabled: timerConfigurationEnabled
                    && purchaseEntitlements.evaluation.allowsAppUse,
                purchaseAllowsUse: purchaseEntitlements.evaluation.allowsAppUse,
                onStartSession: { viewModel.startSessionFromMenuBar() },
                onPresentPaywall: { presentPaywall() },
                onTogglePause: { viewModel.togglePause() },
                onRequestEndSession: { viewModel.requestEndSession() },
                onCancelGetReady: { viewModel.cancelMenuBarGetReadyCountdown() }
            )
            .frame(maxWidth: .infinity)

            MenuBarPopoverActions(
                viewModel: viewModel,
                purchaseAllowsUse: purchaseEntitlements.evaluation.allowsAppUse,
                onOpenFullWindow: { openFullWindow() },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSpacing.spacing5)
    }

    private var paywallLockSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
            Text("FocusHacker is locked until StoreKit recognises a lifetime purchase or introductory access.")
                .font(.macDSHelper)
                .foregroundStyle(popoverPalette.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Button("Show unlock window…") {
                presentPaywall()
            }
            .buttonStyle(MenuBarPopoverPrimaryButtonStyle())
        }
    }

    private func completionBanner(_ text: String) -> some View {
        HStack(spacing: DesignSpacing.spacing3) {
            Image(systemName: "sparkles")
                .foregroundStyle(popoverPalette.teal)
            Text(text)
                .font(.macDSBody.weight(.semibold))
                .foregroundStyle(popoverPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSpacing.spacing3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MenuBarPopoverLayout.cardCornerRadius)
                .fill(popoverPalette.cellFill)
                .overlay(
                    RoundedRectangle(cornerRadius: MenuBarPopoverLayout.cardCornerRadius)
                        .stroke(popoverPalette.cellBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Popover palette (scheme-explicit — avoids NSColor dynamicProvider in MenuBarExtra)

struct MenuBarPopoverPalette: Equatable {
    let background: Color
    let textPrimary: Color
    let textMuted: Color
    let textMutedSecondary: Color
    let teal: Color
    let cellFill: Color
    let cellBorder: Color
    let grayOutline: Color
    let onTealForeground: Color
    let timerHeroOnTealPrimary: Color
    let timerHeroOnTealSecondary: Color
    let metricsBandOverlay: Color
    let metricsBandDivider: Color
    let metricsLabelOnHero: Color
    let metricsValueOnHero: Color
    let actionBandOverlay: Color
    let actionBandOverlayStrong: Color
    let primaryButtonFill: Color
    let primaryButtonForeground: Color

    static func resolve(for colorScheme: ColorScheme) -> MenuBarPopoverPalette {
        let metricsOverlayLight = Color.white.opacity(0.15)
        let metricsOverlayDark = Color.black.opacity(0.24)
        let actionOverlayLight = Color.black.opacity(0.28)
        let actionOverlayDark = Color.black.opacity(0.35)
        let actionOverlayStrongLight = Color.black.opacity(0.35)
        let actionOverlayStrongDark = Color.black.opacity(0.42)

        return MenuBarPopoverPalette(
            background: MacDS.Resolved.backgroundPrimary(for: colorScheme),
            textPrimary: MacDS.Resolved.textPrimary(for: colorScheme),
            textMuted: MacDS.Resolved.textSecondary(for: colorScheme),
            textMutedSecondary: MacDS.Resolved.textTertiary(for: colorScheme),
            teal: MacDS.Resolved.accentTeal(for: colorScheme),
            cellFill: MacDS.Resolved.accentTealLightest(for: colorScheme),
            cellBorder: MacDS.Resolved.accentTealCellBorder(for: colorScheme),
            grayOutline: MacDS.Resolved.border(for: colorScheme),
            onTealForeground: .white,
            timerHeroOnTealPrimary: .white,
            timerHeroOnTealSecondary: Color.white.opacity(0.92),
            metricsBandOverlay: colorScheme == .dark ? metricsOverlayDark : metricsOverlayLight,
            metricsBandDivider: Color.white.opacity(0.30),
            metricsLabelOnHero: Color.white.opacity(0.88),
            metricsValueOnHero: Color.white.opacity(0.92),
            actionBandOverlay: colorScheme == .dark ? actionOverlayDark : actionOverlayLight,
            actionBandOverlayStrong: colorScheme == .dark ? actionOverlayStrongDark : actionOverlayStrongLight,
            primaryButtonFill: .white,
            primaryButtonForeground: MacDS.Resolved.accentTeal(for: colorScheme)
        )
    }

    func actionBandOverlay(usesGetReadyChrome: Bool) -> Color {
        usesGetReadyChrome ? actionBandOverlayStrong : actionBandOverlay
    }
}

private struct MenuBarPopoverPaletteKey: EnvironmentKey {
    static let defaultValue = MenuBarPopoverPalette.resolve(for: .light)
}

extension EnvironmentValues {
    var menuBarPopoverPalette: MenuBarPopoverPalette {
        get { self[MenuBarPopoverPaletteKey.self] }
        set { self[MenuBarPopoverPaletteKey.self] = newValue }
    }
}

enum MenuBarPopoverLayout {
    static let width: CGFloat = 384
    static let timerCornerRadius: CGFloat = 8
    static let unifiedTimerCornerRadius: CGFloat = 8
    static let cardCornerRadius: CGFloat = 6
    static let primaryButtonCornerRadius: CGFloat = 8
    static let timerHeroHeight: CGFloat = 152
    static let metricsBandHeight: CGFloat = 46
    static let actionBandVerticalPadding: CGFloat = 12
    static let actionBandButtonVerticalPadding: CGFloat = 12
    /// Minimum height for the standalone idle Start focus primary CTA.
    static let primaryStartButtonMinHeight: CGFloat = 56
    static let presetSelectorMinHeight: CGFloat = 44
    static let presetNavButtonSize: CGFloat = 32

    /// Config + footer metric bands + fixed hero height (action band is dynamic).
    static var unifiedTimerCardCoreHeight: CGFloat {
        configBandHeight + timerHeroHeight + footerBandHeight
    }

    static let configBandHeight: CGFloat = metricsBandHeight
    static let footerBandHeight: CGFloat = metricsBandHeight

    /// Cap when paywall or completion banner stacks make the popover taller than the screen.
    static let maxScrollableHeight: CGFloat = 600

    /// Custom session configuration expands the panel; scrolling is reserved for lock/banner overlays.
    static func requiresVerticalScrolling(allowsAppUse: Bool, hasCompletionBanner: Bool) -> Bool {
        !allowsAppUse || hasCompletionBanner
    }

    /// Maximum panel height before clamping (menu bar anchor, grow downward).
    static func maxHeightBelowMenuBar(for window: NSWindow) -> CGFloat {
        guard let screen = window.screen ?? NSScreen.main else { return 800 }
        let margin: CGFloat = 12
        let spaceBelowMenuBar = window.frame.maxY - screen.visibleFrame.minY - margin
        return max(320, spaceBelowMenuBar)
    }
}

// MARK: - Button styles

struct MenuBarPopoverPrimaryButtonStyle: ButtonStyle {
    @Environment(\.menuBarPopoverPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.macDSBody.weight(.semibold))
            .foregroundStyle(palette.onTealForeground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: MenuBarPopoverLayout.primaryStartButtonMinHeight)
            .background(
                RoundedRectangle(cornerRadius: MenuBarPopoverLayout.primaryButtonCornerRadius)
                    .fill(palette.teal.opacity(configuration.isPressed ? 0.85 : 1))
            )
    }
}

struct MenuBarPopoverTealOutlineButtonStyle: ButtonStyle {
    @Environment(\.menuBarPopoverPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(palette.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: MenuBarPopoverLayout.cardCornerRadius)
                    .stroke(palette.cellBorder, lineWidth: 0.5)
                    .background(
                        RoundedRectangle(cornerRadius: MenuBarPopoverLayout.cardCornerRadius)
                            .fill(Color.clear)
                    )
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct MenuBarPopoverGrayOutlineButtonStyle: ButtonStyle {
    @Environment(\.menuBarPopoverPalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(palette.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: MenuBarPopoverLayout.cardCornerRadius)
                    .stroke(palette.grayOutline.opacity(0.6), lineWidth: 0.5)
                    .background(
                        RoundedRectangle(cornerRadius: MenuBarPopoverLayout.cardCornerRadius)
                            .fill(Color.clear)
                    )
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - CTAs

struct MenuBarPopoverActions: View {
    @ObservedObject var viewModel: AppShellViewModel
    let purchaseAllowsUse: Bool
    let onOpenFullWindow: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: DesignSpacing.spacing3) {
            HStack(spacing: DesignSpacing.spacing3) {
                Button("Open Focus Hacker") {
                    onOpenFullWindow()
                }
                .buttonStyle(MenuBarPopoverTealOutlineButtonStyle())
                .disabled(!purchaseAllowsUse)
                .opacity(purchaseAllowsUse ? 1 : 0.55)

                Button("Quit app") {
                    onQuit()
                }
                .buttonStyle(MenuBarPopoverGrayOutlineButtonStyle())
            }
        }
    }
}
