import Foundation

actor BlockerService: BlockerServiceProtocol {
    private let coordinator: BlockingStateCoordinator

    init(coordinator: BlockingStateCoordinator = .shared) {
        self.coordinator = coordinator
    }

    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async {
        await coordinator.setBlockingActive(
            isActive,
            bounceFilterConnectionsOnActivate: bounceFilterConnectionsOnActivate,
            blockingEpoch: blockingEpoch,
            tearDownStaleConnectionsOnActivate: tearDownStaleConnectionsOnActivate
        )
    }

    func refreshBlockingLeaseIfActive() async {
        await coordinator.refreshBlockingLeaseIfActive()
    }

    func refreshBlockedIPLiteralsAfterBlocklistChange() async {
        await coordinator.refreshBlockedIPLiteralsAfterBlocklistChange()
    }

    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async {
        await coordinator.syncSharedBlocklistMirror(domains: domains, bundleIDs: bundleIDs)
    }
}
