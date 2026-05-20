import Foundation
import os.log

/// Polls Safari tabs and redirects blocklisted URLs to the bundled blocked page during focus.
final class SafariBlockingScript: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.focushacker.app", category: "SafariBlocking")
    private let applicationName = "Safari"
    private let pollIntervalNanoseconds: UInt64 = 400_000_000
    private var pollTask: Task<Void, Never>?
    private(set) var permissionState: AutomationPermissionState = .unknown

    func start() {
        guard pollTask == nil else {
            return
        }
        pollTask = Task { [weak self] in
            guard let self else {
                return
            }
            while !Task.isCancelled {
                await self.pollOnce()
                try? await Task.sleep(nanoseconds: self.pollIntervalNanoseconds)
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func pollOnce() async {
        guard let blockedPage = BlockedPageGenerator.resolvedBlockedPageURLString() else {
            logger.error("blocked.html missing from app bundle")
            return
        }
        let payload = BrowserBlockingPolicy.currentPayload()
        switch BrowserAppleScriptRunner.runListTabs(applicationName: applicationName) {
        case .failure(let error):
            let state = BrowserAppleScriptRunner.permissionState(for: error)
            if state == .denied {
                permissionState = .denied
                logger.warning("Safari automation permission denied")
            }
            return
        case .success(let tabs):
            permissionState = .granted
            UserDefaults.standard.set(true, forKey: "blocker.automation.granted.Safari")
            for tab in tabs {
                guard let url = URL(string: tab.urlString) else {
                    continue
                }
                if BlockedPageURL.isBlockedPageURL(url) {
                    continue
                }
                guard BrowserBlockingPolicy.shouldBlock(url: url, payload: payload) else {
                    continue
                }
                _ = BrowserAppleScriptRunner.runRedirectTab(
                    applicationName: applicationName,
                    windowIndex: tab.windowIndex,
                    tabIndex: tab.tabIndex,
                    to: blockedPage
                )
            }
        }
    }
}
