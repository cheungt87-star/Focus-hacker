import AppKit
import Foundation

@MainActor
final class FocusHackerAppDelegate: NSObject, NSApplicationDelegate {
    private let onboardingPresenter = FirstLaunchOnboardingPresenter()
    private var onboardingObserver: NSObjectProtocol?
    private var activationPolicyObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let dependencies = AppDependencies.live

        onboardingObserver = NotificationCenter.default.addObserver(
            forName: .focusHackerOnboardingChromeDismissed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                AutomationPermissionPrimer.primeOnLaunchIfNeeded()
                await self?.coordinateMonetisationGate(dependencies: AppDependencies.live)
            }
        }

        activationPolicyObserver = NotificationCenter.default.addObserver(
            forName: .focusHackerActivationPolicyChanged,
            object: nil,
            queue: .main
        ) { _ in }

        onboardingPresenter.presentIfNeeded(dependencies: dependencies)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if UserDefaults.standard.bool(forKey: "onboarding.didCompleteGuidedFlow") {
                AutomationPermissionPrimer.primeOnLaunchIfNeeded()
            } else {
                AutomationPermissionPrimer.primeForOnboardingIfNeeded()
            }
        }

        Task { @MainActor in
            await dependencies.automationCoordinator.resyncFromTimer(dependencies.timerService)
            await AppDependencies.live.purchaseEntitlementService.bootstrap()
            await coordinateMonetisationGate(dependencies: AppDependencies.live)
            #if DEBUG
            if ProcessInfo.processInfo.environment["FE1347_AUTO_VERIFY"] == "1" {
                await runFE1347AutoVerifySession()
            }
            #endif
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(Self.workspaceDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        BlockingStateCoordinator.deactivateSharedStateForHostQuit()
    }

    @objc private func workspaceDidWake(_ notification: Notification) {
        Task {
            await BlockingStateCoordinator.shared.refreshBlockingLeaseIfActive()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        AutomationPermissionPrimer.refreshGrantStateQuietly()
        Task {
            let timerState = await AppDependencies.live.timerService.currentSessionState()
            let phase = timerState.intervalPhase.map { String(describing: $0) } ?? "nil"
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H5",
                location: "FocusHackerAppDelegate.applicationDidBecomeActive",
                message: "app_became_active",
                data: [
                    "lifecycle": String(describing: timerState.lifecycleState),
                    "phase": phase,
                    "round": String(timerState.currentRound),
                ]
            )
            // #endregion
            await AppDependencies.live.timerService.resyncBlockingForRunningFocusIfNeeded()
            await AppDependencies.live.automationCoordinator.resyncFromTimer(AppDependencies.live.timerService)
            await BlockingStateCoordinator.shared.refreshBlockingLeaseIfActive()
        }
    }

    #if DEBUG
    /// `FE1347_AUTO_VERIFY=1` — Pomodoro 30s/30s, 2 rounds (build 57 Chrome round-2 repro).
    private func runFE1347AutoVerifySession() async {
        try? await Task.sleep(nanoseconds: 4_000_000_000)
        let configuration = TimerConfiguration(
            focusDurationSeconds: 30,
            shortRestDurationSeconds: 30,
            longRestDurationSeconds: 900,
            roundsPerSession: 2,
            cyclesPerSession: 1
        )
        AgentDebugLog.write(
            hypothesisId: "H57",
            location: "FocusHackerAppDelegate.runFE1347AutoVerifySession",
            message: "fe1347_auto_verify_starting",
            data: ["focusSec": "30", "restSec": "30", "rounds": "2"],
            runId: "post-fix-v24"
        )
        await AppDependencies.live.timerService.startSession(configuration: configuration)
    }
    #endif

    private func coordinateMonetisationGate(dependencies: AppDependencies) async {
        let store = dependencies.purchaseEntitlementService
        guard dependencies.settingsStore.hasCompletedFullOnboarding else {
            return
        }

        await store.reloadLifetimeProductPrice()
        await store.refreshEntitlementsFromStore()
        await store.attemptIntroTrialSignupIfEligible()
        await store.refreshEntitlementsFromStore()

        if store.evaluation.allowsAppUse {
            dependencies.paywallWindowPresenter.dismissIfNeeded()
            return
        }

        dependencies.paywallWindowPresenter.presentIfLocked(purchaseEntitlements: store)
    }
}
