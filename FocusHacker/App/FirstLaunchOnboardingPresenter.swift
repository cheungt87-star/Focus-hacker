import AppKit
import SwiftUI

@MainActor
final class FirstLaunchOnboardingPresenter: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func presentIfNeeded(dependencies: AppDependencies) {
        guard !dependencies.settingsStore.hasCompletedFullOnboarding else {
            return
        }

        if window != nil {
            return
        }

        let dismiss: () -> Void = { [weak self] in
            self?.window?.close()
            self?.window = nil
        }

        let viewModel = FirstLaunchOnboardingFlowViewModel(
            settingsStore: dependencies.settingsStore,
            blockerService: dependencies.blockerService,
            notificationAuthorization: dependencies.notificationAuthorization,
            dismissAfterCompletion: dismiss
        )

        let rootView = FirstLaunchOnboardingFlowView(viewModel: viewModel)
            .frame(minWidth: 560, minHeight: 540)

        let hostingController = NSHostingController(rootView: rootView)
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Welcome to FocusHacker"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        window = newWindow

        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing == window else {
            return
        }
        window = nil
        NotificationCenter.default.post(name: .focusHackerOnboardingChromeDismissed, object: nil)
    }
}
