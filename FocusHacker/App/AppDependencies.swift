import Foundation

struct AppDependencies {
    let timerService: TimerServiceProtocol
    let blockerService: BlockerServiceProtocol
    let automationCoordinator: AutomationCoordinator
    let xpStatsReader: XPStatsReading
    let gamificationDashboardReader: GamificationDashboardReading
    let analyticsSessionReader: AnalyticsSessionReading
    let weeklyGamificationEvaluating: WeeklyGamificationEvaluating
    let settingsStore: UserDefaultsSettingsStore
    let audioCueService: AudioCuePlaying
    let transitionNotificationService: TransitionNotificationHandling
    let notificationAuthorization: NotificationAuthorizationServing
    let purchaseEntitlementService: PurchaseEntitlementService
    let paywallWindowPresenter: PaywallWindowPresenter
    let gamificationProgressResetting: GamificationProgressResetting?

    init(
        timerService: TimerServiceProtocol,
        blockerService: BlockerServiceProtocol,
        automationCoordinator: AutomationCoordinator,
        xpStatsReader: XPStatsReading,
        gamificationDashboardReader: GamificationDashboardReading,
        analyticsSessionReader: AnalyticsSessionReading,
        weeklyGamificationEvaluating: WeeklyGamificationEvaluating,
        settingsStore: UserDefaultsSettingsStore,
        audioCueService: AudioCuePlaying,
        transitionNotificationService: TransitionNotificationHandling,
        notificationAuthorization: NotificationAuthorizationServing,
        purchaseEntitlementService: PurchaseEntitlementService,
        paywallWindowPresenter: PaywallWindowPresenter,
        gamificationProgressResetting: GamificationProgressResetting? = nil
    ) {
        self.timerService = timerService
        self.blockerService = blockerService
        self.automationCoordinator = automationCoordinator
        self.xpStatsReader = xpStatsReader
        self.gamificationDashboardReader = gamificationDashboardReader
        self.analyticsSessionReader = analyticsSessionReader
        self.weeklyGamificationEvaluating = weeklyGamificationEvaluating
        self.settingsStore = settingsStore
        self.audioCueService = audioCueService
        self.transitionNotificationService = transitionNotificationService
        self.notificationAuthorization = notificationAuthorization
        self.purchaseEntitlementService = purchaseEntitlementService
        self.paywallWindowPresenter = paywallWindowPresenter
        self.gamificationProgressResetting = gamificationProgressResetting
    }
}

@MainActor
extension AppDependencies {
    static let live: AppDependencies = {
        let settingsStore = UserDefaultsSettingsStore(userDefaults: .standard)
        let sessionRecorder: SessionRecording
        let xpStatsReader: XPStatsReading
        let dashboardReader: GamificationDashboardReading
        let analyticsReader: AnalyticsSessionReading
        let weeklyGamificationEvaluator: WeeklyGamificationEvaluating
        let blockerService = BlockerService()
        let automationCoordinator = AutomationCoordinator.shared

        var gamificationProgressResetting: GamificationProgressResetting?
        if #available(macOS 14.0, *) {
            let container = SwiftDataContainerFactory.makePersistentContainer()
            gamificationProgressResetting = SwiftDataGamificationProgressResetter(container: container)
            do {
                // #region agent log
                let backfillStart = CFAbsoluteTimeGetCurrent()
                // #endregion
                try GamificationXPBackfill.runIfNeeded(container: container, settingsStore: settingsStore)
                // #region agent log
                let backfillMs = Int((CFAbsoluteTimeGetCurrent() - backfillStart) * 1000)
                DebugSessionLog82afba.write(
                    hypothesisId: "H3",
                    location: "AppDependencies.live",
                    message: "xp_backfill_finished",
                    data: ["durationMs": "\(backfillMs)"]
                )
                // #endregion
            } catch {
                // Best-effort; XP totals recompute on next successful backfill.
            }
            sessionRecorder = SwiftDataSessionLifecycleRecorder(container: container, settingsStore: settingsStore)
            xpStatsReader = SwiftDataXPStatsReader(container: container, settingsStore: settingsStore)
            dashboardReader = SwiftDataGamificationDashboardReader(container: container, settingsStore: settingsStore)
            analyticsReader = SwiftDataAnalyticsSessionReader(container: container)
            weeklyGamificationEvaluator = SwiftDataWeeklyGamificationEvaluator(
                container: container,
                settingsStore: settingsStore
            )
        } else {
            sessionRecorder = NoOpSessionRecorder()
            xpStatsReader = NoOpXPStatsReader()
            dashboardReader = NoOpGamificationDashboardReader()
            analyticsReader = NoOpAnalyticsSessionReader()
            weeklyGamificationEvaluator = NoOpWeeklyGamificationEvaluator()
        }

        let timerService = TimerService(
            blockerService: blockerService,
            sessionRecorder: sessionRecorder,
            gamificationDashboardReader: dashboardReader,
            tickIntervalNanoseconds: 1_000_000_000
        )
        let voicePackPlayer = VoicePackPlayer()
        let voiceOption = VoiceOption.resolve(storedIdentifier: settingsStore.selectedVoiceOption)
        let audioCueService = AudioCueService(voiceOption: voiceOption, voicePackPlayer: voicePackPlayer)
        let transitionNotificationService = TransitionNotificationService()
        let notificationAuthorization = NotificationAuthorizationService()
        let purchaseEntitlementService = PurchaseEntitlementService(settingsStore: settingsStore)
        let paywallWindowPresenter = PaywallWindowPresenter()

        return AppDependencies(
            timerService: timerService,
            blockerService: blockerService,
            automationCoordinator: automationCoordinator,
            xpStatsReader: xpStatsReader,
            gamificationDashboardReader: dashboardReader,
            analyticsSessionReader: analyticsReader,
            weeklyGamificationEvaluating: weeklyGamificationEvaluator,
            settingsStore: settingsStore,
            audioCueService: audioCueService,
            transitionNotificationService: transitionNotificationService,
            notificationAuthorization: notificationAuthorization,
            purchaseEntitlementService: purchaseEntitlementService,
            paywallWindowPresenter: paywallWindowPresenter,
            gamificationProgressResetting: gamificationProgressResetting
        )
    }()
}
