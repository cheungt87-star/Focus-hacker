import SwiftUI

private struct TimerSessionConfigurationProfileKey: EnvironmentKey {
    static let defaultValue: TimerSessionConfigurationProfile = .mainWindow
}

extension EnvironmentValues {
    var timerSessionConfigurationProfile: TimerSessionConfigurationProfile {
        get { self[TimerSessionConfigurationProfileKey.self] }
        set { self[TimerSessionConfigurationProfileKey.self] = newValue }
    }
}

private enum TimerConfigureRowMetrics {
    static let titleColumnWidth: CGFloat = 108
    static let groupedFieldWidth: CGFloat = 60
    static let chevronColumnWidth: CGFloat = 20
    static let controlRowHeight: CGFloat = 28
    static let durationColonWidth: CGFloat = 8
    static var chevronHalfHeight: CGFloat {
        (controlRowHeight - 1) / 2
    }
    static var durationControlsWidth: CGFloat {
        groupedFieldWidth
            + DesignSpacing.spacing1
            + durationColonWidth
            + DesignSpacing.spacing1
            + groupedFieldWidth
    }
}

/// macOS `Button` + `.plain` often drops clicks on narrow stacked chevrons; use an explicit tap target.
private struct TimerChromeChevronTapTarget: View {
    let systemName: String
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: () -> Void
    @Environment(\.timerChromeTheme) private var chrome
    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: appUISurface, timerChrome: chrome, colorScheme: colorScheme)
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(palette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: TimerConfigureRowMetrics.chevronHalfHeight)
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.35)
            .onTapGesture {
                guard isEnabled else { return }
                action()
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}

enum TimerConfigureFieldEmphasis {
    case primary
    case secondary
}

struct TimerConfigurationFieldRow<Content: View>: View {
    let title: String
    /// Optional left rail dot (Tabata-style phase hint); uses design-system accent colors.
    var phaseAccent: Color?
    var emphasis: TimerConfigureFieldEmphasis = .primary
    @ViewBuilder private var content: () -> Content
    @Environment(\.timerChromeTheme) private var chrome
    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.menuBarPopoverPalette) private var popoverPalette
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: appUISurface, timerChrome: chrome, colorScheme: colorScheme)
    }

    init(
        title: String,
        phaseAccent: Color? = nil,
        emphasis: TimerConfigureFieldEmphasis = .primary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.phaseAccent = phaseAccent
        self.emphasis = emphasis
        self.content = content
    }

    @Environment(\.timerSessionConfigurationProfile) private var configurationProfile

    private var titleFont: Font {
        switch emphasis {
        case .primary:
            return appUISurface == .mainWindow ? .macDSLabel.weight(.semibold) : .fhCaption.weight(.semibold)
        case .secondary:
            if configurationProfile == .menuBarPopoverCustom {
                return .macDSHelper
            }
            return appUISurface == .mainWindow ? .macDSCaption : .fhCaption.weight(.medium)
        }
    }

    private var titleColor: Color {
        if configurationProfile == .menuBarPopoverCustom {
            switch emphasis {
            case .primary:
                return popoverPalette.textPrimary
            case .secondary:
                return popoverPalette.textMuted
            }
        }
        switch emphasis {
        case .primary:
            return palette.textPrimary
        case .secondary:
            return palette.textSecondary
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignSpacing.spacing2) {
            HStack(alignment: .center, spacing: DesignSpacing.spacing2) {
                if let phaseAccent {
                    Circle()
                        .fill(phaseAccent)
                        .frame(width: emphasis == .primary ? 8 : 6, height: emphasis == .primary ? 8 : 6)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: TimerConfigureRowMetrics.titleColumnWidth, alignment: .leading)

            Spacer(minLength: DesignSpacing.spacing2)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

/// Single bordered control: numeric `TextField` and stacked chevrons (shadcn / React Aria style).
private struct TimerChromeGroupedIntField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var isEnabled: Bool = true
    let accessibilityLabel: String
    var onIncrement: (() -> Void)? = nil
    var onDecrement: (() -> Void)? = nil
    var canIncrementOverride: Bool? = nil
    var canDecrementOverride: Bool? = nil
    @Environment(\.timerChromeTheme) private var chrome
    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.timerSessionConfigurationProfile) private var configurationProfile
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: appUISurface, timerChrome: chrome, colorScheme: colorScheme)
    }

    private var focusRingColor: Color {
        configurationProfile == .menuBarPopoverCustom
            ? MacDS.Resolved.accentTeal(for: colorScheme)
            : palette.inputFocusRingColor
    }

    private var defaultCanIncrement: Bool { value < range.upperBound }
    private var defaultCanDecrement: Bool { value > range.lowerBound }
    private var canIncrement: Bool { canIncrementOverride ?? defaultCanIncrement }
    private var canDecrement: Bool { canDecrementOverride ?? defaultCanDecrement }

    private func performIncrement() {
        if let onIncrement {
            onIncrement()
        } else {
            value = min(range.upperBound, value + 1)
        }
    }

    private func performDecrement() {
        if let onDecrement {
            onDecrement()
        } else {
            value = max(range.lowerBound, value - 1)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            TextField(
                accessibilityLabel,
                value: $value,
                format: .number.precision(.fractionLength(0))
            )
            .textFieldStyle(.plain)
            .font(appUISurface == .mainWindow ? .macDSBody.monospacedDigit() : .fhBody.monospacedDigit())
            .foregroundStyle(palette.textPrimary)
            .multilineTextAlignment(.leading)
            .focused($isFocused)
            .labelsHidden()
            .accessibilityLabel(accessibilityLabel)
            .frame(minWidth: 22, maxWidth: .infinity, alignment: .leading)
            .padding(.leading, DesignSpacing.spacing2)
            .padding(.vertical, DesignSpacing.spacing1)
            .padding(.trailing, DesignSpacing.spacing1)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.4)

            VStack(spacing: 0) {
                TimerChromeChevronTapTarget(
                    systemName: "chevron.up",
                    isEnabled: isEnabled && canIncrement,
                    accessibilityLabel: "Increase \(accessibilityLabel)",
                    action: performIncrement
                )

                Rectangle()
                    .fill(palette.borderDefault)
                    .frame(height: 1)
                    .allowsHitTesting(false)

                TimerChromeChevronTapTarget(
                    systemName: "chevron.down",
                    isEnabled: isEnabled && canDecrement,
                    accessibilityLabel: "Decrease \(accessibilityLabel)",
                    action: performDecrement
                )
            }
            .frame(
                width: TimerConfigureRowMetrics.chevronColumnWidth,
                height: TimerConfigureRowMetrics.controlRowHeight
            )
            .contentShape(Rectangle())
            .zIndex(1)
            .disabled(!isEnabled)
        }
        .frame(minHeight: TimerConfigureRowMetrics.controlRowHeight)
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
                    .stroke(focusRingColor, lineWidth: 2)
                    .shadow(color: focusRingColor.opacity(0.35), radius: 3, x: 0, y: 0)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct TimerDurationColonSeparator: View {
    @Environment(\.timerChromeTheme) private var chrome
    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: appUISurface, timerChrome: chrome, colorScheme: colorScheme)
    }

    var body: some View {
        Text(":")
            .font(appUISurface == .mainWindow ? .macDSBody.monospacedDigit() : .fhBody.monospacedDigit())
            .foregroundStyle(palette.textSecondary)
            .frame(width: TimerConfigureRowMetrics.durationColonWidth)
            .accessibilityHidden(true)
    }
}

struct TimerDurationMinuteSecondFields: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    var minuteRange: ClosedRange<Int> = 0...120
    var secondRange: ClosedRange<Int> = 0...59
    var isEnabled: Bool = true
    /// When set, decrement is blocked once total duration would fall below this value.
    var minimumTotalSeconds: Int? = nil
    /// When disabled, show an em dash placeholder instead of numeric fields.
    var showsBlankWhenDisabled: Bool = false
    @Environment(\.timerChromeTheme) private var chrome
    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: appUISurface, timerChrome: chrome, colorScheme: colorScheme)
    }

    private var secondsCanIncrement: Bool {
        seconds < secondRange.upperBound || minutes < minuteRange.upperBound
    }

    private var totalDurationSeconds: Int {
        TimerConfiguration.composeDuration(minutes: minutes, seconds: seconds)
    }

    private var secondsCanDecrement: Bool {
        if let minimumTotalSeconds,
           totalDurationSeconds <= minimumTotalSeconds {
            return false
        }
        if minutes == minuteRange.lowerBound, seconds <= secondRange.lowerBound {
            return false
        }
        return seconds > secondRange.lowerBound || minutes > minuteRange.lowerBound
    }

    private var minutesCanDecrement: Bool {
        guard minutes > minuteRange.lowerBound else {
            return false
        }
        if let minimumTotalSeconds {
            let nextTotal = TimerConfiguration.composeDuration(
                minutes: minutes - 1,
                seconds: seconds
            )
            return nextTotal >= minimumTotalSeconds
        }
        return minutes > minuteRange.lowerBound + 1 || seconds > 0
    }

    private var durationAccessibilityValue: String {
        let totalSeconds = TimerConfiguration.composeDuration(minutes: minutes, seconds: seconds)
        let bounded = max(0, totalSeconds)
        return String(format: "%02d:%02d", bounded / 60, bounded % 60)
    }

    var body: some View {
        Group {
            if showsBlankWhenDisabled, !isEnabled {
                sessionBreakBlankPlaceholder
            } else {
                durationFields
            }
        }
    }

    private var sessionBreakBlankPlaceholder: some View {
        HStack(alignment: .center, spacing: DesignSpacing.spacing1) {
            blankDurationSlot()
            TimerDurationColonSeparator()
            blankDurationSlot()
        }
        .frame(width: TimerConfigureRowMetrics.durationControlsWidth, alignment: .trailing)
        .opacity(0.4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session Break")
        .accessibilityValue("Not set")
        .accessibilityHint("Available when Total Sessions is greater than one.")
    }

    private func blankDurationSlot() -> some View {
        Text("—")
            .font(appUISurface == .mainWindow ? .macDSBody.monospacedDigit() : .fhBody.monospacedDigit())
            .foregroundStyle(palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, DesignSpacing.spacing2)
            .padding(.vertical, DesignSpacing.spacing1)
            .frame(width: TimerConfigureRowMetrics.groupedFieldWidth)
            .background(palette.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: MacDS.Radius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: MacDS.Radius.standard)
                    .stroke(palette.borderDefault, lineWidth: 1)
            )
    }

    private var durationFields: some View {
        HStack(alignment: .center, spacing: DesignSpacing.spacing1) {
            TimerChromeGroupedIntField(
                value: $minutes,
                range: minuteRange,
                isEnabled: isEnabled,
                accessibilityLabel: "Minutes",
                canDecrementOverride: minutesCanDecrement
            )
            .frame(width: TimerConfigureRowMetrics.groupedFieldWidth)

            TimerDurationColonSeparator()

            TimerChromeGroupedIntField(
                value: $seconds,
                range: secondRange,
                isEnabled: isEnabled,
                accessibilityLabel: "Seconds",
                onIncrement: {
                    if seconds < secondRange.upperBound {
                        seconds += 1
                    } else if minutes < minuteRange.upperBound {
                        seconds = secondRange.lowerBound
                        minutes += 1
                    }
                },
                onDecrement: {
                    if seconds > secondRange.lowerBound {
                        seconds -= 1
                    } else if minutes > minuteRange.lowerBound {
                        seconds = secondRange.upperBound
                        minutes -= 1
                    }
                },
                canIncrementOverride: secondsCanIncrement,
                canDecrementOverride: secondsCanDecrement
            )
            .frame(width: TimerConfigureRowMetrics.groupedFieldWidth)
        }
        .frame(width: TimerConfigureRowMetrics.durationControlsWidth, alignment: .trailing)
        .accessibilityElement(children: .contain)
        .accessibilityValue(durationAccessibilityValue)
    }
}

struct TimerPositiveIntegerField: View {
    let accessibilityLabel: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...999
    var isEnabled: Bool = true

    var body: some View {
        TimerChromeGroupedIntField(
            value: $value,
            range: range,
            isEnabled: isEnabled,
            accessibilityLabel: accessibilityLabel
        )
        .frame(width: TimerConfigureRowMetrics.groupedFieldWidth, alignment: .trailing)
    }
}

/// Validation ranges and accent styling for timer configuration forms.
enum TimerSessionConfigurationProfile: Equatable, Sendable {
    case mainWindow
    case menuBarPopoverCustom

    var usesTealAccents: Bool {
        switch self {
        case .mainWindow, .menuBarPopoverCustom:
            return true
        }
    }

    var focusMinuteRange: ClosedRange<Int> {
        switch self {
        case .mainWindow:
            return 0...120
        case .menuBarPopoverCustom:
            return 1...60
        }
    }

    var shortBreakMinuteRange: ClosedRange<Int> {
        switch self {
        case .mainWindow:
            return 0...30
        case .menuBarPopoverCustom:
            return 1...30
        }
    }

    var focusSetsRange: ClosedRange<Int> {
        switch self {
        case .mainWindow:
            return 1...99
        case .menuBarPopoverCustom:
            return 1...10
        }
    }

    var totalSessionsRange: ClosedRange<Int> {
        switch self {
        case .mainWindow:
            return 1...10
        case .menuBarPopoverCustom:
            return 1...20
        }
    }

    var sessionBreakMinuteRange: ClosedRange<Int> {
        switch self {
        case .mainWindow:
            return 0...60
        case .menuBarPopoverCustom:
            return 1...60
        }
    }
}

/// Shared work/rest/rounds/cycles/long break fields for the main timer and menu bar popover.
struct TimerSessionConfigurationForm: View {
    @ObservedObject var viewModel: AppShellViewModel
    var isEnabled: Bool
    var sectionTitle: String
    var profile: TimerSessionConfigurationProfile = .mainWindow
    @Environment(\.timerChromeTheme) private var chrome
    @Environment(\.appUISurface) private var appUISurface
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.menuBarPopoverPalette) private var popoverPalette

    private var palette: FormChromePalette {
        FormChromePalette.resolve(surface: resolvedSurface, timerChrome: chrome, colorScheme: colorScheme)
    }

    private var resolvedSurface: AppUISurface {
        profile == .menuBarPopoverCustom ? .menuBarPopover : appUISurface
    }

    private var phaseAccentFocus: Color {
        profile.usesTealAccents ? MacDS.Color.accentTeal : .fhColorEmber
    }

    private var phaseAccentRest: Color {
        profile.usesTealAccents ? MacDS.Color.accentTealLight : .fhColorMint
    }

    private var phaseAccentSets: Color {
        profile.usesTealAccents ? MacDS.Color.accentTeal : .fhColorPowerBlue
    }

    private var phaseAccentSessions: Color {
        profile.usesTealAccents ? MacDS.Color.accentTeal : .fhColorGold
    }

    private var phaseAccentLongRest: Color {
        profile.usesTealAccents ? MacDS.Color.accentTeal : .fhColorSunny
    }

    private var sectionHeaderFont: Font {
        switch profile {
        case .mainWindow:
            return .macDSCardTitle
        case .menuBarPopoverCustom:
            return .macDSLabel.weight(.semibold)
        }
    }

    private var fieldLabelEmphasis: TimerConfigureFieldEmphasis {
        profile == .menuBarPopoverCustom ? .secondary : .primary
    }

    private var sectionHeaderColor: Color {
        profile == .menuBarPopoverCustom ? popoverPalette.textPrimary : palette.textPrimary
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            configureSessionSection
            repeatScheduleSection
        }
        .frame(maxWidth: .infinity)
        .environment(\.timerSessionConfigurationProfile, profile)
        .environment(\.appUISurface, resolvedSurface)
    }

    private var configureSessionSection: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(sectionTitle)
                .font(sectionHeaderFont)
                .foregroundStyle(sectionHeaderColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, DesignSpacing.spacing2)

            fieldBlock(
                title: "Focus Time",
                phaseAccent: phaseAccentFocus
            ) {
                TimerDurationMinuteSecondFields(
                    minutes: $viewModel.focusDurationMinutes,
                    seconds: $viewModel.focusDurationSecondsComponent,
                    minuteRange: profile.focusMinuteRange,
                    secondRange: 0...59,
                    isEnabled: isEnabled,
                    minimumTotalSeconds: profile == .menuBarPopoverCustom ? 60 : nil
                )
            }

            rowDivider

            fieldBlock(
                title: "Short Break",
                phaseAccent: phaseAccentRest
            ) {
                TimerDurationMinuteSecondFields(
                    minutes: $viewModel.shortRestDurationMinutes,
                    seconds: $viewModel.shortRestDurationSecondsComponent,
                    minuteRange: profile.shortBreakMinuteRange,
                    secondRange: 0...59,
                    isEnabled: isEnabled,
                    minimumTotalSeconds: profile == .menuBarPopoverCustom ? 60 : nil
                )
            }

            rowDivider

            fieldBlock(
                title: "Focus Sets",
                phaseAccent: phaseAccentSets
            ) {
                TimerPositiveIntegerField(
                    accessibilityLabel: "Focus Sets",
                    value: $viewModel.roundsPerSession,
                    range: profile.focusSetsRange,
                    isEnabled: isEnabled
                )
            }
        }
    }

    private var repeatScheduleSection: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Repeat Schedule")
                .font(sectionHeaderFont)
                .foregroundStyle(sectionHeaderColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignSpacing.spacing2)
                .padding(.bottom, DesignSpacing.spacing2)
                .accessibilityLabel("Repeat schedule")
                .accessibilityValue(
                    viewModel.sessionBreakConfigurationEnabled
                        ? "\(viewModel.cyclesPerSession) sessions with breaks between"
                        : "\(viewModel.cyclesPerSession) session"
                )

            fieldBlock(
                title: "Total Sessions",
                phaseAccent: phaseAccentSessions
            ) {
                TimerPositiveIntegerField(
                    accessibilityLabel: "Total Sessions",
                    value: $viewModel.cyclesPerSession,
                    range: profile.totalSessionsRange,
                    isEnabled: isEnabled
                )
            }

            if viewModel.sessionBreakConfigurationEnabled {
                rowDivider

                fieldBlock(
                    title: "Session Break",
                    phaseAccent: phaseAccentLongRest
                ) {
                    TimerDurationMinuteSecondFields(
                        minutes: $viewModel.longRestDurationMinutes,
                        seconds: $viewModel.longRestDurationSecondsComponent,
                        minuteRange: profile.sessionBreakMinuteRange,
                        secondRange: 0...59,
                        isEnabled: isEnabled,
                        minimumTotalSeconds: profile == .menuBarPopoverCustom ? 60 : nil,
                        showsBlankWhenDisabled: false
                    )
                }
                .accessibilityHint("Rest between each repetition of this session.")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(FocusHackerMotion.easeFast, value: viewModel.sessionBreakConfigurationEnabled)
    }

    private var rowDivider: some View {
        Divider()
            .frame(maxWidth: .infinity)
            .overlay(palette.borderDefault)
            .padding(.vertical, DesignSpacing.spacing1)
    }

    private func fieldBlock<Content: View>(
        title: String,
        phaseAccent: Color?,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        TimerConfigurationFieldRow(
            title: title,
            phaseAccent: phaseAccent,
            emphasis: fieldLabelEmphasis,
            content: content
        )
        .padding(.vertical, DesignSpacing.spacing1)
    }
}
