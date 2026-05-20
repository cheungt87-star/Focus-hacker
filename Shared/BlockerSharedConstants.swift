import Foundation

/// App group container shared by the host app and `NetworkFilterExtension`.
enum BlockerAppGroup {
    static let identifier = "group.com.focushacker.blocker"

    enum UserDefaultsKey {
        static let blockedDomains = "blocker.shared.domains"
        static let blockedBundleIDs = "blocker.shared.bundleIDs"
        /// Mirror of `Payload.blockedIPLiterals` in the host App Group suite (DNS refresh / host-only); the filter reads **only** `/Users/Shared` JSON.
        static let blockedIPLiterals = "blocker.shared.blockedIPLiterals"
        /// When true, filter should enforce blocklists if the lease is still valid (focus interval).
        static let blockingIsActive = "blocker.shared.blockingActive"
        /// Time interval since reference date (`Date.timeIntervalSinceReferenceDate`). Fail-open after expiry.
        static let blockingLeaseExpiresAtReference = "blocker.shared.leaseExpiresReference"
        /// When true, drop all QUIC-shaped UDP/443 flows while a domain blocklist is active (not only Chromium-attributed). May affect other apps using HTTP/3 on 443.
        static let aggressiveUdp443DropWhileBlocking = "blocker.shared.aggressiveUdp443DropWhileBlocking"
        /// Opaque ID for the current focus blocking activation (mirrored into `/Users/Shared` JSON for log correlation).
        static let blockingEpoch = "blocker.shared.blockingEpoch"
    }

    enum StandardUserDefaultsKey {
        static let blockedDomains = "settings.blocklist.domains"
        static let blockedBundleIdentifiers = "settings.blocklist.bundleIDs"
    }

    /// Filter extension bundle identifier (must match Xcode target).
    static let filterDataProviderBundleIdentifier = "com.focushacker.app.network-extension"

    /// App must renew the lease more often than this interval or the extension treats blocking as inactive.
    /// Kept comfortably above renewal jitter + short App Nap so `/Users/Shared` JSON does not read as expired
    /// while focus is still running (the filter extension does not share the host's App Group UserDefaults).
    static let blockingLeaseTTLSeconds: TimeInterval = 120
    static let blockingLeaseRenewalIntervalNanoseconds: UInt64 = 4_000_000_000
    /// Steady-state DNS refresh for `blockedIPLiterals` while focus is active.
    static let blockedIPRefreshIntervalNanoseconds: UInt64 = 30 * 1_000_000_000
    /// Faster refresh for the first two minutes after activate/resume (CDN rotation / Chrome IP pinning).
    static let blockedIPRefreshBurstIntervalNanoseconds: UInt64 = 12 * 1_000_000_000
    static let blockedIPRefreshBurstDurationSeconds: TimeInterval = 120
    /// Upper bound for `NEFilterManager` disable/re-enable during rest→focus or deactivate.
    static let filterBounceTimeoutNanoseconds: UInt64 = 12_000_000_000

    static func isBlockingLeaseValid(isActive: Bool, leaseUntilReference: Double, now: Date = .init()) -> Bool {
        guard isActive, leaseUntilReference > 0 else {
            return false
        }
        return now.timeIntervalSinceReferenceDate <= leaseUntilReference
    }
}

/// Host app install path checks (system extension activation requires `/Applications` on macOS).
enum BlockerHostEnvironment {
    static var isRunningFromApplicationsFolder: Bool {
        Bundle.main.bundlePath.hasPrefix("/Applications/")
    }

    /// Shown in Settings when the app is not under `/Applications` (e.g. Xcode DerivedData run).
    static var systemExtensionLocationHint: String? {
        guard !isRunningFromApplicationsFolder else {
            return nil
        }
        return "For the network filter: copy FocusHacker.app to the Applications folder and launch it from there. "
            + "macOS will not activate the system extension from Xcode’s build folder."
    }

    /// `CFBundleVersion` from the embedded `.systemextension` inside the host app bundle.
    static func embeddedNetworkExtensionBuildVersion() -> String? {
        let url = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/SystemExtensions", isDirectory: true)
            .appendingPathComponent(
                "\(BlockerAppGroup.filterDataProviderBundleIdentifier).systemextension",
                isDirectory: true
            )
        guard let bundle = Bundle(url: url) else {
            return nil
        }
        return bundle.infoDictionary?["CFBundleVersion"] as? String
    }

    /// Parses extension build from liveness sidecar: `build=NN`, `legacy` (ping without build), or `none` (no ping).
    static func parseExtensionBuildVersion(fromLivenessPingContents contents: String) -> String {
        let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "none"
        }
        guard let range = trimmed.range(of: "build=") else {
            return "legacy"
        }
        let tail = trimmed[range.upperBound...]
        let token = tail.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).first
        return token.map(String.init) ?? "legacy"
    }

    /// Parses `plane=v16-data-plane` from extension liveness ping; `legacy` when absent.
    static func parseExtensionFilterPlaneRevision(fromLivenessPingContents contents: String) -> String {
        let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "none"
        }
        guard let range = trimmed.range(of: "plane=") else {
            return "legacy"
        }
        let tail = trimmed[range.upperBound...]
        let token = tail.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).first
        return token.map(String.init) ?? "legacy"
    }
}

/// Bump when filter extension behavior changes materially (independent of `CFBundleVersion`).
enum BlockerExtensionFilterPlaneRevision {
    static let current = "v16m-post-bounce-rules-apply"
}

// MARK: - Extension → shared ping (proves `/Users/Shared` write from system extension)

/// Atomic file so Gather can tell whether the filter extension ran (`startFilter` and/or first `handleNewFlow`).
enum BlockerExtensionSharedPing {
    static let filename = "extension-liveness-ping.txt"
    static var fileURL: URL {
        URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
    }

    /// Overwrites with latest liveness line (source distinguishes `startFilter` vs first flow).
    static func writeLivenessPing(source: String) {
        let bid = Bundle.main.bundleIdentifier ?? "nil"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let plane = BlockerExtensionFilterPlaneRevision.current
        let line =
            "\(source) ts=\(Date().timeIntervalSince1970) pid=\(ProcessInfo.processInfo.processIdentifier) proc=\(ProcessInfo.processInfo.processName) bundle=\(bid) build=\(build) plane=\(plane)\n"
        guard let data = line.data(using: .utf8) else {
            return
        }
        BlockerSharedSidecarAtomicWrite.replace(filename: filename, contents: data)
    }
}

/// Monotonic counter incremented on every `handleNewFlow` (fe1347: proves extension receives Chrome traffic).
enum BlockerExtensionFlowCounter {
    static let filename = "extension-flow-counter.txt"
    static var fileURL: URL {
        URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
    }

    static func increment() {
        let current = (try? String(contentsOf: fileURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
        let next = (Int(current) ?? 0) + 1
        guard let data = "\(next)\n".data(using: .utf8) else { return }
        BlockerSharedSidecarAtomicWrite.replace(filename: filename, contents: data)
    }

    static func readValue() -> Int {
        let text = (try? String(contentsOf: fileURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
        return Int(text) ?? 0
    }
}

// MARK: - Diagnostics file paths (Gather UI reads legacy NDJSON sidecars if present)

/// Paths for optional debug NDJSON sidecars written during development. No runtime logging in production builds.
enum BlockerDiagnosticsPaths {
    static let appGroupMirrorFilename = "chrome-blocking-debug-7a1df6.log"
    static let extensionOnlySharedMirrorFilename = "chrome-blocking-debug-7a1df6-extension.log"

    static var usersSharedMirrorURL: URL {
        URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(appGroupMirrorFilename, isDirectory: false)
    }

    static var usersSharedExtensionMirrorURL: URL {
        URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(extensionOnlySharedMirrorFilename, isDirectory: false)
    }
}
