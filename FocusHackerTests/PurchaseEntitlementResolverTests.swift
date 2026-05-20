import XCTest
@testable import FocusHacker

final class PurchaseEntitlementResolverTests: XCTestCase {
    private let referenceNow = Date(timeIntervalSince1970: 1_700_000_000)

    func testLifetimePurchaseIgnoresSubscriptionAndCache() {
        let inputs = PurchaseEntitlementInputs(
            verifiedLifetimePurchased: true,
            verifiedSubscriptionExpiry: referenceNow.addingTimeInterval(86_400),
            lastStoreKitVerificationSucceeded: true,
            cachedTrialExpiry: referenceNow.addingTimeInterval(172_800)
        )
        let snapshot = PurchaseEntitlementResolver.evaluate(inputs: inputs, now: referenceNow)
        guard case let .fullAccess(basis) = snapshot else {
            return XCTFail("Expected full access.")
        }
        if case .lifetimePurchase = basis {
            return
        }
        XCTFail("Expected lifetime basis.")
    }

    func testActiveSubscriptionTrialWindowUnlocksThroughStoreSnapshot() {
        let expiry = referenceNow.addingTimeInterval(2 * 86_400)
        let inputs = PurchaseEntitlementInputs(
            verifiedLifetimePurchased: false,
            verifiedSubscriptionExpiry: expiry,
            lastStoreKitVerificationSucceeded: true,
            cachedTrialExpiry: referenceNow.addingTimeInterval(-86_400)
        )
        let snapshot = PurchaseEntitlementResolver.evaluate(inputs: inputs, now: referenceNow)
        guard case let .fullAccess(.trialActive(expiresAt)) = snapshot else {
            return XCTFail("Expected trial baseline.")
        }
        XCTAssertEqual(expiresAt, expiry)
    }

    func testStaleCacheIgnoredWhenVerificationSucceededButNoEntitlementFound() {
        let inputs = PurchaseEntitlementInputs(
            verifiedLifetimePurchased: false,
            verifiedSubscriptionExpiry: nil,
            lastStoreKitVerificationSucceeded: true,
            cachedTrialExpiry: referenceNow.addingTimeInterval(3 * 86_400)
        )
        let snapshot = PurchaseEntitlementResolver.evaluate(inputs: inputs, now: referenceNow)
        XCTAssertEqual(snapshot, PurchaseAccessEvaluation.requiresPurchaseOrRestore)
    }

    func testUnreadableStoreAllowsCachedTrialContinuation() {
        let inputs = PurchaseEntitlementInputs(
            verifiedLifetimePurchased: false,
            verifiedSubscriptionExpiry: nil,
            lastStoreKitVerificationSucceeded: false,
            cachedTrialExpiry: referenceNow.addingTimeInterval(86_400)
        )
        let snapshot = PurchaseEntitlementResolver.evaluate(inputs: inputs, now: referenceNow)
        guard case let .fullAccess(.trialActive(expiresAt)) = snapshot else {
            return XCTFail("Expected cache-driven trial hint.")
        }
        XCTAssertEqual(expiresAt, referenceNow.addingTimeInterval(86_400))
    }

    func testAboutSubtitleLifetimeCopy() {
        let snapshot = PurchaseAccessEvaluation.fullAccess(.lifetimePurchase)
        XCTAssertEqual(snapshot.aboutSubtitle(now: referenceNow), "FocusHacker — Lifetime Access ✓")
    }

    func testAboutSubtitleTrialDaysRoundedToCalendar() {
        let calendar = Calendar(identifier: .gregorian)
        var parts = DateComponents()
        parts.year = 2023
        parts.month = 11
        parts.day = 10
        let now = calendar.date(from: parts)!
        parts.day = 13
        let expiry = calendar.date(from: parts)!
        let snapshot = PurchaseAccessEvaluation.fullAccess(.trialActive(expiresAt: expiry))
        XCTAssertEqual(snapshot.aboutSubtitle(now: now), "Trial — 3 days remaining")
    }
}
