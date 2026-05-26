import SwiftUI

enum FocusSessionScreenLayout: Equatable {
    case menuBarPopover
    case mainWindow

    var maxWidth: CGFloat {
        switch self {
        case .menuBarPopover:
            return MenuBarPopoverLayout.width - DesignSpacing.spacing5 * 2
        case .mainWindow:
            return 480
        }
    }

    var screenLabelFontSize: CGFloat {
        switch self {
        case .menuBarPopover:
            return 12
        case .mainWindow:
            return 12
        }
    }

    var presetNameFontSize: CGFloat {
        switch self {
        case .menuBarPopover:
            return 17
        case .mainWindow:
            return 17
        }
    }

    var presetSubtitleFontSize: CGFloat {
        12
    }

    var upNextFontSize: CGFloat {
        11
    }

    var timerFontSize: CGFloat {
        switch self {
        case .menuBarPopover:
            return 68
        case .mainWindow:
            return 72
        }
    }

    var cyclePillLabelFontSize: CGFloat {
        11
    }

    var cyclePillValueFontSize: CGFloat {
        13
    }

    var ctaFontSize: CGFloat {
        16
    }

    var statsLabelFontSize: CGFloat {
        10
    }

    var statsValueFontSize: CGFloat {
        12
    }

    var cardCornerRadius: CGFloat {
        14
    }

    var selectorCornerRadius: CGFloat {
        14
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .menuBarPopover:
            return 0
        case .mainWindow:
            return DesignSpacing.spacing4
        }
    }

    /// Inset for preset carousel and primary CTA from the card’s left/right edges.
    var contentHorizontalInset: CGFloat {
        DesignSpacing.spacing4
    }
}

struct FocusSessionScreenView: View {
    @ObservedObject var viewModel: AppShellViewModel
    let layout: FocusSessionScreenLayout
    let configurationEnabled: Bool
    let purchaseAllowsUse: Bool
    let onStartSession: () -> Void
    let onPresentPaywall: () -> Void
    let onTogglePause: () -> Void
    let onRequestEndSession: () -> Void
    let onCancelGetReady: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FocusSessionScreenPalette {
        FocusSessionScreenPalette.resolve(for: colorScheme)
    }

    private var configurationProfile: TimerSessionConfigurationProfile {
        layout == .menuBarPopover ? .menuBarPopoverCustom : .mainWindow
    }

    var body: some View {
        VStack(spacing: 0) {
            screenLabel
            presetSelector
            timerContentBlock
            statsFooter
            customConfigurationSection
        }
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.vertical, layout == .mainWindow ? DesignSpacing.spacing4 : 0)
        .frame(maxWidth: layout.maxWidth)
        .background(palette.bgScreen)
        .clipShape(RoundedRectangle(cornerRadius: layout.cardCornerRadius))
        .overlay {
            if let borderScreen = palette.borderScreen {
                RoundedRectangle(cornerRadius: layout.cardCornerRadius)
                    .stroke(borderScreen, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.focusSessionAccessibilitySummary)
    }

    @ViewBuilder
    private var customConfigurationSection: some View {
        if viewModel.focusSessionShowsCustomConfiguration {
            TimerSessionConfigurationForm(
                viewModel: viewModel,
                isEnabled: configurationEnabled,
                sectionTitle: "Configure Session",
                profile: configurationProfile
            )
            .padding(DesignSpacing.spacing3)
            .background(
                RoundedRectangle(cornerRadius: layout.selectorCornerRadius)
                    .fill(palette.bgSelector)
                    .overlay(
                        RoundedRectangle(cornerRadius: layout.selectorCornerRadius)
                            .stroke(palette.borderSelector.opacity(0.55), lineWidth: 1)
                    )
            )
            .padding(.top, DesignSpacing.spacing3)
            .transition(.opacity)
            .animation(FocusHackerMotion.easeFast, value: viewModel.focusSessionShowsCustomConfiguration)
        }
    }

    private var screenLabel: some View {
        Text("Focus session")
            .font(.system(size: layout.screenLabelFontSize, weight: .medium))
            .textCase(.uppercase)
            .tracking(0.06 * layout.screenLabelFontSize)
            .foregroundStyle(palette.textLabel)
            .frame(maxWidth: .infinity)
            .padding(.top, DesignSpacing.spacing5)
            .padding(.bottom, 14)
    }

    private var presetSelector: some View {
        HStack(spacing: 0) {
            presetNavButton(forward: false)

            VStack(spacing: 2) {
                Text(viewModel.focusSessionPresetName)
                    .font(.system(size: layout.presetNameFontSize, weight: .medium))
                    .foregroundStyle(palette.textTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(viewModel.focusSessionPresetSubtitle)
                    .font(.system(size: layout.presetSubtitleFontSize))
                    .foregroundStyle(palette.textSubtitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            presetNavButton(forward: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(palette.bgSelector)
        .clipShape(RoundedRectangle(cornerRadius: layout.selectorCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: layout.selectorCornerRadius)
                .stroke(palette.borderSelector, lineWidth: 1.5)
        )
        .padding(.horizontal, layout.contentHorizontalInset)
        .padding(.bottom, 24)
        .opacity(configurationEnabled ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus session preset")
        .accessibilityValue("\(viewModel.focusSessionPresetName). \(viewModel.focusSessionPresetSubtitle)")
    }

    private func presetNavButton(forward: Bool) -> some View {
        Button {
            viewModel.cycleFocusPreset(forward: forward)
        } label: {
            Text(forward ? "›" : "‹")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(palette.accent)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(!configurationEnabled)
        .accessibilityLabel(forward ? "Next focus session preset" : "Previous focus session preset")
    }

    private var timerContentBlock: some View {
        VStack(spacing: 0) {
            timerDisplay
            cyclePill
            primaryAction
            if viewModel.focusSessionShowsEndSessionButton {
                endSessionButton
            }
        }
        .frame(maxWidth: .infinity)
        .background(palette.bgTimer)
    }

    private var timerDisplay: some View {
        VStack(spacing: 6) {
            Text(viewModel.focusSessionUpNextLine)
                .font(.system(size: layout.upNextFontSize, weight: .medium))
                .textCase(.uppercase)
                .tracking(0.08 * layout.upNextFontSize)
                .foregroundStyle(palette.textUpNext)

            FocusSessionTimerDigits(
                countdownText: viewModel.heroCountdownText,
                identity: viewModel.heroTimerDisplayIdentity,
                fontSize: layout.timerFontSize,
                textColor: palette.textTimer,
                colonColor: palette.accentColon
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSpacing.spacing3)
        .padding(.bottom, 10)
    }

    private var cyclePill: some View {
        HStack(spacing: 4) {
            Text("CYCLE")
                .font(.system(size: layout.cyclePillLabelFontSize, weight: .medium))
                .textCase(.uppercase)
                .tracking(0.06 * layout.cyclePillLabelFontSize)
                .foregroundStyle(palette.textStatsValue)

            Text(viewModel.focusSessionCyclePillText)
                .font(.system(size: layout.cyclePillValueFontSize, weight: .semibold).monospacedDigit())
                .foregroundStyle(palette.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(palette.bgCyclePill)
        .clipShape(Capsule())
        .padding(.top, DesignSpacing.spacing2)
        .padding(.bottom, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cycle \(viewModel.focusSessionCyclePillText)")
    }

    private var primaryAction: some View {
        Button {
            performPrimaryAction()
        } label: {
            HStack(spacing: DesignSpacing.spacing2) {
                if viewModel.focusSessionPrimaryButtonUsesPlayIcon {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                } else if viewModel.focusSessionPrimaryButtonUsesPauseIcon {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(viewModel.focusSessionPrimaryButtonTitle)
            }
            .font(.system(size: layout.ctaFontSize, weight: .semibold))
            .foregroundStyle(palette.ctaForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: layout.cardCornerRadius)
                    .fill(palette.ctaBackground)
            )
        }
        .buttonStyle(.plain)
        .disabled(primaryActionDisabled)
        .opacity(primaryActionDisabled ? 0.45 : 1)
        .padding(.horizontal, layout.contentHorizontalInset)
        .padding(.bottom, viewModel.focusSessionShowsEndSessionButton ? DesignSpacing.spacing2 : DesignSpacing.spacing4)
    }

    private var endSessionButton: some View {
        Button("End session") {
            onRequestEndSession()
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(palette.textUpNext)
        .buttonStyle(.plain)
        .padding(.bottom, DesignSpacing.spacing4)
    }

    private var statsFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(palette.borderStats)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                statColumn(
                    label: viewModel.focusSessionTotalStatLabel,
                    value: viewModel.focusSessionTotalStatValue
                )

                Rectangle()
                    .fill(palette.borderStats)
                    .frame(width: 0.5)
                    .padding(.vertical, 10)

                statColumn(
                    label: viewModel.focusSessionFocusStatLabel,
                    value: viewModel.focusSessionFocusStatValue
                )

                Rectangle()
                    .fill(palette.borderStats)
                    .frame(width: 0.5)
                    .padding(.vertical, 10)

                statColumn(
                    label: viewModel.focusSessionSessionsStatLabel,
                    value: viewModel.focusSessionSessionsStatValue
                )
            }
            .padding(.top, 14)
            .padding(.bottom, DesignSpacing.spacing5)
        }
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: layout.statsLabelFontSize, weight: .medium))
                .textCase(.uppercase)
                .tracking(0.05 * layout.statsLabelFontSize)
                .foregroundStyle(palette.textStatsLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.system(size: layout.statsValueFontSize, weight: .medium).monospacedDigit())
                .foregroundStyle(palette.textStatsValue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 4)
    }

    private var primaryActionDisabled: Bool {
        if viewModel.shouldShowCancelGetReadyButton {
            return false
        }
        if viewModel.shouldShowStartButton {
            return !purchaseAllowsUse
        }
        return !viewModel.canPause || !purchaseAllowsUse
    }

    private func performPrimaryAction() {
        if viewModel.shouldShowCancelGetReadyButton {
            onCancelGetReady()
            return
        }
        if viewModel.shouldShowStartButton {
            guard purchaseAllowsUse else {
                onPresentPaywall()
                return
            }
            onStartSession()
            return
        }
        guard purchaseAllowsUse else { return }
        onTogglePause()
    }
}

private struct FocusSessionTimerDigits: View {
    let countdownText: String
    let identity: String
    let fontSize: CGFloat
    let textColor: Color
    let colonColor: Color

    private var parts: (left: String, right: String) {
        let pieces = countdownText.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if pieces.count == 2 {
            return (String(pieces[0]), String(pieces[1]))
        }
        return (countdownText, "")
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(parts.left)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .tracking(-2)
                .foregroundStyle(textColor)

            Text(":")
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .tracking(-2)
                .foregroundStyle(colonColor)

            Text(parts.right)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .tracking(-2)
                .foregroundStyle(textColor)
        }
        .id(identity)
        .lineLimit(1)
        .minimumScaleFactor(0.4)
    }
}
