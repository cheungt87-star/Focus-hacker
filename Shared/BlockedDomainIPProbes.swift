import Foundation

/// Known CDN literals for blocked domains when DNS/union-cap drops AAAA answers (fe1347: Chrome IPv6 example.com).
enum BlockedDomainIPProbes {
    static let exampleComIPv4: [String] = ["104.20.23.154", "172.66.147.243"]
    static let exampleComIPv6: [String] = [
        "2a06:98c1:3105::6812:21ce",
        "2a06:98c1:3102::6812:2929",
        "2a06:98c1:3106::ac40:9bb3",
    ]

    static var exampleComLiterals: [String] {
        exampleComIPv4 + exampleComIPv6
    }

    static func supplementalLiterals(forBlockedDomains domains: [String]) -> [String] {
        let hosts = Set(domains.compactMap { BlocklistEvaluation.parseDomainEntry($0) })
        guard hosts.contains("example.com") || hosts.contains(where: { $0.hasSuffix(".example.com") }) else {
            return []
        }
        return exampleComLiterals.compactMap { BlockerIPLiteralCanonical.canonical($0) }
    }
}
