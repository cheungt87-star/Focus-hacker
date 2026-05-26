import XCTest
@testable import FocusHacker

final class AutomationPermissionPrimerPolicyTests: XCTestCase {
    private let safariGrantedKey = "blocker.automation.granted.Safari"
    private let chromeGrantedKey = "blocker.automation.granted.Google Chrome"

    override func setUp() {
        super.setUp()
        BrowserAutomationTarget.isRunningOverride = { _ in false }
        clearGrantCache()
    }

    override func tearDown() {
        BrowserAutomationTarget.isRunningOverride = nil
        clearGrantCache()
        super.tearDown()
    }

    func testPassiveWhenBrowserNotRunningReturnsUnknownWithoutCache() {
        let state = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.safariApplicationName,
            context: "test",
            policy: .passive
        )
        XCTAssertEqual(state, .unknown)
    }

    func testPassiveWhenBrowserNotRunningReturnsCachedGranted() {
        UserDefaults.standard.set(true, forKey: safariGrantedKey)
        let state = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.safariApplicationName,
            context: "test",
            policy: .passive
        )
        XCTAssertEqual(state, .granted)
    }

    func testPassiveWhenBrowserNotRunningReturnsCachedDenied() {
        UserDefaults.standard.set(false, forKey: safariGrantedKey)
        let state = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.safariApplicationName,
            context: "test",
            policy: .passive
        )
        XCTAssertEqual(state, .denied)
    }

    func testBeforeMonitoringWhenBrowserNotRunningMatchesPassiveCache() {
        UserDefaults.standard.set(false, forKey: chromeGrantedKey)
        let state = AutomationPermissionPrimer.refreshPermissionState(
            applicationName: BrowserAutomationTarget.chromeApplicationName,
            context: "pre_monitor",
            policy: .beforeMonitoring
        )
        XCTAssertEqual(state, .denied)
    }

    func testCachedPermissionStateReflectsUserDefaults() {
        XCTAssertEqual(
            AutomationPermissionPrimer.cachedPermissionState(
                applicationName: BrowserAutomationTarget.safariApplicationName
            ),
            .unknown
        )
        UserDefaults.standard.set(true, forKey: safariGrantedKey)
        XCTAssertEqual(
            AutomationPermissionPrimer.cachedPermissionState(
                applicationName: BrowserAutomationTarget.safariApplicationName
            ),
            .granted
        )
    }

    func testBrowserAutomationTargetBundleIdentifierMapping() {
        XCTAssertEqual(
            BrowserAutomationTarget.bundleIdentifier(
                forApplicationName: BrowserAutomationTarget.safariApplicationName
            ),
            "com.apple.Safari"
        )
        XCTAssertEqual(
            BrowserAutomationTarget.bundleIdentifier(
                forApplicationName: BrowserAutomationTarget.chromeApplicationName
            ),
            "com.google.Chrome"
        )
        XCTAssertEqual(
            BrowserAutomationTarget.applicationName(forBundleIdentifier: "com.google.Chrome"),
            BrowserAutomationTarget.chromeApplicationName
        )
        XCTAssertTrue(BrowserAutomationTarget.isSupportedBundleIdentifier("com.apple.Safari"))
        XCTAssertFalse(BrowserAutomationTarget.isSupportedBundleIdentifier("com.apple.finder"))
    }

    func testPrimeOnLaunchSkipsWhenOnboardingIncomplete() {
        UserDefaults.standard.set(false, forKey: "onboarding.didCompleteGuidedFlow")
        AutomationPermissionPrimer.primeOnLaunchIfNeeded()
        XCTAssertEqual(
            AutomationPermissionPrimer.cachedPermissionState(
                applicationName: BrowserAutomationTarget.safariApplicationName
            ),
            .unknown
        )
    }

    private func clearGrantCache() {
        UserDefaults.standard.removeObject(forKey: safariGrantedKey)
        UserDefaults.standard.removeObject(forKey: chromeGrantedKey)
        UserDefaults.standard.removeObject(forKey: "blocker.automation.primed.Safari")
        UserDefaults.standard.removeObject(forKey: "blocker.automation.primed.Google Chrome")
    }
}
