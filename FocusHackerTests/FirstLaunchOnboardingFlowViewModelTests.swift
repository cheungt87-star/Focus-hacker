@testable import FocusHacker
import XCTest

private struct FixedBlockerOutcomeService: BlockerServiceProtocol {
    let outcome: Result<Void, Error>

    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async {
        _ = bounceFilterConnectionsOnActivate
        _ = tearDownStaleConnectionsOnActivate
        _ = blockingEpoch
    }

    func refreshBlockingLeaseIfActive() async { }


    func refreshBlockedIPLiteralsAfterBlocklistChange() async { }

    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async {}
}

private struct FixedNotificationAuthService: NotificationAuthorizationServing {
    let grant: Bool

    func requestAuthorization() async -> Bool {
        grant
    }
}

@MainActor
final class FirstLaunchOnboardingFlowViewModelTests: XCTestCase {
    private func makeFreshStore() -> UserDefaultsSettingsStore {
        let suiteName = "OnboardingVM.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
    }

    func testLeavingBlockPermissionStepMarksBlockerTutorialSeen() {
        let store = makeFreshStore()
        XCTAssertFalse(store.didPresentBlockerOnboarding)

        let viewModel = FirstLaunchOnboardingFlowViewModel(
            settingsStore: store,
            blockerService: FixedBlockerOutcomeService(outcome: .failure(NSError(domain: "test", code: -1))),
            notificationAuthorization: FixedNotificationAuthService(grant: false),
            dismissAfterCompletion: { }
        )

        XCTAssertEqual(viewModel.step, .appOverview)

        viewModel.goForward()
        viewModel.goForward()
        viewModel.goForward()

        XCTAssertEqual(viewModel.step, .blockerPermission)

        viewModel.goForward()

        XCTAssertTrue(store.didPresentBlockerOnboarding)
        XCTAssertEqual(viewModel.step, .notificationsPermission)
    }

    func testSkipBlockPermissionProceeds() {
        let store = makeFreshStore()
        let viewModel = FirstLaunchOnboardingFlowViewModel(
            settingsStore: store,
            blockerService: FixedBlockerOutcomeService(outcome: .failure(NSError(domain: "test", code: -1))),
            notificationAuthorization: FixedNotificationAuthService(grant: true),
            dismissAfterCompletion: { }
        )

        viewModel.goForward()
        viewModel.goForward()
        viewModel.goForward()

        viewModel.skipBlockInstallAndContinue()

        XCTAssertTrue(store.didPresentBlockerOnboarding)
        XCTAssertEqual(viewModel.step, .notificationsPermission)
    }

    func testCompleteMarksFullOnboarding() async {
        let store = makeFreshStore()
        let expectation = expectation(description: "dismiss fired")

        let viewModel = FirstLaunchOnboardingFlowViewModel(
            settingsStore: store,
            blockerService: FixedBlockerOutcomeService(outcome: .success(())),
            notificationAuthorization: FixedNotificationAuthService(grant: true),
            dismissAfterCompletion: {
                expectation.fulfill()
            }
        )

        viewModel.completeGuidedTour()

        XCTAssertTrue(store.hasCompletedFullOnboarding)

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testNotificationContinuationRecordsSnapshot() async throws {
        let store = makeFreshStore()
        let viewModel = FirstLaunchOnboardingFlowViewModel(
            settingsStore: store,
            blockerService: FixedBlockerOutcomeService(outcome: .success(())),
            notificationAuthorization: FixedNotificationAuthService(grant: true),
            dismissAfterCompletion: { }
        )

        viewModel.requestNotificationAuthorization()
        try await Task.sleep(nanoseconds: 350_000_000)

        XCTAssertTrue(store.notificationAuthorizationPromptWasRecorded)
        XCTAssertTrue(store.lastNotificationAuthorizationGrantedSnapshot)
        XCTAssertEqual(viewModel.notificationDecisionHint, true)
    }

    func testContinueWithoutNotificationPromptDoesNotRecordSnapshot() {
        let store = makeFreshStore()
        let viewModel = FirstLaunchOnboardingFlowViewModel(
            settingsStore: store,
            blockerService: FixedBlockerOutcomeService(outcome: .success(())),
            notificationAuthorization: FixedNotificationAuthService(grant: false),
            dismissAfterCompletion: { }
        )

        viewModel.continueWithoutNotificationPrompt()

        XCTAssertFalse(store.notificationAuthorizationPromptWasRecorded)
        XCTAssertNil(viewModel.notificationDecisionHint)
    }
}
