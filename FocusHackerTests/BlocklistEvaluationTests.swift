@testable import FocusHacker
import XCTest

final class BlocklistEvaluationTests: XCTestCase {
    func testDomainExactMatchAndSubdomains() {
        XCTAssertTrue(BlocklistEvaluation.shouldBlockHost("twitter.com", blockedEntries: ["twitter.com"]))
        XCTAssertTrue(BlocklistEvaluation.shouldBlockHost("www.twitter.com", blockedEntries: ["twitter.com"]))
    }

    func testDomainEntriesValidateUserInput() {
        XCTAssertTrue(BlocklistEvaluation.isValidUserDomainPatternEntry("twitter.com"))
        XCTAssertTrue(BlocklistEvaluation.isValidUserDomainPatternEntry("https://twitter.com/path"))
        XCTAssertTrue(BlocklistEvaluation.isValidUserDomainPatternEntry("*.reddit.com"))
        XCTAssertFalse(BlocklistEvaluation.isValidUserDomainPatternEntry(" "))
        XCTAssertFalse(BlocklistEvaluation.isValidUserDomainPatternEntry("not a domain"))
    }

    func testWildcardDomains() {
        XCTAssertTrue(BlocklistEvaluation.shouldBlockHost("old.reddit.com", blockedEntries: ["*.reddit.com"]))
        XCTAssertTrue(BlocklistEvaluation.shouldBlockHost("reddit.com", blockedEntries: ["*.reddit.com"]))
        XCTAssertFalse(BlocklistEvaluation.shouldBlockHost("notreddit.com", blockedEntries: ["*.reddit.com"]))
    }

    func testParseEntriesFromURLs() {
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockHost("example.com", blockedEntries: ["https://example.com/path"])
        )
        XCTAssertTrue(BlocklistEvaluation.shouldBlockHost("example.com", blockedEntries: ["http://example.com"]))
    }

    func testChromiumSigningIdentifierDetection() {
        XCTAssertTrue(BlocklistEvaluation.isChromiumSigningIdentifier("com.google.Chrome.helper"))
        XCTAssertTrue(BlocklistEvaluation.isChromiumSigningIdentifier("org.chromium.Chromium.helper"))
        XCTAssertFalse(BlocklistEvaluation.isChromiumSigningIdentifier("com.apple.Safari"))
        XCTAssertFalse(BlocklistEvaluation.isChromiumSigningIdentifier(nil))
    }

    func testPrivateOrLocalHostDetection() {
        XCTAssertTrue(BlocklistEvaluation.isPrivateOrLocalHost("192.168.1.1"))
        XCTAssertTrue(BlocklistEvaluation.isPrivateOrLocalHost("10.0.0.5"))
        XCTAssertTrue(BlocklistEvaluation.isPrivateOrLocalHost("172.16.0.1"))
        XCTAssertTrue(BlocklistEvaluation.isPrivateOrLocalHost("127.0.0.1"))
        XCTAssertFalse(BlocklistEvaluation.isPrivateOrLocalHost("142.250.4.94"))
    }

    func testParseWWWSlashTypoJoinsSecondPathSegment() {
        XCTAssertEqual(
            BlocklistEvaluation.parseDomainEntry("https://www/linkedin.com"),
            "www.linkedin.com"
        )
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockHost("www.linkedin.com", blockedEntries: ["https://www/linkedin.com"])
        )
    }

    func testSigningIdentifierTeamPrefixMatching() {
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "ABCDEF.com.apple.Safari",
                blockedBundleIdentifiers: ["com.apple.Safari"]
            )
        )
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "com.apple.Safari",
                blockedBundleIdentifiers: ["com.apple.Safari"]
            )
        )
        XCTAssertFalse(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "com.apple.dt.Xcode",
                blockedBundleIdentifiers: ["com.apple.Safari"]
            )
        )
    }

    func testLooksLikeBundleIdentifierFiltersDomainListMistakes() {
        XCTAssertTrue(BlocklistEvaluation.looksLikeBundleIdentifier("com.google.Chrome"))
        XCTAssertFalse(BlocklistEvaluation.looksLikeBundleIdentifier("weather.com"))
        XCTAssertFalse(BlocklistEvaluation.looksLikeBundleIdentifier("github.com"))
    }

    func testSigningIdentifierBlocksNestedHelpersWhenMainBundleListed() {
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "com.google.Chrome.helper",
                blockedBundleIdentifiers: ["com.google.Chrome"]
            )
        )
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "1234567890.com.google.Chrome.helper",
                blockedBundleIdentifiers: ["com.google.Chrome"]
            )
        )
        XCTAssertFalse(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "com.google.Chrome.helper",
                blockedBundleIdentifiers: ["com.google.Chrome.beta"]
            )
        )
        XCTAssertTrue(
            BlocklistEvaluation.shouldBlockSigningIdentifier(
                "com.google.chrome.helper",
                blockedBundleIdentifiers: ["com.google.Chrome"]
            )
        )
    }

    func testBlockingLeaseFailsOpenWhenExpired() {
        XCTAssertTrue(
            BlocklistEvaluationLeaseTestsHarness.isLeaseValid(referenceNow: 9, leaseEndsAt: 50, isActive: true)
        )
        XCTAssertFalse(
            BlocklistEvaluationLeaseTestsHarness.isLeaseValid(referenceNow: 51, leaseEndsAt: 50, isActive: true)
        )
        XCTAssertFalse(
            BlocklistEvaluationLeaseTestsHarness.isLeaseValid(referenceNow: 10, leaseEndsAt: 50, isActive: false)
        )
    }
}

final class BlockerIPLiteralCanonicalTests: XCTestCase {
    func testCanonicalIPv4() {
        XCTAssertEqual(BlockerIPLiteralCanonical.canonical("192.0.2.1"), "192.0.2.1")
    }

    func testCappedUnionMergesUniqueAddresses() {
        let result = BlockerIPLiteralCanonical.cappedUnion(
            previous: ["192.0.2.1"],
            tickLiterals: ["192.0.2.1", "192.0.2.2"],
            cap: 100
        )
        XCTAssertEqual(Set(result.merged), Set(["192.0.2.1", "192.0.2.2"]))
        XCTAssertFalse(result.truncated)
    }

    func testCappedUnionPrefersTickLiteralsWhenAtCap() {
        let previous = ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
        let tick = ["10.0.0.9", "10.0.0.8"]
        let result = BlockerIPLiteralCanonical.cappedUnion(previous: previous, tickLiterals: tick, cap: 2)
        XCTAssertEqual(Set(result.merged), Set(["10.0.0.8", "10.0.0.9"]))
        XCTAssertTrue(result.truncated)
    }
}

private enum BlocklistEvaluationLeaseTestsHarness {
    static func isLeaseValid(referenceNow: TimeInterval, leaseEndsAt: TimeInterval, isActive: Bool) -> Bool {
        let now = Date(timeIntervalSinceReferenceDate: referenceNow)
        return BlockerAppGroup.isBlockingLeaseValid(
            isActive: isActive,
            leaseUntilReference: leaseEndsAt,
            now: now
        )
    }
}
