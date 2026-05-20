import Foundation

enum TimerIntervalPhase: String, Sendable, Equatable {
    case focus
    case shortRest
    case longRest
}

enum TimerLifecycleState: String, Sendable, Equatable {
    case idle
    case running
    case paused
    case completed
    case endedEarly
}

struct TimerConfiguration: Sendable, Equatable {
    var focusDurationSeconds: Int
    var shortRestDurationSeconds: Int
    var longRestDurationSeconds: Int
    /// Focus intervals per cycle (each cycle is `roundsPerSession` work segments plus short rests between them).
    var roundsPerSession: Int
    /// How many times the round-block repeats. `1` matches legacy single-block sessions.
    var cyclesPerSession: Int

    static let `default` = TimerConfiguration(
        focusDurationSeconds: 25 * 60,
        shortRestDurationSeconds: 5 * 60,
        longRestDurationSeconds: 15 * 60,
        roundsPerSession: 4,
        cyclesPerSession: 1
    )

    static func splitDuration(seconds totalSeconds: Int) -> (minutes: Int, seconds: Int) {
        let bounded = max(0, totalSeconds)
        return (bounded / 60, bounded % 60)
    }

    static func composeDuration(minutes: Int, seconds: Int) -> Int {
        max(0, minutes) * 60 + max(0, seconds)
    }

    /// Focus + rests for a configured session.
    /// Exact seconds; used for menubar previews and a single source for rounded-minute estimates.
    var plannedWallClockSecondsExcludingTransitions: Int {
        let R = max(0, roundsPerSession)
        let C = max(0, cyclesPerSession)
        let focusSeg = max(0, focusDurationSeconds)
        let shortSeg = max(0, shortRestDurationSeconds)
        let longSeg = max(0, longRestDurationSeconds)
        let perCycle = R * focusSeg + max(0, R - 1) * shortSeg
        let totalSeconds: Int
        if C <= 0 || R <= 0 {
            totalSeconds = 0
        } else if C == 1 {
            let trailingLong = longSeg > 0 ? longSeg : 0
            totalSeconds = perCycle + trailingLong
        } else {
            totalSeconds = C * perCycle + max(0, C - 1) * longSeg
        }
        return max(0, totalSeconds)
    }

    /// Total configured focus time (all work segments), excluding rests.
    var plannedTotalFocusSeconds: Int {
        let R = max(0, roundsPerSession)
        let C = max(0, cyclesPerSession)
        let focusSeg = max(0, focusDurationSeconds)
        return R * C * focusSeg
    }

    /// Number of focus intervals in the plan (`roundsPerSession` × `cyclesPerSession`). Matches session completion bookkeeping.
    var plannedFocusIntervalCount: Int {
        let R = max(0, roundsPerSession)
        let C = max(0, cyclesPerSession)
        return R * C
    }

    /// Focus + rests for a configured session.
    var approximateWallClockMinutes: Int {
        let totalSeconds = plannedWallClockSecondsExcludingTransitions
        let roundedMinutes = Int((Double(totalSeconds) / 60.0).rounded())
        return max(0, roundedMinutes)
    }

    /// Same basis as `approximateWallClockMinutes`, in exact seconds (for session progress UI).
    var approximateWallClockSeconds: Int {
        let exact = plannedWallClockSecondsExcludingTransitions
        return max(1, exact)
    }
}

struct TimerSessionState: Sendable, Equatable {
    var lifecycleState: TimerLifecycleState
    var intervalPhase: TimerIntervalPhase?
    var remainingSeconds: Int
    var currentRound: Int
    var totalRounds: Int
    var currentCycle: Int
    var totalCycles: Int
    var completedFocusMinutes: Int
    /// Running time while the session ticker is active (excludes paused intervals).
    var elapsedSessionSeconds: Int
    /// Cumulative focus seconds for this session, including the current focus interval so far.
    var completedWorkSeconds: Int

    static let idle = TimerSessionState(
        lifecycleState: .idle,
        intervalPhase: nil,
        remainingSeconds: TimerConfiguration.default.focusDurationSeconds,
        currentRound: 0,
        totalRounds: 0,
        currentCycle: 0,
        totalCycles: 0,
        completedFocusMinutes: 0,
        elapsedSessionSeconds: 0,
        completedWorkSeconds: 0
    )
}

enum TimerTransitionEvent: Sendable, Equatable {
    case focusStarted(round: Int, totalRounds: Int)
    case shortRestStarted(round: Int, totalRounds: Int)
    case longRestStarted
    case sessionCompleted(xpAwarded: Int)
    case sessionEndedEarly
}

protocol TimerServiceProtocol: Sendable {
    func sessionStateStream() -> AsyncStream<TimerSessionState>
    func transitionEventStream() -> AsyncStream<TimerTransitionEvent>
    func startSession(configuration: TimerConfiguration) async
    func pauseSession() async
    func resumeSession() async
    func endSession() async
    /// Jumps to the next interval immediately.
    func skipToNextPhase() async
    /// Restores the current phase duration to its configured length (running or paused).
    func restartCurrentInterval() async
    /// While a focus interval is running, re-publishes blocking without a filter bounce (app resume / heal).
    func resyncBlockingForRunningFocusIfNeeded() async
    /// Snapshot of timer state (diagnostics / debug instrumentation).
    func currentSessionState() async -> TimerSessionState
}

protocol BlockerServiceProtocol: Sendable {
    /// - Parameter bounceFilterConnectionsOnActivate: When `true` and `isActive` is `true`, briefly toggles
    ///   `NEFilterManager` so sockets allowed while paused (invalid lease) cannot bypass rules after resume.
    /// - Parameter blockingEpoch: When `isActive` is `true`, written to the App Group suite and mirrored into `/Users/Shared` JSON for log correlation; pass `nil` to keep any existing epoch.
    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async
    /// Extends `/Users/Shared` lease while focus blocking is on (timer / wake / activation).
    func refreshBlockingLeaseIfActive() async
    /// While blocking is active, clears merged IP literals and re-resolves from the current blocklist (call after edits).
    func refreshBlockedIPLiteralsAfterBlocklistChange() async
    /// Host-only mirror of blocklist rows into `/Users/Shared` JSON (suite must already be updated).
    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async
}

extension BlockerServiceProtocol {
    func setBlockingActive(_ isActive: Bool, bounceFilterConnectionsOnActivate: Bool, blockingEpoch: String?) async {
        await setBlockingActive(
            isActive,
            bounceFilterConnectionsOnActivate: bounceFilterConnectionsOnActivate,
            blockingEpoch: blockingEpoch,
            tearDownStaleConnectionsOnActivate: false
        )
    }

    func setBlockingActive(_ isActive: Bool, bounceFilterConnectionsOnActivate: Bool) async {
        await setBlockingActive(isActive, bounceFilterConnectionsOnActivate: bounceFilterConnectionsOnActivate, blockingEpoch: nil)
    }

    func setBlockingActive(_ isActive: Bool) async {
        await setBlockingActive(isActive, bounceFilterConnectionsOnActivate: false, blockingEpoch: nil)
    }
}

protocol NotificationAuthorizationServing: Sendable {
    func requestAuthorization() async -> Bool
}

protocol NetworkExtensionBridgeProtocol: Sendable {
    func sendBlockingState(
        isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async
    func refreshLeaseIfBlockingActive() async
    func refreshBlockedIPLiteralsAfterBlocklistChange() async
}

extension NetworkExtensionBridgeProtocol {
    func sendBlockingState(isActive: Bool, bounceFilterConnectionsOnActivate: Bool, blockingEpoch: String?) async {
        await sendBlockingState(
            isActive: isActive,
            bounceFilterConnectionsOnActivate: bounceFilterConnectionsOnActivate,
            blockingEpoch: blockingEpoch,
            tearDownStaleConnectionsOnActivate: false
        )
    }

    func sendBlockingState(isActive: Bool, bounceFilterConnectionsOnActivate: Bool) async {
        await sendBlockingState(isActive: isActive, bounceFilterConnectionsOnActivate: bounceFilterConnectionsOnActivate, blockingEpoch: nil)
    }
}

