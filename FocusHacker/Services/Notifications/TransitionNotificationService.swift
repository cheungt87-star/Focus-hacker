import AppKit
import Foundation
import UserNotifications

protocol TransitionNotificationHandling: AnyObject {
    func handleTransitionEvent(_ event: TimerTransitionEvent)
    var onCompletionNotificationSuppressed: (() -> Void)? { get set }
}

final class TransitionNotificationService: NSObject, TransitionNotificationHandling {
    private static let categoryIdentifier = "SESSION_COMPLETED"
    private static let viewStatsActionIdentifier = "VIEW_STATS"

    private let center: UNUserNotificationCenter
    private var authorizationRequestInFlight = false

    var onViewStatsRequested: (() -> Void)?
    var onCompletionNotificationSuppressed: (() -> Void)?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        registerNotificationCategory()
        center.delegate = self
    }

    func handleTransitionEvent(_ event: TimerTransitionEvent) {
        let isCompletion: Bool
        if case .sessionCompleted = event {
            isCompletion = true
        } else {
            isCompletion = false
        }

        guard shouldScheduleNotifications || isCompletion else {
            return
        }

        guard let payload = payload(for: event) else {
            return
        }

        center.getNotificationSettings { [weak self] settings in
            self?.deliverNotificationIfPermitted(
                payload: payload,
                event: event,
                isCompletion: isCompletion,
                settings: settings
            )
        }
    }

    /// Formats completion notification copy for tests and `payload(for:)`.
    static func completionPayload(
        xpAwarded: Int,
        focusMinutes: Int,
        focusSeconds: Int
    ) -> (title: String, body: String) {
        let title = "Session complete — nice work 🎉"
        let displayMinutes = displayFocusMinutes(focusMinutes: focusMinutes, focusSeconds: focusSeconds)
        let focusLabel = ProfileChartAxisLabels.tooltipFocusDuration(minutes: displayMinutes)
        let body = "Focus time: \(focusLabel) +\(max(0, xpAwarded))xp"
        return (title: title, body: body)
    }

    static func displayFocusMinutes(focusMinutes: Int, focusSeconds: Int) -> Int {
        let fromSeconds = max(0, focusSeconds + 59) / 60
        return max(max(0, focusMinutes), fromSeconds)
    }
}

extension TransitionNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == Self.viewStatsActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.onViewStatsRequested?()
            }
        }
        completionHandler()
    }
}

private extension TransitionNotificationService {
    var shouldScheduleNotifications: Bool {
        NSApp?.isActive == false
    }

    func registerNotificationCategory() {
        let viewStats = UNNotificationAction(
            identifier: Self.viewStatsActionIdentifier,
            title: "View Stats",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [viewStats],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func deliverNotificationIfPermitted(
        payload: (title: String, body: String),
        event: TimerTransitionEvent,
        isCompletion: Bool,
        settings: UNNotificationSettings
    ) {
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            scheduleNotification(payload: payload, event: event)
        case .notDetermined:
            requestAuthorization { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.scheduleNotification(payload: payload, event: event)
                } else if isCompletion {
                    self.notifyCompletionSuppressed()
                }
            }
        case .denied:
            if isCompletion {
                notifyCompletionSuppressed()
            }
        @unknown default:
            if isCompletion {
                notifyCompletionSuppressed()
            }
        }
    }

    func scheduleNotification(
        payload: (title: String, body: String),
        event: TimerTransitionEvent
    ) {
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default
        if case .sessionCompleted = event {
            content.categoryIdentifier = Self.categoryIdentifier
        }

        let request = UNNotificationRequest(
            identifier: "transition.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard !authorizationRequestInFlight else {
            return
        }
        authorizationRequestInFlight = true
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            self?.authorizationRequestInFlight = false
            completion(granted)
        }
    }

    func notifyCompletionSuppressed() {
        DispatchQueue.main.async { [weak self] in
            self?.onCompletionNotificationSuppressed?()
        }
    }

    func payload(for event: TimerTransitionEvent) -> (title: String, body: String)? {
        switch event {
        case .focusStarted:
            return ("Focus started", "Time to work, Let's Focus!")
        case .shortRestStarted, .longRestStarted:
            return ("Rest started", "It's time to have a short break!. Take a rest!")
        case let .sessionCompleted(xpAwarded, focusMinutes, focusSeconds):
            return Self.completionPayload(
                xpAwarded: xpAwarded,
                focusMinutes: focusMinutes,
                focusSeconds: focusSeconds
            )
        case .sessionEndedEarly(let xpAwarded):
            if xpAwarded > 0 {
                return ("Session ended early", "You earned \(xpAwarded) XP.")
            }
            return ("Session ended early", "Keep going — finish a session for bonus XP.")
        }
    }
}
