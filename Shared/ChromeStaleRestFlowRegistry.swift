import Foundation
#if canImport(Network)
import Network
#endif
#if canImport(NetworkExtension)
import NetworkExtension
#endif

/// Tracks Chrome socket remote IPs that received `filterDataVerdict` during rest or while focus-active
/// (fe1347: survives extension restart via `/Users/Shared` sidecar).
enum ChromeStaleRestFlowRegistry {
    static let filename = "chrome-stale-rest-ips.v1.txt"

    private static let lock = NSLock()
    private static var restPeriodIPs = Set<String>()

    private static var fileURL: URL {
        URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
    }

    /// Reload persisted IPs (extension `startFilter` and after sysext replace).
    static func reloadFromDisk() {
        lock.lock()
        defer { lock.unlock() }
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return
        }
        for line in contents.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            if let canonical = BlockerIPLiteralCanonical.canonical(trimmed) {
                restPeriodIPs.insert(canonical)
            }
        }
    }

    /// Host rest→focus path: discard in-process cache and mirror extension-written disk file before seeding.
    static func replaceFromDisk() {
        lock.lock()
        restPeriodIPs.removeAll()
        lock.unlock()
        reloadFromDisk()
    }

    /// Seeds known example.com CDN literals when example.com is blocked (fe1347 build 54:
    /// silent pre-rest Chrome TCP never hits `handleNewFlow` during rest).
    @discardableResult
    static func seedBlockedProbeLiterals(fromBlockedDomains domains: [String]) -> Int {
        seedLiterals(BlockedDomainIPProbes.supplementalLiterals(forBlockedDomains: domains))
    }

    @discardableResult
    static func seedLiterals(_ literals: [String]) -> Int {
        var insertedCount = 0
        for literal in literals {
            guard let canonical = BlockerIPLiteralCanonical.canonical(literal) else {
                continue
            }
            lock.lock()
            let inserted = restPeriodIPs.insert(canonical).inserted
            lock.unlock()
            if inserted {
                insertedCount += 1
            }
        }
        guard insertedCount > 0 else {
            return 0
        }
        persistToDisk()
        return insertedCount
    }

    static func registerRestChromeFlow(remoteIP: String?) {
        guard let canonical = remoteIP.flatMap({ BlockerIPLiteralCanonical.canonical($0) }) else {
            return
        }
        lock.lock()
        let inserted = restPeriodIPs.insert(canonical).inserted
        lock.unlock()
        guard inserted else { return }
        persistToDisk()
    }

    static var registeredCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return restPeriodIPs.count
    }

    static func containsStaleRestIP(_ remoteIP: String?) -> Bool {
        guard let canonical = remoteIP.flatMap({ BlockerIPLiteralCanonical.canonical($0) }) else {
            return false
        }
        lock.lock()
        defer { lock.unlock() }
        return restPeriodIPs.contains(canonical)
    }

    static func removeAfterDrop(remoteIP: String?) {
        guard let canonical = remoteIP.flatMap({ BlockerIPLiteralCanonical.canonical($0) }) else {
            return
        }
        lock.lock()
        let removed = restPeriodIPs.remove(canonical) != nil
        lock.unlock()
        guard removed else { return }
        persistToDisk()
    }

    /// After rest→focus filter bounce — stale sockets should be gone.
    static func clearAll() {
        lock.lock()
        restPeriodIPs.removeAll()
        lock.unlock()
        persistToDisk()
        clearFlowHandles()
    }

    /// Test-only reset.
    static func resetForTests() {
        clearAll()
    }

#if canImport(NetworkExtension)
    private struct StaleFlowEntry {
        weak var flow: NEFilterSocketFlow?
        let remoteIP: String
        let remotePort: Int?
    }

    private static let flowLock = NSLock()
    private static var staleFlowEntries: [StaleFlowEntry] = []

    /// Retains a weak handle to a Chrome socket flow opened during rest (extension-only; not persisted).
    static func registerFlow(_ flow: NEFilterSocketFlow, remoteIP: String?) {
        guard let canonical = remoteIP.flatMap({ BlockerIPLiteralCanonical.canonical($0) }) else {
            return
        }
        let port = remotePort(from: flow)
        flowLock.lock()
        compactStaleFlowEntriesUnlocked()
        staleFlowEntries.append(StaleFlowEntry(flow: flow, remoteIP: canonical, remotePort: port))
        flowLock.unlock()
    }

    /// Live socket flows whose remote IP is in the stale-rest registry (for active teardown on focus).
    static func flowsEligibleForDrop() -> [NEFilterSocketFlow] {
        lock.lock()
        let ips = restPeriodIPs
        lock.unlock()

        flowLock.lock()
        compactStaleFlowEntriesUnlocked()
        let flows = staleFlowEntries.compactMap { entry -> NEFilterSocketFlow? in
            guard ips.contains(entry.remoteIP), let flow = entry.flow else {
                return nil
            }
            return flow
        }
        flowLock.unlock()
        return flows
    }

    /// Flows eligible for drop with endpoint metadata for logging.
    static func staleFlowDropTargets() -> [(flow: NEFilterSocketFlow, remoteIP: String, remotePort: Int?)] {
        lock.lock()
        let ips = restPeriodIPs
        lock.unlock()

        flowLock.lock()
        compactStaleFlowEntriesUnlocked()
        let targets = staleFlowEntries.compactMap { entry -> (NEFilterSocketFlow, String, Int?)? in
            guard ips.contains(entry.remoteIP), let flow = entry.flow else {
                return nil
            }
            return (flow, entry.remoteIP, entry.remotePort)
        }
        flowLock.unlock()
        return targets
    }

    /// In-memory flow handles only; disk IP registry is unchanged.
    static func clearFlowHandles() {
        flowLock.lock()
        staleFlowEntries.removeAll()
        flowLock.unlock()
    }

    /// Test-only count of in-memory flow handle entries (including deallocated weak refs until compacted).
    static var flowHandleEntryCountForTests: Int {
        flowLock.lock()
        defer { flowLock.unlock() }
        return staleFlowEntries.count
    }

    private static func compactStaleFlowEntriesUnlocked() {
        staleFlowEntries.removeAll { $0.flow == nil }
    }

    private static func remotePort(from flow: NEFilterSocketFlow) -> Int? {
        guard let ep = flow.remoteEndpoint as? NWHostEndpoint else {
            return nil
        }
        let trimmed = ep.port.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let port = Int(trimmed) else {
            return nil
        }
        return port
    }
#endif

    private static func persistToDisk() {
        lock.lock()
        let body = restPeriodIPs.sorted().joined(separator: "\n")
        lock.unlock()
        let text = body.isEmpty ? "" : body + "\n"
        guard let data = text.data(using: .utf8) else { return }
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// Drop decision for Chrome bidirectional data-plane callbacks (unit-testable).
enum ChromeDataPlaneDropDecision {
    struct Inputs {
        let diskLeaseValid: Bool
        let shouldDrop: Bool
        let hostBlocked: Bool
        let sniBlocked: Bool
        let staleRestIP: Bool
    }

    enum Reason: String, Equatable {
        case sni
        case host
        case ip
        case staleRest = "stale_rest"
    }

    static func shouldDrop(_ inputs: Inputs) -> (drop: Bool, reason: Reason?) {
        guard inputs.diskLeaseValid else {
            return (false, nil)
        }
        if inputs.sniBlocked {
            return (true, .sni)
        }
        if inputs.shouldDrop {
            return (true, inputs.hostBlocked ? .host : .ip)
        }
        if inputs.staleRestIP {
            return (true, .staleRest)
        }
        return (false, nil)
    }
}
