import AppKit
import XCTest
@testable import FocusHacker

final class BlockedAppDisplayInfoResolverTests: XCTestCase {
    func testResolvesKnownSystemAppWithNonEmptyName() {
        let info = BlockedAppDisplayInfoResolver.resolve(bundleIdentifier: "com.apple.Safari")
        XCTAssertEqual(info.bundleIdentifier, "com.apple.Safari")
        XCTAssertFalse(info.displayName.isEmpty)
        XCTAssertGreaterThan(info.icon.size.width, 0)
        XCTAssertGreaterThan(info.icon.size.height, 0)
    }

    func testUnknownBundleIdentifierFallsBackGracefully() {
        let info = BlockedAppDisplayInfoResolver.resolve(
            bundleIdentifier: "com.example.nonexistent.app.blocker.test"
        )
        XCTAssertEqual(info.bundleIdentifier, "com.example.nonexistent.app.blocker.test")
        XCTAssertFalse(info.displayName.isEmpty)
        XCTAssertGreaterThan(info.icon.size.width, 0)
        XCTAssertGreaterThan(info.icon.size.height, 0)
    }

    func testFallbackDisplayNameUsesLastBundleComponent() {
        let info = BlockedAppDisplayInfoResolver.resolve(bundleIdentifier: "com.google.Chrome")
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") == nil {
            XCTAssertEqual(info.displayName, "Chrome")
        }
    }
}
