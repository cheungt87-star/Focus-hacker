import Foundation

struct AppDependencies {
    let timerService: TimerServiceProtocol
    let blockerService: BlockerServiceProtocol
    let automationCoordinator: AutomationCoordinator
    let xpStatsReader: XPStatsReading
    let gamificationDashboardReader: GamificationDashboardReading
    let weeklyLevelEvaluating: WeeklyLevelEvaluating
    let settingsStore: UserDefaultsSettingsStore
    let audioCueService: AudioCuePlaying
    let transitionNotificationService: TransitionNotificationHandling
    let notificationAuthorization: NotificationAuthorizationServing
    let purchaseEntitlementService: PurchaseEntitlementService
    let paywallWindowPresenter: PaywallWindowPresenter
}

@MainActor
extension AppDependencies {
    static let live: AppDependencies = {
        let settingsStore = UserDefaultsSettingsStore(userDefaults: .standard)
        let sessionRecorder: SessionRecording
        let xpStatsReader: XPStatsReading
        let dashboardReader: GamificationDashboardReading
        let weeklyLevelEvaluator: WeeklyLevelEvaluating
        let blockerService = BlockerService()
        let automationCoordinator = AutomationCoordinator.shared

        if #available(macOS 14.0, *) {
            let container = SwiftDataContainerFactory.makePersistentContainer()
            sessionRecorder = SwiftDataSessionLifecycleRecorder(container: container)
            xpStatsReader = SwiftDataXPStatsReader(container: container)
            dashboardReader = SwiftDataGamificationDashboardReader(container: container)
            weeklyLevelEvaluator = SwiftDataWeeklyLevelEvaluator(
                container: container,
                settingsStore: settingsStore
            )
        } else {
            sessionRecorder = NoOpSessionRecorder()
            xpStatsReader = NoOpXPStatsReader()
            dashboardReader = NoOpGamificationDashboardReader()
            weeklyLevelEvaluator = NoOpWeeklyLevelEvaluator()
        }

        let timerService = TimerService(
            blockerService: blockerService,
            sessionRecorder: sessionRecorder,
            tickIntervalNanoseconds: 1_000_000_000
        )
        let audioCueService = AudioCueService()
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
            weeklyLevelEvaluating: weeklyLevelEvaluator,
            settingsStore: settingsStore,
            audioCueService: audioCueService,
            transitionNotificationService: transitionNotificationService,
            notificationAuthorization: notificationAuthorization,
            purchaseEntitlementService: purchaseEntitlementService,
            paywallWindowPresenter: paywallWindowPresenter
        )
    }()
}
