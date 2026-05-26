import XCTest
@testable import FocusHacker

final class AutomationPermissionStateTests: XCTestCase {
    func testPermissionStateFromListTabsSuccess() {
        let state = AutomationPermissionPrimer.permissionState(
            fromListTabsResult: .success([])
        )
        XCTAssertEqual(state, .granted)
    }

    func testPermissionStateFromListTabsNotPermitted() {
        let error = NSError(
            domain: "com.focushacker.applescript",
            code: BrowserAppleScriptRunner.appleEventNotPermittedCode
        )
        let state = AutomationPermissionPrimer.permissionState(fromListTabsResult: .failure(error))
        XCTAssertEqual(state, .denied)
    }

    func testPermissionStateFromListTabsOtherFailure() {
        let error = NSError(domain: "com.focushacker.applescript", code: -1)
        let state = AutomationPermissionPrimer.permissionState(fromListTabsResult: .failure(error))
        XCTAssertEqual(state, .granted)
    }

    func testPermissionStatusLabels() {
        XCTAssertEqual(
            AutomationPermissionPrimer.permissionStatusLabel(for: .granted),
            "Connected"
        )
        XCTAssertEqual(
            AutomationPermissionPrimer.permissionStatusLabel(for: .unknown),
            "Not connected"
        )
        XCTAssertEqual(
            AutomationPermissionPrimer.permissionStatusLabel(for: .denied),
            "Not connected"
        )
    }
}
