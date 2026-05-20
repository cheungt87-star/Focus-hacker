import AppKit
import SwiftUI

@MainActor
final class MainWindowPresenter: NSObject, ObservableObject {
    private var window: NSWindow?

    @available(macOS 14.0, *)
    func openWindow(viewModel: AppShellViewModel, purchaseEntitlements: PurchaseEntitlementService) {
        if window == nil {
            let contentView = MainWindowView(viewModel: viewModel, purchaseEntitlements: purchaseEntitlements)
                .frame(minWidth: 900, minHeight: 560)
            let hostingController = NSHostingController(rootView: contentView)
            let newWindow = NSWindow(contentViewController: hostingController)
            newWindow.title = "FocusHacker"
            newWindow.setContentSize(NSSize(width: 980, height: 620))
            newWindow.isReleasedWhenClosed = false
            newWindow.delegate = self
            window = newWindow
        }

        guard let window else {
            return
        }
        if let hostingController = window.contentViewController as? NSHostingController<MainWindowView> {
            // Rehydrate the root view on every open to avoid stale/cached split-view detail rendering.
            hostingController.rootView = MainWindowView(
                viewModel: viewModel,
                purchaseEntitlements: purchaseEntitlements
            )
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

extension MainWindowPresenter: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow, closedWindow == window else {
            return
        }
        closedWindow.orderOut(nil)
    }
}
