import AppKit
import Foundation
import SwiftUI

extension Notification.Name {
    /// Posted after menubar panel NSAppearance is synced to the user's color theme preference.
    static let focusHackerMenuBarAppearanceChanged = Notification.Name("focushacker.menuBarAppearanceChanged")
}

enum MenuBarExtraAppearanceController {
    @MainActor
    static func apply(preference: AppearancePreference) {
        let appearanceName: NSAppearance.Name? = switch preference {
        case .light: .aqua
        case .dark: .darkAqua
        case .system: nil
        }

        for window in NSApp.windows where isMenuBarExtraPanel(window) {
            if let appearanceName {
                window.appearance = NSAppearance(named: appearanceName)
            } else {
                window.appearance = nil
            }
        }

        NotificationCenter.default.post(name: .focusHackerMenuBarAppearanceChanged, object: nil)
    }

    static func isMenuBarExtraPanel(_ window: NSWindow) -> Bool {
        window.className.contains("StatusBar")
            || window.className.contains("MenuBarExtra")
            || (window is NSPanel && window.level == .popUpMenu)
    }

    /// SwiftUI `.window` popover content — not the status-item chrome (`NSStatusBarWindow`).
    static func isMenuBarExtraPopoverWindow(_ window: NSWindow) -> Bool {
        window.className.contains("MenuBarExtraWindow")
    }
}

// MARK: - Popover presentation

@MainActor
enum MenuBarExtraPanelController {
    private static var localClickMonitor: Any?
    private static var globalClickMonitor: Any?
    private static var keyWindowObserver: NSObjectProtocol?

    static var hasVisiblePopover: Bool {
        !visiblePopoverWindows.isEmpty
    }

    private static var visiblePopoverWindows: [NSWindow] {
        NSApp.windows.filter {
            MenuBarExtraAppearanceController.isMenuBarExtraPopoverWindow($0) && $0.isVisible
        }
    }

    static func dismissPopover() {
        let windows = visiblePopoverWindows
        guard !windows.isEmpty else { return }
        for window in windows {
            window.orderOut(nil)
        }
        stopOutsideClickMonitoring()
    }

    static func beginOutsideClickMonitoring() {
        stopOutsideClickMonitoring()

        keyWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyWindow = notification.object as? NSWindow else { return }
            guard hasVisiblePopover else { return }
            if MenuBarExtraAppearanceController.isMenuBarExtraPopoverWindow(keyWindow) {
                return
            }
            dismissPopover()
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            guard hasVisiblePopover else { return event }
            if clickIsInsidePopover(NSEvent.mouseLocation) {
                return event
            }
            dismissPopover()
            return event
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in
                guard hasVisiblePopover else { return }
                if clickIsInsidePopover(NSEvent.mouseLocation) {
                    return
                }
                dismissPopover()
            }
        }
    }

    static func stopOutsideClickMonitoring() {
        if let keyWindowObserver {
            NotificationCenter.default.removeObserver(keyWindowObserver)
            self.keyWindowObserver = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }

    private static func clickIsInsidePopover(_ screenPoint: NSPoint) -> Bool {
        visiblePopoverWindows.contains { $0.frame.contains(screenPoint) }
    }
}

// MARK: - Panel height ↔ SwiftUI content

/// Resizes the `MenuBarExtra` window when SwiftUI content changes (e.g. preset stats ↔ custom configure form).
struct MenuBarExtraWindowSizeFitter: NSViewRepresentable {
    func makeNSView(context: Context) -> FitterHostingView {
        FitterHostingView()
    }

    func updateNSView(_ nsView: FitterHostingView, context: Context) {
        nsView.scheduleWindowResize()
    }

    final class FitterHostingView: NSView {
        private var pendingResize: DispatchWorkItem?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            scheduleWindowResize()
        }

        override func layout() {
            super.layout()
            scheduleWindowResize()
        }

        func scheduleWindowResize() {
            pendingResize?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.resizeWindowToFittingContent()
            }
            pendingResize = work
            DispatchQueue.main.async(execute: work)
        }

        private func resizeWindowToFittingContent() {
            guard let window,
                  MenuBarExtraAppearanceController.isMenuBarExtraPopoverWindow(window),
                  let contentView = window.contentView
            else { return }

            contentView.layoutSubtreeIfNeeded()
            let fittingSize = contentView.fittingSize
            guard fittingSize.width > 1, fittingSize.height > 1 else { return }

            let targetWidth = MenuBarPopoverLayout.width
            let maxHeight = MenuBarPopoverLayout.maxHeightBelowMenuBar(for: window)
            let targetHeight = min(fittingSize.height, maxHeight)

            var frame = window.frame
            let heightDelta = targetHeight - frame.size.height
            guard abs(heightDelta) > 0.5 || abs(frame.size.width - targetWidth) > 0.5 else { return }

            frame.size.width = targetWidth
            frame.size.height = targetHeight
            frame.origin.y -= heightDelta
            window.setFrame(frame, display: true, animate: window.isVisible)
        }
    }
}
