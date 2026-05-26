import AppKit
import Foundation

enum AutomationProbePolicy {
    /// Launch/become-active/settings: cache when quit; list-tabs only when already running.
    case passive
    /// Onboarding connect, settings recheck: may launch browser for TCC registration.
    case userInitiated
    /// Before focus monitoring: list-tabs only when running; never launch or alert.
    case beforeMonitoring
}

/// Sends tab-access Apple Events so macOS registers FocusHacker under Automation and shows permission dialogs.
enum AutomationPermissionPrimer {
    private static let browserTargets = BrowserAutomationTarget.supportedApplicationNames
    private static var didShowDeniedAlertThisSession = false

    private static func primedKey(for applicationName: String) -> String {
        "blocker.automation.primed.\(applicationName)"
    }

    private static func grantedKey(for applicationName: String) -> String {
        "blocker.automation.granted.\(applicationName)"
    }

    static func isSafariAutomationGranted() -> Bool {
        UserDefaults.standard.bool(forKey: grantedKey(for: BrowserAutomationTarget.safariApplicationName))
    }

    static func isChromeAutomationGranted() -> Bool {
        UserDefaults.standard.bool(forKey: grantedKey(for: BrowserAutomationTarget.chromeApplicationName))
    }

    static var isBrowserBlockingReady: Bool {
        isSafariAutomationGranted() && isChromeAutomationGranted()
    }

    static func permissionStatusLabel(for state: AutomationPermissionState) -> String {
        switch state {
        case .granted:
            return "Connected"
        case .denied, .unknown:
            return "Not connected"
        }
    }

    /// Maps a tab-list probe result to Automation permission state for Settings UI.
    static func permissionState(fromListTabsResult result: Result<[BrowserTabRef], Error>) -> AutomationPermissionState {
        switch result {
        case .success:
            return .granted
        case .failure(let error):
            if (error as NSError).code == BrowserAppleScriptRunner.appleEventNotPermittedCode {
                return .denied
            }
            return .granted
        }
    }

    @discardableResult
    static func refreshPermissionState(
        applicationName: String,
        context: String,
        policy: AutomationProbePolicy
    ) -> AutomationPermissionState {
        switch policy {
        case .passive:
            return refreshPassivePermissionState(applicationName: applicationName, context: context)
        case .userInitiated:
            return refreshUserInitiatedPermissionState(applicationName: applicationName, context: context)
        case .beforeMonitoring:
            return refreshBeforeMonitoringPermissionState(applicationName: applicationName, context: context)
        }
    }

    /// Backward-compatible alias for settings and other call sites that expect a live refresh API.
    @discardableResult
    static func refreshLivePermissionState(applicationName: String, context: String) -> AutomationPermissionState {
        refreshPermissionState(applicationName: applicationName, context: context, policy: .passive)
    }

    /// Returning users: passive cache refresh on launch (does not open browsers).
    static func primeOnLaunchIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "onboarding.didCompleteGuidedFlow") else {
            return
        }
        refreshAllPermissionStates(context: "launch", policy: .passive)
    }

    /// Onboarding / explicit connect — may launch browsers for TCC prompts.
    static func primeForOnboardingIfNeeded() {
        requestUserInitiatedPermissions(context: "onboarding")
    }

    static func forceProbeNow() {
        refreshAllPermissionStates(context: "force", policy: .userInitiated)
    }

    /// Re-probe before monitoring when Automation toggles are off (-1743 during focus).
    static func ensurePermissionsBeforeMonitoring() {
        refreshAllPermissionStates(context: "pre_monitor", policy: .beforeMonitoring)
    }

    /// After returning from System Settings, refresh without launching quit browsers.
    static func refreshGrantStateQuietly() {
        let safari = refreshPermissionState(
            applicationName: BrowserAutomationTarget.safariApplicationName,
            context: "become_active",
            policy: .passive
        )
        let chrome = refreshPermissionState(
            applicationName: BrowserAutomationTarget.chromeApplicationName,
            context: "become_active",
            policy: .passive
        )
        if safari == .granted, chrome == .granted {
            didShowDeniedAlertThisSession = false
        }
    }

    static func cachedPermissionState(applicationName: String) -> AutomationPermissionState {
        guard UserDefaults.standard.object(forKey: grantedKey(for: applicationName)) != nil else {
            return .unknown
        }
        return UserDefaults.standard.bool(forKey: grantedKey(for: applicationName)) ? .granted : .denied
    }

    // MARK: - Private

    private static func refreshPassivePermissionState(applicationName: String, context: String) -> AutomationPermissionState {
        guard BrowserAutomationTarget.isRunning(applicationName: applicationName) else {
            return cachedPermissionState(applicationName: applicationName)
        }
        return refreshListTabsPermissionState(applicationName: applicationName, context: context)
    }

    private static func refreshBeforeMonitoringPermissionState(
        applicationName: String,
        context: String
    ) -> AutomationPermissionState {
        guard BrowserAutomationTarget.isRunning(applicationName: applicationName) else {
            return cachedPermissionState(applicationName: applicationName)
        }
        return refreshListTabsPermissionState(applicationName: applicationName, context: context)
    }

    private static func refreshUserInitiatedPermissionState(
        applicationName: String,
        context: String
    ) -> AutomationPermissionState {
        primeTarget(applicationName, context: "\(context)_register", force: true)
        return refreshListTabsPermissionState(applicationName: applicationName, context: context)
    }

    private static func refreshListTabsPermissionState(
        applicationName: String,
        context: String
    ) -> AutomationPermissionState {
        let listTabsResult = BrowserAppleScriptRunner.runListTabs(applicationName: applicationName)
        let state = permissionState(fromListTabsResult: listTabsResult)
        UserDefaults.standard.set(state == .granted, forKey: grantedKey(for: applicationName))
        if state == .denied {
            UserDefaults.standard.set(false, forKey: primedKey(for: applicationName))
        }
        _ = context
        return state
    }

    private static func refreshAllPermissionStates(context: String, policy: AutomationProbePolicy) {
        for applicationName in browserTargets {
            _ = refreshPermissionState(applicationName: applicationName, context: context, policy: policy)
        }
    }

    private static func requestUserInitiatedPermissions(context: String) {
        refreshAllPermissionStates(context: context, policy: .userInitiated)
        let safariGranted = cachedPermissionState(applicationName: BrowserAutomationTarget.safariApplicationName) == .granted
        let chromeGranted = cachedPermissionState(applicationName: BrowserAutomationTarget.chromeApplicationName) == .granted
        if !safariGranted || !chromeGranted {
            presentAutomationRequiredAlertOnLaunch(safariGranted: safariGranted, chromeGranted: chromeGranted)
        }
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
                safariGranted ? nil : BrowserAutomationTarget.safariApplicationName,
                chromeGranted ? nil : BrowserAutomationTarget.chromeApplicationName,
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
        _ = context
    }
}
