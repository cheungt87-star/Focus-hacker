import SwiftUI

enum TimerThreeRowSlabLayout {
    case mainWindow
    case menuBarPopover

    fileprivate var slabHeight: CGFloat {
        switch self {
        case .mainWindow:
            return 460
        case .menuBarPopover:
            return 312
        }
    }

    fileprivate var row1FontSize: CGFloat {
        switch self {
        case .mainWindow:
            return 12
        case .menuBarPopover:
            return 10
        }
    }

    fileprivate var heroTimerBaseSize: CGFloat {
        switch self {
        case .mainWindow:
            return 96
        case .menuBarPopover:
            return 56
        }
    }

    fileprivate var heroActivityLabelFontSize: CGFloat {
        switch self {
        case .mainWindow:
            return 20
        case .menuBarPopover:
            return 14
        }
    }

    fileprivate var row3FontSize: CGFloat {
        row1FontSize
    }

    fileprivate var row3UpNextCaptionFontSize: CGFloat {
        switch self {
        case .mainWindow:
            return 10
        case .menuBarPopover:
            return 9
        }
    }

    fileprivate var row3UpNextDetailFontSize: CGFloat {
        switch self {
        case .mainWindow:
            return row1FontSize + 4
        case .menuBarPopover:
            return row1FontSize + 3
        }
    }

    fileprivate var controlFontSize: CGFloat {
        switch self {
        case .mainWindow:
            return 11
        case .menuBarPopover:
            return 10
        }
    }

    fileprivate var slabStatCaptionFontSize: CGFloat {
        max(8, row1FontSize - 1)
    }

    fileprivate var slabStatValueFontSize: CGFloat {
        row1FontSize + 4
    }
}

struct TimerThreeRowSlabView: View {
    @ObservedObject var viewModel: AppShellViewModel
    var layout: TimerThreeRowSlabLayout
    var purchaseAllowsUse: Bool
    var onStartSession: () -> Void
    var onPresentPaywall: () -> Void
    var onRequestEndSession: () -> Void

    private var appearance: TimerSlabAppearance {
        TimerSlabAppearance.make(layout: layout, viewModel: viewModel)
    }

    private static let slabRowHeightRatioSum = 0.16 + 0.56 + 0.18

    private var slabRow1Height: CGFloat {
        layout.slabHeight * (0.16 / Self.slabRowHeightRatioSum)
    }

    private var slabRow2Height: CGFloat {
        layout.slabHeight * (0.56 / Self.slabRowHeightRatioSum)
    }

    private var slabRow3Height: CGFloat {
        layout.slabHeight * (0.18 / Self.slabRowHeightRatioSum)
    }

    var body: some View {
        VStack(spacing: 0) {
            row1(height: slabRow1Height)
            row2(height: slabRow2Height)
            row3(height: slabRow3Height)
        }
        .frame(height: layout.slabHeight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: appearance.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: appearance.cornerRadius)
                .stroke(appearance.strokeColor, lineWidth: appearance.strokeWidth)
        )
        .macDSCardShadow(elevated: layout == .mainWindow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.timerSlabAccessibilitySummary)
    }

    @ViewBuilder
    private func row1(height: CGFloat) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.menuBarSessionStatLabel)
                    .font(.system(size: layout.slabStatCaptionFontSize, weight: .medium))
                    .foregroundStyle(appearance.headerSecondaryForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(viewModel.menuBarSessionStatValue)
                    .font(.system(size: layout.slabStatValueFontSize, weight: .bold).monospacedDigit())
                    .foregroundStyle(appearance.headerPrimaryForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignSpacing.spacing2)

            Group {
                if viewModel.showsTimerSlabRow1CenterTitle {
                    Text(viewModel.timerSlabRow1CurrentSessionTitle)
                        .font(.system(size: layout.row1FontSize, weight: appearance.usesUppercaseLabels ? .heavy : .semibold))
                        .modifier(OptionalUppercase(enabled: appearance.usesUppercaseLabels))
                        .tracking(appearance.usesUppercaseLabels ? 0.35 : 0)
                        .foregroundStyle(appearance.headerPrimaryForeground)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.55)
                } else {
                    Color.clear
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, DesignSpacing.spacing1)

            Group {
                if viewModel.shouldShowStartButton {
                    Button("Start") {
                        guard purchaseAllowsUse else {
                            onPresentPaywall()
                            return
                        }
                        onStartSession()
                    }
                    .modifier(SlabStartButtonStyle(
                        appearance: appearance,
                        fontSize: layout.controlFontSize
                    ))
                    .opacity(purchaseAllowsUse ? 1 : 0.55)
                } else {
                    HStack(spacing: 6) {
                        Button(viewModel.pauseButtonTitle) {
                            viewModel.togglePause()
                        }
                        .modifier(SlabPauseButtonStyle(
                            appearance: appearance,
                            fontSize: layout.controlFontSize
                        ))
                        .disabled(!viewModel.canPause || !purchaseAllowsUse)
                        .opacity((viewModel.canPause && purchaseAllowsUse) ? 1 : 0.45)

                        Button("End") {
                            onRequestEndSession()
                        }
                        .modifier(SlabEndButtonStyle(
                            appearance: appearance,
                            fontSize: layout.controlFontSize
                        ))
                        .disabled(viewModel.state.sessionState == .idle || !purchaseAllowsUse)
                        .opacity(purchaseAllowsUse ? 1 : 0.45)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, DesignSpacing.spacing2)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(appearance.headerBackground)
    }

    private func row2(height: CGFloat) -> some View {
        let labelReserve = layout.heroActivityLabelFontSize + DesignSpacing.spacing2 + DesignSpacing.spacing3
        let heroFontSize = max(layout.heroTimerBaseSize * 0.9, max(1, height - labelReserve) * 0.52)
        return VStack(spacing: DesignSpacing.spacing2) {
            Text(viewModel.timerSlabRow1CurrentSessionTitle)
                .font(.system(size: layout.heroActivityLabelFontSize, weight: appearance.usesUppercaseLabels ? .heavy : .semibold))
                .modifier(OptionalUppercase(enabled: appearance.usesUppercaseLabels))
                .tracking(appearance.usesUppercaseLabels ? 0.45 : 0)
                .foregroundStyle(appearance.heroForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(viewModel.heroCountdownText)
                .id(viewModel.heroTimerDisplayIdentity)
                .font(layout == .mainWindow ? .macDSTimerDigits(size: heroFontSize) : .fhTimer(size: heroFontSize))
                .foregroundStyle(appearance.heroForeground)
                .minimumScaleFactor(0.35)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appearance.heroBackground)
    }

    @ViewBuilder
    private func row3(height: CGFloat) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 3) {
                Text(viewModel.timerSlabCyclesLeftLabel)
                    .font(.system(size: layout.slabStatCaptionFontSize, weight: .medium))
                    .foregroundStyle(appearance.footerLabelTint)
                Text(viewModel.timerSlabCyclesLeftValue)
                    .font(.system(size: layout.slabStatValueFontSize, weight: .bold).monospacedDigit())
                    .foregroundStyle(appearance.footerPrimaryForeground)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignSpacing.spacing2)
            .padding(.vertical, DesignSpacing.spacing2)
            .frame(maxHeight: .infinity)
            .background(appearance.footerColumnCarbon)

            Rectangle()
                .fill(appearance.footerBackground)
                .frame(width: 1)

            upNextCenterColumn(accent: appearance.upNextAccent)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
                .padding(.horizontal, DesignSpacing.spacing2)
                .padding(.vertical, DesignSpacing.spacing2)
                .frame(maxHeight: .infinity)
                .background(appearance.upNextColumnBackground)

            Rectangle()
                .fill(appearance.footerBackground)
                .frame(width: 1)

            VStack(alignment: .center, spacing: 3) {
                Text(viewModel.timerSlabRoundsLeftLabel)
                    .font(.system(size: layout.slabStatCaptionFontSize, weight: .medium))
                    .foregroundStyle(appearance.footerLabelTint)
                Text(viewModel.timerSlabRoundsLeftValue)
                    .font(.system(size: layout.slabStatValueFontSize, weight: .bold).monospacedDigit())
                    .foregroundStyle(appearance.footerPrimaryForeground)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignSpacing.spacing2)
            .padding(.vertical, DesignSpacing.spacing2)
            .frame(maxHeight: .infinity)
            .background(appearance.footerColumnStone)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(appearance.footerBackground)
    }

    @ViewBuilder
    private func upNextCenterColumn(accent: Color) -> some View {
        VStack(alignment: .center, spacing: DesignSpacing.spacing2) {
            Text(viewModel.timerSlabRow3UpNextCaption)
                .font(.system(size: layout.row3UpNextCaptionFontSize, weight: .semibold))
                .modifier(OptionalUppercase(enabled: appearance.usesUppercaseLabels))
                .tracking(appearance.usesUppercaseLabels ? 0.4 : 0)
                .foregroundStyle(appearance.footerSecondaryForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if viewModel.timerSlabNextIntervalPreview.kind == .sessionComplete {
                Text("Done")
                    .font(.system(size: layout.row3UpNextDetailFontSize, weight: .bold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            } else {
                HStack(spacing: 0) {
                    Text(viewModel.timerSlabRow3UpNextDetailPhasePrefix)
                        .font(.system(size: layout.row3UpNextDetailFontSize, weight: .semibold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    Text(viewModel.timerSlabRow3UpNextDetailTimeText)
                        .font(.system(size: layout.row3UpNextDetailFontSize, weight: .bold).monospacedDigit())
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Slab button routing

private struct OptionalUppercase: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.textCase(.uppercase)
        } else {
            content
        }
    }
}

private struct SlabStartButtonStyle: ViewModifier {
    let appearance: TimerSlabAppearance
    let fontSize: CGFloat
    func body(content: Content) -> some View {
        if appearance.usesBrutalistControls {
            content.buttonStyle(SlabCompactPrimaryButtonStyle(fill: .fhBrutalistLime, fontSize: fontSize))
        } else {
            content.buttonStyle(MacDSSlabCompactPrimaryButtonStyle(fontSize: fontSize))
        }
    }
}

private struct SlabPauseButtonStyle: ViewModifier {
    let appearance: TimerSlabAppearance
    let fontSize: CGFloat
    func body(content: Content) -> some View {
        if appearance.usesBrutalistControls {
            content.buttonStyle(SlabCompactPrimaryButtonStyle(fill: .fhColorGold, fontSize: fontSize))
        } else {
            content.buttonStyle(MacDSSlabCompactPrimaryButtonStyle(fontSize: fontSize))
        }
    }
}

private struct SlabEndButtonStyle: ViewModifier {
    let appearance: TimerSlabAppearance
    let fontSize: CGFloat
    func body(content: Content) -> some View {
        if appearance.usesBrutalistControls {
            content.buttonStyle(SlabGoldCompactOutlineButtonStyle(fontSize: fontSize))
        } else {
            content.buttonStyle(MacDSSlabCompactSecondaryButtonStyle(fontSize: fontSize))
        }
    }
}

// MARK: - Legacy popover-only button styles

private struct SlabCompactPrimaryButtonStyle: ButtonStyle {
    var fill: Color
    var fontSize: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .heavy))
            .textCase(.uppercase)
            .tracking(0.35)
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .padding(.vertical, 7)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(fill.opacity(configuration.isPressed ? 0.88 : 1))
            )
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}

private struct SlabGoldCompactOutlineButtonStyle: ButtonStyle {
    var fontSize: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .heavy))
            .textCase(.uppercase)
            .tracking(0.35)
            .foregroundStyle(Color.fhColorGold)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .padding(.vertical, 7)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.fhColorGold.opacity(0.95), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(FocusHackerMotion.easeFast, value: configuration.isPressed)
    }
}
