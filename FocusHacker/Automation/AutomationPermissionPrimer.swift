import AppKit
import Foundation

/// Sends tab-access Apple Events so macOS registers FocusHacker under Automation and shows permission dialogs.
enum AutomationPermissionPrimer {
    private static let browserTargets = ["Safari", "Google Chrome"]
    private static var didShowDeniedAlertThisSession = false

    private static func primedKey(for applicationName: String) -> String {
        "blocker.automation.primed.\(applicationName)"
    }

    private static func grantedKey(for applicationName: String) -> String {
        "blocker.automation.granted.\(applicationName)"
    }

    static func isSafariAutomationGranted() -> Bool {
        UserDefaults.standard.bool(forKey: grantedKey(for: "Safari"))
    }

    static func isChromeAutomationGranted() -> Bool {
        UserDefaults.standard.bool(forKey: grantedKey(for: "Google Chrome"))
    }

    static var isBrowserBlockingReady: Bool {
        isSafariAutomationGranted() && isChromeAutomationGranted()
    }

    static func permissionStatusLabel(for state: AutomationPermissionState) -> String {
        switch state {
        case .granted:
            return "Allowed"
        case .denied:
            return "Not allowed"
        case .unknown:
            return "Unknown"
        }
    }

    /// Returning users: verify + prompt on launch after onboarding is complete.
    static func primeOnLaunchIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "onboarding.didCompleteGuidedFlow") else {
            return
        }
        requestAutomationPermissionsOnStartup(context: "launch")
    }

    /// First launch: verify + prompt during onboarding blocker step (before focus session).
    static func primeForOnboardingIfNeeded() {
        requestAutomationPermissionsOnStartup(context: "onboarding")
    }

    static func forceProbeNow() {
        primeAllBrowsers(context: "force", force: true)
    }

    /// Live tab-list probe (same privilege as blocking). Updates grant cache and prompts if needed.
    static func requestAutomationPermissionsOnStartup(context: String) {
        let safariGranted = refreshLiveGrantState(applicationName: "Safari", context: context)
        let chromeGranted = refreshLiveGrantState(applicationName: "Google Chrome", context: context)
        if !safariGranted {
            primeTarget("Safari", context: "\(context)_register", force: true)
        }
        if !chromeGranted {
            primeTarget("Google Chrome", context: "\(context)_register", force: true)
        }
        if !safariGranted || !chromeGranted {
            presentAutomationRequiredAlertOnLaunch(
                safariGranted: refreshLiveGrantState(applicationName: "Safari", context: "\(context)_recheck"),
                chromeGranted: refreshLiveGrantState(applicationName: "Google Chrome", context: "\(context)_recheck")
            )
        }
    }

    /// Re-probe before monitoring when Automation toggles are off (-1743 during focus).
    static func ensurePermissionsBeforeMonitoring() {
        let safariGranted = refreshLiveGrantState(applicationName: "Safari", context: "pre_monitor")
        let chromeGranted = refreshLiveGrantState(applicationName: "Google Chrome", context: "pre_monitor")
        if !safariGranted {
            primeTarget("Safari", context: "pre_monitor_register", force: true)
        }
        if !chromeGranted {
            primeTarget("Google Chrome", context: "pre_monitor_register", force: true)
        }
        if !safariGranted || !chromeGranted {
            presentAutomationRequiredAlertOnLaunch(safariGranted: safariGranted, chromeGranted: chromeGranted)
        }
    }

    /// After returning from System Settings, refresh grant cache without prompting.
    static func refreshGrantStateQuietly() {
        let safari = refreshLiveGrantState(applicationName: "Safari", context: "become_active")
        let chrome = refreshLiveGrantState(applicationName: "Google Chrome", context: "become_active")
        if safari && chrome {
            didShowDeniedAlertThisSession = false
        }
    }

    /// Uses the same AppleScript as blocking so grant cache cannot disagree with runtime (-1743).
    @discardableResult
    private static func refreshLiveGrantState(applicationName: String, context: String) -> Bool {
        _ = BrowserAppleScriptRunner.runAutomationRegistrationProbe(applicationName: applicationName)
        let granted: Bool
        switch BrowserAppleScriptRunner.runListTabs(applicationName: applicationName) {
        case .success:
            granted = true
        case .failure(let error):
            granted = (error as NSError).code != BrowserAppleScriptRunner.appleEventNotPermittedCode
        }
        UserDefaults.standard.set(granted, forKey: grantedKey(for: applicationName))
        return granted
    }

    private static func presentAutomationRequiredAlertOnLaunch(safariGranted: Bool, chromeGranted: Bool) {
        guard !safariGranted || !chromeGranted else {
            return
        }
        guard !didShowDeniedAlertThisSession else {
            return
        }
        didShowDeniedAlertThisSession = true
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let missing = [
                safariGranted ? nil : "Safari",
                chromeGranted ? nil : "Google Chrome",
            ].compactMap { $0 }
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Allow FocusHacker to control your browsers"
            alert.informativeText =
                "Website blocking during focus needs Automation access for "
                + missing.joined(separator: " and ")
                + ". Turn on each browser under FocusHacker in Automation settings."
            alert.addButton(withTitle: "Open Automation Settings")
            alert.addButton(withTitle: "Not Now")
            if alert.runModal() == .alertFirstButtonReturn {
                SystemSettingsLinker.openAutomationSettings()
            }
        }
    }

    private static func primeAllBrowsers(context: String, force: Bool) {
        for appName in browserTargets {
            primeTarget(appName, context: context, force: force)
        }
    }

    private static func primeTarget(_ applicationName: String, context: String, force: Bool) {
        let key = primedKey(for: applicationName)
        if !force, UserDefaults.standard.bool(forKey: grantedKey(for: applicationName)) {
            return
        }

        let result = BrowserAppleScriptRunner.runAutomationRegistrationProbe(applicationName: applicationName)
        switch result {
        case .success:
            UserDefaults.standard.set(true, forKey: key)
        case .failure(let error):
            let ns = error as NSError
            UserDefaults.standard.set(false, forKey: grantedKey(for: applicationName))
            if ns.code == BrowserAppleScriptRunner.appleEventNotPermittedCode {
                UserDefaults.standard.set(false, forKey: key)
            } else {
                UserDefaults.standard.set(true, forKey: key)
            }
        }
    }
}
