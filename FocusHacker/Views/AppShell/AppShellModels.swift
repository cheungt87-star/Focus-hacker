import Foundation

enum AppShellSessionState: String, CaseIterable, Sendable {
    case idle
    case focus
    case rest

    var iconSymbolName: String {
        switch self {
        case .idle:
            return "pause.circle"
        case .focus:
            return "flame.circle.fill"
        case .rest:
            return "leaf.circle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .focus:
            return "Focus"
        case .rest:
            return "Rest"
        }
    }
}

enum AppShellSection: String, CaseIterable, Identifiable, Sendable {
    case history
    case timer
    case blockedItems
    case analytics
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timer:
            return "Timer"
        case .blockedItems:
            return "Blocked Items"
        case .analytics:
            return "Analytics"
        case .history:
            return "My profile"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .timer:
            return "timer"
        case .blockedItems:
            return "hand.raised"
        case .analytics:
            return "chart.bar"
        case .history:
            return "person.crop.circle"
        case .settings:
            return "gearshape"
        }
    }

    /// Sections shown in the main window sidebar (Timer is menu-bar / programmatic only).
    static var sidebarCases: [AppShellSection] {
        allCases.filter { $0 != .timer }
    }
}

struct AppShellState: Sendable {
    var sessionState: AppShellSessionState
    var countdownText: String
    var isSessionPaused: Bool
    /// Mirrored from `TimerSessionState.intervalPhase` while a session is active.
    var intervalPhase: TimerIntervalPhase?
    var remainingSeconds: Int
    var currentRound: Int?
    var totalRounds: Int?
    var currentCycle: Int?
    var totalCycles: Int?
    var elapsedSessionSeconds: Int
    var completedWorkSeconds: Int

    static let initial = AppShellState(
        sessionState: .idle,
        countdownText: "25:00",
        isSessionPaused: false,
        intervalPhase: nil,
        remainingSeconds: TimerConfiguration.default.focusDurationSeconds,
        currentRound: nil,
        totalRounds: nil,
        currentCycle: nil,
        totalCycles: nil,
        elapsedSessionSeconds: 0,
        completedWorkSeconds: 0
    )

    var sessionStateLabel: String {
        if isSessionPaused {
            return "Paused"
        }
        return sessionState.displayName
    }

    var roundProgressLabel: String? {
        guard
            let currentRound,
            let totalRounds,
            totalRounds > 0
        else {
            return nil
        }
        return "Round \(currentRound) of \(totalRounds)"
    }

    /// Fully completed focus intervals this session, aligned with `TimerService` round/cycle indexing. `nil` when idle or counters are absent.
    var completedPlannedFocusIntervals: Int? {
        guard sessionState != .idle,
              let tr = totalRounds, tr > 0,
              let tc = totalCycles, tc > 0,
              let cy = currentCycle, cy >= 1,
              let r = currentRound, r >= 1,
              let phase = intervalPhase
        else {
            return nil
        }
        switch phase {
        case .focus:
            return (cy - 1) * tr + (r - 1)
        case .shortRest:
            return (cy - 1) * tr + r
        case .longRest:
            return cy * tr
        }
    }

    /// Same counts as `roundProgressLabel`, copy tuned for timer hero ("Session").
    var sessionOrdinalLabel: String? {
        guard
            let currentRound,
            let totalRounds,
            totalRounds > 0
        else {
            return nil
        }
        return "Session \(currentRound) of \(totalRounds)"
    }

    var cycleProgressLabel: String? {
        guard
            let currentCycle,
            let totalCycles,
            totalCycles > 1
        else {
            return nil
        }
        return "Cycle \(currentCycle) of \(totalCycles)"
    }

    var menuBarPresentation: AppShellMenuBarPresentation {
        if sessionState == .idle {
            return .neutral
        }
        if isSessionPaused {
            return .paused
        }
        switch sessionState {
        case .focus:
            return .focus
        case .rest:
            return .rest
        case .idle:
            return .neutral
        }
    }

    var menuBarText: String {
        switch menuBarPresentation {
        case .neutral:
            return "FocusHacker"
        case .focus:
            return "FOCUS: \(countdownText)"
        case .rest:
            return "REST: \(countdownText)"
        case .paused:
            return "PAUSED: \(countdownText)"
        }
    }

    /// Suffix for the focus menu bar pill, e.g. `"1 of 4"`. Nil when not in focus or only one round is configured.
    var menuBarFocusRoundSuffix: String? {
        guard menuBarPresentation == .focus,
              let currentRound,
              let totalRounds,
              totalRounds > 1
        else {
            return nil
        }
        return "\(currentRound) of \(totalRounds)"
    }

    var menuBarPillText: String {
        guard let suffix = menuBarFocusRoundSuffix else {
            return menuBarText
        }
        return "\(menuBarText) · \(suffix)"
    }

    /// Shorter status-item copy (no round suffix; space-separated phase label).
    var menuBarCompactPillText: String {
        switch menuBarPresentation {
        case .neutral:
            return menuBarText
        case .focus:
            return "FOCUS \(countdownText)"
        case .rest:
            return "REST \(countdownText)"
        case .paused:
            return "PAUSED \(countdownText)"
        }
    }

    var menuBarShouldFlash: Bool {
        !isSessionPaused && sessionState != .idle && remainingSeconds <= AppShellMenuBarMetrics.flashThresholdSeconds
    }

    var menuBarAccessibilityLabel: String {
        switch menuBarPresentation {
        case .neutral:
            return "FocusHacker idle"
        case .focus:
            if let suffix = menuBarFocusRoundSuffix {
                return "Focus, \(countdownText) remaining, round \(suffix)"
            }
            return "Focus, \(countdownText) remaining"
        case .rest:
            return "Rest, \(countdownText) remaining"
        case .paused:
            return "Paused, \(countdownText) remaining"
        }
    }
}

enum AppShellMenuBarMetrics {
    /// Menu bar pill opacity flash begins when this many seconds remain in the interval.
    static let flashThresholdSeconds = 20
}

enum AppShellMenuBarPresentation: Sendable {
    case neutral
    case focus
    case rest
    case paused
}

/// Next interval after the current countdown completes — mirrors `TimerService.advanceAfterIntervalCompletion`.
struct TimerNextIntervalPreview: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case focus
        case shortRest
        case longRest
        case sessionComplete
    }

    let kind: Kind
    let durationSeconds: Int?

    var footerPhaseName: String {
        switch kind {
        case .focus:
            return "Focus"
        case .shortRest:
            return "Short break"
        case .longRest:
            return "Session break"
        case .sessionComplete:
            return "Done"
        }
    }

    static func resolve(configuration cfg: TimerConfiguration, state: AppShellState) -> TimerNextIntervalPreview {
        if state.sessionState == .idle || state.intervalPhase == nil {
            return TimerNextIntervalPreview(kind: .focus, durationSeconds: cfg.focusDurationSeconds)
        }

        guard
            let phase = state.intervalPhase,
            let currentRound = state.currentRound,
            let totalRounds = state.totalRounds,
            let currentCycle = state.currentCycle,
            let totalCycles = state.totalCycles,
            totalRounds > 0
        else {
            return TimerNextIntervalPreview(kind: .focus, durationSeconds: cfg.focusDurationSeconds)
        }

        let cycles = max(1, cfg.cyclesPerSession)

        switch phase {
        case .focus:
            if currentRound < totalRounds {
                return TimerNextIntervalPreview(kind: .shortRest, durationSeconds: cfg.shortRestDurationSeconds)
            }
            if currentCycle < cycles {
                if cfg.longRestDurationSeconds > 0 {
                    return TimerNextIntervalPreview(kind: .longRest, durationSeconds: cfg.longRestDurationSeconds)
                }
                return TimerNextIntervalPreview(kind: .focus, durationSeconds: cfg.focusDurationSeconds)
            }
            if cycles == 1, cfg.longRestDurationSeconds > 0 {
                return TimerNextIntervalPreview(kind: .longRest, durationSeconds: cfg.longRestDurationSeconds)
            }
            return TimerNextIntervalPreview(kind: .sessionComplete, durationSeconds: nil)
        case .shortRest:
            return TimerNextIntervalPreview(kind: .focus, durationSeconds: cfg.focusDurationSeconds)
        case .longRest:
            if currentCycle < totalCycles {
                return TimerNextIntervalPreview(kind: .focus, durationSeconds: cfg.focusDurationSeconds)
            }
            return TimerNextIntervalPreview(kind: .sessionComplete, durationSeconds: nil)
        }
    }
}
