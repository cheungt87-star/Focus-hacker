import AppKit
import Foundation

/// Refreshes cached browser Automation state when the user launches Safari or Chrome.
@MainActor
final class BrowserAutomationLaunchObserver {
    static let shared = BrowserAutomationLaunchObserver()

    private var launchObserver: NSObjectProtocol?

    private init() {}

    func start() {
        guard launchObserver == nil else {
            return
        }
        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication,
                let bundleIdentifier = application.bundleIdentifier,
                let applicationName = BrowserAutomationTarget.applicationName(
                    forBundleIdentifier: bundleIdentifier
                )
            else {
                return
            }
            _ = AutomationPermissionPrimer.refreshPermissionState(
                applicationName: applicationName,
                context: "browser_launched",
                policy: .passive
            )
        }
    }

    func stop() {
        if let launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(launchObserver)
            self.launchObserver = nil
        }
    }
}
