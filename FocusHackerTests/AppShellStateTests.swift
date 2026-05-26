@testable import FocusHacker
import XCTest

final class AppShellStateTests: XCTestCase {
    func testSessionStateIconsAreDistinct() {
        let symbolNames = Set(AppShellSessionState.allCases.map(\.iconSymbolName))
        XCTAssertEqual(symbolNames.count, AppShellSessionState.allCases.count)
    }

    func testSettingsStorePersistsSelectedSectionAndAppearancePreference() {
        let suiteName = "tests.appShellSettings.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected dedicated UserDefaults suite.")
            return
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: userDefaults, appGroupSuiteName: nil)

        XCTAssertEqual(store.selectedAppShellSection, "history")

        store.selectedAppShellSection = "settings"
        XCTAssertEqual(store.selectedAppShellSection, "settings")

        store.selectedAppShellSection = "blockedItems"
        XCTAssertEqual(store.selectedAppShellSection, "blockedItems")
        XCTAssertEqual(AppShellSection(rawValue: store.selectedAppShellSection), .blockedItems)

        store.selectedAppShellSection = "analytics"
        XCTAssertEqual(store.selectedAppShellSection, "analytics")
        XCTAssertEqual(AppShellSection(rawValue: store.selectedAppShellSection), .analytics)

        XCTAssertEqual(store.appearancePreference, .system)
        store.appearancePreference = .dark
        XCTAssertEqual(store.appearancePreference, .dark)

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
        XCTAssertEqual(store.selectedVoiceOption, VoiceOption.defaultSelection.rawValue)
        XCTAssertFalse(store.isAudioMuted)

        store.selectedSoundPackIdentifier = "chimes"
        store.selectedVoiceOption = VoiceOption.david.rawValue
        store.isAudioMuted = true

        XCTAssertEqual(store.selectedSoundPackIdentifier, "chimes")
        XCTAssertEqual(store.selectedVoiceOption, VoiceOption.david.rawValue)
        XCTAssertTrue(store.isAudioMuted)

        store.selectedVoiceOption = VoiceOption.defaultSelection.rawValue
        XCTAssertEqual(store.selectedVoiceOption, VoiceOption.defaultSelection.rawValue)

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
        XCTAssertEqual(state.menuBarCompactPillText, "FOCUS 25:00")
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
        XCTAssertEqual(state.menuBarCompactPillText, "FOCUS 05:00")
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
        XCTAssertEqual(state.menuBarCompactPillText, "FOCUS 25:00")
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
        XCTAssertEqual(state.menuBarCompactPillText, "REST 00:05")
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
        XCTAssertEqual(state.menuBarCompactPillText, "PAUSED 12:34")
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

    func testIdleCompactPillMatchesAppName() {
        let state = AppShellState.testShell(
            sessionState: .idle,
            intervalPhase: nil,
            currentRound: nil,
            totalRounds: nil,
            currentCycle: nil,
            totalCycles: nil
        )
        XCTAssertEqual(state.menuBarCompactPillText, "FocusHacker")
    }
}

@MainActor
final class AppShellViewModelMenuBarSessionTests: XCTestCase {
    private func makeViewModel() -> (AppShellViewModel, TimerService) {
        let suiteName = "AppShellViewModelMenuBar.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        let blocker = SessionConfigTestBlockerService()
        let timerService = TimerService(
            blockerService: blocker,
            sessionRecorder: NoOpSessionRecorder(),
            tickIntervalNanoseconds: 100_000_000
        )
        let dependencies = AppDependencies(
            timerService: timerService,
            blockerService: blocker,
            automationCoordinator: .shared,
            xpStatsReader: NoOpXPStatsReader(),
            gamificationDashboardReader: NoOpGamificationDashboardReader(),
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: SessionConfigTestNotificationAuth(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        return (AppShellViewModel(dependencies: dependencies), timerService)
    }

    func testRunningSessionShowsCompactFocusPillInMenuBar() async {
        let (viewModel, _) = makeViewModel()
        viewModel.applyFocusPreset(FocusSessionPresets.expert)

        viewModel.startSession()
        for _ in 0..<100 {
            if viewModel.state.sessionState == .focus {
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(viewModel.state.sessionState, .focus)
        XCTAssertTrue(viewModel.menuBarShowsPill)
        XCTAssertTrue(viewModel.menuBarPillText.hasPrefix("FOCUS "))
        XCTAssertFalse(viewModel.menuBarPillText.contains("·"))
        XCTAssertGreaterThan(viewModel.menuBarLabelRevision, 0)
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
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
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

@MainActor
final class FocusSessionPresetViewModelTests: XCTestCase {
    private func makeStore() -> UserDefaultsSettingsStore {
        let suiteName = "FocusPreset.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Expected dedicated UserDefaults suite.")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
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
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: SessionConfigTestNotificationAuth(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        return AppShellViewModel(dependencies: dependencies)
    }

    func testApplyFocusPresetUpdatesFieldsAndPersists() {
        let store = makeStore()
        let viewModel = makeViewModel(store: store)

        viewModel.applyFocusPreset(FocusSessionPresets.intense)

        XCTAssertEqual(viewModel.selectedFocusPresetID, "intense")
        XCTAssertEqual(store.lastSelectedFocusPresetID, "intense")
        XCTAssertEqual(viewModel.focusDurationMinutes, 40)
        XCTAssertEqual(viewModel.focusDurationSecondsComponent, 0)
        XCTAssertEqual(viewModel.shortRestDurationMinutes, 10)
        XCTAssertEqual(viewModel.shortRestDurationSecondsComponent, 0)
        XCTAssertEqual(viewModel.roundsPerSession, 3)
        XCTAssertEqual(viewModel.cyclesPerSession, 1)
        XCTAssertEqual(viewModel.stagingTimerConfiguration, FocusSessionPresets.intense.timerConfiguration)
    }

    func testManualEditClearsSelectedPreset() {
        let store = makeStore()
        let viewModel = makeViewModel(store: store)

        viewModel.applyFocusPreset(FocusSessionPresets.classic)
        viewModel.roundsPerSession = 5

        XCTAssertEqual(viewModel.selectedFocusPresetID, FocusSessionPresets.createCustomCarouselID)
        XCTAssertEqual(store.lastSelectedFocusPresetID, FocusSessionPresets.createCustomCarouselID)
    }

    func testRestoreFocusPresetSelectionUsesSavedPreset() {
        let store = makeStore()
        store.lastSelectedFocusPresetID = "expert"
        let viewModel = makeViewModel(store: store)

        viewModel.restoreFocusPresetSelectionIfNeeded()

        XCTAssertEqual(viewModel.selectedFocusPresetID, "expert")
        XCTAssertEqual(viewModel.roundsPerSession, 3)
        XCTAssertEqual(viewModel.focusDurationMinutes, 50)
    }

    func testRestoreFocusPresetSelectionDefaultsToClassic() {
        let store = makeStore()
        let viewModel = makeViewModel(store: store)

        viewModel.restoreFocusPresetSelectionIfNeeded()

        XCTAssertEqual(viewModel.selectedFocusPresetID, "classic")
        XCTAssertEqual(viewModel.stagingTimerConfiguration, FocusSessionPresets.classic.timerConfiguration)
    }

    func testClearFocusPresetSelectionRemovesPersistence() {
        let store = makeStore()
        store.lastSelectedFocusPresetID = "classic"
        let viewModel = makeViewModel(store: store)

        viewModel.clearFocusPresetSelection()

        XCTAssertNil(viewModel.selectedFocusPresetID)
        XCTAssertNil(store.lastSelectedFocusPresetID)
    }

    func testFocusSessionDisplayNameClassicIncludesRecommended() {
        let viewModel = makeViewModel(store: makeStore())

        viewModel.applyFocusPreset(FocusSessionPresets.classic)
        XCTAssertEqual(viewModel.focusSessionDisplayName, "Classic Recommended")

        viewModel.applyFocusPreset(FocusSessionPresets.intense)
        XCTAssertEqual(viewModel.focusSessionDisplayName, "Intense")

        viewModel.selectCreateCustomFocusPreset()
        XCTAssertEqual(viewModel.focusSessionDisplayName, "Create Custom")
    }

    func testPopoverFocusSessionDescriptionMatchesPreset() {
        let viewModel = makeViewModel(store: makeStore())

        viewModel.applyFocusPreset(FocusSessionPresets.classic)
        XCTAssertEqual(
            viewModel.popoverFocusSessionDescription,
            FocusSessionPresets.classic.descriptionLine
        )

        viewModel.selectCreateCustomFocusPreset()
        XCTAssertEqual(viewModel.popoverFocusSessionDescription, "Custom durations")
    }

    func testPopoverTimerCardConfigAndFooterStatsFollowPreset() {
        let viewModel = makeViewModel(store: makeStore())
        viewModel.applyFocusPreset(FocusSessionPresets.classic)

        XCTAssertEqual(viewModel.popoverFocusTimeValue, "25 min")
        XCTAssertEqual(viewModel.popoverRestTimeValue, "5 min")
        XCTAssertEqual(viewModel.popoverConfigCyclesValue, "4")
        XCTAssertEqual(viewModel.popoverSessionsStatValue, "1")
        XCTAssertEqual(viewModel.menuBarSessionStatLabel, "Total session time")
        XCTAssertEqual(viewModel.menuBarFocusStatLabel, "Total focus time")
    }

    func testPopoverConfigCyclesValueUpdatesWhenCustomRoundsChange() {
        let viewModel = makeViewModel(store: makeStore())
        viewModel.selectCreateCustomFocusPreset()
        viewModel.roundsPerSession = 6

        XCTAssertEqual(viewModel.popoverConfigCyclesValue, "6")
    }

    func testCycleFocusPresetForwardWrapsThroughAllFourCarouselSlots() {
        let viewModel = makeViewModel(store: makeStore())

        viewModel.applyFocusPreset(FocusSessionPresets.classic)
        viewModel.cycleFocusPreset(forward: true)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "intense")

        viewModel.cycleFocusPreset(forward: true)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "expert")

        viewModel.cycleFocusPreset(forward: true)
        XCTAssertEqual(viewModel.selectedFocusPresetID, FocusSessionPresets.createCustomCarouselID)
        XCTAssertTrue(viewModel.isCreateCustomFocusPresetSelected)

        viewModel.cycleFocusPreset(forward: true)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "classic")
    }

    func testCycleFocusPresetBackwardWrapsThroughAllFourCarouselSlots() {
        let viewModel = makeViewModel(store: makeStore())

        viewModel.applyFocusPreset(FocusSessionPresets.classic)
        viewModel.cycleFocusPreset(forward: false)
        XCTAssertEqual(viewModel.selectedFocusPresetID, FocusSessionPresets.createCustomCarouselID)

        viewModel.cycleFocusPreset(forward: false)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "expert")

        viewModel.cycleFocusPreset(forward: false)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "intense")

        viewModel.cycleFocusPreset(forward: false)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "classic")
    }

    func testCycleFocusPresetFromCreateCustomSelectsClassicOnForward() {
        let viewModel = makeViewModel(store: makeStore())

        viewModel.selectCreateCustomFocusPreset()
        viewModel.cycleFocusPreset(forward: true)

        XCTAssertEqual(viewModel.selectedFocusPresetID, "classic")
        XCTAssertEqual(viewModel.stagingTimerConfiguration, FocusSessionPresets.classic.timerConfiguration)
    }

    func testRestoreFocusPresetSelectionRestoresCreateCustomSlot() {
        let store = makeStore()
        store.lastSelectedFocusPresetID = FocusSessionPresets.createCustomCarouselID
        let viewModel = makeViewModel(store: store)

        viewModel.restoreFocusPresetSelectionIfNeeded()

        XCTAssertEqual(viewModel.selectedFocusPresetID, FocusSessionPresets.createCustomCarouselID)
        XCTAssertTrue(viewModel.isCreateCustomFocusPresetSelected)
    }

    func testCycleFocusPresetNoOpWhenSessionActive() async {
        let store = makeStore()
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
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: SessionConfigTestNotificationAuth(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        let viewModel = AppShellViewModel(dependencies: dependencies)
        viewModel.applyFocusPreset(FocusSessionPresets.classic)

        await timerService.startSession(configuration: viewModel.stagingTimerConfiguration)
        for _ in 0..<100 {
            if viewModel.state.sessionState == .focus {
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(viewModel.state.sessionState, .focus)

        viewModel.cycleFocusPreset(forward: true)
        XCTAssertEqual(viewModel.selectedFocusPresetID, "classic")
    }
}

@MainActor
final class PopoverHeroUpNextTests: XCTestCase {
    private func makeStore(
        rounds: Int = 4,
        cycles: Int = 1,
        longRestSeconds: Int = 15 * 60
    ) -> UserDefaultsSettingsStore {
        let suiteName = "PopoverHeroUpNext.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        store.roundsPerSession = rounds
        store.cyclesPerSession = cycles
        store.longRestDurationSeconds = longRestSeconds
        return store
    }

    private func makeViewModel(store: UserDefaultsSettingsStore) -> (AppShellViewModel, TimerService) {
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
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: SessionConfigTestNotificationAuth(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        return (AppShellViewModel(dependencies: dependencies), timerService)
    }

    func testIdleHeroUpNextIsFocus() {
        let store = makeStore()
        let (viewModel, _) = makeViewModel(store: store)

        XCTAssertEqual(viewModel.heroUpNextCaption, "Up next")
        XCTAssertEqual(viewModel.heroUpNextPhaseName, "Focus")
        XCTAssertEqual(viewModel.heroUpNextLine, "Up next: Focus")
        XCTAssertEqual(
            viewModel.popoverTimerAccessibilityLabel,
            "Up next: Focus. \(viewModel.heroCountdownText) remaining. Ready to start"
        )
    }

    func testRunningFocusShowsShortBreakUpNext() async {
        let store = makeStore()
        let (viewModel, timerService) = makeViewModel(store: store)

        await timerService.startSession(configuration: viewModel.stagingTimerConfiguration)
        await waitUntilFocusRunning(viewModel)

        XCTAssertEqual(viewModel.heroUpNextPhaseName, "Short break")
        XCTAssertTrue(viewModel.popoverTimerAccessibilityLabel.contains("Up next: Short break"))
    }

    func testLastFocusRoundShowsDoneUpNext() async {
        let store = makeStore(rounds: 1, cycles: 1, longRestSeconds: 0)
        let (viewModel, timerService) = makeViewModel(store: store)

        await timerService.startSession(configuration: viewModel.stagingTimerConfiguration)
        await waitUntilFocusRunning(viewModel)

        XCTAssertEqual(viewModel.heroUpNextPhaseName, "Done")
    }

    func testFocusMidRoundPreviewResolvesShortBreak() {
        let cfg = TimerConfiguration(
            focusDurationSeconds: 1_500,
            shortRestDurationSeconds: 300,
            longRestDurationSeconds: 0,
            roundsPerSession: 4,
            cyclesPerSession: 1
        )
        let state = AppShellState.testShell(
            sessionState: .focus,
            intervalPhase: .focus,
            currentRound: 1,
            totalRounds: 4,
            currentCycle: 1,
            totalCycles: 1
        )
        XCTAssertEqual(
            TimerNextIntervalPreview.resolve(configuration: cfg, state: state).footerPhaseName,
            "Short break"
        )
    }

    private func waitUntilFocusRunning(_ viewModel: AppShellViewModel) async {
        for _ in 0..<100 {
            if viewModel.state.sessionState == .focus, viewModel.state.intervalPhase == .focus {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Expected focus session to start")
    }
}

@MainActor
final class FocusSessionFormatterTests: XCTestCase {
    private func makeStore(rounds: Int) -> UserDefaultsSettingsStore {
        let suiteName = "FocusSessionFormatter.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Expected UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        store.roundsPerSession = rounds
        store.cyclesPerSession = 1
        return store
    }

    private func makeViewModel(store: UserDefaultsSettingsStore) -> (AppShellViewModel, TimerService) {
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
            analyticsSessionReader: NoOpAnalyticsSessionReader(),
            weeklyGamificationEvaluating: NoOpWeeklyGamificationEvaluator(),
            settingsStore: store,
            audioCueService: AudioCueService(voiceOption: .crystal),
            transitionNotificationService: TransitionNotificationService(),
            notificationAuthorization: SessionConfigTestNotificationAuth(),
            purchaseEntitlementService: PurchaseEntitlementService(settingsStore: store),
            paywallWindowPresenter: PaywallWindowPresenter()
        )
        return (AppShellViewModel(dependencies: dependencies), timerService)
    }

    private func waitUntilFocusRunning(_ viewModel: AppShellViewModel) async {
        for _ in 0..<100 {
            if viewModel.state.sessionState == .focus, viewModel.state.intervalPhase == .focus {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Expected focus session to reach .focus state")
    }

    func testIdleFocusSessionFormatters() {
        let store = makeStore(rounds: 3)
        let (viewModel, _) = makeViewModel(store: store)
        viewModel.applyFocusPreset(FocusSessionPresets.expert)

        XCTAssertEqual(viewModel.focusSessionPresetName, "Expert")
        XCTAssertEqual(viewModel.focusSessionPresetSubtitle, "50 min · 10 min break · 3 cycles")
        XCTAssertEqual(viewModel.focusSessionUpNextLine, "UP NEXT · FOCUS")
        XCTAssertEqual(viewModel.focusSessionCyclePillText, "1 / 3")
        XCTAssertEqual(viewModel.focusSessionTotalStatLabel, "TOTAL")
        XCTAssertEqual(viewModel.focusSessionFocusStatLabel, "FOCUS")
        XCTAssertEqual(viewModel.focusSessionSessionsStatLabel, "SESSIONS")
        XCTAssertEqual(viewModel.focusSessionPrimaryButtonTitle, "Start focus")
        XCTAssertFalse(viewModel.focusSessionShowsEndSessionButton)
    }

    func testRunningFocusSessionCyclePillAndFooterLabels() async {
        let store = makeStore(rounds: 3)
        let (viewModel, timerService) = makeViewModel(store: store)
        viewModel.applyFocusPreset(FocusSessionPresets.expert)

        await timerService.startSession(configuration: viewModel.stagingTimerConfiguration)
        await waitUntilFocusRunning(viewModel)

        XCTAssertEqual(viewModel.focusSessionUpNextLine, "UP NEXT · FOCUS")
        XCTAssertEqual(viewModel.focusSessionCyclePillText, "1 / 3")
        XCTAssertEqual(viewModel.focusSessionTotalStatLabel, "SESSION LEFT")
        XCTAssertEqual(viewModel.focusSessionFocusStatLabel, "FOCUS LEFT")
        XCTAssertEqual(viewModel.focusSessionSessionsStatLabel, "SESSIONS LEFT")
        XCTAssertEqual(viewModel.focusSessionPrimaryButtonTitle, "Pause")
        XCTAssertTrue(viewModel.focusSessionShowsEndSessionButton)
    }

    func testCustomFocusSessionShowsInlineConfigurationSubtitle() {
        let store = makeStore(rounds: 3)
        let (viewModel, _) = makeViewModel(store: store)
        viewModel.selectCreateCustomFocusPreset()

        XCTAssertTrue(viewModel.focusSessionShowsCustomConfiguration)
        XCTAssertEqual(viewModel.focusSessionPresetSubtitle, "Custom session")
    }

    func testPausedFocusSessionPrimaryButtonTitle() async {
        let store = makeStore(rounds: 3)
        let (viewModel, timerService) = makeViewModel(store: store)
        viewModel.applyFocusPreset(FocusSessionPresets.expert)

        await timerService.startSession(configuration: viewModel.stagingTimerConfiguration)
        await waitUntilFocusRunning(viewModel)
        viewModel.togglePause()

        for _ in 0..<100 {
            if viewModel.state.isSessionPaused {
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertTrue(viewModel.state.isSessionPaused)
        XCTAssertEqual(viewModel.focusSessionPrimaryButtonTitle, "Resume")
        XCTAssertTrue(viewModel.focusSessionPrimaryButtonUsesPlayIcon)
    }
}
