import Foundation

/// Evaluates whether a newly launched app should be terminated during focus blocking.
enum AppBlockingPolicy {
    static func shouldTerminate(
        bundleIdentifier: String,
        payload: BlockerSharedStateFile.Payload?,
        blockedBundleIdentifiers: [String],
        now: Date = .init()
    ) -> Bool {
        guard let payload else {
            return false
        }
        let leaseValid = BlockerAppGroup.isBlockingLeaseValid(
            isActive: payload.blockingIsActive,
            leaseUntilReference: payload.blockingLeaseExpiresAtReference,
            now: now
        )
        guard leaseValid else {
            return false
        }
        return BlocklistEvaluation.shouldBlockApp(
            bundleIdentifier: bundleIdentifier,
            blockedBundleIdentifiers: blockedBundleIdentifiers
        )
    }

    static func currentPayload() -> BlockerSharedStateFile.Payload? {
        BlockerSharedStateFile.read()
    }
}
