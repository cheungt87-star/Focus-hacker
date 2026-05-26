import AppKit

/// AppKit window that refuses native full-screen space transitions.
final class NonFullScreenWindow: NSWindow {
    override func toggleFullScreen(_ sender: Any?) {
        // Block View > Enter Full Screen, the green button, and keyboard shortcuts.
    }
}

enum AppWindowChrome {
    static func makeWindow(contentViewController: NSViewController) -> NSWindow {
        NonFullScreenWindow(contentViewController: contentViewController)
    }

    /// Re-apply on create and whenever the window is shown; AppKit/SwiftUI can reset flags.
    static func applyNoFullScreenPolicy(to window: NSWindow) {
        var behavior = window.collectionBehavior
        behavior.remove(.fullScreenPrimary)
        behavior.insert(.fullScreenNone)
        behavior.insert(.fullScreenAuxiliary)
        window.collectionBehavior = behavior

        if let zoomButton = window.standardWindowButton(.zoomButton) {
            zoomButton.isEnabled = false
            zoomButton.toolTip = nil
        }
    }

    static func exitFullScreenIfNeeded(_ window: NSWindow) {
        guard window.styleMask.contains(.fullScreen) else { return }
        window.toggleFullScreen(nil)
    }
}
