import AppKit
import SwiftUI

@MainActor
final class MainWindowPresenter: NSObject, ObservableObject {
    private var window: NSWindow?

    @available(macOS 14.0, *)
    func openWindow(viewModel: AppShellViewModel, purchaseEntitlements: PurchaseEntitlementService) {
        // #region agent log
        let openStart = CFAbsoluteTimeGetCurrent()
        DebugSessionLog82afba.write(
            hypothesisId: "H4",
            location: "MainWindowPresenter.openWindow",
            message: "open_started",
            data: [
                "reusingWindow": "\(window != nil)",
                "section": viewModel.selectedSection.rawValue,
            ]
        )
        // #endregion
        if window == nil {
            let contentView = MainWindowView(viewModel: viewModel, purchaseEntitlements: purchaseEntitlements)
                .frame(minWidth: 900, minHeight: 560)
            let hostingController = NSHostingController(rootView: contentView)
            let newWindow = AppWindowChrome.makeWindow(contentViewController: hostingController)
            newWindow.title = "FocusHacker"
            AppWindowChrome.applyNoFullScreenPolicy(to: newWindow)
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
        AppWindowChrome.applyNoFullScreenPolicy(to: window)
        AppWindowChrome.exitFullScreenIfNeeded(window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        // #region agent log
        let openMs = Int((CFAbsoluteTimeGetCurrent() - openStart) * 1000)
        DebugSessionLog82afba.write(
            hypothesisId: "H4",
            location: "MainWindowPresenter.openWindow",
            message: "open_finished",
            data: ["durationMs": "\(openMs)"]
        )
        // #endregion
    }
}

extension MainWindowPresenter: NSWindowDelegate {
    func windowWillEnterFullScreen(_ notification: Notification) {
        guard let entering = notification.object as? NSWindow, entering == window else {
            return
        }
        DispatchQueue.main.async {
            AppWindowChrome.exitFullScreenIfNeeded(entering)
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow, closedWindow == window else {
            return
        }
        closedWindow.orderOut(nil)
    }
}
