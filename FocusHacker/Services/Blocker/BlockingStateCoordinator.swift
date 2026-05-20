import Foundation

/// Single host-side entry for blocking instruction, lease refresh, shared JSON mirrors, and the network-extension bridge.
/// Prefer this over calling `BlockerSharedStateFile` merge APIs or `NetworkExtensionBridge` directly from scattered call sites.
actor BlockingStateCoordinator {
    static let shared = BlockingStateCoordinator(
        bridge: NetworkExtensionBridge.shared,
        automationCoordinator: AutomationCoordinator.shared
    )

    private let bridge: NetworkExtensionBridgeProtocol
    private let automationCoordinator: AutomationCoordinator?

    init(
        bridge: NetworkExtensionBridgeProtocol,
        automationCoordinator: AutomationCoordinator? = AutomationCoordinator.shared
    ) {
        self.bridge = bridge
        self.automationCoordinator = automationCoordinator
    }

    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async {
        await bridge.sendBlockingState(
            isActive: isActive,
            bounceFilterConnectionsOnActivate: bounceFilterConnectionsOnActivate,
            blockingEpoch: blockingEpoch,
            tearDownStaleConnectionsOnActivate: tearDownStaleConnectionsOnActivate
        )
        automationCoordinator?.setBlockingActive(isActive)
    }

    func refreshBlockingLeaseIfActive() async {
        await bridge.refreshLeaseIfBlockingActive()
    }

    func refreshBlockedIPLiteralsAfterBlocklistChange() async {
        await bridge.refreshBlockedIPLiteralsAfterBlocklistChange()
    }

    /// Writes domain/bundle lists to `/Users/Shared` JSON; App Group suite must already match (caller mirrors suite first).
    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async {
        Self.applySharedBlocklistMergeSync(domains: domains, bundleIDs: bundleIDs)
    }

    /// Synchronous merge after the caller updates the App Group suite — used from synchronous settings setters so JSON cannot lag behind suite writes.
    nonisolated static func applySharedBlocklistMergeSync(domains: [String], bundleIDs: [String]) {
        BlockingSnapshotWriter.mergeBlocklistsIntoSharedJSON(domains: domains, bundleIDs: bundleIDs)
    }

    /// Synchronous teardown for `applicationWillTerminate` — must complete before process exit.
    nonisolated static func deactivateSharedStateForHostQuit(suiteDefaults: UserDefaults? = nil) {
        BlockerSharedStateFile.deactivateBlockingForHostQuit(suiteDefaults: suiteDefaults)
    }
}
