import AppKit
import Foundation

extension Notification.Name {
    /// Posted after `NSApplication.setActivationPolicy` runs so the Help menu can be re-synced.
    static let focusHackerActivationPolicyChanged = Notification.Name("focushacker.activationPolicyChanged")
}

enum DockIconVisibilityController {
    @MainActor
    static func apply(showsDockIcon: Bool) {
        let policy: NSApplication.ActivationPolicy = showsDockIcon ? .regular : .accessory
        _ = NSApplication.shared.setActivationPolicy(policy)
        NotificationCenter.default.post(name: .focusHackerActivationPolicyChanged, object: nil)
    }
}
