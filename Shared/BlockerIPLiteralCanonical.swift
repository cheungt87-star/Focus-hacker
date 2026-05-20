import Darwin
import Foundation

/// Canonical IPv4/IPv6 text for stable `blockedIPLiterals` set operations (host refresh + filter matching).
enum BlockerIPLiteralCanonical {
    /// Max distinct IPs stored when unioning across DNS refresh ticks (Chrome IP-only / coalesced TCP paths).
    static let blockedIPLiteralsUnionCap = 768

    static func canonical(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("["), text.hasSuffix("]"), text.count >= 4 {
            text = String(text.dropFirst().dropLast())
        }
        let base = text.split(separator: "%", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? text
        var v4 = in_addr()
        if base.withCString({ inet_pton(AF_INET, $0, &v4) == 1 }) {
            var v4mut = v4
            var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &v4mut, &buf, socklen_t(buf.count))
            return String(cString: buf)
        }
        var v6 = in6_addr()
        if base.withCString({ inet_pton(AF_INET6, $0, &v6) == 1 }) {
            var v6mut = v6
            var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &v6mut, &buf, socklen_t(buf.count))
            return String(cString: buf)
        }
        return nil
    }

    /// Merges prior IPs with this tick’s DNS results. **Tick literals first** so fresh answers survive cap trimming.
    static func cappedUnion(previous: [String], tickLiterals: [String], cap: Int) -> (merged: [String], truncated: Bool) {
        guard cap > 0 else { return ([], false) }
        var seen = Set<String>()
        var out: [String] = []
        for raw in tickLiterals {
            guard let c = canonical(raw), seen.insert(c).inserted else { continue }
            out.append(c)
            if out.count >= cap {
                return (out.sorted(), true)
            }
        }
        for raw in previous {
            guard let c = canonical(raw), seen.insert(c).inserted else { continue }
            out.append(c)
            if out.count >= cap {
                return (out.sorted(), true)
            }
        }
        return (out.sorted(), false)
    }
}
