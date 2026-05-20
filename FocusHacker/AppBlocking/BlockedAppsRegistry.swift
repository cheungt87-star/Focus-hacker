import Foundation

/// Reads blocked bundle IDs from shared state and applies a system-app denylist.
enum BlockedAppsRegistry {
    /// Bundle IDs that must never be terminated, even if present in the user blocklist.
    static let protectedSystemBundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "com.apple.systempreferences",
        "com.apple.systempreferences.GeneralSettings",
        "com.apple.loginwindow",
        "com.apple.WindowManager",
        "com.apple.dock",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.Spotlight",
        "com.apple.PowerChime",
        "com.apple.securityagent",
        "com.apple.coreservices.uiagent",
    ]

    static func currentBlockedBundleIDs() -> [String] {
        BlockerSharedStateFile.read()?.blockedBundleIDs ?? []
    }

    static func isProtectedSystemApp(bundleIdentifier: String) -> Bool {
        protectedSystemBundleIdentifiers.contains(bundleIdentifier)
    }

    static func isBlocked(bundleIdentifier: String) -> Bool {
        guard !bundleIdentifier.isEmpty else {
            return false
        }
        if isProtectedSystemApp(bundleIdentifier: bundleIdentifier) {
            return false
        }
        return BlocklistEvaluation.shouldBlockApp(
            bundleIdentifier: bundleIdentifier,
            blockedBundleIdentifiers: currentBlockedBundleIDs()
        )
    }
}
