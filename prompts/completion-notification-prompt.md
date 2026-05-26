# Implementation Prompt: Focus Session Completion Notification

## Goal

Upgrade the existing `sessionCompleted` macOS notification to be celebratory and informative. Show focus time, XP earned, and current daily streak. Add a "View Stats" action button that opens the main window.

---

## Current state

`TransitionNotificationService` already fires a `UNNotificationRequest` on `sessionCompleted`, but only when the app is backgrounded (`NSApp?.isActive == false`). The current body text is: `"Focus session complete. Well done! Come back for more focus! You earned X XP."` — no focus duration, no streak, no action buttons.

`TimerTransitionEvent.sessionCompleted(xpAwarded: Int)` carries XP but not focus minutes or streak. Both are available at the call site in `TimerService.completeSession()` — `focusMinutes` is a local variable there.

---

## Step 1 — Enrich `TimerTransitionEvent.sessionCompleted`

In `FocusHacker/Services/ServiceProtocols.swift`, update the enum case:

```swift
// Before
case sessionCompleted(xpAwarded: Int)

// After
case sessionCompleted(xpAwarded: Int, focusMinutes: Int, streakDays: Int)
```

`streakDays` is the updated daily streak **after** the session has been recorded. Read it from `GamificationDashboardReader` (or `FocusStreakCalculator` directly) immediately after `sessionRecorder.recordSessionCompleted(...)` succeeds in `TimerService.completeSession()`. Use `0` as a safe fallback if the read throws.

In `TimerService.completeSession()`, replace:

```swift
publishTransition(.sessionCompleted(xpAwarded: xpAwarded))
```

with:

```swift
let streakDays = (try? await /* read streak from GamificationDashboardReader */) ?? 0
publishTransition(.sessionCompleted(xpAwarded: xpAwarded, focusMinutes: focusMinutes, streakDays: streakDays))
```

Fix all exhaustive switch sites that pattern-match `sessionCompleted` — the compiler will surface them. They are in:
- `TransitionNotificationService` (`payload(for:)`)
- `AudioCueService` (`voicePhrase(for:)`, `chimeSoundName(for:)`)
- `AppShellViewModel` (`apply(transitionEvent:)`)

---

## Step 2 — Register a notification category with action buttons

In `TransitionNotificationService`, add a private method and call it from `init`:

```swift
private static let categoryIdentifier = "SESSION_COMPLETED"
private static let viewStatsActionIdentifier = "VIEW_STATS"

private func registerNotificationCategory() {
    let viewStats = UNNotificationAction(
        identifier: Self.viewStatsActionIdentifier,
        title: "View Stats",
        options: [.foreground]   // .foreground brings the app to front
    )
    let category = UNNotificationCategory(
        identifier: Self.categoryIdentifier,
        actions: [viewStats],
        intentIdentifiers: [],
        options: []
    )
    center.setNotificationCategories([category])
}
```

Call `registerNotificationCategory()` at the end of `init`.

---

## Step 3 — Update the notification payload

Update `payload(for:)` in `TransitionNotificationService`:

```swift
case let .sessionCompleted(xpAwarded, focusMinutes, streakDays):
    let title = "Session complete — nice work 🎉"
    var parts: [String] = []
    if focusMinutes > 0 {
        parts.append("\(focusMinutes) min")
    }
    if xpAwarded > 0 {
        parts.append("+\(xpAwarded) XP")
    }
    if streakDays > 1 {
        parts.append("🔥 \(streakDays)-day streak")
    }
    let body = parts.joined(separator: " · ")
    return (title: title, body: body.isEmpty ? "Well done!" : body)
```

In `handleTransitionEvent(_:)`, attach the category to the content:

```swift
if case .sessionCompleted = event {
    content.categoryIdentifier = Self.categoryIdentifier
}
```

---

## Step 4 — Handle the "View Stats" action

`TransitionNotificationService` needs to open the main window when the user taps "View Stats". The cleanest approach is a closure injected at init:

```swift
// Add to TransitionNotificationService
var onViewStatsRequested: (() -> Void)?
```

Set `TransitionNotificationService` as the `UNUserNotificationCenter` delegate (it already subclasses `NSObject`):

```swift
// In init, after registerNotificationCategory()
center.delegate = self

// Add extension
extension TransitionNotificationService: UNUserNotificationCenterDelegate {

    // Show notifications even when app is foregrounded (optional — remove if you
    // want to keep the existing guard that suppresses when app is active)
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
```

---

## Step 5 — Wire `onViewStatsRequested` to open the main window

In `AppDependencies` (or wherever `TransitionNotificationService` is instantiated), after creating the service, set the closure:

```swift
transitionNotificationService.onViewStatsRequested = { [weak mainWindowPresenter, weak viewModel, weak purchaseEntitlements] in
    guard let presenter = mainWindowPresenter,
          let vm = viewModel,
          let entitlements = purchaseEntitlements else { return }
    presenter.openWindow(viewModel: vm, purchaseEntitlements: entitlements)
}
```

`MainWindowPresenter.openWindow(viewModel:purchaseEntitlements:)` already exists and handles the bring-to-front / create-if-needed logic.

---

## Step 6 — Remove or relax the `isActive` guard (optional)

Currently notifications are suppressed when the app is active:

```swift
var shouldScheduleNotifications: Bool {
    NSApp?.isActive == false
}
```

For the completion notification specifically, you may want to fire it regardless (since the user might be in another app briefly when the timer finishes). If so, override the guard only for `sessionCompleted`:

```swift
func handleTransitionEvent(_ event: TimerTransitionEvent) {
    let isCompletion: Bool
    if case .sessionCompleted = event { isCompletion = true } else { isCompletion = false }

    guard shouldScheduleNotifications || isCompletion else { return }
    // ...
}
```

---

## Files to change

| File | Change |
|---|---|
| `Services/ServiceProtocols.swift` | Add `focusMinutes` and `streakDays` to `sessionCompleted` |
| `Services/Timer/TimerService.swift` | Read streak after record; pass to `publishTransition` |
| `Services/Notifications/TransitionNotificationService.swift` | Register category, richer payload, delegate, `onViewStatsRequested` closure |
| `Services/Audio/AudioCueService.swift` | Update exhaustive switch (no logic change needed) |
| `Views/AppShell/AppShellViewModel.swift` | Update exhaustive switch; pass new fields to `completionBannerText` if desired |
| `App/AppDependencies.swift` | Wire `onViewStatsRequested` closure |

---

## What to leave alone

- `menuBarText` / `menuBarPill*` symbols — out of scope per spec
- `NotificationAuthorizationService` — already handles permission; no changes needed
- `completionBannerText` in `AppShellViewModel` — separate in-app banner, unrelated to this work
- All other `TimerTransitionEvent` cases
