import Foundation
import StoreKit

enum PurchaseInteractionError: LocalizedError, Equatable {
    case lifetimeProductUnavailable
    case restoreFoundNoEntitlements
    case verificationRejected(String)

    var errorDescription: String? {
        switch self {
        case .lifetimeProductUnavailable:
            return "Unable to reach the App Store catalog right now."
        case .restoreFoundNoEntitlements:
            return "No purchase found for this Apple ID."
        case let .verificationRejected(detail):
            return "Receipt verification failed: \(detail)"
        }
    }
}

#if DEBUG
// TEMPORARY: bypasses EPIC 8 (monetisation) so the rest of the flow can be tested
// without StoreKit. Flip to `false` (or delete this block + its `#if DEBUG` guards
// below) to restore the paywall, 7-day trial gate, and lock-out UI.
private let monetisationGateBypassedForTesting = true
#else
private let monetisationGateBypassedForTesting = false
#endif

/// StoreKit‑first entitlement + transactional helpers surfaced to SwiftUI.
@MainActor
final class PurchaseEntitlementService: ObservableObject {
    @Published private(set) var evaluation: PurchaseAccessEvaluation = .requiresPurchaseOrRestore
    /// Localized formatted price (`Product.displayPrice`) with a deterministic fallback until the catalog resolves.
    @Published private(set) var lifetimeDisplayPrice: String
    @Published private(set) var hasFinishedBootstrap: Bool = false
    @Published private(set) var transactionalNotice: String?

    private let settingsStore: UserDefaultsSettingsStore

    private var cachedLifetimeProduct: Product?
    private var transactionObservation: Task<Void, Never>?

    init(settingsStore: UserDefaultsSettingsStore) {
        self.settingsStore = settingsStore
        self.lifetimeDisplayPrice = "$14.99"
        self.cachedLifetimeProduct = nil
        if monetisationGateBypassedForTesting {
            evaluation = .fullAccess(.lifetimePurchase)
        }
        beginListeningForTransactionUpdatesIfNeeded()
    }

    deinit {
        transactionObservation?.cancel()
    }

    func bootstrap(now: Date = Date()) async {
        if monetisationGateBypassedForTesting {
            evaluation = .fullAccess(.lifetimePurchase)
            hasFinishedBootstrap = true
            return
        }
        cachedLifetimeProduct = nil
        await reloadLifetimeProductPrice()
        await refreshEntitlementsFromStore(now: now)
        hasFinishedBootstrap = true
    }

    func reloadLifetimeProductPrice() async {
        if monetisationGateBypassedForTesting {
            return
        }
        do {
            let products = try await Product.products(for: [FocusHackerProductIdentifier.lifetime.rawValue])
            cachedLifetimeProduct = products.first(where: { $0.id == FocusHackerProductIdentifier.lifetime.rawValue })
            lifetimeDisplayPrice = cachedLifetimeProduct?.displayPrice ?? "$14.99"
        } catch {
            cachedLifetimeProduct = nil
            lifetimeDisplayPrice = "$14.99"
        }
    }

    func refreshEntitlementsFromStore(now: Date = Date()) async {
        if monetisationGateBypassedForTesting {
            evaluation = .fullAccess(.lifetimePurchase)
            return
        }
        let inputs = await collectEntitlementFacts(now: now)
        reconcileCachesWithVerifiedSignals(inputs: inputs)
        evaluation = PurchaseEntitlementResolver.evaluate(inputs: inputs, now: now)
    }

    func attemptIntroTrialSignupIfEligible() async {
        if monetisationGateBypassedForTesting {
            return
        }
        do {
            let products = try await Product.products(for: [FocusHackerProductIdentifier.introSubscription.rawValue])
            guard let subscriptionProduct = products.first(where: { $0.id == FocusHackerProductIdentifier.introSubscription.rawValue }),
                  let subscriptionDetails = subscriptionProduct.subscription
            else {
                return
            }
            guard await subscriptionDetails.isEligibleForIntroOffer else {
                return
            }
            let outcome = try await subscriptionProduct.purchase()
            switch outcome {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    await refreshEntitlementsFromStore()
                    await transaction.finish()
                case let .unverified(_, verificationError):
                    throw PurchaseInteractionError.verificationRejected(verificationError.localizedDescription)
                }
            case .userCancelled:
                return
            case .pending:
                scheduleTransactionalNotice("Purchase pending approval.")
            @unknown default:
                break
            }
        } catch is CancellationError {
            return
        } catch PurchaseInteractionError.verificationRejected {
            return
        } catch {
            return
        }
    }

    func purchaseLifetimeAccess() async throws {
        if monetisationGateBypassedForTesting {
            evaluation = .fullAccess(.lifetimePurchase)
            return
        }
        await reloadLifetimeProductPrice()
        if cachedLifetimeProduct == nil {
            let products = try await Product.products(for: [FocusHackerProductIdentifier.lifetime.rawValue])
            cachedLifetimeProduct = products.first
        }
        guard let lifetimeProduct = cachedLifetimeProduct else {
            throw PurchaseInteractionError.lifetimeProductUnavailable
        }
        let outcome = try await lifetimeProduct.purchase()
        switch outcome {
        case let .success(verificationResult):
            switch verificationResult {
            case let .verified(transaction):
                await refreshEntitlementsFromStore()
                await transaction.finish()
                scheduleTransactionalNotice("Lifetime access unlocked — thank you.")
            case let .unverified(_, error):
                throw PurchaseInteractionError.verificationRejected(error.localizedDescription)
            }
        case .userCancelled:
            throw CancellationError()
        case .pending:
            scheduleTransactionalNotice("Lifetime purchase pending approval.")
        @unknown default:
            break
        }
    }

    /// US-031: `AppStore.sync()` followed by entitlement refresh; throws unless an unlock is observable afterwards.
    func restorePurchases() async throws {
        if monetisationGateBypassedForTesting {
            evaluation = .fullAccess(.lifetimePurchase)
            return
        }
        try await AppStore.sync()
        await refreshEntitlementsFromStore()
        guard evaluation.allowsAppUse else {
            throw PurchaseInteractionError.restoreFoundNoEntitlements
        }
        scheduleTransactionalNotice("Purchases restored.")
    }

    private func beginListeningForTransactionUpdatesIfNeeded() {
        guard !monetisationGateBypassedForTesting else { return }
        guard transactionObservation == nil else { return }
        transactionObservation = Task { [weak self] in
            for await verification in Transaction.updates {
                await self?.ingestUpstreamTransaction(verification)
            }
        }
    }

    private func ingestUpstreamTransaction(_ verification: VerificationResult<Transaction>) async {
        switch verification {
        case let .verified(transaction):
            await refreshEntitlementsFromStore()
            await transaction.finish()
        case .unverified:
            await refreshEntitlementsFromStore()
        }
    }

    /// Serial pass over `Transaction.currentEntitlements`.

    private func collectEntitlementFacts(now: Date) async -> PurchaseEntitlementInputs {
        var lifetimeUnlocked = false
        var bestSubscriptionExpiry: Date?
        var sawUnverified = false

        let lifetimeSKU = FocusHackerProductIdentifier.lifetime.rawValue
        let introSKU = FocusHackerProductIdentifier.introSubscription.rawValue

        for await verification in Transaction.currentEntitlements {
            switch verification {
            case let .verified(transaction):
                if transaction.revocationDate != nil {
                    continue
                }
                switch transaction.productID {
                case lifetimeSKU:
                    lifetimeUnlocked = true
                case introSKU:
                    if let expiry = transaction.expirationDate {
                        if let current = bestSubscriptionExpiry {
                            if expiry > current {
                                bestSubscriptionExpiry = expiry
                            }
                        } else {
                            bestSubscriptionExpiry = expiry
                        }
                    }
                    if settingsStore.trialPurchaseStartDateCacheSnapshot == nil {
                        settingsStore.trialPurchaseStartDateCacheSnapshot = transaction.purchaseDate
                    }
                default:
                    break
                }
            case .unverified:
                sawUnverified = true
            }
        }

        let storeReadSucceeded = !sawUnverified

        let cachedExpiry = settingsStore.cachedTrialAccessExpiryDateSnapshot

        return PurchaseEntitlementInputs(
            verifiedLifetimePurchased: lifetimeUnlocked,
            verifiedSubscriptionExpiry: bestSubscriptionExpiry,
            lastStoreKitVerificationSucceeded: storeReadSucceeded,
            cachedTrialExpiry: cachedExpiry
        )
    }

    private func reconcileCachesWithVerifiedSignals(inputs: PurchaseEntitlementInputs) {
        if inputs.lastStoreKitVerificationSucceeded {
            if inputs.verifiedLifetimePurchased {
                settingsStore.cachedTrialAccessExpiryDateSnapshot = nil
                return
            }
            if let expiry = inputs.verifiedSubscriptionExpiry {
                settingsStore.cachedTrialAccessExpiryDateSnapshot = expiry
            } else {
                settingsStore.cachedTrialAccessExpiryDateSnapshot = nil
            }
            return
        }
        // Unverified entitlement stream — preserve existing cache untouched for Resolver fallback logic.
    }

    private func scheduleTransactionalNotice(_ text: String?, durationNanos: UInt64 = 4_500_000_000) {
        transactionalNotice = text
        guard text != nil else { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: durationNanos)
            await MainActor.run {
                guard let self else { return }
                if self.transactionalNotice == text {
                    self.transactionalNotice = nil
                }
            }
        }
    }
}
