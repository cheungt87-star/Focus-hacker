import Foundation

/// Authoritative entitlement outcome after evaluating Store-backed signals (with optional UserDefaults cache for cold/offline UX).
enum PurchaseAccessEvaluation: Equatable, Sendable {
    case fullAccess(UnlockBasis)
    case requiresPurchaseOrRestore

    var allowsAppUse: Bool {
        switch self {
        case .fullAccess:
            return true
        case .requiresPurchaseOrRestore:
            return false
        }
    }

    /// Why the shell should treat the user as entitled.
    enum UnlockBasis: Equatable, Sendable {
        case lifetimePurchase
        case trialActive(expiresAt: Date)
    }

    /// Human-readable subtitle for Settings → About (non-localized identifiers stay in code until Localizable.strings exist).
    func aboutSubtitle(now: Date) -> String? {
        switch self {
        case .fullAccess(.lifetimePurchase):
            return "FocusHacker — Lifetime Access ✓"
        case let .fullAccess(.trialActive(expiresAt)):
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let startOfExpiry = calendar.startOfDay(for: expiresAt)
            let daysRemaining = calendar.dateComponents([.day], from: startOfToday, to: startOfExpiry).day ?? 0
            let capped = max(0, daysRemaining)
            return "Trial — \(capped) day\(capped == 1 ? "" : "s") remaining"
        case .requiresPurchaseOrRestore:
            return nil
        }
    }

    var isLifetimeUnlockedEvaluatedLocally: Bool {
        switch self {
        case let .fullAccess(basis):
            switch basis {
            case .lifetimePurchase:
                return true
            case .trialActive:
                return false
            }
        case .requiresPurchaseOrRestore:
            return false
        }
    }

    func isTrialActive(now: Date) -> Bool {
        switch self {
        case let .fullAccess(.trialActive(expiresAt)):
            return expiresAt > now
        default:
            return false
        }
    }
}

/// Pure reducer input for XCTest coverage (maps StoreKit-derived facts + cache).
struct PurchaseEntitlementInputs: Equatable, Sendable {
    var verifiedLifetimePurchased: Bool
    /// Active subscription entitlement (intro trial or paid period) expiry, if applicable.
    var verifiedSubscriptionExpiry: Date?
    var lastStoreKitVerificationSucceeded: Bool
    /// Offline / cold-launch convenience only (`focushacker.trialAccess.cache.expiresAt`); ignored when verification succeeded and contradicts access.
    var cachedTrialExpiry: Date?

    static let emptyInit = PurchaseEntitlementInputs(
        verifiedLifetimePurchased: false,
        verifiedSubscriptionExpiry: nil,
        lastStoreKitVerificationSucceeded: false,
        cachedTrialExpiry: nil
    )
}

enum PurchaseEntitlementResolver {
    static func evaluate(
        inputs: PurchaseEntitlementInputs,
        now: Date
    ) -> PurchaseAccessEvaluation {
        if inputs.verifiedLifetimePurchased {
            return .fullAccess(.lifetimePurchase)
        }

        if let expiry = inputs.verifiedSubscriptionExpiry, expiry > now {
            return .fullAccess(.trialActive(expiresAt: expiry))
        }

        // Failed StoreKit read: conservative offline hint only — never contradicts successful verification above.
        if !inputs.lastStoreKitVerificationSucceeded, let cached = inputs.cachedTrialExpiry, cached > now {
            return .fullAccess(.trialActive(expiresAt: cached))
        }

        return .requiresPurchaseOrRestore
    }
}
