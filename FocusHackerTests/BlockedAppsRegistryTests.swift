@testable import FocusHacker
import XCTest

final class BlockedAppsRegistryTests: XCTestCase {
    func testProtectedSystemAppsAreNeverBlocked() {
        XCTAssertFalse(BlockedAppsRegistry.isBlocked(bundleIdentifier: "com.apple.finder"))
        XCTAssertFalse(BlockedAppsRegistry.isBlocked(bundleIdentifier: "com.apple.systempreferences"))
        XCTAssertTrue(BlockedAppsRegistry.isProtectedSystemApp(bundleIdentifier: "com.apple.finder"))
    }

    func testEmptyBundleIdentifierIsNotBlocked() {
        XCTAssertFalse(BlockedAppsRegistry.isBlocked(bundleIdentifier: ""))
    }
}
