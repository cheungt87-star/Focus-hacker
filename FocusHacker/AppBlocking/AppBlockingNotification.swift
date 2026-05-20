import Foundation
import UserNotifications

enum AppBlockingNotification {
    private static let center = UNUserNotificationCenter.current()
    private static var authorizationRequested = false
    private static let lock = NSLock()
    private static var lastPostedAtByBundleID: [String: Date] = [:]
    private static let debounceInterval: TimeInterval = 30

    static func postIfNeeded(bundleIdentifier: String, leaseUntilReference: Double) {
        lock.lock()
        let now = Date()
        if let lastPosted = lastPostedAtByBundleID[bundleIdentifier],
           now.timeIntervalSince(lastPosted) < debounceInterval {
            lock.unlock()
            return
        }
        lastPostedAtByBundleID[bundleIdentifier] = now
        lock.unlock()

        requestAuthorizationIfNeeded()

        let displayInfo = BlockedAppDisplayInfoResolver.resolve(bundleIdentifier: bundleIdentifier)
        let untilPhrase = untilPhrase(leaseUntilReference: leaseUntilReference, now: now)

        let content = UNMutableNotificationContent()
        content.title = displayInfo.displayName
        content.body = "\(displayInfo.displayName) is blocked \(untilPhrase)"

        let request = UNNotificationRequest(
            identifier: "app-block.\(bundleIdentifier)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    static func clearDebounceState() {
        lock.lock()
        lastPostedAtByBundleID.removeAll()
        lock.unlock()
    }

    private static func requestAuthorizationIfNeeded() {
        lock.lock()
        let alreadyRequested = authorizationRequested
        if !alreadyRequested {
            authorizationRequested = true
        }
        lock.unlock()
        guard !alreadyRequested else {
            return
        }
        center.requestAuthorization(options: [.alert]) { _, _ in }
    }

    private static func untilPhrase(leaseUntilReference: Double, now: Date) -> String {
        guard leaseUntilReference > 0 else {
            return "until your focus session ends"
        }
        let leaseEnd = Date(timeIntervalSinceReferenceDate: leaseUntilReference)
        guard leaseEnd > now else {
            return "until your focus session ends"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "until \(formatter.string(from: leaseEnd))"
    }
}
