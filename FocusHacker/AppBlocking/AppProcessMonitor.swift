import AppKit
import Foundation
import os.log

/// Terminates blocked native apps when they launch during an active focus blocking lease.
final class AppProcessMonitor: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.focushacker.app", category: "AppProcessMonitor")
    private let workspace: NSWorkspace
    private let lock = NSLock()
    private var isMonitoring = false
    private var launchObserver: NSObjectProtocol?

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func setActive(_ isActive: Bool) {
        guard AppBlockingConfiguration.isEnabled else {
            if isMonitoring {
                stop()
            }
            return
        }
        lock.lock()
        if isActive {
            if !isMonitoring {
                startLocked()
            }
        } else if isMonitoring {
            stopLocked()
        }
        lock.unlock()
    }

    private func startLocked() {
        isMonitoring = true
        launchObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleApplicationLaunch(notification)
        }
        logger.info("App launch monitor started")
        DispatchQueue.main.async { [weak self] in
            self?.terminateAlreadyRunningBlockedApps()
        }
    }

    private func stopLocked() {
        isMonitoring = false
        if let launchObserver {
            workspace.notificationCenter.removeObserver(launchObserver)
            self.launchObserver = nil
        }
        AppBlockingNotification.clearDebounceState()
        logger.info("App launch monitor stopped")
    }

    private func stop() {
        lock.lock()
        if isMonitoring {
            stopLocked()
        }
        lock.unlock()
    }

    private func handleApplicationLaunch(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        processRunningApplication(application)
    }

    /// Terminates blocked apps that were already running when focus blocking turns on.
    private func terminateAlreadyRunningBlockedApps() {
        guard isMonitoring else {
            return
        }
        let payload = AppBlockingPolicy.currentPayload()
        let leaseValid = payload.map {
            BlockerAppGroup.isBlockingLeaseValid(
                isActive: $0.blockingIsActive,
                leaseUntilReference: $0.blockingLeaseExpiresAtReference
            )
        } ?? false
        guard leaseValid else {
            return
        }

        let hostBundleID = Bundle.main.bundleIdentifier
        let hostPID = ProcessInfo.processInfo.processIdentifier

        for application in workspace.runningApplications {
            if application.processIdentifier == hostPID {
                continue
            }
            if let hostBundleID, application.bundleIdentifier == hostBundleID {
                continue
            }
            processRunningApplication(application)
        }
    }

    @discardableResult
    private func processRunningApplication(_ application: NSRunningApplication) -> Bool {
        let bundleIdentifier = application.bundleIdentifier ?? ""
        guard !bundleIdentifier.isEmpty else {
            return false
        }
        if BlockedAppsRegistry.isProtectedSystemApp(bundleIdentifier: bundleIdentifier) {
            return false
        }

        let payload = AppBlockingPolicy.currentPayload()
        let blockedBundleIDs = payload?.blockedBundleIDs ?? BlockedAppsRegistry.currentBlockedBundleIDs()
        guard AppBlockingPolicy.shouldTerminate(
            bundleIdentifier: bundleIdentifier,
            payload: payload,
            blockedBundleIdentifiers: blockedBundleIDs
        ) else {
            return false
        }

        let termination = terminateBlockedApplication(application)
        logger.info(
            "Terminated blocked app \(bundleIdentifier, privacy: .public) graceful=\(termination.gracefulSent, privacy: .public) force=\(termination.forceSent, privacy: .public)"
        )

        let leaseUntil = payload?.blockingLeaseExpiresAtReference ?? 0
        AppBlockingNotification.postIfNeeded(
            bundleIdentifier: bundleIdentifier,
            leaseUntilReference: leaseUntil
        )
        return termination.gracefulSent || termination.forceSent
    }

    /// Graceful quit first; WhatsApp and some Catalyst apps ignore it while still appearing in `runningApplications`.
    private func terminateBlockedApplication(_ application: NSRunningApplication) -> (gracefulSent: Bool, forceSent: Bool) {
        let gracefulSent = application.terminate()
        if application.isTerminated {
            return (gracefulSent, false)
        }
        let forceSent = application.forceTerminate()
        return (gracefulSent, forceSent)
    }
}
