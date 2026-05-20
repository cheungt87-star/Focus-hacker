import Foundation

/// Host-only projection of App Group `UserDefaults` into [`BlockerSharedStateFile`] (`/Users/Shared` JSON).
/// The system extension reads **only** that JSON at decision time (different UID than the host; see `BlockerSharedStateFile` header).
enum BlockingSnapshotWriter {
    /// Writes `blockingIsActive`, lease, domain/bundle lists, and `blockingEpoch` from the suite into shared JSON.
    static func commitHostSuiteProjectionToSharedJSON(suite: UserDefaults) {
        let active = suite.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        let lease = suite.double(forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)
        BlockerSharedStateFile.persistSuiteBlockingFieldsToSharedFile(
            suiteDefaults: suite,
            blockingIsActive: active,
            leaseUntilReference: active ? lease : 0
        )
    }

    static func mergeBlocklistsIntoSharedJSON(domains: [String], bundleIDs: [String]) {
        BlockerSharedStateFile.mergeBlocklistsOnly(domains: domains, bundleIDs: bundleIDs)
    }

    static func mergeBlockedIPLiteralsIntoSharedJSON(
        _ ipLiterals: [String],
        hostSuite: UserDefaults?,
        preserveValidDiskLeaseWhenSuiteInactive: Bool = false
    ) {
        BlockerSharedStateFile.mergeBlockedIPLiteralsOnly(
            ipLiterals,
            hostBlockerSuite: hostSuite,
            preserveValidDiskLeaseWhenSuiteInactive: preserveValidDiskLeaseWhenSuiteInactive
        )
    }
}
