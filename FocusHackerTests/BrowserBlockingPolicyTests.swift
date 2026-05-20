@testable import FocusHacker
import XCTest

final class BrowserBlockingPolicyTests: XCTestCase {
    private func payload(
        active: Bool,
        leaseUntil: Double,
        domains: [String],
        now: Date
    ) -> BlockerSharedStateFile.Payload {
        BlockerSharedStateFile.Payload(
            blockingIsActive: active,
            blockingLeaseExpiresAtReference: leaseUntil,
            blockedDomains: domains,
            blockedBundleIDs: []
        )
    }

    func testAllowsWhenLeaseExpired() {
        let now = Date()
        let expiredLease = now.timeIntervalSinceReferenceDate - 1
        let payload = payload(active: true, leaseUntil: expiredLease, domains: ["example.com"], now: now)
        let url = URL(string: "https://example.com/")!
        XCTAssertFalse(BrowserBlockingPolicy.shouldBlock(url: url, payload: payload, now: now))
    }

    func testAllowsWhenBlockingInactive() {
        let now = Date()
        let validLease = now.timeIntervalSinceReferenceDate + 120
        let payload = payload(active: false, leaseUntil: validLease, domains: ["example.com"], now: now)
        let url = URL(string: "https://example.com/")!
        XCTAssertFalse(BrowserBlockingPolicy.shouldBlock(url: url, payload: payload, now: now))
    }

    func testBlocksMatchingDomainDuringFocus() {
        let now = Date()
        let validLease = now.timeIntervalSinceReferenceDate + 120
        let payload = payload(active: true, leaseUntil: validLease, domains: ["example.com"], now: now)
        let url = URL(string: "https://www.example.com/path")!
        XCTAssertTrue(BrowserBlockingPolicy.shouldBlock(url: url, payload: payload, now: now))
    }

    func testWildcardDomain() {
        let now = Date()
        let validLease = now.timeIntervalSinceReferenceDate + 120
        let payload = payload(active: true, leaseUntil: validLease, domains: ["*.reddit.com"], now: now)
        XCTAssertTrue(
            BrowserBlockingPolicy.shouldBlock(
                url: URL(string: "https://old.reddit.com/")!,
                payload: payload,
                now: now
            )
        )
        XCTAssertFalse(
            BrowserBlockingPolicy.shouldBlock(
                url: URL(string: "https://notreddit.com/")!,
                payload: payload,
                now: now
            )
        )
    }

    func testAllowsNilPayload() {
        let url = URL(string: "https://example.com/")!
        XCTAssertFalse(BrowserBlockingPolicy.shouldBlock(url: url, payload: nil))
    }
}
