import Foundation
import os.log

/// Host-side coordinator for Safari/Chrome tab blocking and native app launch termination during focus intervals.
final class AutomationCoordinator: @unchecked Sendable {
    static let shared = AutomationCoordinator()

    private let logger = Logger(subsystem: "com.focushacker.app", category: "AutomationCoordinator")
    private let safariScript = SafariBlockingScript()
    private let chromeScript = ChromeBlockingScript()
    private let appProcessMonitor = AppProcessMonitor()
    private let lock = NSLock()
    private var isBrowserMonitoring = false

    private init() {}

    var safariPermissionState: AutomationPermissionState {
        safariScript.permissionState
    }

    var chromePermissionState: AutomationPermissionState {
        chromeScript.permissionState
    }

    func setBlockingActive(_ isActive: Bool) {
        appProcessMonitor.setActive(isActive)

        lock.lock()
        if isActive {
            if !isBrowserMonitoring {
                AutomationPermissionPrimer.ensurePermissionsBeforeMonitoring()
                isBrowserMonitoring = true
                safariScript.start()
                chromeScript.start()
                logger.info("Browser automation monitoring started")
            }
        } else {
            if isBrowserMonitoring {
                isBrowserMonitoring = false
                safariScript.stop()
                chromeScript.stop()
                logger.info("Browser automation monitoring stopped")
            }
        }
        lock.unlock()
    }

    /// Resync when the app launches or becomes active while a focus interval is already running.
    func resyncFromTimer(_ timerService: TimerServiceProtocol) async {
        let state = await timerService.currentSessionState()
        let shouldMonitor = state.lifecycleState == .running && state.intervalPhase == .focus
        setBlockingActive(shouldMonitor)
    }
}
