@testable import FocusHacker
import XCTest

final class AppShellStateTests: XCTestCase {
    func testSessionStateIconsAreDistinct() {
        let symbolNames = Set(AppShellSessionState.allCases.map(\.iconSymbolName))
        XCTAssertEqual(symbolNames.count, AppShellSessionState.allCases.count)
    }

    func testSettingsStorePersistsSelectedSectionAndDockPreference() {
        let suiteName = "tests.appShellSettings.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected dedicated UserDefaults suite.")
            return
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: userDefaults, appGroupSuiteName: nil)

        XCTAssertEqual(store.selectedAppShellSection, "history")
        XCTAssertTrue(store.showsDockIcon, "Registered default is true so app menus / Help work.")

        store.selectedAppShellSection = "settings"
        store.showsDockIcon = false
        XCTAssertEqual(store.selectedAppShellSection, "settings")
        XCTAssertFalse(store.showsDockIcon)

        store.selectedAppShellSection = "blockedItems"
        XCTAssertEqual(store.selectedAppShellSection, "blockedItems")
        XCTAssertEqual(AppShellSection(rawValue: store.selectedAppShellSection), .blockedItems)

        store.showsDockIcon = true
        XCTAssertTrue(store.showsDockIcon)

        userDefaults.removePersistentDomain(forName: suiteName)
    }

    func testSettingsStorePersistsAudioSettings() {
        let suiteName = "tests.audioSettings.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected dedicated UserDefaults suite.")
            return
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: userDefaults, appGroupSuiteName: nil)

        XCTAssertEqual(store.selectedSoundPackIdentifier, "voice-prompts")
        XCTAssertFalse(store.isAudioMuted)

        store.selectedSoundPackIdentifier = "chimes"
        store.isAudioMuted = true

        XCTAssertEqual(store.selectedSoundPackIdentifier, "chimes")
        XCTAssertTrue(store.isAudioMuted)

        userDefaults.removePersistentDomain(forName: suiteName)
    }
}

final class TimerConfigurationPlannedDurationTests: XCTestCase {
    func testDefaultPlannedWallClockAndFocusSeconds() {
        let cfg = TimerConfiguration.default
        XCTAssertEqual(cfg.plannedWallClockSecondsExcludingTransitions, 7_800)
        XCTAssertEqual(cfg.plannedTotalFocusSeconds, 6_000)
    }

    func testSingleCycleOmitsTrailingLongWhenLongRestIsZero() {
        var cfg = TimerConfiguration.default
        cfg.longRestDurationSeconds = 0
        XCTAssertEqual(cfg.plannedWallClockSecondsExcludingTransitions, 6_900)
        XCTAssertEqual(cfg.plannedTotalFocusSeconds, 6_000)
    }

    func testMultipleCyclesAddsLongRestBetweenCycles() {
        var cfg = TimerConfiguration.default
        cfg.cyclesPerSession = 2
        XCTAssertEqual(cfg.plannedWallClockSecondsExcludingTransitions, 14_700)
        XCTAssertEqual(cfg.plannedTotalFocusSeconds, 12_000)
    }

    func testSingleRoundPerCycleNoShortRestsInWallClock() {
        let cfg = TimerConfiguration(
            focusDurationSeconds: 60,
            shortRestDurationSeconds: 30,
            longRestDurationSeconds: 120,
            roundsPerSession: 1,
            cyclesPerSession: 2
        )
        XCTAssertEqual(cfg.plannedWallClockSecondsExcludingTransitions, 240)
        XCTAssertEqual(cfg.plannedTotalFocusSeconds, 120)
    }

    func testPlannedFocusIntervalCountDefault() {
        XCTAssertEqual(TimerConfiguration.default.plannedFocusIntervalCount, 4)
    }

    func testPlannedFocusIntervalCountMultiCycle() {
        var cfg = TimerConfiguration.default
        cfg.cyclesPerSession = 2
        XCTAssertEqual(cfg.plannedFocusIntervalCount, 8)
    }

    func testPlannedFocusIntervalCountClampsNonPositiveRounds() {
        var cfg = TimerConfiguration.default
        cfg.roundsPerSession = 0
        cfg.cyclesPerSession = 3
        XCTAssertEqual(cfg.plannedFocusIntervalCount, 0)
    }
}

private extension AppShellState {
    static func testShell(
        sessionState: AppShellSessionState,
        intervalPhase: TimerIntervalPhase?,
        currentRound: Int?,
        totalRounds: Int?,
        currentCycle: Int?,
        totalCycles: Int?,
        countdownText: String = "25:00",
        isSessionPaused: Bool = false,
        remainingSeconds: Int = 1500
    ) -> AppShellState {
        AppShellState(
            sessionState: sessionState,
            countdownText: countdownText,
            isSessionPaused: isSessionPaused,
            intervalPhase: intervalPhase,
            remainingSeconds: remainingSeconds,
            currentRound: currentRound,
            totalRounds: totalRounds,
            currentCycle: currentCycle,
            totalCycles: totalCycles,
            elapsedSessionSeconds: 0,
            completedWorkSeconds: 0
        )
    }
}

final class AppShellStateMenuBarTests: XCTestCase {
    func testIdleShowsAppNameWithoutPillPresentation() {
        let state = AppShellState.testShell(
            sessionState: .idle,
            intervalPhase: nil,
            currentRound: nil,
            totalRounds: nil,
            currentCycle: nil,
            totalCycles: nil
        )
        XCTAssertEqual(state.menuBarPresentation, .neutral)
        XCTAssertEqual(state.menuBarText, "FocusHacker")
        XCTAssertFalse(state.menuBarShouldFlash)
    }

    func testFocusRunningShowsFocusPillText() {
        let state = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "25:00",
            remainingSeconds: 21
        )
        XCTAssertEqual(state.menuBarPresentation, .focus)
        XCTAssertEqual(state.menuBarText, "FOCUS: 25:00")
        XCTAssertEqual(state.menuBarPillText, "FOCUS: 25:00 · 1 of 4")
        XCTAssertEqual(
            state.menuBarAccessibilityLabel,
            "Focus, 25:00 remaining, round 1 of 4"
        )
        XCTAssertFalse(state.menuBarShouldFlash)
    }

    func testFocusLastRoundShowsFourOfFourOnPill() {
        let state = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 4,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "05:00",
            remainingSeconds: 300
        )
        XCTAssertEqual(state.menuBarText, "FOCUS: 05:00")
        XCTAssertEqual(state.menuBarPillText, "FOCUS: 05:00 · 4 of 4")
    }

    func testFocusSingleRoundOmitsRoundSuffixOnPill() {
        let state = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 1,
            totalRounds: 1,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "25:00",
            remainingSeconds: 1500
        )
        XCTAssertEqual(state.menuBarText, "FOCUS: 25:00")
        XCTAssertEqual(state.menuBarPillText, "FOCUS: 25:00")
        XCTAssertEqual(state.menuBarAccessibilityLabel, "Focus, 25:00 remaining")
    }

    func testRestPillTextMatchesMenuBarText() {
        let state = AppShellState.testShell(
            sessionState: .rest,
            intervalPhase: .shortRest,
            currentRound: 2,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "00:05",
            remainingSeconds: 5
        )
        XCTAssertEqual(state.menuBarText, "REST: 00:05")
        XCTAssertEqual(state.menuBarPillText, state.menuBarText)
    }

    func testPausedPillTextMatchesMenuBarText() {
        let state = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 2,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "12:34",
            isSessionPaused: true,
            remainingSeconds: 754
        )
        XCTAssertEqual(state.menuBarText, "PAUSED: 12:34")
        XCTAssertEqual(state.menuBarPillText, state.menuBarText)
    }

    func testRestAtTwentySecondsFlashes() {
        let state = AppShellState.testShell(
            sessionState: .rest,
            intervalPhase: .shortRest,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "00:20",
            remainingSeconds: 20
        )
        XCTAssertEqual(state.menuBarPresentation, .rest)
        XCTAssertEqual(state.menuBarText, "REST: 00:20")
        XCTAssertTrue(state.menuBarShouldFlash)
    }

    func testPausedShowsPausedPillWithoutFlash() {
        let state = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1,
            countdownText: "12:34",
            isSessionPaused: true,
            remainingSeconds: 5
        )
        XCTAssertEqual(state.menuBarPresentation, .paused)
        XCTAssertEqual(state.menuBarText, "PAUSED: 12:34")
        XCTAssertFalse(state.menuBarShouldFlash)
    }
}

final class AppShellStateCompletedPlannedFocusIntervalsTests: XCTestCase {
    func testIdleReturnsNil() {
        let s = AppShellState.testShell(
            sessionState: .idle,
            intervalPhase: nil,
            currentRound: nil,
            totalRounds: nil,
            currentCycle: nil,
            totalCycles: nil
        )
        XCTAssertNil(s.completedPlannedFocusIntervals)
    }

    func testFirstFocusZeroCompleted() {
        let s = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1
        )
        XCTAssertEqual(s.completedPlannedFocusIntervals, 0)
        XCTAssertEqual(4 - (s.completedPlannedFocusIntervals ?? 0), 4)
    }

    func testFocusRoundThreeTwoCompleted() {
        let s = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 3,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1
        )
        XCTAssertEqual(s.completedPlannedFocusIntervals, 2)
    }

    func testShortRestAfterRoundOneOneCompleted() {
        let s = AppShellState.testShell(
            sessionState: .rest,
            intervalPhase: .shortRest,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1
        )
        XCTAssertEqual(s.completedPlannedFocusIntervals, 1)
    }

    func testLongRestAfterFullCycleSingleCycleFourCompleted() {
        let s = AppShellState.testShell(
            sessionState: .rest,
            intervalPhase: .longRest,
            currentRound: 4,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1
        )
        XCTAssertEqual(s.completedPlannedFocusIntervals, 4)
    }

    func testLongRestBetweenCyclesFourCompletedEightPlanned() {
        let s = AppShellState.testShell(
            sessionState: .rest,
            intervalPhase: .longRest,
            currentRound: 4,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 2
        )
        XCTAssertEqual(s.completedPlannedFocusIntervals, 4)
        var cfg = TimerConfiguration.default
        cfg.cyclesPerSession = 2
        XCTAssertEqual(cfg.plannedFocusIntervalCount - (s.completedPlannedFocusIntervals ?? 0), 4)
    }

    func testSecondCycleFirstFocusFourCompleted() {
        let s = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 2,
            totalCycles: 2
        )
        XCTAssertEqual(s.completedPlannedFocusIntervals, 4)
    }
}

private struct SessionConfigTestBlockerService: BlockerServiceProtocol {
    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async {
        _ = isActive
        _ = bounceFilterConnectionsOnActivate
        _ = blockingEpoch
        _ = tearDownStaleConnectionsOnActivate
    }

    func refreshBlockingLeaseIfActive() async { }
    func refreshBlockedIPLiteralsAfterBlocklistChange() async { }
    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async { }
}

private struct SessionConfigTestNotificationAuth: NotificationAuthorizationServing {
    func requestAuthorization() async -> Bool { false }
}

@MainActor
final class AppShellViewModelSessionConfigTests: XCTestCase {
    private func makeStore(longRestSeconds: Int, cycles: Int) -> UserDefaultsSettingsStore {
        let suiteName = "AppShellVM.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        store.longRestDurationSeconds = longRestSeconds
        store.cyclesPerSession = cycles
        return store
    }

    private func makeViewModel(store: UserDefaultsSettingsStore) -> AppShellViewModel {
        let blocker = SessionConfigTestBlockerService()
        let timerService = TimerService(
            blockerService: blocker,
            sessionRecorder: NoOpSessionRecorder()
        )
        let dependencies = AppDependencies(
            timerService: timerService,
            blockerService: blocker,
            automationCoordinator: .shared,
            xpStatsReader: NoOpXPStatsReader(),
            gamificationDashboardReader: NoOpGamificationDashboardReader(),
            weeklyLevelEvaluating: NoOpWeeklyLevelEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: SessionConfigTestNotificationAuth(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        return AppShellViewModel(dependencies: dependencies)
    }

    func testEffectiveLongRestZeroWhenSingleSession() {
        let store = makeStore(longRestSeconds: 15 * 60, cycles: 1)
        let viewModel = makeViewModel(store: store)

        XCTAssertFalse(viewModel.sessionBreakConfigurationEnabled)
        XCTAssertEqual(viewModel.effectiveLongRestDurationSeconds, 0)
        XCTAssertEqual(viewModel.stagingTimerConfiguration.longRestDurationSeconds, 0)
        XCTAssertEqual(viewModel.longRestDurationMinutes, 0)
        XCTAssertEqual(viewModel.longRestDurationSecondsComponent, 0)
        XCTAssertEqual(store.longRestDurationSeconds, 15 * 60)
    }

    func testEffectiveLongRestUsesStoredWhenMultipleSessions() {
        let store = makeStore(longRestSeconds: 15 * 60, cycles: 2)
        let viewModel = makeViewModel(store: store)

        XCTAssertTrue(viewModel.sessionBreakConfigurationEnabled)
        XCTAssertEqual(viewModel.effectiveLongRestDurationSeconds, 15 * 60)
        XCTAssertEqual(viewModel.stagingTimerConfiguration.longRestDurationSeconds, 15 * 60)
    }

    func testReducingSessionsClearsDisplayAndPreservesStoredBreak() {
        let store = makeStore(longRestSeconds: 20 * 60, cycles: 2)
        let viewModel = makeViewModel(store: store)

        viewModel.cyclesPerSession = 1
        XCTAssertEqual(viewModel.longRestDurationMinutes, 0)
        XCTAssertEqual(viewModel.longRestDurationSecondsComponent, 0)
        XCTAssertEqual(store.longRestDurationSeconds, 20 * 60)

        viewModel.cyclesPerSession = 2
        XCTAssertEqual(viewModel.stagingTimerConfiguration.longRestDurationSeconds, 20 * 60)
        XCTAssertEqual(viewModel.effectiveLongRestDurationSeconds, 20 * 60)
    }
}
