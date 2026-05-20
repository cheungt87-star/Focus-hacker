import Foundation
#if canImport(NetworkExtension)
import NetworkExtension
#endif

/// In-memory snapshot of host-pushed probe control rules (extension applies via `applySettings`).
enum ChromeProbeControlRuleState {
    private static let lock = NSLock()
    private static var blockingEpoch: String?
    private static var probeIPSet = Set<String>()
    private static var rulesGeneration: UInt64 = 0

    static var generation: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return rulesGeneration
    }

    static func reloadFromDisk() {
        guard let payload = ChromeProbeControlRulesFile.read() else {
            lock.lock()
            blockingEpoch = nil
            probeIPSet = []
            rulesGeneration = 0
            lock.unlock()
            return
        }
        adoptPayload(payload)
    }

    /// Sync in-memory probe rules without writing disk (host may have just pushed a newer epoch).
    static func adoptPayload(_ payload: ChromeProbeControlRulesFile.Payload) {
        lock.lock()
        blockingEpoch = payload.blockingEpoch
        probeIPSet = Set(payload.probeIPs)
        rulesGeneration = payload.rulesGeneration
        lock.unlock()
    }

    static func matchesCurrentEpoch(_ diskEpoch: String?) -> Bool {
        guard let diskEpoch, !diskEpoch.isEmpty else {
            return false
        }
        lock.lock()
        defer { lock.unlock() }
        return blockingEpoch == diskEpoch
    }

    static func containsProbeIP(_ remoteIP: String?) -> Bool {
        guard let canonical = remoteIP.flatMap({ BlockerIPLiteralCanonical.canonical($0) }) else {
            return false
        }
        lock.lock()
        defer { lock.unlock() }
        return probeIPSet.contains(canonical)
    }

    static var probeIPCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return probeIPSet.count
    }

    static var probeIPLiterals: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(probeIPSet)
    }

    #if canImport(NetworkExtension)
    /// Kernel-level drop rules for probe IPs; default action keeps other traffic on the data provider.
    static func buildFilterSettings() -> NEFilterSettings? {
        let ips = probeIPLiterals
        guard !ips.isEmpty else {
            return nil
        }
        var rules: [NEFilterRule] = []
        for ip in ips {
            rules.append(contentsOf: makeDropRules(for: ip))
        }
        guard !rules.isEmpty else {
            return nil
        }
        return NEFilterSettings(rules: rules, defaultAction: .filterData)
    }

    /// Removes kernel-level probe drop rules so rest/break traffic is not blocked (b68).
    static func buildClearFilterSettings() -> NEFilterSettings {
        NEFilterSettings(rules: [], defaultAction: .filterData)
    }

    /// fe1347 b66: TCP + UDP so QUIC/HTTP3 stale sockets cannot bypass kernel drop rules.
    private static func makeDropRules(for ip: String) -> [NEFilterRule] {
        let endpoint = NWHostEndpoint(hostname: ip, port: "")
        let prefix: Int = ip.contains(":") ? 128 : 32
        let tcpRule = NENetworkRule(
            destinationNetwork: endpoint,
            prefix: prefix,
            protocol: .TCP
        )
        let udpRule = NENetworkRule(
            destinationNetwork: endpoint,
            prefix: prefix,
            protocol: .UDP
        )
        return [
            NEFilterRule(networkRule: tcpRule, action: .drop),
            NEFilterRule(networkRule: udpRule, action: .drop),
        ]
    }
    #endif
}
