import Foundation

/// Evaluates whether a browser navigation should be redirected during focus blocking.
enum BrowserBlockingPolicy {
    static func shouldBlock(url: URL, payload: BlockerSharedStateFile.Payload?, now: Date = .init()) -> Bool {
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
        guard let host = BlocklistEvaluation.canonicalHost(from: url) else {
            return false
        }
        return BlocklistEvaluation.shouldBlockHost(host, blockedEntries: payload.blockedDomains)
    }

    static func currentPayload() -> BlockerSharedStateFile.Payload? {
        BlockerSharedStateFile.read()
    }
}
