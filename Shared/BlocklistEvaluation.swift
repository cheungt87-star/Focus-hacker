import Foundation

enum BlocklistEvaluation {
    /// Hostname extracted from URLs or sockets: lowercased, no port, Punycode as provided by OS.
    static func canonicalHost(from url: URL?) -> String? {
        guard let host = url?.host?.lowercased(), !host.isEmpty else {
            return nil
        }
        return host
    }

    static func canonicalHost(hostname: String?) -> String? {
        guard let trimmed = hostname?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    /// Normalizes common user-entered prefixes into a canonical host suffix for matching (`twitter.com`).
    static func parseDomainEntry(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        text = text.lowercased()
        if text.hasPrefix("http://") {
            text.removeFirst("http://".count)
        } else if text.hasPrefix("https://") {
            text.removeFirst("https://".count)
        }

        let pathSplit = text.split(whereSeparator: { $0 == "/" || $0 == "?" })
        guard let hostPart = pathSplit.first else { return nil }
        var hostPartString = String(hostPart)
        // Common typo: `https://www/linkedin.com` — treat as `www.linkedin.com` for matching and DNS refresh.
        if pathSplit.count >= 2, !hostPartString.contains("."), hostPartString == "www" {
            let secondRaw = String(pathSplit[1])
            let secondHost = secondRaw.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init) ?? secondRaw
            if secondHost.contains(".") {
                hostPartString = "www.\(secondHost)"
            }
        }
        let withoutPort = hostPartString.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? hostPartString
        return canonicalHost(hostname: withoutPort)
    }

    static func shouldBlockHost(_ host: String, blockedEntries: [String]) -> Bool {
        for entry in blockedEntries {
            let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let lower = trimmed.lowercased()
            if lower.hasPrefix("*.") {
                let suffix = String(lower.dropFirst(2))
                guard let normalizedSuffix = parseDomainEntry(suffix) ?? canonicalHost(hostname: suffix) else {
                    continue
                }
                if host == normalizedSuffix || host.hasSuffix("." + normalizedSuffix) {
                    return true
                }
            } else if let pattern = parseDomainEntry(lower) ?? canonicalHost(hostname: lower) {
                if host == pattern || host.hasSuffix("." + pattern) {
                    return true
                }
            }
        }
        return false
    }

    /// Rejects domain-list entries that are clearly macOS bundle IDs (e.g. `com.google.Chrome`).
    static func looksLikeBundleIdentifier(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.hasPrefix("com.") || trimmed.hasPrefix("org.") || trimmed.hasPrefix("net.") else {
            return false
        }
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3 else { return false }
        let commonTLDs: Set<String> = [
            "com", "org", "net", "edu", "gov", "io", "co", "uk", "de", "fr", "app", "dev", "ai",
        ]
        if let last = parts.last, commonTLDs.contains(last) {
            return false
        }
        return true
    }

    static func shouldBlockApp(bundleIdentifier: String?, blockedBundleIdentifiers: [String]) -> Bool {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return false
        }
        return shouldBlockSigningIdentifier(bundleIdentifier, blockedBundleIdentifiers: blockedBundleIdentifiers)
    }

    /// Matches a code signing identifier against user-entered bundle IDs, including `TeamID.bundle.id` style signing IDs.
    /// Returns whether the trimmed entry parses as `host`, `scheme://host/path`, `*.suffix`, or wildcard hostname entry.
    static func isValidUserDomainPatternEntry(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        if trimmed.unicodeScalars.contains(where: CharacterSet.whitespacesAndNewlines.contains) {
            return false
        }
        let lower = trimmed.lowercased()
        if lower.hasPrefix("*.") {
            let suffix = String(lower.dropFirst(2))
            guard !suffix.isEmpty else {
                return false
            }
            return parseDomainEntry(suffix) != nil
        }
        return parseDomainEntry(trimmed) != nil
    }

    static func shouldBlockSigningIdentifier(_ signingIdentifier: String, blockedBundleIdentifiers: [String]) -> Bool {
        let id = signingIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            return false
        }
        let idKey = normalizedSigningIdentifierForBundleMatch(id).lowercased()
        for raw in blockedBundleIdentifiers {
            let blocked = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !blocked.isEmpty else { continue }
            let blockedKey = normalizedSigningIdentifierForBundleMatch(blocked).lowercased()
            if idKey == blockedKey {
                return true
            }
            // `TEAMID.bundle.id` style signing IDs vs user-entered `bundle.id`
            if idKey.hasSuffix("." + blockedKey) {
                return true
            }
            // Network flows often attribute to nested helpers (e.g. `com.google.Chrome.helper`) while the user
            // picks the main app bundle (`com.google.Chrome`) in Settings.
            if idKey.hasPrefix(blockedKey + ".") {
                return true
            }
        }
        return false
    }

    /// Strips a leading Apple Developer **team ID** segment when present (`TEAMID.bundle.id` → `bundle.id`).
    /// Matches `NetworkFilterDataProvider.normalizedCodeSigningIdentifierForBrowserMatch` semantics for bundle rules.
    private static func normalizedSigningIdentifierForBundleMatch(_ signingIdentifier: String) -> String {
        let trimmed = signingIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard let first = parts.first,
              first.count == 10,
              first.allSatisfy({ $0.isLetter || $0.isNumber }),
              parts.count >= 3 else {
            return trimmed
        }
        return parts.dropFirst().joined(separator: ".")
    }

    /// Chromium network stacks (Chrome, Edge, Brave helpers, etc.) for filter attribution.
    static func isChromiumSigningIdentifier(_ signingIdentifier: String?) -> Bool {
        guard let id = signingIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !id.isEmpty else {
            return false
        }
        return id.contains("chrome") || id.contains("chromium")
    }

    /// LAN/link-local/reserved hosts that must not be dropped by Chromium IP-pin rules.
    static func isPrivateOrLocalHost(_ host: String) -> Bool {
        let h = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if h.isEmpty || h == "localhost" || h.hasSuffix(".local") {
            return true
        }
        if h.hasPrefix("127.") || h == "::1" || h.hasPrefix("fe80:") || h.hasPrefix("fc") || h.hasPrefix("fd") {
            return true
        }
        if h.hasPrefix("192.168.") || h.hasPrefix("10.") || h.hasPrefix("169.254.") {
            return true
        }
        if h.hasPrefix("172.") {
            let parts = h.split(separator: ".", omittingEmptySubsequences: true)
            if parts.count >= 2, let second = Int(parts[1]), (16 ... 31).contains(second) {
                return true
            }
        }
        return false
    }
}
