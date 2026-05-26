import SwiftUI

struct PaywallView: View {
    @ObservedObject var purchaseEntitlements: PurchaseEntitlementService

    @State private var purchaseErrorAlert: String?
    private var appearancePreference: AppearancePreference {
        AppDependencies.live.settingsStore.appearancePreference
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.spacing6) {
                MacDSHeroCard {
                    VStack(alignment: .leading, spacing: DesignSpacing.spacing3) {
                        Text("Unlock FocusHacker")
                            .font(.macDSPageTitle)
                            .foregroundStyle(.white)
                        Text(freeTrialCopyLine)
                            .font(.macDSBody)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                MacDSCard {
                    VStack(alignment: .leading, spacing: DesignSpacing.spacing4) {
                        Text(priceLine)
                            .font(.macDSBody.weight(.medium))
                            .foregroundStyle(MacDS.Color.textPrimary)

                        HStack(spacing: DesignSpacing.spacing3) {
                            Button("Start free trial") {
                                Task { await trialAction() }
                            }
                            .buttonStyle(MacDSSecondaryButtonStyle())

                            Button("Purchase lifetime (\(purchaseEntitlements.lifetimeDisplayPrice))") {
                                Task { await lifetimeAction() }
                            }
                            .buttonStyle(MacDSPrimaryButtonStyle())
                        }

                        Button("Restore purchase") {
                            Task { await restoreAction() }
                        }
                        .buttonStyle(.plain)
                        .font(.macDSLabel)
                        .foregroundStyle(MacDS.Color.accentTeal)

                        Text("Full access stays active during the introductory period. Trials and purchases clear only through Apple's storefront.")
                            .macDSHelperText()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .macDSPagePadding()
        }
        .frame(width: 480)
        .background(MacDS.Color.backgroundPrimary)
        .environment(\.appUISurface, .mainWindow)
        .preferredColorScheme(appearancePreference.preferredColorScheme)
        .alert("Purchases", isPresented: Binding(
            get: { purchaseErrorAlert != nil },
            set: { presented in if !presented { purchaseErrorAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseErrorAlert ?? "")
        }
    }

    private var freeTrialCopyLine: String {
        "Use “Start free trial” to launch the 7-day introductory access Apple defines in the StoreKit configuration. "
            + "When that window ends, unlock with the one-time lifetime purchase."
    }

    private var priceLine: String {
        "\(purchaseEntitlements.lifetimeDisplayPrice) one-time for lifetime unlock."
    }

    private func lifetimeAction() async {
        purchaseErrorAlert = nil
        do {
            try await purchaseEntitlements.purchaseLifetimeAccess()
        } catch is CancellationError {
            return
        } catch PurchaseInteractionError.lifetimeProductUnavailable {
            purchaseErrorAlert = PurchaseInteractionError.lifetimeProductUnavailable.errorDescription ?? "Unavailable."
        } catch let PurchaseInteractionError.verificationRejected(detail) {
            purchaseErrorAlert = detail
        } catch {
            purchaseErrorAlert = error.localizedDescription
        }
    }

    private func restoreAction() async {
        purchaseErrorAlert = nil
        do {
            try await purchaseEntitlements.restorePurchases()
        } catch let failure as PurchaseInteractionError {
            purchaseErrorAlert = failure.errorDescription
        } catch {
            purchaseErrorAlert = error.localizedDescription
        }
    }

    private func trialAction() async {
        purchaseErrorAlert = nil
        await purchaseEntitlements.attemptIntroTrialSignupIfEligible()
        await purchaseEntitlements.refreshEntitlementsFromStore()
        if !purchaseEntitlements.evaluation.allowsAppUse {
            purchaseErrorAlert = "StoreKit declined the introductory offer — use Restore if you subscribed already."
        }
    }
}
