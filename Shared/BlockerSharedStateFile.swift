import Foundation
import os.log

private let sharedStateOSLog = OSLog(subsystem: "com.focushacker.app.shared-state", category: "debug-5b748e")

/// JSON file in `/Users/Shared/` so the root-owned system extension and the user-owned host
/// read **the same** on-disk file. App Group containers resolve to per-uid paths
/// (root's `/private/var/root/Library/Group Containers/...` vs the user's `~/Library/...`),
/// so they cannot be shared across those processes. `/Users/Shared` is mode 1777 on macOS
/// and is the canonical inter-user shared location.
enum BlockerSharedStateFile {
    static let filename = "blocker-shared-state.v1.json"

    /// Host + system extension use `/Users/Shared/...`. Unit tests set `BLOCKER_SHARED_STATE_DIR` to a temp
    /// directory so `xcodebuild test` cannot overwrite the on-disk lease / `blockedIPLiterals` used by the real app.
    static var sharedDirectoryPath: String {
        if let ptr = getenv("BLOCKER_SHARED_STATE_DIR"), let raw = String(validatingUTF8: ptr) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return "/Users/Shared/com.focushacker.blocker"
    }

    /// Serializes read/modify/write so `mergeBlocklistsOnly` cannot race with blocking snapshot writes and
    /// accidentally publish an older lease.
    private static let stateQueue = DispatchQueue(label: "com.focushacker.blocker.shared-state-io")

    struct Payload: Codable, Equatable {
        var blockingIsActive: Bool
        /// `Date.timeIntervalSinceReferenceDate`
        var blockingLeaseExpiresAtReference: Double
        var blockedDomains: [String]
        var blockedBundleIDs: [String]
        /// Bumped on every host write so the extension can detect freshness; `Date.timeIntervalSinceReferenceDate`.
        var lastUpdatedAtReference: Double = 0
        /// IPv4/IPv6 string forms resolved from `blockedDomains` by the host app. Used by the network
        /// extension to match IP-only flows (Chrome IP-pinned TCP connections that omit SNI from the
        /// filter API) against the same blocklist. Optional for backwards compatibility with older
        /// payloads written by previous extension builds.
        var blockedIPLiterals: [String]? = nil
        /// When true, drop QUIC-shaped UDP/443 for any process while blocking (opt-in; see docs).
        var aggressiveUdp443DropWhileBlocking: Bool? = nil
        /// Host-written correlation ID for the current focus blocking window (optional for older JSON).
        var blockingEpoch: String? = nil
    }

    private static func fileURL() -> URL? {
        URL(fileURLWithPath: sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
    }

    private static func sharedStateFileExistsOnDisk() -> Bool {
        guard let url = fileURL() else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// True when `blocker-shared-state.v1.json` is present. Used to avoid treating a decode failure as “no IPs”.
    static func sharedJSONFileExists() -> Bool {
        sharedStateFileExistsOnDisk()
    }

    private static func readUnlocked() -> Payload? {
        guard let url = fileURL(), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            return nil
        }
    }

    static func read() -> Payload? {
        stateQueue.sync { readUnlocked() }
    }

    private static func writeUnlocked(_ payload: Payload) {
        guard let url = fileURL() else {
            return
        }
        var stamped = payload
        stamped.lastUpdatedAtReference = Date().timeIntervalSinceReferenceDate
        let directory = url.deletingLastPathComponent()
        let tmp = directory.appendingPathComponent("\(filename).tmp", isDirectory: false)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o777]
            )
            let data = try JSONEncoder().encode(stamped)
            try data.write(to: tmp, options: [.atomic])
            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
            } else {
                try FileManager.default.moveItem(at: tmp, to: url)
            }
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        } catch {
            try? FileManager.default.removeItem(at: tmp)
        }
    }

    /// Writes the full payload atomically (write + rename).
    static func write(_ payload: Payload) {
        stateQueue.sync {
            writeUnlocked(payload)
        }
    }

    /// Writes blocking + lease from **caller-supplied** values (do not re-read the lease key from
    /// `UserDefaults` immediately after `set` — it can still return a stale on-disk value; see runtime
    /// `PERSIST_WRITE` with an old `lease` and fresh `updatedAt`).
    static func persistSuiteBlockingFieldsToSharedFile(
        suiteDefaults: UserDefaults,
        blockingIsActive: Bool,
        leaseUntilReference: Double
    ) {
        let domains = suiteDefaults.stringArray(forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains) ?? []
        let bundles = suiteDefaults.stringArray(forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs) ?? []
        stateQueue.sync {
            // Merge with existing on-disk payload so frequent lease renewals do not wipe
            // `blockedIPLiterals` (Chrome IP-only / coalesced TCP paths depend on this set).
            var merged = readUnlocked() ?? Payload(
                blockingIsActive: false,
                blockingLeaseExpiresAtReference: 0,
                blockedDomains: [],
                blockedBundleIDs: []
            )
            merged.blockingIsActive = blockingIsActive
            merged.blockingLeaseExpiresAtReference = leaseUntilReference
            merged.blockedDomains = domains
            merged.blockedBundleIDs = bundles
            merged.aggressiveUdp443DropWhileBlocking = suiteDefaults.bool(
                forKey: BlockerAppGroup.UserDefaultsKey.aggressiveUdp443DropWhileBlocking
            )
            if blockingIsActive {
                merged.blockingEpoch = suiteDefaults.string(forKey: BlockerAppGroup.UserDefaultsKey.blockingEpoch)
            } else {
                merged.blockingEpoch = nil
            }
            writeUnlocked(merged)
        }
    }

    /// Updates only domain/bundle lists. **Does not** copy blocking/lease from the App Group suite — those
    /// keys are owned by `NetworkExtensionBridge`. `mirrorBlocklistIntoSuite` used to call a full-suite snapshot,
    /// re-read stale suite blocking fields and overwrote a fresh JSON lease (runtime: `leaseValid=0` while
    /// `blockingIsActive=true` in the file).
    ///
    /// **Critical:** Never substitute `Payload(blockingIsActive: false, lease: 0, …)` when `readUnlocked()` is nil
    /// but the JSON file still exists — that pattern wiped a valid focus lease while Chrome saw `payloadSource=file`
    /// with `leaseValid=false` (debug-5acc35: `H1_lease_early_allow` floods after pause/resume + settings mirror).
    static func mergeBlocklistsOnly(domains: [String], bundleIDs: [String]) {
        stateQueue.sync {
            if var merged = readUnlocked() {
                merged.blockedDomains = domains
                merged.blockedBundleIDs = bundleIDs
                writeUnlocked(merged)
                return
            }
            if sharedStateFileExistsOnDisk() {
                // File exists but couldn't be decoded. The atomic rename guarantees we see either
                // old or new — not partial. Skip rather than overwrite, preserving any active lease.
                os_log(
                    "mergeBlocklistsOnly SKIP decode_failed preserve_lease path=%{public}@",
                    log: sharedStateOSLog,
                    type: .error,
                    fileURL()?.path ?? "nil"
                )
                return
            }
            writeUnlocked(Payload(
                blockingIsActive: false,
                blockingLeaseExpiresAtReference: 0,
                blockedDomains: domains,
                blockedBundleIDs: bundleIDs
            ))
        }
    }

    /// Host App Group is authoritative for `blockingIsActive` + lease; IP merges only read/modify `blockedIPLiterals`
    /// but must not publish a stale instruction/lease from disk if the suite was updated earlier in the same
    /// resume tick (debug `H1_lease_early_allow` after pause/resume while a long DNS refresh was in flight).
    private static func reconcileBlockingInstructionFromHostSuiteIfAvailable(
        _ merged: inout Payload,
        hostBlockerSuite: UserDefaults?,
        preserveValidDiskLeaseWhenSuiteInactive: Bool
    ) {
        guard let suite = hostBlockerSuite ?? UserDefaults(suiteName: BlockerAppGroup.identifier) else {
            return
        }
        let suiteActive = suite.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        if suiteActive {
            merged.blockingIsActive = true
            merged.blockingLeaseExpiresAtReference = suite.double(
                forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference
            )
            return
        }
        // Suite inactive: only keep a valid on-disk lease when the caller is an in-flight focus IP refresh
        // (host suite still has blocking on). Stale refreshes after rest must not revive JSON blocking.
        if preserveValidDiskLeaseWhenSuiteInactive,
           merged.blockingIsActive,
           BlockerAppGroup.isBlockingLeaseValid(
               isActive: merged.blockingIsActive,
               leaseUntilReference: merged.blockingLeaseExpiresAtReference
           ) {
            return
        }
        merged.blockingIsActive = false
        merged.blockingLeaseExpiresAtReference = 0
    }

    /// Atomically replaces the resolved IP set without disturbing any other field.
    /// - Parameter hostBlockerSuite: Host App Group suite used to re-sync `blockingIsActive` + lease so a slow
    ///   DNS tick cannot republish a paused snapshot over a resumed lease. Pass `nil` in tests that use a custom suite.
    static func mergeBlockedIPLiteralsOnly(
        _ ipLiterals: [String],
        hostBlockerSuite: UserDefaults? = nil,
        preserveValidDiskLeaseWhenSuiteInactive: Bool = false
    ) {
        stateQueue.sync {
            if var merged = readUnlocked() {
                merged.blockedIPLiterals = ipLiterals
                reconcileBlockingInstructionFromHostSuiteIfAvailable(
                    &merged,
                    hostBlockerSuite: hostBlockerSuite,
                    preserveValidDiskLeaseWhenSuiteInactive: preserveValidDiskLeaseWhenSuiteInactive
                )
                writeUnlocked(merged)
                return
            }
            if sharedStateFileExistsOnDisk() {
                // File exists but couldn't be decoded — skip to preserve any active lease.
                os_log(
                    "mergeBlockedIPLiteralsOnly skip decode_failed path=%{public}@",
                    log: sharedStateOSLog,
                    type: .error,
                    fileURL()?.path ?? "nil"
                )
                return
            }
            writeUnlocked(Payload(
                blockingIsActive: false,
                blockingLeaseExpiresAtReference: 0,
                blockedDomains: [],
                blockedBundleIDs: [],
                blockedIPLiterals: ipLiterals
            ))
        }
    }

    static func mergeAggressiveUdp443DropFlagOnly(_ enabled: Bool) {
        stateQueue.sync {
            if var merged = readUnlocked() {
                merged.aggressiveUdp443DropWhileBlocking = enabled
                writeUnlocked(merged)
                return
            }
            guard !sharedStateFileExistsOnDisk() else {
                os_log(
                    "mergeAggressiveUdp443DropFlagOnly skip decode_failed path=%{public}@",
                    log: sharedStateOSLog,
                    type: .error,
                    fileURL()?.path ?? "nil"
                )
                return
            }
            let merged = Payload(
                blockingIsActive: false,
                blockingLeaseExpiresAtReference: 0,
                blockedDomains: [],
                blockedBundleIDs: [],
                aggressiveUdp443DropWhileBlocking: enabled
            )
            writeUnlocked(merged)
        }
    }

    /// Clears suite blocking flags and writes inactive + zero lease to the shared JSON synchronously.
    /// Call from `applicationWillTerminate` so the filter extension fail-opens immediately on normal quit
    /// (lease renewal cannot continue after the host exits).
    /// - Parameter suiteDefaults: Pass a test suite; default uses the real App Group.
    static func deactivateBlockingForHostQuit(suiteDefaults: UserDefaults? = nil) {
        guard let defaults = suiteDefaults ?? UserDefaults(suiteName: BlockerAppGroup.identifier) else {
            return
        }
        defaults.set(false, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        defaults.removeObject(forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)
        defaults.removeObject(forKey: BlockerAppGroup.UserDefaultsKey.blockingEpoch)
        defaults.synchronize()
        persistSuiteBlockingFieldsToSharedFile(
            suiteDefaults: defaults,
            blockingIsActive: false,
            leaseUntilReference: 0
        )
        #if DEBUG
        let filePayload = read()
        os_log(
            "AGENT_QUIT_POST proc=%{public}@ fileActive=%{public}d lease=%{public}f suiteActive=%{public}d",
            log: sharedStateOSLog,
            type: .default,
            ProcessInfo.processInfo.processName,
            filePayload?.blockingIsActive == true ? 1 : 0,
            filePayload?.blockingLeaseExpiresAtReference ?? 0,
            defaults.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive) ? 1 : 0
        )
        #endif
    }
}

/// Atomic sibling files in `sharedDirectoryPath` using the same tmp + `replaceItemAt` pattern as `writeUnlocked`
/// (some system-extension sandboxes reject plain `Data.write` to the final URL).
enum BlockerSharedSidecarAtomicWrite {
    private static let oslog = OSLog(subsystem: "com.focushacker.app.shared-state", category: "sidecar-atomic")

    static func replace(filename: String, contents: Data) {
        let directory = URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
        let url = directory.appendingPathComponent(filename, isDirectory: false)
        let tmp = directory.appendingPathComponent("\(filename).tmp", isDirectory: false)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o777]
            )
            try contents.write(to: tmp, options: [.atomic])
            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
            } else {
                try FileManager.default.moveItem(at: tmp, to: url)
            }
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        } catch {
            os_log(
                "SIDECAR_REPLACE_FAILED file=%{public}@ err=%{public}@ proc=%{public}@",
                log: oslog,
                type: .error,
                filename,
                String(describing: error),
                ProcessInfo.processInfo.processName
            )
            try? FileManager.default.removeItem(at: tmp)
        }
    }
}
