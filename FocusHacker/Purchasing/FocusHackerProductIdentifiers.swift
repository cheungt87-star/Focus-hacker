import Foundation

/// Product identifiers shared by App Store Connect, `FocusHacker.storekit`, and runtime purchase code.
enum FocusHackerProductIdentifier: String, CaseIterable, Sendable {
    /// One-time unlock (non-consumable).
    case lifetime = "com.focushacker.lifetime"
    /// Auto-renewable subscription used solely to express StoreKit-introductory trial access (`introductoryOffer` in the StoreKit config).
    /// After the trial interval, entitlement ends unless the user purchases `lifetime`.
    case introSubscription = "com.focushacker.intro"

    static var allProductIDs: [String] {
        FocusHackerProductIdentifier.allCases.map(\.rawValue)
    }
}
