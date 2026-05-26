import Foundation

@MainActor
final class FirstLaunchOnboardingFlowViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case appOverview
        case timerExplanation
        case gamificationGoals
        case blockerExplanation
        case blockerPermission
        case notificationsPermission
    }

    @Published private(set) var step: Step = .appOverview

    @Published var blockerInstallErrorDescription: String?

    /// `nil` = no decision yet / skipped without prompt; updates after system prompt resolves.
    @Published private(set) var notificationDecisionHint: Bool?

    @Published var onboardingPersonalWeeklyTargetHoursComponent: Int {
        didSet {
            guard !isSyncingOnboardingPersonalTargetParts else { return }
            syncOnboardingPersonalTargetParts()
        }
    }

    @Published var onboardingPersonalWeeklyTargetMinutesComponent: Int {
        didSet {
            guard !isSyncingOnboardingPersonalTargetParts else { return }
            syncOnboardingPersonalTargetParts()
        }
    }

    private var isSyncingOnboardingPersonalTargetParts = false

    private let settingsStore: UserDefaultsSettingsStore
    private let notificationAuthorization: NotificationAuthorizationServing
    private let dismissAfterCompletion: () -> Void

    init(
        settingsStore: UserDefaultsSettingsStore,
        blockerService: BlockerServiceProtocol,
        notificationAuthorization: NotificationAuthorizationServing,
        dismissAfterCompletion: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        let parts = PersonalWeeklyTargetFormatting.split(
            totalMinutes: settingsStore.personalWeeklyMinutesTarget
        )
        self.onboardingPersonalWeeklyTargetHoursComponent = parts.hours
        self.onboardingPersonalWeeklyTargetMinutesComponent = parts.minutes
        _ = blockerService
        self.notificationAuthorization = notificationAuthorization
        self.dismissAfterCompletion = dismissAfterCompletion
    }

    var progressLabel: String {
        "\(step.rawValue + 1) / \(Step.allCases.count)"
    }

    var appearancePreference: AppearancePreference {
        settingsStore.appearancePreference
    }

    var onboardingStepHeading: String {
        switch step {
        case .appOverview:
            return "Overview"
        case .timerExplanation:
            return "Timer"
        case .gamificationGoals:
            return "Goals"
        case .blockerExplanation:
            return "Blocking"
        case .blockerPermission:
            return "Blocking permission"
        case .notificationsPermission:
            return "Notifications"
        }
    }

    var canGoBack: Bool {
        step != .appOverview
    }

    var isFinalStep: Bool {
        step == .notificationsPermission
    }

    func goBack() {
        guard let previousRaw = Step(rawValue: step.rawValue - 1) else {
            return
        }
        step = previousRaw
        if previousRaw != .blockerPermission {
            blockerInstallErrorDescription = nil
        }
    }

    func goForward() {
        if step == .blockerPermission {
            markBlockerOnboardingExplainerConsumed()
        }
        guard let next = Step(rawValue: step.rawValue + 1) else {
            return
        }
        step = next
    }

    /// Primary CTA forward progress (skips browser permission prompts but retains education).
    func skipBlockInstallAndContinue() {
        blockerInstallErrorDescription = nil
        markBlockerOnboardingExplainerConsumed()
        guard let next = Step(rawValue: step.rawValue + 1) else {
            return
        }
        step = next
    }

    func requestBrowserAutomationPermissions() {
        AutomationPermissionPrimer.primeForOnboardingIfNeeded()
    }

    func requestNotificationAuthorization() {
        Task {
            let granted = await notificationAuthorization.requestAuthorization()
            await MainActor.run {
                notificationDecisionHint = granted
                settingsStore.lastNotificationAuthorizationGrantedSnapshot = granted
                settingsStore.notificationAuthorizationPromptWasRecorded = true
            }
        }
    }

    func continueWithoutNotificationPrompt() {
        notificationDecisionHint = nil
        settingsStore.notificationAuthorizationPromptWasRecorded = false
    }

    func applyOnboardingPersonalTarget() {
        let normalized = PersonalWeeklyTargetFormatting.normalizedParts(
            hours: onboardingPersonalWeeklyTargetHoursComponent,
            minutes: onboardingPersonalWeeklyTargetMinutesComponent
        )
        settingsStore.personalWeeklyMinutesTarget = normalized.totalMinutes
        applyOnboardingPersonalTargetParts(normalized.hours, normalized.minutes)
    }

    private func syncOnboardingPersonalTargetParts() {
        let normalized = PersonalWeeklyTargetFormatting.normalizedParts(
            hours: onboardingPersonalWeeklyTargetHoursComponent,
            minutes: onboardingPersonalWeeklyTargetMinutesComponent
        )
        applyOnboardingPersonalTargetParts(normalized.hours, normalized.minutes)
    }

    private func applyOnboardingPersonalTargetParts(_ hours: Int, _ minutes: Int) {
        guard hours != onboardingPersonalWeeklyTargetHoursComponent || minutes != onboardingPersonalWeeklyTargetMinutesComponent else {
            return
        }
        isSyncingOnboardingPersonalTargetParts = true
        onboardingPersonalWeeklyTargetHoursComponent = hours
        onboardingPersonalWeeklyTargetMinutesComponent = minutes
        isSyncingOnboardingPersonalTargetParts = false
    }

    func completeGuidedTour() {
        applyOnboardingPersonalTarget()
        markBlockerOnboardingExplainerConsumed()
        settingsStore.hasCompletedFullOnboarding = true
        dismissAfterCompletion()
    }

    private func markBlockerOnboardingExplainerConsumed() {
        settingsStore.didPresentBlockerOnboarding = true
    }
}
