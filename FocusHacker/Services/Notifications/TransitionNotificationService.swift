import AppKit
import Foundation
import UserNotifications

protocol TransitionNotificationHandling: AnyObject {
    func handleTransitionEvent(_ event: TimerTransitionEvent)
}

final class TransitionNotificationService: NSObject, TransitionNotificationHandling {
    private let center: UNUserNotificationCenter
    private var authorizationRequested = false

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func handleTransitionEvent(_ event: TimerTransitionEvent) {
        guard shouldScheduleNotifications else {
            return
        }
        requestAuthorizationIfNeeded()

        let payload = payload(for: event)
        guard let payload else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "transition.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}

private extension TransitionNotificationService {
    var shouldScheduleNotifications: Bool {
        NSApp?.isActive == false
    }

    func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else {
            return
        }
        authorizationRequested = true
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func payload(for event: TimerTransitionEvent) -> (title: String, body: String)? {
        switch event {
        case .focusStarted:
            return ("Focus started", "Get back to work.")
        case .shortRestStarted, .longRestStarted:
            return ("Rest started", "Take a short break.")
        case .sessionCompleted(let xpAwarded):
            return ("Session complete", "You earned \(xpAwarded) XP.")
        case .sessionEndedEarly:
            return ("Session ended early", "No XP awarded for this session.")
        }
    }
}
