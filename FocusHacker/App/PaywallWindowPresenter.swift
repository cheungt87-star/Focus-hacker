import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    /// Fired whenever the onboarding `NSWindow` closes (completed or discarded).
    static let focusHackerOnboardingChromeDismissed = Notification.Name("focushacker.onboarding.windowDismissedChrome")
}

@MainActor
final class PaywallWindowPresenter: NSObject, NSWindowDelegate {
    private weak var entitlementServiceWeak: PurchaseEntitlementService?

    private var window: NSWindow?
    private var unlockSink: AnyCancellable?

    /// Non-dismissible paywall layered like first-launch onboarding.
    func presentIfLocked(purchaseEntitlements: PurchaseEntitlementService) {
        entitlementServiceWeak = purchaseEntitlements

        unlockSink?.cancel()

        observeEvaluations(for: purchaseEntitlements)

        guard purchaseEntitlements.hasFinishedBootstrap else {
            return
        }

        guard !purchaseEntitlements.evaluation.allowsAppUse else {
            dismissIfNeeded()
            return
        }

        if window != nil {
            return
        }

        let rootView = PaywallView(purchaseEntitlements: purchaseEntitlements)

        let hosting = NSHostingController(rootView: rootView)
        let newWindow = NSWindow(contentViewController: hosting)
        newWindow.title = "Activate FocusHacker"
        newWindow.styleMask = [.titled]
        newWindow.standardWindowButton(.closeButton)?.isHidden = true
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.isMovableByWindowBackground = false
        newWindow.center()
        window = newWindow

        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
    }

    func dismissIfNeeded() {
        unlockSink?.cancel()
        unlockSink = nil
        guard let closing = window else { return }
        closing.close()
        window = nil
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard let entitlement = entitlementServiceWeak else {
            return true
        }
        return entitlement.evaluation.allowsAppUse
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func observeEvaluations(for service: PurchaseEntitlementService) {
        unlockSink = service.$evaluation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                guard let self else { return }
                if snapshot.allowsAppUse {
                    self.dismissIfNeeded()
                }
            }
    }
}
