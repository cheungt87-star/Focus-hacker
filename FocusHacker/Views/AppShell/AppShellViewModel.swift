import Combine
import Foundation
import SwiftUI

// Keeping timer + transition orchestration in one type matches the menubar/window shell UX.
// swiftlint:disable type_body_length
@MainActor
final class AppShellViewModel: ObservableObject {
    @Published private(set) var state: AppShellState

    /// Website / app blocker settings and filter onboarding (`BlockerSettingsController`).
    let blockerSettings: BlockerSettingsController

    @Published var selectedSection: AppShellSection {
        didSet {
            // #region agent log
            DebugSessionLog82afba.write(
                hypothesisId: "H2",
                location: "AppShellViewModel.selectedSection",
                message: "section_changed",
                data: [
                    "from": oldValue.rawValue,
                    "to": selectedSection.rawValue,
                ]
            )
            // #endregion
            dependencies.settingsStore.selectedAppShellSection = selectedSection.rawValue
            if selectedSection == .history {
                refreshAllProfileData()
            }
            if selectedSection == .analytics {
                analyticsRefreshToken &+= 1
            }
        }
    }
    @Published var appearancePreference: AppearancePreference {
        didSet {
            dependencies.settingsStore.appearancePreference = appearancePreference
            MenuBarExtraAppearanceController.apply(preference: appearancePreference)
        }
    }
    @Published var focusDurationMinutes: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(focusDurationMinutes, range: 0...120)
            if clamped != focusDurationMinutes {
                focusDurationMinutes = clamped
                return
            }
            persistFocusDuration()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var focusDurationSecondsComponent: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(focusDurationSecondsComponent, range: 0...59)
            if clamped != focusDurationSecondsComponent {
                focusDurationSecondsComponent = clamped
                return
            }
            persistFocusDuration()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var shortRestDurationMinutes: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(shortRestDurationMinutes, range: 0...30)
            if clamped != shortRestDurationMinutes {
                shortRestDurationMinutes = clamped
                return
            }
            persistShortRestDuration()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var shortRestDurationSecondsComponent: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(shortRestDurationSecondsComponent, range: 0...59)
            if clamped != shortRestDurationSecondsComponent {
                shortRestDurationSecondsComponent = clamped
                return
            }
            persistShortRestDuration()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var longRestDurationMinutes: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(longRestDurationMinutes, range: 0...60)
            if clamped != longRestDurationMinutes {
                longRestDurationMinutes = clamped
                return
            }
            guard sessionBreakConfigurationEnabled else {
                return
            }
            persistLongRestDuration()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var longRestDurationSecondsComponent: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(longRestDurationSecondsComponent, range: 0...59)
            if clamped != longRestDurationSecondsComponent {
                longRestDurationSecondsComponent = clamped
                return
            }
            guard sessionBreakConfigurationEnabled else {
                return
            }
            persistLongRestDuration()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var roundsPerSession: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(roundsPerSession, range: 1...99)
            if clamped != roundsPerSession {
                roundsPerSession = clamped
                return
            }
            dependencies.settingsStore.roundsPerSession = clamped
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var cyclesPerSession: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(cyclesPerSession, range: 1...20)
            if clamped != cyclesPerSession {
                cyclesPerSession = clamped
                return
            }
            dependencies.settingsStore.cyclesPerSession = clamped
            syncSessionBreakEditorToCyclesCount()
            invalidateFocusPresetIfEdited()
        }
    }
    @Published var selectedFocusPresetID: String? {
        didSet {
            dependencies.settingsStore.lastSelectedFocusPresetID = selectedFocusPresetID
        }
    }
    @Published var selectedSoundPack: AudioSoundPack {
        didSet {
            dependencies.settingsStore.selectedSoundPackIdentifier = selectedSoundPack.rawValue
        }
    }
    @Published var selectedVoiceOption: VoiceOption {
        didSet {
            dependencies.settingsStore.selectedVoiceOption = selectedVoiceOption.rawValue
            dependencies.audioCueService.voiceOption = selectedVoiceOption
        }
    }
    @Published var isAudioMuted: Bool {
        didSet {
            dependencies.settingsStore.isAudioMuted = isAudioMuted
        }
    }

    @Published var showsEndSessionConfirmation = false
    /// Non-nil while the menu-bar “Get Ready” pre-start countdown is active (popover start only).
    @Published private(set) var menuBarGetReadySecondsRemaining: Int?
    /// Bumped on each menu-bar label tick so `MenuBarExtra` repaints reliably.
    @Published private(set) var menuBarLabelRevision = 0
    @Published var completionBannerText: String?
    @Published var levelUpBannerText: String?
    @Published private(set) var totalLifetimeXP: Int = 0
    @Published private(set) var defaultWeeklyStreak: Int = 0
    @Published private(set) var personalWeeklyStreak: Int = 0
    @Published private(set) var longestDefaultWeeklyStreak: Int = 0
    @Published private(set) var longestPersonalWeeklyStreak: Int = 0
    @Published private(set) var lifetimeEndedSessionCount: Int = 0
    @Published private(set) var nextBadgeTitle: String = "Rookie"
    @Published private(set) var xpToNextBadge: Int = 0
    @Published private(set) var badgeProgressFraction: Double = 0

    @Published var profileDisplayName: String {
        didSet {
            let sanitized = UserDefaultsSettingsStore.sanitizeProfileDisplayName(profileDisplayName)
            if sanitized != profileDisplayName {
                profileDisplayName = sanitized
                return
            }
            dependencies.settingsStore.profileDisplayName = sanitized
        }
    }

    @Published private(set) var focusChartBuckets: [FocusHoursChartBucket] = []

    @Published private(set) var weeklyXPEarned: Int = 0
    @Published private(set) var playerLevel: Int = 0
    @Published private(set) var playerLevelTitle: String = FocusBadgeProgression.preTier.title

    @Published var statsDashboardWindow: StatsDashboardWindow = .week
    @Published var profileChartPeriod: ProfileChartPeriod = .week
    @Published var profileChartWeekStart: Date
    @Published var profileChartMonthStart: Date
    @Published var profileChartYearStart: Date

    @Published private(set) var profileIsLoading = false
    @Published private(set) var focusChartIsLoading = false
    /// Bumped when gamification/session data changes so Analytics reloads from SwiftData.
    @Published private(set) var analyticsRefreshToken: UInt = 0
    @Published private(set) var focusChartLastUpdated: Date?
    @Published private(set) var currentWeekFocusMinutes: Int = 0

    @Published var personalWeeklyMinutesTargetSelection: Int

    @Published var personalWeeklyTargetHoursComponent: Int {
        didSet {
            guard !isSyncingPersonalWeeklyTargetParts else { return }
            syncPersonalWeeklyTargetFromParts()
        }
    }

    @Published var personalWeeklyTargetMinutesComponent: Int {
        didSet {
            guard !isSyncingPersonalWeeklyTargetParts else { return }
            syncPersonalWeeklyTargetFromParts()
        }
    }

    private var isSyncingPersonalWeeklyTargetParts = false

    var profileHandleDisplay: String {
        ProfileDashboardMetrics.profileHandle(from: profileDisplayName)
    }

    var weeklyMinutesProgressFraction: Double {
        ProfileDashboardMetrics.weeklyMinutesProgressFraction(currentMinutes: currentWeekFocusMinutes)
    }

    var weeklyMinutesRemaining: Int {
        ProfileDashboardMetrics.weeklyMinutesRemaining(currentMinutes: currentWeekFocusMinutes)
    }

    var weeklyMinutesPercentDisplay: Int {
        ProfileDashboardMetrics.weeklyMinutesPercentDisplay(currentMinutes: currentWeekFocusMinutes)
    }

    var weeklyMinutesTargetDisplay: Int {
        ProfileDashboardMetrics.defaultWeeklyMinutesTarget
    }

    private var hackerWeeklyGoalSnapshot: ProfileWeeklyGoalSnapshot {
        let target = ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        return ProfileWeeklyGoalSnapshot(
            fraction: ProfileDashboardMetrics.weeklyMinutesProgressFraction(
                currentMinutes: currentWeekFocusMinutes,
                targetMinutes: target
            ),
            percentDisplay: ProfileDashboardMetrics.weeklyMinutesPercentDisplay(
                currentMinutes: currentWeekFocusMinutes,
                targetMinutes: target
            ),
            currentMinutes: currentWeekFocusMinutes,
            targetMinutes: target
        )
    }

    private var personalWeeklyGoalSnapshot: ProfileWeeklyGoalSnapshot {
        let target = dependencies.settingsStore.personalWeeklyMinutesTarget
        return ProfileWeeklyGoalSnapshot(
            fraction: ProfileDashboardMetrics.weeklyMinutesProgressFraction(
                currentMinutes: currentWeekFocusMinutes,
                targetMinutes: target
            ),
            percentDisplay: ProfileDashboardMetrics.weeklyMinutesPercentDisplay(
                currentMinutes: currentWeekFocusMinutes,
                targetMinutes: target
            ),
            currentMinutes: currentWeekFocusMinutes,
            targetMinutes: target
        )
    }

    var hackerWeeklyCurrentMinutes: Int {
        hackerWeeklyGoalSnapshot.currentMinutes
    }

    var hackerWeeklyTargetMinutes: Int {
        hackerWeeklyGoalSnapshot.targetMinutes
    }

    var hackerWeeklyProgressFraction: Double {
        hackerWeeklyGoalSnapshot.fraction
    }

    var hackerWeeklyMinutesRemaining: Int {
        ProfileDashboardMetrics.weeklyMinutesRemaining(
            currentMinutes: hackerWeeklyCurrentMinutes,
            targetMinutes: hackerWeeklyTargetMinutes
        )
    }

    var hackerWeeklyMinutesPercentDisplay: Int {
        hackerWeeklyGoalSnapshot.percentDisplay
    }

    var personalWeeklyCurrentMinutes: Int {
        personalWeeklyGoalSnapshot.currentMinutes
    }

    var personalWeeklyTargetMinutes: Int {
        personalWeeklyGoalSnapshot.targetMinutes
    }

    var personalWeeklyProgressFraction: Double {
        personalWeeklyGoalSnapshot.fraction
    }

    var personalWeeklyMinutesRemaining: Int {
        ProfileDashboardMetrics.weeklyMinutesRemaining(
            currentMinutes: personalWeeklyCurrentMinutes,
            targetMinutes: personalWeeklyTargetMinutes
        )
    }

    var personalWeeklyMinutesPercentDisplay: Int {
        personalWeeklyGoalSnapshot.percentDisplay
    }

    func applyPersonalWeeklyMinutesTarget(_ newValue: Int) {
        let clamped = UserDefaultsSettingsStore.clampPersonalWeeklyMinutes(newValue)
        personalWeeklyMinutesTargetSelection = clamped
        dependencies.settingsStore.personalWeeklyMinutesTarget = clamped
        refreshProfileDashboard()
        applyPersonalWeeklyTargetPartsFromStoredTotal()
    }

    private func syncPersonalWeeklyTargetFromParts() {
        let normalized = PersonalWeeklyTargetFormatting.normalizedParts(
            hours: personalWeeklyTargetHoursComponent,
            minutes: personalWeeklyTargetMinutesComponent
        )
        if normalized.totalMinutes != personalWeeklyMinutesTargetSelection {
            applyPersonalWeeklyMinutesTarget(normalized.totalMinutes)
            return
        }
        applyPersonalWeeklyTargetPartsFromStoredTotal()
    }

    private func applyPersonalWeeklyTargetPartsFromStoredTotal() {
        let parts = PersonalWeeklyTargetFormatting.split(
            totalMinutes: personalWeeklyMinutesTargetSelection
        )
        guard parts.hours != personalWeeklyTargetHoursComponent || parts.minutes != personalWeeklyTargetMinutesComponent else {
            return
        }
        isSyncingPersonalWeeklyTargetParts = true
        personalWeeklyTargetHoursComponent = parts.hours
        personalWeeklyTargetMinutesComponent = parts.minutes
        isSyncingPersonalWeeklyTargetParts = false
    }

    let dependencies: AppDependencies
    private var stateStreamTask: Task<Void, Never>?
    private var transitionStreamTask: Task<Void, Never>?
    private var menuBarGetReadyTask: Task<Void, Never>?
    private var gamificationHourlyRefresh: AnyCancellable?
    private var isApplyingFocusPreset = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.blockerSettings = BlockerSettingsController(
            settingsStore: dependencies.settingsStore,
            blockerService: dependencies.blockerService
        )
        self.state = AppShellState.initial
        self.selectedSection = AppShellSection(rawValue: dependencies.settingsStore.selectedAppShellSection) ?? .history
        self.appearancePreference = dependencies.settingsStore.appearancePreference
        let focusSplit = TimerConfiguration.splitDuration(seconds: dependencies.settingsStore.focusDurationSeconds)
        self.focusDurationMinutes = focusSplit.minutes
        self.focusDurationSecondsComponent = focusSplit.seconds
        let shortRestSplit = TimerConfiguration.splitDuration(seconds: dependencies.settingsStore.shortRestDurationSeconds)
        self.shortRestDurationMinutes = shortRestSplit.minutes
        self.shortRestDurationSecondsComponent = shortRestSplit.seconds
        let storedCyclesPerSession = dependencies.settingsStore.cyclesPerSession
        let longRestSplit = TimerConfiguration.splitDuration(seconds: dependencies.settingsStore.longRestDurationSeconds)
        if storedCyclesPerSession <= 1 {
            self.longRestDurationMinutes = 0
            self.longRestDurationSecondsComponent = 0
        } else {
            self.longRestDurationMinutes = longRestSplit.minutes
            self.longRestDurationSecondsComponent = longRestSplit.seconds
        }
        self.roundsPerSession = dependencies.settingsStore.roundsPerSession
        self.cyclesPerSession = storedCyclesPerSession
        self.selectedFocusPresetID = dependencies.settingsStore.lastSelectedFocusPresetID
        self.selectedSoundPack = AudioSoundPack.from(
            storedIdentifier: dependencies.settingsStore.selectedSoundPackIdentifier
        )
        let resolvedVoiceOption = VoiceOption.resolve(
            storedIdentifier: dependencies.settingsStore.selectedVoiceOption
        )
        self.selectedVoiceOption = resolvedVoiceOption
        self.isAudioMuted = dependencies.settingsStore.isAudioMuted
        let personalTargetMinutes = dependencies.settingsStore.personalWeeklyMinutesTarget
        self.personalWeeklyMinutesTargetSelection = personalTargetMinutes
        let personalTargetParts = PersonalWeeklyTargetFormatting.split(totalMinutes: personalTargetMinutes)
        self.personalWeeklyTargetHoursComponent = personalTargetParts.hours
        self.personalWeeklyTargetMinutesComponent = personalTargetParts.minutes
        self.profileDisplayName = dependencies.settingsStore.profileDisplayName
        let chartNow = Date()
        let chartCalendar = Calendar.current
        self.profileChartWeekStart = ProfileChartNavigation.currentWeekStart(now: chartNow, calendar: chartCalendar)
        self.profileChartMonthStart = ProfileChartNavigation.currentMonthStart(now: chartNow, calendar: chartCalendar)
        self.profileChartYearStart = ProfileChartNavigation.currentYearStart(now: chartNow, calendar: chartCalendar)
        dependencies.audioCueService.voiceOption = resolvedVoiceOption
        DockIconVisibilityController.apply(showsDockIcon: true)
        MenuBarExtraAppearanceController.apply(preference: appearancePreference)
        startListeningToTimer()
        refreshGamificationStats()

        gamificationHourlyRefresh = Timer.publish(every: 3_600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshGamificationStats()
            }

    }

    deinit {
        gamificationHourlyRefresh?.cancel()
        stateStreamTask?.cancel()
        transitionStreamTask?.cancel()
        menuBarGetReadyTask?.cancel()
    }

    var isMenuBarGetReadyActive: Bool {
        menuBarGetReadySecondsRemaining != nil
    }

    var menuBarText: String {
        if let seconds = menuBarGetReadySecondsRemaining {
            return MenuBarGetReadyCountdown.menuBarPillText(secondsRemaining: seconds)
        }
        return state.menuBarText
    }

    var menuBarAccessibilityLabel: String {
        if let seconds = menuBarGetReadySecondsRemaining {
            return MenuBarGetReadyCountdown.menuBarAccessibilityLabel(secondsRemaining: seconds)
        }
        return state.menuBarAccessibilityLabel
    }

    var menuBarShowsPill: Bool {
        isMenuBarGetReadyActive || state.menuBarPresentation != .neutral
    }

    var menuBarPillText: String {
        if menuBarGetReadySecondsRemaining != nil {
            return menuBarText
        }
        return state.menuBarCompactPillText
    }

    var menuBarPillBackground: Color {
        if isMenuBarGetReadyActive {
            return MacDS.Color.accentOrange
        }
        switch state.menuBarPresentation {
        case .neutral:
            return .clear
        case .focus:
            return .fhColorAqua
        case .rest:
            return .fhColorEmber
        case .paused:
            return .fhColorDSStone
        }
    }

    var menuBarShouldFlash: Bool {
        guard !isMenuBarGetReadyActive else {
            return false
        }
        return state.menuBarShouldFlash
    }

    var shouldShowStartButton: Bool {
        state.sessionState == .idle && !isMenuBarGetReadyActive
    }

    var shouldShowCancelGetReadyButton: Bool {
        isMenuBarGetReadyActive
    }

    var pauseButtonTitle: String {
        state.isSessionPaused ? "Resume" : "Pause"
    }

    var isBlockingSetupReady: Bool {
        AutomationPermissionPrimer.isBrowserBlockingReady
    }

    /// Deprecated alias — use `isBlockingSetupReady`.
    var isBlockerFilteringReady: Bool {
        isBlockingSetupReady
    }

    var notificationAuthorizationPromptRecorded: Bool {
        dependencies.settingsStore.notificationAuthorizationPromptWasRecorded
    }

    var notificationAuthorizationLastGrantedSnapshot: Bool {
        dependencies.settingsStore.lastNotificationAuthorizationGrantedSnapshot
    }

    var canPause: Bool {
        state.sessionState != .idle
    }

    var elapsedSessionDisplay: String {
        AppShellTimerFormatting.sessionDurationClock(seconds: state.elapsedSessionSeconds)
    }

    var completedWorkDisplay: String {
        AppShellTimerFormatting.sessionDurationClock(seconds: state.completedWorkSeconds)
    }

    /// Session break is only user-configurable when more than one total session is planned.
    var sessionBreakConfigurationEnabled: Bool {
        cyclesPerSession > 1
    }

    /// Long rest used for previews and `startSession`; zero when session break is unavailable.
    var effectiveLongRestDurationSeconds: Int {
        sessionBreakConfigurationEnabled ? longRestDurationTotalSeconds : 0
    }

    /// Current editor values as the same model used to start a session.
    var stagingTimerConfiguration: TimerConfiguration {
        TimerConfiguration(
            focusDurationSeconds: focusDurationTotalSeconds,
            shortRestDurationSeconds: shortRestDurationTotalSeconds,
            longRestDurationSeconds: effectiveLongRestDurationSeconds,
            roundsPerSession: roundsPerSession,
            cyclesPerSession: cyclesPerSession
        )
    }

    var menuBarSessionStatLabel: String {
        state.sessionState == .idle ? "Total session time" : "Session time left"
    }

    var menuBarFocusStatLabel: String {
        state.sessionState == .idle ? "Total focus time" : "Focus time left"
    }

    /// Popover timer card — top config band labels.
    var popoverConfigFocusTimeLabel: String { "Focus time" }
    var popoverConfigRestTimeLabel: String { "Rest time" }

    var popoverConfigCyclesLabel: String {
        state.sessionState == .idle ? "Cycles" : "Cycles left"
    }

    /// Focus sets per cycle when idle; rounds remaining in the active cycle when running.
    var popoverConfigCyclesValue: String {
        if state.sessionState == .idle {
            return "\(max(1, roundsPerSession))"
        }
        guard let currentRound = state.currentRound,
              let totalRounds = state.totalRounds,
              totalRounds > 0,
              let phase = state.intervalPhase
        else {
            return "—"
        }
        switch phase {
        case .focus:
            return "\(max(1, totalRounds - currentRound + 1))"
        case .shortRest, .longRest:
            return "\(max(0, totalRounds - currentRound))"
        }
    }

    var popoverSessionsStatLabel: String {
        state.sessionState == .idle ? "Sessions" : "Sessions left"
    }

    var popoverSessionsStatValue: String {
        timerSlabCyclesLeftValue
    }

    var menuBarThirdStatLabel: String {
        state.sessionState == .idle ? "Total sets" : "Rounds left"
    }

    var menuBarSessionStatValue: String {
        let cfg = stagingTimerConfiguration
        if state.sessionState == .idle {
            return AppShellTimerFormatting.sessionDurationClock(
                seconds: cfg.plannedWallClockSecondsExcludingTransitions
            )
        }
        let remaining = max(0, cfg.plannedWallClockSecondsExcludingTransitions - state.elapsedSessionSeconds)
        return AppShellTimerFormatting.sessionDurationClock(seconds: remaining)
    }

    var timerSlabRow1IdleCombinedStatLine: String {
        "Total session: \(menuBarSessionStatValue)  |  Total focus: \(menuBarFocusStatValue)"
    }

    var menuBarFocusStatValue: String {
        let cfg = stagingTimerConfiguration
        if state.sessionState == .idle {
            return AppShellTimerFormatting.sessionDurationClock(seconds: cfg.plannedTotalFocusSeconds)
        }
        let remaining = max(0, cfg.plannedTotalFocusSeconds - state.completedWorkSeconds)
        return AppShellTimerFormatting.sessionDurationClock(seconds: remaining)
    }

    var menuBarThirdStatValue: String {
        let cfg = stagingTimerConfiguration
        let planned = cfg.plannedFocusIntervalCount
        if state.sessionState == .idle {
            return "\(planned)"
        }
        let completed = state.completedPlannedFocusIntervals ?? 0
        return "\(max(0, planned - completed))"
    }

    var timerSlabNextIntervalPreview: TimerNextIntervalPreview {
        TimerNextIntervalPreview.resolve(configuration: stagingTimerConfiguration, state: state)
    }

    /// Top-row center: current session phase (TimerPlus-style all-caps strip).
    var timerSlabRow1CurrentSessionTitle: String {
        if isMenuBarGetReadyActive {
            return "GET READY"
        }
        if state.isSessionPaused {
            return "PAUSED"
        }
        if state.sessionState == .idle {
            return "READY"
        }
        switch state.intervalPhase {
        case .focus:
            return "FOCUS"
        case .shortRest:
            return "SHORT BREAK"
        case .longRest:
            return "SESSION BREAK"
        case nil:
            return "READY"
        }
    }

    /// When `false`, row1 hides the center phase strip (idle “READY”) while row2 still shows it.
    var showsTimerSlabRow1CenterTitle: Bool {
        if isMenuBarGetReadyActive {
            return true
        }
        if state.isSessionPaused {
            return true
        }
        if state.sessionState == .idle {
            return false
        }
        return true
    }

    /// Footer “Up next” column background from the upcoming interval kind.
    var timerSlabUpNextColumnBackground: Color {
        switch timerSlabNextIntervalPreview.kind {
        case .focus:
            return .fhColorDSUpNextFocusBg
        case .shortRest:
            return .fhColorDSUpNextShortRestBg
        case .longRest:
            return .fhColorDSUpNextLongRestBg
        case .sessionComplete:
            return .fhColorDSSurface
        }
    }

    var timerSlabRow3UpNextCaption: String {
        "UP NEXT"
    }

    /// Second line under UP NEXT (e.g. `Short break: 05:00`), or `Done` when the session is complete.
    var timerSlabRow3UpNextDetailLine: String {
        let preview = timerSlabNextIntervalPreview
        if preview.kind == .sessionComplete {
            return "Done"
        }
        guard let seconds = preview.durationSeconds else {
            return "\(preview.footerPhaseName): —"
        }
        return "\(preview.footerPhaseName): \(AppShellTimerFormatting.countdownText(seconds: seconds))"
    }

    /// Accent for the up-next detail line (tuned for tinted column backgrounds in the timer slab).
    var timerSlabRow3UpNextDetailColor: Color {
        switch timerSlabNextIntervalPreview.kind {
        case .focus:
            return .fhBrutalistLime
        case .shortRest, .longRest:
            return .fhColorWhite
        case .sessionComplete:
            return .fhColorDSSmoke
        }
    }

    /// Phase name plus colon and space (not used when `sessionComplete`).
    var timerSlabRow3UpNextDetailPhasePrefix: String {
        "\(timerSlabNextIntervalPreview.footerPhaseName): "
    }

    /// Countdown for next interval, or em dash when duration is unknown (not used when `sessionComplete`).
    var timerSlabRow3UpNextDetailTimeText: String {
        let preview = timerSlabNextIntervalPreview
        guard let seconds = preview.durationSeconds else {
            return "—"
        }
        return AppShellTimerFormatting.countdownText(seconds: seconds)
    }

    /// Single phrase for VoiceOver on the whole slab.
    var timerSlabRow3UpNextLine: String {
        "Up next. \(timerSlabRow3UpNextDetailLine)"
    }

    /// Menu bar popover hero — sentence-case caption above the countdown.
    var heroUpNextCaption: String {
        "Up next"
    }

    /// Upcoming interval phase name (Focus / Short break / Session break / Done).
    var heroUpNextPhaseName: String {
        timerSlabNextIntervalPreview.footerPhaseName
    }

    /// Full up-next phrase for accessibility on the popover timer card.
    var heroUpNextLine: String {
        "\(heroUpNextCaption): \(heroUpNextPhaseName)"
    }

    var timerSlabCyclesLeftLabel: String {
        "Cycles left"
    }

    var timerSlabCyclesLeftValue: String {
        let cfg = stagingTimerConfiguration
        if state.sessionState == .idle {
            return "\(max(1, cfg.cyclesPerSession))"
        }
        guard let totalCycles = state.totalCycles, totalCycles > 0 else {
            return "—"
        }
        if timerSlabNextIntervalPreview.kind == .sessionComplete {
            return "0"
        }
        if totalCycles == 1 {
            return "1"
        }
        guard let currentCycle = state.currentCycle else {
            return "—"
        }
        return "\(max(0, totalCycles - currentCycle + 1))"
    }

    var timerSlabRoundsLeftLabel: String {
        menuBarThirdStatLabel
    }

    var timerSlabRoundsLeftValue: String {
        menuBarThirdStatValue
    }

    var timerSlabAccessibilitySummary: String {
        let centerPhaseForA11y: String
        if showsTimerSlabRow1CenterTitle {
            centerPhaseForA11y = timerSlabRow1CurrentSessionTitle
        } else if state.sessionState == .idle, !state.isSessionPaused {
            centerPhaseForA11y = "Ready"
        } else {
            centerPhaseForA11y = timerSlabRow1CurrentSessionTitle
        }
        return "\(menuBarSessionStatLabel) \(menuBarSessionStatValue). \(centerPhaseForA11y). Time remaining \(heroCountdownText). \(timerSlabCyclesLeftLabel) \(timerSlabCyclesLeftValue). \(timerSlabRoundsLeftLabel) \(timerSlabRoundsLeftValue). \(timerSlabRow3UpNextLine)"
    }

    var canSkipCurrentPhase: Bool {
        state.sessionState != .idle && !state.isSessionPaused && state.remainingSeconds > 0
    }

    var canRestartCurrentInterval: Bool {
        state.sessionState != .idle && state.remainingSeconds > 0
    }

    /// Session wall-clock progress vs configured session length (excludes transition overlays).
    var sessionProgressFraction: Double {
        let denominator = Double(stagingTimerConfiguration.approximateWallClockSeconds)
        return min(1, max(0, Double(state.elapsedSessionSeconds) / denominator))
    }

    /// Hero countdown: staged focus length while idle (live with configuration), otherwise service `remainingSeconds`.
    var heroDisplaySeconds: Int {
        if let seconds = menuBarGetReadySecondsRemaining {
            return seconds
        }
        if state.sessionState == .idle, !state.isSessionPaused {
            return max(1, focusDurationTotalSeconds)
        }
        return state.remainingSeconds
    }

    var heroCountdownText: String {
        AppShellTimerFormatting.countdownText(seconds: heroDisplaySeconds)
    }

    var heroNextUpTitle: String {
        if state.sessionState == .idle {
            return "Next up: Focus time"
        }
        switch state.intervalPhase {
        case .focus:
            return "Next up: Focus"
        case .shortRest:
            return "Next up: Short break"
        case .longRest:
            return "Next up: Session break"
        case nil:
            return "Next up: Focus time"
        }
    }

    var heroNextUpAccessibilityLabel: String {
        "\(heroNextUpTitle), \(heroCountdownText) remaining"
    }

    /// Stable identity so the hero countdown refreshes when idle staging fields change.
    var heroTimerDisplayIdentity: String {
        if let seconds = menuBarGetReadySecondsRemaining {
            return "get-ready-\(seconds)"
        }
        if state.sessionState == .idle, !state.isSessionPaused {
            return "\(focusDurationMinutes)-\(focusDurationSecondsComponent)-\(heroCountdownText)"
        }
        return heroCountdownText
    }

    /// Solid neon slab behind the hero timer (brutalist poster); cases track `heroNextUpTitle`.
    var heroBrutalistBlockBackground: Color {
        if state.sessionState == .idle {
            return .fhColorGold
        }
        switch state.intervalPhase {
        case .focus:
            return .fhBrutalistLime
        case .shortRest:
            return .fhColorSunny
        case .longRest:
            return .fhColorEmber
        case nil:
            return .fhColorGold
        }
    }

    /// Black on bright slabs; white on ember long-rest for contrast.
    var heroBrutalistBlockForeground: Color {
        if state.sessionState != .idle, state.intervalPhase == .longRest {
            return .fhColorWhite
        }
        return .black
    }

    // MARK: - Timer slab header / footer (TimerPlus-style dark bands)

    var timerModeBadgeTitle: String {
        if state.isSessionPaused {
            return "Paused"
        }
        switch state.intervalPhase {
        case nil:
            return "Ready"
        case .focus:
            return "Focus"
        case .shortRest:
            return "Short rest"
        case .longRest:
            return "Long rest"
        }
    }

    // MARK: - Menu bar popover display

    var focusSessionDisplayName: String {
        if FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID) {
            return "Create Custom"
        }
        if let presetID = selectedFocusPresetID,
           let preset = FocusSessionPresets.preset(id: presetID) {
            if preset.isRecommended {
                return "\(preset.name) Recommended"
            }
            return preset.name
        }
        return "Create Custom"
    }

    /// Subtitle under the popover preset carousel (e.g. "25 min focus / 5 min break × 4 cycles").
    var popoverFocusSessionDescription: String {
        if FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID) {
            return "Custom durations"
        }
        if let presetID = selectedFocusPresetID,
           let preset = FocusSessionPresets.preset(id: presetID) {
            return preset.descriptionLine
        }
        return "Custom durations"
    }

    /// True when the popover preset carousel is on the Create Custom slot (form visible, stat cards hidden).
    var isCreateCustomFocusPresetSelected: Bool {
        FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID)
    }

    /// Inline custom duration fields on the focus session card (idle only).
    var focusSessionShowsCustomConfiguration: Bool {
        isCreateCustomFocusPresetSelected
            && state.sessionState == .idle
            && !isMenuBarGetReadyActive
    }

    var popoverTimerSubtext: String {
        if isMenuBarGetReadyActive {
            return MenuBarGetReadyCountdown.label
        }
        if state.sessionState == .idle, !state.isSessionPaused {
            return "Ready to start"
        }
        return timerModeBadgeTitle
    }

    var popoverTimerHeroBackground: Color {
        if isMenuBarGetReadyActive {
            return MacDS.Color.accentOrange
        }
        return Color.clear
    }

    var popoverTimerUsesGetReadyChrome: Bool {
        isMenuBarGetReadyActive
    }

    /// VoiceOver label for the menu bar popover timer hero card.
    var popoverTimerAccessibilityLabel: String {
        "\(heroUpNextLine). \(heroCountdownText) remaining. \(popoverTimerSubtext)"
    }

    var popoverFocusTimeValue: String {
        "\(focusDurationMinutes) min"
    }

    var popoverRestTimeValue: String {
        "\(shortRestDurationMinutes) min"
    }

    var popoverTotalSessionValue: String {
        "\(stagingTimerConfiguration.approximateWallClockMinutes) min"
    }

    var popoverTotalFocusValue: String {
        "\(stagingTimerConfiguration.plannedTotalFocusSeconds / 60) min"
    }

    // MARK: - Focus session card (popover + main window)

    /// Preset carousel title without “Recommended” suffix.
    var focusSessionPresetName: String {
        if FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID) {
            return "Create Custom"
        }
        if let presetID = selectedFocusPresetID,
           let preset = FocusSessionPresets.preset(id: presetID) {
            return preset.name
        }
        return "Create Custom"
    }

    var focusSessionPresetSubtitle: String {
        if focusSessionShowsCustomConfiguration {
            return "Custom session"
        }
        if FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID) {
            return focusSessionCustomCarouselSubtitle
        }
        if let presetID = selectedFocusPresetID,
           let preset = FocusSessionPresets.preset(id: presetID) {
            return preset.carouselDescriptionLine
        }
        return focusSessionCustomCarouselSubtitle
    }

    private var focusSessionCustomCarouselSubtitle: String {
        let rounds = max(1, roundsPerSession)
        return "\(focusDurationMinutes) min · \(shortRestDurationMinutes) min break · \(rounds) cycles"
    }

    var focusSessionUpNextLine: String {
        if isMenuBarGetReadyActive {
            return "GET READY"
        }
        return "UP NEXT · \(focusSessionPhaseLabel)"
    }

    private var focusSessionPhaseLabel: String {
        if state.sessionState == .idle {
            return "FOCUS"
        }
        switch state.intervalPhase {
        case .focus:
            return "FOCUS"
        case .shortRest, .longRest:
            return "BREAK"
        case nil:
            return "FOCUS"
        }
    }

    var focusSessionCyclePillText: String {
        let total = max(1, roundsPerSession)
        if state.sessionState == .idle {
            return "1 / \(total)"
        }
        guard let current = state.currentRound else {
            return "— / \(total)"
        }
        return "\(current) / \(total)"
    }

    var focusSessionTotalStatLabel: String {
        state.sessionState == .idle ? "TOTAL" : "SESSION LEFT"
    }

    var focusSessionFocusStatLabel: String {
        state.sessionState == .idle ? "FOCUS" : "FOCUS LEFT"
    }

    var focusSessionSessionsStatLabel: String {
        state.sessionState == .idle ? "SESSIONS" : "SESSIONS LEFT"
    }

    var focusSessionTotalStatValue: String {
        menuBarSessionStatValue
    }

    var focusSessionFocusStatValue: String {
        menuBarFocusStatValue
    }

    var focusSessionSessionsStatValue: String {
        popoverSessionsStatValue
    }

    var focusSessionPrimaryButtonTitle: String {
        if shouldShowCancelGetReadyButton {
            return "Cancel"
        }
        if shouldShowStartButton {
            return "Start focus"
        }
        if state.isSessionPaused {
            return "Resume"
        }
        return "Pause"
    }

    var focusSessionPrimaryButtonUsesPlayIcon: Bool {
        shouldShowStartButton || state.isSessionPaused
    }

    var focusSessionPrimaryButtonUsesPauseIcon: Bool {
        !shouldShowStartButton && !shouldShowCancelGetReadyButton && !state.isSessionPaused
    }

    var focusSessionShowsEndSessionButton: Bool {
        state.sessionState != .idle && !isMenuBarGetReadyActive
    }

    var focusSessionAccessibilitySummary: String {
        [
            "Focus session",
            "\(focusSessionPresetName). \(focusSessionPresetSubtitle)",
            focusSessionUpNextLine,
            "\(heroCountdownText) remaining",
            "Cycle \(focusSessionCyclePillText)",
            "\(focusSessionTotalStatLabel) \(focusSessionTotalStatValue)",
            "\(focusSessionFocusStatLabel) \(focusSessionFocusStatValue)",
            "\(focusSessionSessionsStatLabel) \(focusSessionSessionsStatValue)"
        ].joined(separator: ". ")
    }

    var timerAccentColor: Color {
        MacDS.Color.accentTeal
    }

    var timerMotivationalLine: String {
        if state.isSessionPaused {
            return "Take a breath — resume when you are ready."
        }
        switch state.intervalPhase {
        case nil:
            return "Dial in your session, then start when you are ready."
        case .focus:
            return "Stay with it — depth beats distraction."
        case .shortRest:
            return "Recharge — you earned this break."
        case .longRest:
            return "Slow down — long breaks keep you sustainable."
        }
    }

    var weeklyProgressFraction: Double {
        hackerWeeklyProgressFraction
    }

    var menuBarWeeklyMinutesLabel: String {
        "\(currentWeekFocusMinutes)/\(ProfileDashboardMetrics.defaultWeeklyMinutesTarget) min"
    }

    var focusHackerDailyTargetMinutes: Int {
        ProfileChartTargets.dailyMinutes(fromWeekly: ProfileDashboardMetrics.defaultWeeklyMinutesTarget)
    }

    var personalDailyTargetMinutes: Int {
        ProfileChartTargets.dailyMinutes(fromWeekly: dependencies.settingsStore.personalWeeklyMinutesTarget)
    }

    func refreshGamificationStats() {
        Task { @MainActor in
            await refreshGamificationStatsAwaiting()
            objectWillChange.send()
        }
    }

    var profileStatusLabel: String {
        state.sessionStateLabel
    }

    var profileStatusIconName: String {
        if state.isSessionPaused {
            return "pause.circle.fill"
        }
        return state.sessionState.iconSymbolName
    }

    var profileLevelSubtitle: String {
        "Level \(playerLevel) · \(playerLevelTitle)"
    }

    func refreshProfileDashboard() {
        refreshAllProfileData()
    }

    var showsProfileChartPeriodNavigation: Bool {
        profileChartPeriod == .week || profileChartPeriod == .month || profileChartPeriod == .year
    }

    var canChartNavigateForward: Bool {
        ProfileChartNavigation.canNavigateForward(
            period: profileChartPeriod,
            weekStart: profileChartWeekStart,
            monthStart: profileChartMonthStart,
            yearStart: profileChartYearStart
        )
    }

    var profileChartRangeTitle: String {
        let calendar = Calendar.current
        switch profileChartPeriod {
        case .week:
            return ProfileChartNavigation.weekRangeTitle(weekStart: profileChartWeekStart, calendar: calendar)
        case .month:
            return ProfileChartNavigation.monthRangeTitle(monthStart: profileChartMonthStart, calendar: calendar)
        case .year:
            return ProfileChartNavigation.yearRangeTitle(yearStart: profileChartYearStart, calendar: calendar)
        }
    }

    func resetProfileChartAnchorsToCurrent() {
        let now = Date()
        let calendar = Calendar.current
        profileChartWeekStart = ProfileChartNavigation.currentWeekStart(now: now, calendar: calendar)
        profileChartMonthStart = ProfileChartNavigation.currentMonthStart(now: now, calendar: calendar)
        profileChartYearStart = ProfileChartNavigation.currentYearStart(now: now, calendar: calendar)
    }

    func selectProfileChartPeriod(_ period: ProfileChartPeriod) {
        profileChartPeriod = period
        resetProfileChartAnchorsToCurrent()
        refreshFocusChart()
    }

    func chartNavigatePrevious() {
        let calendar = Calendar.current
        switch profileChartPeriod {
        case .week:
            if let previous = ProfileChartNavigation.previousWeekStart(from: profileChartWeekStart, calendar: calendar) {
                profileChartWeekStart = previous
            }
        case .month:
            if let previous = ProfileChartNavigation.previousMonthStart(from: profileChartMonthStart, calendar: calendar) {
                profileChartMonthStart = previous
            }
        case .year:
            if let previous = ProfileChartNavigation.previousYearStart(from: profileChartYearStart, calendar: calendar) {
                profileChartYearStart = previous
            }
        }
        refreshFocusChart()
    }

    func chartNavigateNext() {
        guard canChartNavigateForward else { return }
        let calendar = Calendar.current
        switch profileChartPeriod {
        case .week:
            if let next = ProfileChartNavigation.nextWeekStart(from: profileChartWeekStart, calendar: calendar) {
                profileChartWeekStart = next
            }
        case .month:
            if let next = ProfileChartNavigation.nextMonthStart(from: profileChartMonthStart, calendar: calendar) {
                profileChartMonthStart = next
            }
        case .year:
            if let next = ProfileChartNavigation.nextYearStart(from: profileChartYearStart, calendar: calendar) {
                profileChartYearStart = next
            }
        }
        refreshFocusChart()
    }

    /// Reloads only focus-hours chart buckets for the current `profileChartPeriod`.
    func refreshFocusChart() {
        Task { @MainActor in
            focusChartIsLoading = true
            defer { focusChartIsLoading = false }
            await loadFocusChartBuckets()
        }
    }

    /// Loads gamification stats and profile dashboard data together.
    func refreshAllProfileData() {
        Task { @MainActor in
            // #region agent log
            let refreshStart = CFAbsoluteTimeGetCurrent()
            DebugSessionLog82afba.write(
                hypothesisId: "H1",
                location: "AppShellViewModel.refreshAllProfileData",
                message: "refresh_started",
                data: ["section": selectedSection.rawValue]
            )
            // #endregion
            profileIsLoading = true
            defer { profileIsLoading = false }

            await refreshGamificationStatsAwaiting()
            await loadFocusChartBuckets()
            objectWillChange.send()

            // #region agent log
            let refreshMs = Int((CFAbsoluteTimeGetCurrent() - refreshStart) * 1000)
            DebugSessionLog82afba.write(
                hypothesisId: "H1",
                location: "AppShellViewModel.refreshAllProfileData",
                message: "refresh_finished",
                data: [
                    "durationMs": "\(refreshMs)",
                    "section": selectedSection.rawValue,
                ]
            )
            DebugSessionLogAfdf58.write(
                hypothesisId: "H5",
                location: "AppShellViewModel.refreshAllProfileData",
                message: "profile_refreshed",
                data: [
                    "currentWeekFocusMinutes": "\(currentWeekFocusMinutes)",
                    "totalLifetimeXP": "\(totalLifetimeXP)",
                    "chartBucketCount": "\(focusChartBuckets.count)",
                ],
                runId: "post-fix"
            )
            // #endregion
        }
    }

    @MainActor
    private func loadFocusChartBuckets() async {
        let calendar = Calendar.current
        let chartWindow = profileChartPeriod.statsDashboardWindow
        statsDashboardWindow = chartWindow
        let referenceNow = ProfileChartNavigation.chartReferenceDate(
            period: profileChartPeriod,
            weekStart: profileChartWeekStart,
            monthStart: profileChartMonthStart,
            yearStart: profileChartYearStart,
            calendar: calendar
        )

        do {
            focusChartBuckets = try await dependencies.gamificationDashboardReader.focusHoursChartBuckets(
                window: chartWindow,
                referenceNow: referenceNow,
                calendar: calendar
            )
            let bucketSummary = focusChartBuckets
                .map { "\($0.label):\($0.focusMinutes)m/\($0.xpEarned)xp@\(Int($0.periodStart.timeIntervalSince1970))" }
                .joined(separator: ",")
            // #region agent log
            DebugSessionLog5cee87.write(
                hypothesisId: "H3",
                location: "AppShellViewModel.loadFocusChartBuckets",
                message: "chart_loaded",
                data: [
                    "period": profileChartPeriod.rawValue,
                    "weekStart": "\(Int(profileChartWeekStart.timeIntervalSince1970))",
                    "referenceNow": "\(Int(referenceNow.timeIntervalSince1970))",
                    "chartWindow": chartWindow.rawValue,
                    "bucketSummary": bucketSummary,
                ]
            )
            let totalChartMinutes = focusChartBuckets.reduce(0) { $0 + $1.focusMinutes }
            DebugSessionLogAc92a4.write(
                hypothesisId: "H3-H5",
                location: "AppShellViewModel.loadFocusChartBuckets",
                message: "chart_loaded",
                data: [
                    "period": profileChartPeriod.rawValue,
                    "weekStart": "\(Int(profileChartWeekStart.timeIntervalSince1970))",
                    "yearStart": "\(Int(profileChartYearStart.timeIntervalSince1970))",
                    "referenceNow": "\(Int(referenceNow.timeIntervalSince1970))",
                    "chartWindow": chartWindow.rawValue,
                    "bucketCount": "\(focusChartBuckets.count)",
                    "totalChartMinutes": "\(totalChartMinutes)",
                    "bucketSummary": bucketSummary,
                ]
            )
            // #endregion
        } catch {
            focusChartBuckets = []
            // #region agent log
            DebugSessionLog5cee87.write(
                hypothesisId: "H9",
                location: "AppShellViewModel.loadFocusChartBuckets",
                message: "chart_load_failed",
                data: ["error": "\(error)"]
            )
            // #endregion
        }
        focusChartLastUpdated = Date()
    }

    @MainActor
    func resetAllGamificationProgress() {
        do {
            try dependencies.gamificationProgressResetting?.resetAllProgress(
                settingsStore: dependencies.settingsStore
            )
            refreshAllProfileData()
        } catch {
            // Best-effort; UI refresh still runs if partial failure is surfaced later.
        }
    }

    @MainActor
    func resetLifetimeXP() {
        Task { @MainActor in
            await resetLifetimeXPAwaiting()
        }
    }

    @MainActor
    private func resetLifetimeXPAwaiting() async {
        do {
            try dependencies.gamificationProgressResetting?.resetLifetimeXP(
                settingsStore: dependencies.settingsStore
            )
            applyOptimisticZeroLifetimeXP()
            await refreshGamificationStatsAwaiting()
        } catch {
            await refreshGamificationStatsAwaiting()
        }
    }

    @MainActor
    private func applyOptimisticZeroLifetimeXP() {
        totalLifetimeXP = 0
        weeklyXPEarned = 0
        let badge = FocusBadgeProgression.badge(forTotalXP: 0)
        playerLevel = badge.level
        playerLevelTitle = badge.title
        nextBadgeTitle = FocusBadgeProgression.nextBadge(forTotalXP: 0)?.title ?? badge.title
        xpToNextBadge = FocusBadgeProgression.xpToNext(totalXP: 0)
        badgeProgressFraction = FocusBadgeProgression.progressFractionToNext(totalXP: 0)
    }

    #if DEBUG
    @MainActor
    static func profileChartSectionPreview() -> AppShellViewModel {
        let suiteName = "ProfileChartPreview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        let dependencies = AppDependencies(
            timerService: TimerService(blockerService: BlockerService(), sessionRecorder: NoOpSessionRecorder()),
            blockerService: BlockerService(),
            automationCoordinator: .shared,
            xpStatsReader: NoOpXPStatsReader(),
            gamificationDashboardReader: NoOpGamificationDashboardReader(),
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: NotificationAuthorizationService(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        let viewModel = AppShellViewModel(dependencies: dependencies)
        viewModel.focusChartIsLoading = false
        let calendar = Calendar.current
        let now = Date()
        let weekStart = ProfileChartNavigation.currentWeekStart(now: now, calendar: calendar)
        let monthStart = ProfileChartNavigation.currentMonthStart(now: now, calendar: calendar)
        let yearStart = ProfileChartNavigation.currentYearStart(now: now, calendar: calendar)
        let reference = ProfileChartNavigation.chartReferenceDate(
            period: .week,
            weekStart: weekStart,
            monthStart: monthStart,
            yearStart: yearStart,
            calendar: calendar
        )
        viewModel.focusChartBuckets = FocusHoursChartBucketBuilder.build(
            window: .week,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: []
        )
        viewModel.focusChartLastUpdated = Date()
        return viewModel
    }
    #endif

    @MainActor
    private func reloadCurrentWeekFocusMinutes() async {
        let now = Date()
        let timeZone = TimeZone.current
        let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: timeZone)
        let weekEnd = FocusCalendarWeekBounds.exclusiveEndAfter(mondayStart: weekStart, timeZone: timeZone)
        do {
            currentWeekFocusMinutes = try await dependencies.gamificationDashboardReader.focusMinutesAwardedInExclusiveRange(
                start: weekStart,
                endExclusive: weekEnd
            )
        } catch {
            currentWeekFocusMinutes = 0
        }
    }

    @MainActor
    private func refreshGamificationStatsAwaiting() async {
        // #region agent log
        let statsStart = CFAbsoluteTimeGetCurrent()
        // #endregion
        do {
            let previousXP = totalLifetimeXP
            let now = Date()
            let timeZone = TimeZone.current
            let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: timeZone)
            let weekEnd = FocusCalendarWeekBounds.exclusiveEndAfter(mondayStart: weekStart, timeZone: timeZone)

            totalLifetimeXP = try await dependencies.xpStatsReader.totalAccumulatedXP()
            weeklyXPEarned = try await dependencies.gamificationDashboardReader.xpEarnedInExclusiveRange(
                start: weekStart,
                endExclusive: weekEnd
            )

            let badge = FocusBadgeProgression.badge(forTotalXP: totalLifetimeXP)
            playerLevel = badge.level
            playerLevelTitle = badge.title
            nextBadgeTitle = FocusBadgeProgression.nextBadge(forTotalXP: totalLifetimeXP)?.title ?? badge.title
            xpToNextBadge = FocusBadgeProgression.xpToNext(totalXP: totalLifetimeXP)
            badgeProgressFraction = FocusBadgeProgression.progressFractionToNext(totalXP: totalLifetimeXP)

            let previousBadge = FocusBadgeProgression.badge(forTotalXP: previousXP)
            if badge.level > previousBadge.level {
                levelUpBannerText = "You're \(badge.title)!"
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    self?.levelUpBannerText = nil
                }
            }

            let streakOutcome = try await dependencies.weeklyGamificationEvaluating.evaluatePendingClosedWeeks(now: now)
            defaultWeeklyStreak = streakOutcome.defaultTargetStreak
            personalWeeklyStreak = streakOutcome.personalTargetStreak
            longestDefaultWeeklyStreak = streakOutcome.longestDefaultTargetStreak
            longestPersonalWeeklyStreak = streakOutcome.longestPersonalTargetStreak
            lifetimeEndedSessionCount = try await dependencies.gamificationDashboardReader.lifetimeEndedSessionCount()
            await reloadCurrentWeekFocusMinutes()
            analyticsRefreshToken &+= 1
            // #region agent log
            let statsMs = Int((CFAbsoluteTimeGetCurrent() - statsStart) * 1000)
            DebugSessionLog82afba.write(
                hypothesisId: "H1",
                location: "AppShellViewModel.refreshGamificationStatsAwaiting",
                message: "stats_refreshed",
                data: ["durationMs": "\(statsMs)"]
            )
            DebugSessionLogAfdf58.write(
                hypothesisId: "H5",
                location: "AppShellViewModel.refreshGamificationStatsAwaiting",
                message: "stats_refreshed",
                data: [
                    "totalLifetimeXP": "\(totalLifetimeXP)",
                    "weeklyXPEarned": "\(weeklyXPEarned)",
                    "currentWeekFocusMinutes": "\(currentWeekFocusMinutes)",
                ],
                runId: "post-fix"
            )
            // #endregion
        } catch {
            // #region agent log
            DebugSessionLogAfdf58.write(
                hypothesisId: "H5",
                location: "AppShellViewModel.refreshGamificationStatsAwaiting",
                message: "stats_refresh_failed",
                data: ["error": String(describing: error)]
            )
            // #endregion
            totalLifetimeXP = 0
            weeklyXPEarned = 0
            lifetimeEndedSessionCount = 0
        }
    }

    /// Backward-compatible alias for profile refresh.
    func refreshStatsDashboard() {
        refreshProfileDashboard()
    }

    func skipToNextPhase() {
        Task {
            await dependencies.timerService.skipToNextPhase()
        }
    }

    func restartCurrentInterval() {
        Task {
            await dependencies.timerService.restartCurrentInterval()
        }
    }

    func openSection(_ section: AppShellSection) {
        selectedSection = section
        if section == .history {
            refreshProfileDashboard()
        }
    }

    func applyFocusPreset(_ preset: FocusSessionPreset) {
        isApplyingFocusPreset = true
        cyclesPerSession = 1
        focusDurationMinutes = preset.focusMinutes
        focusDurationSecondsComponent = 0
        shortRestDurationMinutes = preset.breakMinutes
        shortRestDurationSecondsComponent = 0
        roundsPerSession = preset.roundsPerSession
        longRestDurationMinutes = 0
        longRestDurationSecondsComponent = 0
        selectedFocusPresetID = preset.id
        isApplyingFocusPreset = false
    }

    func clearFocusPresetSelection() {
        selectedFocusPresetID = nil
    }

    func selectCreateCustomFocusPreset() {
        guard state.sessionState == .idle else {
            return
        }
        selectedFocusPresetID = FocusSessionPresets.createCustomCarouselID
    }

    func cycleFocusPreset(forward: Bool) {
        guard state.sessionState == .idle else {
            return
        }

        let carouselIDs = FocusSessionPresets.popoverCarouselPresetIDs
        guard !carouselIDs.isEmpty else {
            return
        }

        let currentIndex: Int
        if let presetID = selectedFocusPresetID,
           let index = carouselIDs.firstIndex(of: presetID) {
            currentIndex = index
        } else if FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID)
            || selectedFocusPresetID == nil {
            currentIndex = carouselIDs.firstIndex(of: FocusSessionPresets.createCustomCarouselID) ?? carouselIDs.count - 1
        } else if forward {
            currentIndex = -1
        } else {
            currentIndex = carouselIDs.count
        }

        let step = forward ? 1 : -1
        let nextIndex = (currentIndex + step + carouselIDs.count) % carouselIDs.count
        let nextID = carouselIDs[nextIndex]

        if FocusSessionPresets.isCreateCustomCarouselSelection(nextID) {
            selectCreateCustomFocusPreset()
            return
        }

        if let preset = FocusSessionPresets.preset(id: nextID) {
            applyFocusPreset(preset)
        }
    }

    func restoreFocusPresetSelectionIfNeeded() {
        guard state.sessionState == .idle else {
            return
        }
        if let savedID = dependencies.settingsStore.lastSelectedFocusPresetID {
            if FocusSessionPresets.isCreateCustomCarouselSelection(savedID) {
                selectCreateCustomFocusPreset()
                return
            }
            if let preset = FocusSessionPresets.preset(id: savedID) {
                applyFocusPreset(preset)
                return
            }
        }
        applyFocusPreset(FocusSessionPresets.defaultSelection)
    }

    /// Starts a focus session immediately (main window and post-countdown).
    /// - Parameter clearGetReadyCountdown: When false, keeps the Get Ready pill until the timer reports running.
    func startSession(clearGetReadyCountdown: Bool = true) {
        // #region agent log
        DebugSessionLog3c541f.write(
            hypothesisId: "H4",
            location: "AppShellViewModel.startSession",
            message: "enter",
            data: [
                "sessionState": String(describing: state.sessionState),
                "getReadySeconds": menuBarGetReadySecondsRemaining.map(String.init) ?? "nil",
                "focusSeconds": "\(focusDurationTotalSeconds)",
                "isMainThread": Thread.isMainThread ? "true" : "false",
            ]
        )
        // #endregion
        if clearGetReadyCountdown {
            cancelMenuBarGetReadyCountdown()
        }
        Task {
            await dependencies.timerService.startSession(configuration: stagingTimerConfiguration)
            // #region agent log
            await MainActor.run {
                DebugSessionLog3c541f.write(
                    hypothesisId: "H4",
                    location: "AppShellViewModel.startSession",
                    message: "timer_start_returned",
                    data: [
                        "remainingSeconds": "\(state.remainingSeconds)",
                        "sessionState": String(describing: state.sessionState),
                    ]
                )
            }
            // #endregion
        }
        selectedSection = .timer
    }

    /// Popover-only: 500ms delay, then a 10-second menu-bar “Get Ready” countdown before `startSession()`.
    func startSessionFromMenuBar() {
        guard state.sessionState == .idle, !isMenuBarGetReadyActive else {
            // #region agent log
            DebugSessionLog3c541f.write(
                hypothesisId: "H3",
                location: "AppShellViewModel.startSessionFromMenuBar",
                message: "start_rejected",
                data: [
                    "sessionState": String(describing: state.sessionState),
                    "getReadyActive": isMenuBarGetReadyActive ? "true" : "false",
                    "isMainThread": Thread.isMainThread ? "true" : "false",
                ]
            )
            // #endregion
            return
        }
        // #region agent log
        DebugSessionLog3c541f.write(
            hypothesisId: "H3",
            location: "AppShellViewModel.startSessionFromMenuBar",
            message: "start_accepted",
            data: [
                "focusSeconds": "\(focusDurationTotalSeconds)",
                "isMainThread": Thread.isMainThread ? "true" : "false",
            ]
        )
        // #endregion
        menuBarGetReadyTask?.cancel()
        menuBarGetReadyTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: MenuBarGetReadyCountdown.preDisplayDelayNanoseconds)
            guard !Task.isCancelled else {
                // #region agent log
                DebugSessionLog3c541f.write(
                    hypothesisId: "H3",
                    location: "AppShellViewModel.startSessionFromMenuBar",
                    message: "pre_delay_cancelled",
                    data: ["isMainThread": Thread.isMainThread ? "true" : "false"]
                )
                // #endregion
                return
            }
            await self.runMenuBarGetReadyCountdown()
        }
    }

    func cancelMenuBarGetReadyCountdown() {
        // #region agent log
        DebugSessionLog3c541f.write(
            hypothesisId: "H3",
            location: "AppShellViewModel.cancelMenuBarGetReadyCountdown",
            message: "cancel",
            data: [
                "secondsRemaining": menuBarGetReadySecondsRemaining.map(String.init) ?? "nil",
                "sessionState": String(describing: state.sessionState),
                "isMainThread": Thread.isMainThread ? "true" : "false",
            ]
        )
        // #endregion
        menuBarGetReadyTask?.cancel()
        menuBarGetReadyTask = nil
        menuBarGetReadySecondsRemaining = nil
        bumpMenuBarLabelRevision()
    }

    private func bumpMenuBarLabelRevision() {
        menuBarLabelRevision &+= 1
    }

    private func clearMenuBarGetReadyIfSessionIsActive(timerState: TimerSessionState) {
        guard menuBarGetReadySecondsRemaining != nil else { return }
        switch timerState.lifecycleState {
        case .running, .paused:
            menuBarGetReadyTask?.cancel()
            menuBarGetReadyTask = nil
            menuBarGetReadySecondsRemaining = nil
            bumpMenuBarLabelRevision()
        case .idle, .endedEarly, .completed:
            break
        }
    }

    private func publishMenuBarGetReadyTick(_ remaining: Int) {
        menuBarGetReadySecondsRemaining = remaining
        bumpMenuBarLabelRevision()
        if MenuBarGetReadyCountdown.shouldPlayTick(forSecondsRemaining: remaining) {
            dependencies.audioCueService.playGetReadyTickCue(isMuted: isAudioMuted)
        }
    }

    private func runMenuBarGetReadyCountdown() async {
        // #region agent log
        DebugSessionLog3c541f.write(
            hypothesisId: "H1",
            location: "AppShellViewModel.runMenuBarGetReadyCountdown",
            message: "enter",
            data: [
                "sessionState": String(describing: state.sessionState),
                "isMainThread": Thread.isMainThread ? "true" : "false",
            ]
        )
        // #endregion
        guard state.sessionState == .idle else {
            // #region agent log
            DebugSessionLog3c541f.write(
                hypothesisId: "H4",
                location: "AppShellViewModel.runMenuBarGetReadyCountdown",
                message: "abort_not_idle",
                data: ["sessionState": String(describing: state.sessionState)]
            )
            // #endregion
            return
        }

        var remaining = MenuBarGetReadyCountdown.totalSeconds
        publishMenuBarGetReadyTick(remaining)
        // #region agent log
        DebugSessionLog3c541f.write(
            hypothesisId: "H1",
            location: "AppShellViewModel.runMenuBarGetReadyCountdown",
            message: "tick_publish",
            data: [
                "remaining": "\(remaining)",
                "heroCountdown": heroCountdownText,
                "isMainThread": Thread.isMainThread ? "true" : "false",
            ]
        )
        // #endregion

        while remaining > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else {
                // #region agent log
                DebugSessionLog3c541f.write(
                    hypothesisId: "H3",
                    location: "AppShellViewModel.runMenuBarGetReadyCountdown",
                    message: "tick_loop_cancelled",
                    data: ["remaining": "\(remaining)"]
                )
                // #endregion
                return
            }
            remaining -= 1
            publishMenuBarGetReadyTick(remaining)
            // #region agent log
            DebugSessionLog3c541f.write(
                hypothesisId: "H1",
                location: "AppShellViewModel.runMenuBarGetReadyCountdown",
                message: "tick_publish",
                data: [
                    "remaining": "\(remaining)",
                    "heroCountdown": heroCountdownText,
                    "isMainThread": Thread.isMainThread ? "true" : "false",
                ]
            )
            // #endregion
        }

        guard !Task.isCancelled else { return }
        menuBarGetReadyTask = nil
        // #region agent log
        DebugSessionLog3c541f.write(
            hypothesisId: "H4",
            location: "AppShellViewModel.runMenuBarGetReadyCountdown",
            message: "complete_calling_startSession",
            data: [
                "sessionState": String(describing: state.sessionState),
                "isMainThread": Thread.isMainThread ? "true" : "false",
            ]
        )
        // #endregion
        startSession(clearGetReadyCountdown: false)
    }

    func togglePause() {
        guard state.sessionState != .idle else {
            return
        }
        if state.isSessionPaused {
            Task { await dependencies.timerService.resumeSession() }
        } else {
            Task { await dependencies.timerService.pauseSession() }
        }
    }

    func requestEndSession() {
        guard state.sessionState != .idle else {
            return
        }
        showsEndSessionConfirmation = true
    }

    func confirmEndSession() {
        showsEndSessionConfirmation = false
        Task { await dependencies.timerService.endSession() }
    }

    func previewSelectedSoundPack() {
        dependencies.audioCueService.preview(soundPack: selectedSoundPack, isMuted: isAudioMuted)
    }

    func previewVoiceOption(_ voiceOption: VoiceOption) {
        dependencies.audioCueService.previewVoiceOption(voiceOption)
    }

    func previewChimesSoundPack() {
        dependencies.audioCueService.previewChimesSoundPack()
    }

    func resetAppearanceToFactorySettings() {
        resetColorThemeToFactorySettings()
    }

    func resetSoundAndNotificationsSectionToFactorySettings() {
        selectedSoundPack = .voicePrompts
        selectedVoiceOption = .jamal
        isAudioMuted = false
    }

    func resetColorThemeToFactorySettings() {
        appearancePreference = .system
    }

    func resetBlocklistSectionToFactorySettings() {
        blockerSettings.resetBlockedListsToDefaults()
    }

    private func startListeningToTimer() {
        stateStreamTask = Task { [weak self] in
            guard let self else { return }
            for await timerState in dependencies.timerService.sessionStateStream() {
                await MainActor.run {
                    self.apply(timerState: timerState)
                }
            }
        }
        transitionStreamTask = Task { [weak self] in
            guard let self else { return }
            for await event in dependencies.timerService.transitionEventStream() {
                await MainActor.run {
                    self.apply(transitionEvent: event)
                }
            }
        }
    }

    private func apply(timerState: TimerSessionState) {
        if menuBarGetReadySecondsRemaining != nil {
            // #region agent log
            DebugSessionLog3c541f.write(
                hypothesisId: "H5",
                location: "AppShellViewModel.apply(timerState:)",
                message: "timer_state_while_get_ready",
                data: [
                    "lifecycle": String(describing: timerState.lifecycleState),
                    "remaining": "\(timerState.remainingSeconds)",
                    "getReadySeconds": menuBarGetReadySecondsRemaining.map(String.init) ?? "nil",
                ]
            )
            // #endregion
        }
        let sessionState: AppShellSessionState
        switch timerState.intervalPhase {
        case .focus:
            sessionState = .focus
        case .shortRest, .longRest:
            sessionState = .rest
        case nil:
            sessionState = .idle
        }

        var next = state
        next.sessionState = timerState.lifecycleState == .idle ? .idle : sessionState
        next.isSessionPaused = timerState.lifecycleState == .paused
        next.countdownText = AppShellTimerFormatting.countdownText(seconds: timerState.remainingSeconds)
        next.remainingSeconds = timerState.remainingSeconds

        if timerState.lifecycleState == .idle {
            next.currentRound = nil
            next.totalRounds = nil
            next.currentCycle = nil
            next.totalCycles = nil
            next.elapsedSessionSeconds = 0
            next.completedWorkSeconds = 0
            next.intervalPhase = nil
        } else {
            next.currentRound = timerState.currentRound
            next.totalRounds = timerState.totalRounds
            next.currentCycle = timerState.currentCycle
            next.totalCycles = timerState.totalCycles
            next.elapsedSessionSeconds = timerState.elapsedSessionSeconds
            next.completedWorkSeconds = timerState.completedWorkSeconds
            next.intervalPhase = timerState.intervalPhase
        }

        clearMenuBarGetReadyIfSessionIsActive(timerState: timerState)

        // Whole-value assignment so `@Published` emits; `objectWillChange` helps nested SwiftUI
        // (e.g. NavigationSplitView detail) refresh reliably.
        objectWillChange.send()
        state = next
        bumpMenuBarLabelRevision()
    }

    private func apply(transitionEvent: TimerTransitionEvent) {
        dependencies.transitionNotificationService.handleTransitionEvent(transitionEvent)
        dependencies.audioCueService.playTransitionCue(
            for: transitionEvent,
            soundPack: selectedSoundPack,
            isMuted: isAudioMuted
        )

        switch transitionEvent {
        case .focusStarted, .shortRestStarted, .longRestStarted:
            return
        case let .sessionCompleted(xpAwarded, focusMinutes, focusSeconds):
            let payload = TransitionNotificationService.completionPayload(
                xpAwarded: xpAwarded,
                focusMinutes: focusMinutes,
                focusSeconds: focusSeconds
            )
            completionBannerText = payload.body.isEmpty
                ? payload.title
                : "\(payload.title) — \(payload.body)"
            refreshAllProfileData()
        case let .sessionEndedEarly(xpAwarded):
            if xpAwarded > 0 {
                completionBannerText = "Session ended early: +\(xpAwarded) XP"
            } else {
                completionBannerText = "Session ended early"
            }
            refreshAllProfileData()
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                self?.completionBannerText = nil
            }
        }
    }
}

// swiftlint:enable type_body_length

private enum AppShellTimerFormatting {
    static func countdownText(seconds: Int) -> String {
        let boundedSeconds = max(0, seconds)
        let minutes = boundedSeconds / 60
        let remainingSeconds = boundedSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    /// `H:MM:SS` when at least one hour, otherwise `MM:SS`.
    static func sessionDurationClock(seconds: Int) -> String {
        let s = max(0, seconds)
        if s >= 3600 {
            let h = s / 3600
            let m = (s % 3600) / 60
            let r = s % 60
            return String(format: "%d:%02d:%02d", h, m, r)
        }
        return countdownText(seconds: s)
    }

    static func clampInteger(_ value: Int, range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

private extension AppShellViewModel {
    var focusDurationTotalSeconds: Int {
        TimerConfiguration.composeDuration(minutes: focusDurationMinutes, seconds: focusDurationSecondsComponent)
    }

    var shortRestDurationTotalSeconds: Int {
        TimerConfiguration.composeDuration(minutes: shortRestDurationMinutes, seconds: shortRestDurationSecondsComponent)
    }

    var longRestDurationTotalSeconds: Int {
        TimerConfiguration.composeDuration(minutes: longRestDurationMinutes, seconds: longRestDurationSecondsComponent)
    }

    func persistFocusDuration() {
        if focusDurationMinutes == 0 && focusDurationSecondsComponent == 0 {
            focusDurationSecondsComponent = 1
            return
        }
        dependencies.settingsStore.focusDurationSeconds = focusDurationTotalSeconds
    }

    func persistShortRestDuration() {
        if shortRestDurationMinutes == 0 && shortRestDurationSecondsComponent == 0 {
            shortRestDurationSecondsComponent = 1
            return
        }
        dependencies.settingsStore.shortRestDurationSeconds = shortRestDurationTotalSeconds
    }

    func persistLongRestDuration() {
        guard sessionBreakConfigurationEnabled else {
            return
        }
        if longRestDurationMinutes == 0 && longRestDurationSecondsComponent == 0 {
            longRestDurationSecondsComponent = 1
            return
        }
        dependencies.settingsStore.longRestDurationSeconds = longRestDurationTotalSeconds
    }

    private func syncSessionBreakEditorToCyclesCount() {
        if sessionBreakConfigurationEnabled {
            let split = TimerConfiguration.splitDuration(seconds: dependencies.settingsStore.longRestDurationSeconds)
            longRestDurationMinutes = split.minutes
            longRestDurationSecondsComponent = split.seconds
        } else {
            longRestDurationMinutes = 0
            longRestDurationSecondsComponent = 0
        }
    }

    private func invalidateFocusPresetIfEdited() {
        guard !isApplyingFocusPreset,
              !FocusSessionPresets.isCreateCustomCarouselSelection(selectedFocusPresetID),
              let presetID = selectedFocusPresetID,
              let preset = FocusSessionPresets.preset(id: presetID) else {
            return
        }
        if stagingTimerConfiguration != preset.timerConfiguration {
            selectCreateCustomFocusPreset()
        }
    }
}
