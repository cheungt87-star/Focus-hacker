@testable import FocusHacker
import XCTest

final class AppBlockingPolicyTests: XCTestCase {
    private func payload(
        active: Bool,
        leaseUntil: Double,
        bundleIDs: [String],
        now: Date
    ) -> BlockerSharedStateFile.Payload {
        BlockerSharedStateFile.Payload(
            blockingIsActive: active,
            blockingLeaseExpiresAtReference: leaseUntil,
            blockedDomains: [],
            blockedBundleIDs: bundleIDs
        )
    }

    func testAllowsWhenLeaseExpired() {
        let now = Date()
        let expiredLease = now.timeIntervalSinceReferenceDate - 1
        let payload = payload(active: true, leaseUntil: expiredLease, bundleIDs: ["com.example.app"], now: now)
        XCTAssertFalse(
            AppBlockingPolicy.shouldTerminate(
                bundleIdentifier: "com.example.app",
                payload: payload,
                blockedBundleIdentifiers: ["com.example.app"],
                now: now
            )
        )
    }

    func testAllowsWhenBlockingInactive() {
        let now = Date()
        let validLease = now.timeIntervalSinceReferenceDate + 120
        let payload = payload(active: false, leaseUntil: validLease, bundleIDs: ["com.example.app"], now: now)
        XCTAssertFalse(
            AppBlockingPolicy.shouldTerminate(
                bundleIdentifier: "com.example.app",
                payload: payload,
                blockedBundleIdentifiers: ["com.example.app"],
                now: now
            )
        )
    }

    func testTerminatesMatchingBundleDuringFocus() {
        let now = Date()
        let validLease = now.timeIntervalSinceReferenceDate + 120
        let payload = payload(active: true, leaseUntil: validLease, bundleIDs: ["com.example.app"], now: now)
        XCTAssertTrue(
            AppBlockingPolicy.shouldTerminate(
                bundleIdentifier: "com.example.app",
                payload: payload,
                blockedBundleIdentifiers: ["com.example.app"],
                now: now
            )
        )
    }

    func testTerminatesHelperBundleWhenParentBlocked() {
        let now = Date()
        let validLease = now.timeIntervalSinceReferenceDate + 120
        let payload = payload(active: true, leaseUntil: validLease, bundleIDs: ["com.google.Chrome"], now: now)
        XCTAssertTrue(
            AppBlockingPolicy.shouldTerminate(
                bundleIdentifier: "com.google.Chrome.helper",
                payload: payload,
                blockedBundleIdentifiers: ["com.google.Chrome"],
                now: now
            )
        )
    }

    func testAllowsNilPayload() {
        XCTAssertFalse(
            AppBlockingPolicy.shouldTerminate(
                bundleIdentifier: "com.example.app",
                payload: nil,
                blockedBundleIdentifiers: ["com.example.app"]
            )
        )
    }
}
