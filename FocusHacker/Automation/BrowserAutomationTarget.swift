import AppKit
import Foundation

/// Maps AppleScript application names to bundle IDs and running-state checks.
enum BrowserAutomationTarget {
    static let safariApplicationName = "Safari"
    static let chromeApplicationName = "Google Chrome"

    static let supportedApplicationNames = [safariApplicationName, chromeApplicationName]

    private static let bundleIdentifierByApplicationName: [String: String] = [
        safariApplicationName: "com.apple.Safari",
        chromeApplicationName: "com.google.Chrome",
    ]

    /// Test seam — when set, overrides `NSWorkspace` running checks.
    static var isRunningOverride: ((String) -> Bool)?

    static func bundleIdentifier(forApplicationName applicationName: String) -> String? {
        bundleIdentifierByApplicationName[applicationName]
    }

    static func applicationName(forBundleIdentifier bundleIdentifier: String) -> String? {
        bundleIdentifierByApplicationName.first(where: { $0.value == bundleIdentifier })?.key
    }

    static func isSupportedBundleIdentifier(_ bundleIdentifier: String) -> Bool {
        applicationName(forBundleIdentifier: bundleIdentifier) != nil
    }

    static func isRunning(applicationName: String) -> Bool {
        if let isRunningOverride {
            return isRunningOverride(applicationName)
        }
        guard let bundleIdentifier = bundleIdentifier(forApplicationName: applicationName) else {
            return false
        }
        return NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == bundleIdentifier
                && app.activationPolicy != .prohibited
        }
    }
}
