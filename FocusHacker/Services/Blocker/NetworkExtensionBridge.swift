import Foundation

/// App Group lease + shared JSON for browser automation blocking (no network filter extension).
actor NetworkExtensionBridge: NetworkExtensionBridgeProtocol {
    static let shared = NetworkExtensionBridge()

    private let suiteDefaults: UserDefaults?
    private var leaseRenewalTask: Task<Void, Never>?
    private var leaseRenewalGeneration: UInt64 = 0
    private var deactivateGeneration: UInt64 = 0

    init(suiteDefaults: UserDefaults? = UserDefaults(suiteName: BlockerAppGroup.identifier)) {
        self.suiteDefaults = suiteDefaults
    }

    func refreshLeaseIfBlockingActive() async {
        guard let defaults = suiteDefaults else { return }
        guard defaults.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive) else {
            return
        }
        writeLease(defaults: defaults)
    }

    func refreshBlockedIPLiteralsAfterBlocklistChange() async {}

    func sendBlockingState(
        isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool = false,
        blockingEpoch: String? = nil,
        tearDownStaleConnectionsOnActivate: Bool = false
    ) async {
        guard let defaults = suiteDefaults else {
            return
        }
        _ = bounceFilterConnectionsOnActivate
        _ = tearDownStaleConnectionsOnActivate
        if isActive {
            defaults.set(true, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
            defaults.synchronize()
            if let blockingEpoch, !blockingEpoch.isEmpty {
                defaults.set(blockingEpoch, forKey: BlockerAppGroup.UserDefaultsKey.blockingEpoch)
                defaults.synchronize()
            }
            writeLease(defaults: defaults)
            startLeaseRenewal(defaults: defaults)
        } else {
            deactivateGeneration &+= 1
            invalidateLeaseRenewal()
            defaults.set(false, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
            defaults.removeObject(forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)
            defaults.removeObject(forKey: BlockerAppGroup.UserDefaultsKey.blockingEpoch)
            defaults.synchronize()
            BlockingSnapshotWriter.commitHostSuiteProjectionToSharedJSON(suite: defaults)
        }
    }

    private func writeLease(defaults: UserDefaults, renewalGeneration: UInt64? = nil) {
        if let renewalGeneration {
            guard renewalGeneration == leaseRenewalGeneration,
                  !Task.isCancelled else {
                return
            }
        }
        guard defaults.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive) else {
            return
        }
        let until = Date().timeIntervalSinceReferenceDate + BlockerAppGroup.blockingLeaseTTLSeconds
        defaults.set(until, forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)
        defaults.synchronize()
        BlockingSnapshotWriter.commitHostSuiteProjectionToSharedJSON(suite: defaults)
    }

    private func startLeaseRenewal(defaults: UserDefaults) {
        leaseRenewalTask?.cancel()
        leaseRenewalGeneration &+= 1
        let generation = leaseRenewalGeneration
        leaseRenewalTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: BlockerAppGroup.blockingLeaseRenewalIntervalNanoseconds)
                if Task.isCancelled {
                    return
                }
                await self.renewLeaseIfNeeded(defaults: defaults, generation: generation)
            }
        }
    }

    private func renewLeaseIfNeeded(defaults: UserDefaults, generation: UInt64) async {
        if Task.isCancelled || generation != leaseRenewalGeneration {
            return
        }
        guard defaults.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive) else {
            leaseRenewalTask?.cancel()
            leaseRenewalTask = nil
            return
        }
        writeLease(defaults: defaults, renewalGeneration: generation)
    }

    private func invalidateLeaseRenewal() {
        leaseRenewalTask?.cancel()
        leaseRenewalTask = nil
        leaseRenewalGeneration &+= 1
    }
}
