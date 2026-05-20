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
            dependencies.settingsStore.selectedAppShellSection = selectedSection.rawValue
        }
    }
    @Published var showsDockIcon: Bool {
        didSet {
            dependencies.settingsStore.showsDockIcon = showsDockIcon
            DockIconVisibilityController.apply(showsDockIcon: showsDockIcon)
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
        }
    }
    @Published var cyclesPerSession: Int {
        didSet {
            let clamped = AppShellTimerFormatting.clampInteger(cyclesPerSession, range: 1...10)
            if clamped != cyclesPerSession {
                cyclesPerSession = clamped
                return
            }
            dependencies.settingsStore.cyclesPerSession = clamped
            syncSessionBreakEditorToCyclesCount()
        }
    }
    @Published var selectedSoundPack: AudioSoundPack {
        didSet {
            dependencies.settingsStore.selectedSoundPackIdentifier = selectedSoundPack.rawValue
        }
    }
    @Published var isAudioMuted: Bool {
        didSet {
            dependencies.settingsStore.isAudioMuted = isAudioMuted
        }
    }

    @Published var showsEndSessionConfirmation = false
    @Published var completionBannerText: String?
    @Published var levelUpBannerText: String?
    @Published private(set) var totalLifetimeXP: Int = 0
    @Published private(set) var streakDisplay: Int = 0
    @Published private(set) var streakDayStates: [FocusDayActivityState] = []

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
    @Published private(set) var weeklyXPGoal: Int = 1_000
    @Published private(set) var playerLevel: Int = 1
    @Published private(set) var playerLevelTitle: String = FocusPlayerLevelTitle.displayName(for: 1)

    @Published var statsDashboardWindow: StatsDashboardWindow = .week
    @Published var profileChartPeriod: ProfileChartPeriod = .week

    /// Temporary: show mock chart data until rolling session aggregation is verified in QA.
    private let profileChartUsesMockData = true
    /// Temporary: show mock weekly goal ring progress for profile UI QA.
    private let profileWeeklyProgressUsesMockData = true
    @Published private(set) var profileIsLoading = false
    @Published private(set) var focusChartIsLoading = false
    @Published private(set) var currentWeekFocusMinutes: Int = 0

    @Published var weeklyXPGoalSelection: Int

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

    private var hackerWeeklyGoalSnapshot: ProfileWeeklyProgressMockData.GoalSnapshot {
        if profileWeeklyProgressUsesMockData {
            return ProfileWeeklyProgressMockData.hacker
        }
        let target = ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        return ProfileWeeklyProgressMockData.GoalSnapshot(
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

    private var personalWeeklyGoalSnapshot: ProfileWeeklyProgressMockData.GoalSnapshot {
        if profileWeeklyProgressUsesMockData {
            return ProfileWeeklyProgressMockData.personal
        }
        let target = ProfileChartTargets.mockWeeklyPersonalMinutes
        return ProfileWeeklyProgressMockData.GoalSnapshot(
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

    func applyWeeklyGoalSelection(_ newValue: Int) {
        let clamped = UserDefaultsSettingsStore.clampWeeklyGoalStep(newValue)
        weeklyXPGoalSelection = clamped
        dependencies.settingsStore.weeklyXPGoalXP = clamped
        weeklyXPGoal = clamped
    }

    private let dependencies: AppDependencies
    private var stateStreamTask: Task<Void, Never>?
    private var transitionStreamTask: Task<Void, Never>?
    private var gamificationHourlyRefresh: AnyCancellable?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.blockerSettings = BlockerSettingsController(
            settingsStore: dependencies.settingsStore,
            blockerService: dependencies.blockerService
        )
        self.state = AppShellState.initial
        self.selectedSection = AppShellSection(rawValue: dependencies.settingsStore.selectedAppShellSection) ?? .history
        self.showsDockIcon = dependencies.settingsStore.showsDockIcon
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
        self.selectedSoundPack = AudioSoundPack.from(
            storedIdentifier: dependencies.settingsStore.selectedSoundPackIdentifier
        )
        self.isAudioMuted = dependencies.settingsStore.isAudioMuted
        self.weeklyXPGoalSelection = dependencies.settingsStore.weeklyXPGoalXP
        self.weeklyXPGoal = dependencies.settingsStore.weeklyXPGoalXP
        self.profileDisplayName = dependencies.settingsStore.profileDisplayName
        DockIconVisibilityController.apply(showsDockIcon: showsDockIcon)
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
    }

    var menuBarText: String {
        state.menuBarText
    }

    var menuBarAccessibilityLabel: String {
        state.menuBarAccessibilityLabel
    }

    var menuBarShowsPill: Bool {
        state.menuBarPresentation != .neutral
    }

    var menuBarPillText: String {
        state.menuBarPillText
    }

    var menuBarPillBackground: Color {
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
        state.menuBarShouldFlash
    }

    var shouldShowStartButton: Bool {
        state.sessionState == .idle
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
        state.sessionState == .idle ? "Total session" : "Session time left"
    }

    var menuBarFocusStatLabel: String {
        state.sessionState == .idle ? "Total focus time" : "Focus time left"
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

    var timerChromeTheme: TimerChromeTheme {
        TimerChromeTheme(sessionState: state.sessionState)
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

    var timerSlabHeaderBackground: Color {
        .fhColorCharcoal
    }

    var timerSlabFooterBackground: Color {
        .fhColorTimerFooter
    }

    var timerSlabHeaderPrimaryForeground: Color {
        .fhColorWhite
    }

    var timerSlabHeaderSecondaryForeground: Color {
        Color.white.opacity(0.72)
    }

    var timerSlabFooterPrimaryForeground: Color {
        .fhColorWhite
    }

    var timerSlabFooterSecondaryForeground: Color {
        Color.white.opacity(0.76)
    }

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
        let goal = max(1, weeklyXPGoal)
        return min(1, max(0, Double(weeklyXPEarned) / Double(goal)))
    }

    func refreshGamificationStats() {
        Task { @MainActor in
            await refreshGamificationStatsAwaiting()
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
            profileIsLoading = true
            defer { profileIsLoading = false }

            await refreshGamificationStatsAwaiting()

            do {
                let now = Date()
                let calendar = Calendar.current
                let timeZone = TimeZone.current
                let reader = dependencies.gamificationDashboardReader

                let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: timeZone)
                let weekEnd = FocusCalendarWeekBounds.exclusiveEndAfter(mondayStart: weekStart, timeZone: timeZone)
                let weekMetrics = try await reader.sessionMetricsEndedAtInExclusiveRange(
                    start: weekStart,
                    endExclusive: weekEnd
                )
                currentWeekFocusMinutes = weekMetrics.totalCompletedFocusMinutes

                await loadFocusChartBuckets()

                let activeDays = try await reader.completedSessionCalendarDays()
                let streakSnapshot = FocusStreakCalculator.snapshot(
                    activeDays: activeDays,
                    referenceNow: now,
                    calendar: calendar
                )
                streakDisplay = streakSnapshot.currentStreak
                streakDayStates = streakSnapshot.recentDayStates
            } catch {
                currentWeekFocusMinutes = 0
                focusChartBuckets = []
                streakDisplay = 0
                streakDayStates = []
            }
        }
    }

    @MainActor
    private func loadFocusChartBuckets() async {
        let now = Date()
        let calendar = Calendar.current
        let chartWindow = profileChartPeriod.statsDashboardWindow
        statsDashboardWindow = chartWindow

        do {
            if profileChartUsesMockData {
                focusChartBuckets = ProfileFocusChartMockData.buckets(
                    for: profileChartPeriod,
                    endingAt: now,
                    calendar: calendar
                )
            } else {
                focusChartBuckets = try await dependencies.gamificationDashboardReader.focusHoursChartBuckets(
                    window: chartWindow,
                    referenceNow: now,
                    calendar: calendar
                )
            }
        } catch {
            focusChartBuckets = []
        }
    }

    @MainActor
    private func refreshGamificationStatsAwaiting() async {
        do {
            totalLifetimeXP = try await dependencies.xpStatsReader.totalAccumulatedXP()
            weeklyXPGoal = dependencies.settingsStore.weeklyXPGoalXP
            let now = Date()
            let timeZone = TimeZone.current
            let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: timeZone)
            let weekEnd = FocusCalendarWeekBounds.exclusiveEndAfter(mondayStart: weekStart, timeZone: timeZone)
            weeklyXPEarned = try await dependencies.gamificationDashboardReader.xpEarnedInExclusiveRange(
                start: weekStart,
                endExclusive: weekEnd
            )
            let outcome = try await dependencies.weeklyLevelEvaluating.evaluatePendingClosedWeeks(now: now)
            playerLevel = outcome.newLevel
            playerLevelTitle = FocusPlayerLevelTitle.displayName(for: playerLevel)
            if outcome.leveledUp, outcome.evaluatedAnyWeek {
                levelUpBannerText = "Level up — \(FocusPlayerLevelTitle.displayName(for: outcome.previousLevel)) → \(FocusPlayerLevelTitle.displayName(for: outcome.newLevel))"
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    self?.levelUpBannerText = nil
                }
            }
        } catch {
            totalLifetimeXP = 0
            weeklyXPEarned = 0
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

    var timerAccentColor: Color {
        timerChromeTheme.accentTimer
    }

    func openSection(_ section: AppShellSection) {
        selectedSection = section
        if section == .history {
            refreshProfileDashboard()
        }
    }

    func startSession() {
        Task {
            await dependencies.timerService.startSession(configuration: stagingTimerConfiguration)
        }
        selectedSection = .timer
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

    func resetSoundAndNotificationsSectionToFactorySettings() {
        selectedSoundPack = .voicePrompts
        isAudioMuted = false
    }

    func resetAppearanceSectionToFactorySettings() {
        showsDockIcon = false
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

        // Whole-value assignment so `@Published` emits; `objectWillChange` helps nested SwiftUI
        // (e.g. NavigationSplitView detail) refresh reliably.
        objectWillChange.send()
        state = next
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
        case let .sessionCompleted(xpAwarded):
            completionBannerText = "Session complete: +\(xpAwarded) XP"
            refreshGamificationStats()
            refreshProfileDashboard()
        case .sessionEndedEarly:
            completionBannerText = "Session ended early (0 XP)"
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
}
