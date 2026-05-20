import Foundation

actor TimerService: TimerServiceProtocol {
    private let blockerService: BlockerServiceProtocol
    private let sessionRecorder: SessionRecording
    private let dateProvider: @Sendable () -> Date
    private let tickIntervalNanoseconds: UInt64

    private var timerTask: Task<Void, Never>?
    private var activeConfiguration: TimerConfiguration?
    private var activeSessionStartedAt: Date?
    private var activeSessionUUID: UUID?
    /// Wall-clock end of the current running interval; `nil` while paused. Drives `remainingSeconds`
    /// from real time so App Nap / coalesced `Task.sleep` does not drift the visible countdown.
    private var currentIntervalEndsAt: Date?
    private var state = TimerSessionState.idle

    private var stateContinuations: [UUID: AsyncStream<TimerSessionState>.Continuation] = [:]
    private var transitionContinuations: [UUID: AsyncStream<TimerTransitionEvent>.Continuation] = [:]
    /// Debug: log first N ticks after each ticker spawn.
    private var debugTicksToLog = 0
    /// Prevents overlapping `advanceAfterIntervalCompletion` from stacked ticker tasks (fe1347).
    private var advanceInFlight = false
    /// Sub-0.5s tick intervals are treated as fast test harnesses: use per-tick decrement so sessions
    /// can finish without wall-clock waits. Production uses ~1s ticks and wall-clock interval ends.
    private var anchorsIntervalsToWallClock: Bool {
        tickIntervalNanoseconds >= 500_000_000
    }

    init(
        blockerService: BlockerServiceProtocol = BlockerService(),
        sessionRecorder: SessionRecording = NoOpSessionRecorder(),
        dateProvider: @escaping @Sendable () -> Date = { Date() },
        tickIntervalNanoseconds: UInt64 = 1_000_000_000
    ) {
        self.blockerService = blockerService
        self.sessionRecorder = sessionRecorder
        self.dateProvider = dateProvider
        self.tickIntervalNanoseconds = tickIntervalNanoseconds
    }

    nonisolated func sessionStateStream() -> AsyncStream<TimerSessionState> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                await registerStateContinuation(id: id, continuation: continuation)
            }
            continuation.onTermination = { _ in
                Task {
                    await self.removeStateContinuation(id: id)
                }
            }
        }
    }

    nonisolated func transitionEventStream() -> AsyncStream<TimerTransitionEvent> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                await registerTransitionContinuation(id: id, continuation: continuation)
            }
            continuation.onTermination = { _ in
                Task {
                    await self.removeTransitionContinuation(id: id)
                }
            }
        }
    }

    func startSession(configuration: TimerConfiguration) async {
        guard state.lifecycleState == .idle else {
            return
        }

        activeConfiguration = configuration
        let sessionUUID = UUID()
        activeSessionUUID = sessionUUID
        activeSessionStartedAt = dateProvider()
        try? await sessionRecorder.recordSessionBegan(sessionUUID: sessionUUID, startedAt: activeSessionStartedAt ?? dateProvider())
        state.completedFocusMinutes = 0
        state.currentRound = 1
        state.totalRounds = configuration.roundsPerSession
        state.currentCycle = 1
        state.totalCycles = max(1, configuration.cyclesPerSession)
        state.elapsedSessionSeconds = 0
        state.completedWorkSeconds = 0
        await transitionToRunningInterval(.focus, durationSeconds: configuration.focusDurationSeconds)
    }

    func pauseSession() async {
        guard state.lifecycleState == .running else {
            return
        }
        timerTask?.cancel()
        timerTask = nil
        currentIntervalEndsAt = nil
        state.lifecycleState = .paused
        publishState()
        await blockerService.setBlockingActive(false)
    }

    func resumeSession() async {
        guard state.lifecycleState == .paused else {
            return
        }
        guard let phase = state.intervalPhase else {
            return
        }
        let shouldBlock = phase == .focus
        // Must publish `.running` and spawn the ticker before `await setBlockingActive`.
        // 1) `await` on `blockerService` suspends this actor so `tick()` can run while IP/extension work runs.
        // 2) While still `.paused`, `tick()` returns immediately — a long `setBlockingActive` first would
        //    freeze the countdown even if a ticker existed (matches "recommence / resume looks stuck").
        state.lifecycleState = .running
        publishState()
        startTickerTask()
        // Runtime evidence (session 104de4 NDJSON): after pause→resume, `/Users/Shared` JSON already shows
        // `fileActive` + valid lease + domains, yet Chrome could still browse — flows allowed while paused
        // often never re-enter `handleNewFlow`. Bounce only on resume-into-focus (not cold `transitionToRunningInterval`).
        await blockerService.setBlockingActive(
            shouldBlock,
            bounceFilterConnectionsOnActivate: shouldBlock,
            blockingEpoch: shouldBlock ? UUID().uuidString : nil
        )
    }

    func endSession() async {
        guard state.lifecycleState != .idle else {
            return
        }
        timerTask?.cancel()
        timerTask = nil
        state.lifecycleState = .endedEarly
        publishState()
        let endedAt = dateProvider()
        let startedAt = activeSessionStartedAt ?? endedAt
        if let sessionUUID = activeSessionUUID {
            let partialRounds = completedFocusIntervalsSoFar(state: state)
            try? await sessionRecorder.recordSessionEndedEarly(
                sessionUUID: sessionUUID,
                startedAt: startedAt,
                endedAt: endedAt,
                partialFocusMinutes: state.completedFocusMinutes,
                partialRoundsCompleted: partialRounds
            )
        }
        publishTransition(.sessionEndedEarly)
        await resetToIdle()
    }

    func skipToNextPhase() async {
        guard state.lifecycleState == .running, state.remainingSeconds > 0 else {
            return
        }
        timerTask?.cancel()
        timerTask = nil
        currentIntervalEndsAt = nil
        state.remainingSeconds = 0
        publishState()
        await advanceAfterIntervalCompletion()
    }

    func restartCurrentInterval() async {
        guard state.lifecycleState == .running || state.lifecycleState == .paused else {
            return
        }
        guard state.remainingSeconds > 0, let phase = state.intervalPhase, let activeConfiguration else {
            return
        }
        let durationSeconds: Int
        switch phase {
        case .focus:
            durationSeconds = activeConfiguration.focusDurationSeconds
        case .shortRest:
            durationSeconds = activeConfiguration.shortRestDurationSeconds
        case .longRest:
            durationSeconds = activeConfiguration.longRestDurationSeconds
        }
        let duration = max(0, durationSeconds)
        state.remainingSeconds = duration
        currentIntervalEndsAt = nil
        publishState()
        if state.lifecycleState == .running, timerTask == nil {
            startTickerTask()
        }
    }

    func resyncBlockingForRunningFocusIfNeeded() async {
        let phase = state.intervalPhase.map { String(describing: $0) } ?? "nil"
        let lifecycle = String(describing: state.lifecycleState)
        guard state.lifecycleState == .running, state.intervalPhase == .focus else {
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H5",
                location: "TimerService.resyncBlockingForRunningFocusIfNeeded",
                message: "resync_skipped",
                data: ["lifecycle": lifecycle, "phase": phase, "round": String(state.currentRound)]
            )
            // #endregion
            return
        }
        // #region agent log
        AgentDebugLog.write(
            hypothesisId: "H5",
            location: "TimerService.resyncBlockingForRunningFocusIfNeeded",
            message: "resync_activate",
            data: ["lifecycle": lifecycle, "phase": phase, "round": String(state.currentRound)]
        )
        // #endregion
        await blockerService.setBlockingActive(true, bounceFilterConnectionsOnActivate: false, blockingEpoch: nil)
    }

    func currentSessionState() -> TimerSessionState {
        state
    }

    func currentStateForTesting() -> TimerSessionState {
        state
    }
}

private extension TimerService {
    /// Fully completed focus intervals for the current in-session counters (mirrors AppShell `completedPlannedFocusIntervals`).
    func completedFocusIntervalsSoFar(state: TimerSessionState) -> Int {
        guard
            let phase = state.intervalPhase,
            state.totalRounds > 0,
            state.totalCycles > 0,
            state.currentCycle >= 1,
            state.currentRound >= 1
        else {
            return 0
        }
        let tr = state.totalRounds
        let cy = state.currentCycle
        let r = state.currentRound
        switch phase {
        case .focus:
            return (cy - 1) * tr + (r - 1)
        case .shortRest:
            return (cy - 1) * tr + r
        case .longRest:
            return cy * tr
        }
    }

    func registerStateContinuation(id: UUID, continuation: AsyncStream<TimerSessionState>.Continuation) {
        stateContinuations[id] = continuation
        continuation.yield(state)
    }

    func removeStateContinuation(id: UUID) {
        stateContinuations[id] = nil
    }

    func registerTransitionContinuation(id: UUID, continuation: AsyncStream<TimerTransitionEvent>.Continuation) {
        transitionContinuations[id] = continuation
    }

    func removeTransitionContinuation(id: UUID) {
        transitionContinuations[id] = nil
    }

    func publishState() {
        for continuation in stateContinuations.values {
            continuation.yield(state)
        }
    }

    func publishTransition(_ event: TimerTransitionEvent) {
        for continuation in transitionContinuations.values {
            continuation.yield(event)
        }
    }

    func transitionToRunningInterval(_ phase: TimerIntervalPhase, durationSeconds: Int) async {
        let priorPhase = state.intervalPhase
        timerTask?.cancel()
        timerTask = nil

        state.lifecycleState = .running
        state.intervalPhase = phase
        let duration = max(0, durationSeconds)
        state.remainingSeconds = duration
        // Wall-clock end is set in `startTickerTask` after blocking work so activation/bounce time
        // does not consume the visible countdown (rest→focus regression).
        currentIntervalEndsAt = nil
        publishState()

        switch phase {
        case .focus:
            publishTransition(.focusStarted(round: state.currentRound, totalRounds: state.totalRounds))
        case .shortRest:
            publishTransition(.shortRestStarted(round: state.currentRound, totalRounds: state.totalRounds))
        case .longRest:
            publishTransition(.longRestStarted)
        }

        // fe1347: rest→focus bounce / extension hard-restart hung past the 20s focus window and left
        // flowCount at 0 (Chrome detached). Use the same activate path as round 1; epoch still bumps.
        let shouldBounceOnFocusActivate = false
        let tearDownStaleConnectionsOnActivate = priorPhase == .shortRest || priorPhase == .longRest
        // #region agent log
        AgentDebugLog.write(
            hypothesisId: phase == .focus ? "H2" : "H3",
            location: "TimerService.transitionToRunningInterval",
            message: phase == .focus ? "focus_interval" : "rest_interval",
            data: [
                "round": String(state.currentRound),
                "priorPhase": priorPhase.map { String(describing: $0) } ?? "nil",
                "phase": String(describing: phase),
                "shouldBounce": String(shouldBounceOnFocusActivate),
                "tearDownStale": String(tearDownStaleConnectionsOnActivate),
                "bouncePolicy": tearDownStaleConnectionsOnActivate
                    ? "sysext_restart_fe1347"
                    : "disabled_fe1347",
            ],
            runId: "post-fix-v14"
        )
        // #endregion
        if phase == .focus {
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H1",
                location: "TimerService.transitionToRunningInterval",
                message: "before_set_blocking_focus",
                data: [
                    "round": String(state.currentRound),
                    "priorPhase": priorPhase.map { String(describing: $0) } ?? "nil",
                    "shouldBounce": String(shouldBounceOnFocusActivate),
                    "remaining": String(state.remainingSeconds),
                ]
            )
            // #endregion
            if tearDownStaleConnectionsOnActivate {
                // #region agent log
                AgentDebugLog.write(
                    hypothesisId: "H62",
                    location: "TimerService.transitionToRunningInterval",
                    message: "focus_interval_sysext_restart_triggered",
                    data: [
                        "round": String(state.currentRound),
                        "priorPhase": priorPhase.map { String(describing: $0) } ?? "nil",
                    ],
                    runId: "b62"
                )
                // #endregion
            }
            // Spawn ticker before `await setBlockingActive` so rest→focus sysext restart cannot freeze
            // the countdown (same ordering as `resumeSession`).
            startTickerTask()
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H1",
                location: "TimerService.transitionToRunningInterval",
                message: "after_start_ticker_focus",
                data: [
                    "round": String(state.currentRound),
                    "timerTaskNil": String(timerTask == nil),
                ]
            )
            // #endregion
            let activateStarted = dateProvider()
            await blockerService.setBlockingActive(
                true,
                bounceFilterConnectionsOnActivate: shouldBounceOnFocusActivate,
                blockingEpoch: UUID().uuidString,
                tearDownStaleConnectionsOnActivate: tearDownStaleConnectionsOnActivate
            )
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H2",
                location: "TimerService.transitionToRunningInterval",
                message: "set_blocking_active_done",
                data: [
                    "round": String(state.currentRound),
                    "shouldBounce": String(shouldBounceOnFocusActivate),
                    "elapsedMs": String(Int(dateProvider().timeIntervalSince(activateStarted) * 1000)),
                ]
            )
            // #endregion
        } else {
            await blockerService.setBlockingActive(false)
            startTickerTask()
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H3",
                location: "TimerService.transitionToRunningInterval",
                message: "after_start_ticker_rest",
                data: [
                    "round": String(state.currentRound),
                    "timerTaskNil": String(timerTask == nil),
                ]
            )
            // #endregion
        }
    }

    func startTickerTask() {
        timerTask?.cancel()
        timerTask = nil
        debugTicksToLog = 5
        if anchorsIntervalsToWallClock {
            currentIntervalEndsAt = dateProvider().addingTimeInterval(TimeInterval(state.remainingSeconds))
        }
        let tickNanos = tickIntervalNanoseconds
        // #region agent log
        AgentDebugLog.write(
            hypothesisId: "H2",
            location: "TimerService.startTickerTask",
            message: "startTickerTask",
            data: [
                "phase": state.intervalPhase.map { String(describing: $0) } ?? "nil",
                "round": String(state.currentRound),
                "cycle": String(state.currentCycle),
                "lifecycle": String(describing: state.lifecycleState),
                "remaining": String(state.remainingSeconds),
                "hasEndsAt": String(currentIntervalEndsAt != nil),
            ]
        )
        // #endregion
        timerTask = Task { [tickNanos] in
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H6",
                location: "TimerService.startTickerTask",
                message: "ticker_loop_start",
                data: ["isCancelled": String(Task.isCancelled)]
            )
            // #endregion
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tickNanos)
                if Task.isCancelled { return }
                await self.tick()
            }
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H6",
                location: "TimerService.startTickerTask",
                message: "ticker_loop_exit",
                data: ["isCancelled": String(Task.isCancelled)]
            )
            // #endregion
        }
    }

    func tick() async {
        guard state.lifecycleState == .running else {
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H4",
                location: "TimerService.tick",
                message: "tick_skipped_not_running",
                data: [
                    "lifecycle": String(describing: state.lifecycleState),
                    "phase": state.intervalPhase.map { String(describing: $0) } ?? "nil",
                ]
            )
            // #endregion
            return
        }

        if debugTicksToLog > 0 {
            debugTicksToLog -= 1
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H2",
                location: "TimerService.tick",
                message: "tick",
                data: [
                    "phase": state.intervalPhase.map { String(describing: $0) } ?? "nil",
                    "round": String(state.currentRound),
                    "remaining": String(state.remainingSeconds),
                    "elapsed": String(state.elapsedSessionSeconds),
                    "hasEndsAt": String(currentIntervalEndsAt != nil),
                ]
            )
            // #endregion
        }

        if anchorsIntervalsToWallClock, let intervalEnd = currentIntervalEndsAt {
            let now = dateProvider()
            let rawSecondsLeft = intervalEnd.timeIntervalSince(now)
            if rawSecondsLeft <= 0 {
                state.remainingSeconds = 0
                publishState()
                scheduleAdvanceAfterIntervalCompletion()
                return
            }
            // Ceil so a 2s interval is not treated as finished while ~1s of wall time remains
            // (floor(0.9) == 0 would end the interval one tick early).
            let newRemaining = Int(ceil(rawSecondsLeft))

            let previousRemaining = state.remainingSeconds
            let consumed = max(0, previousRemaining - newRemaining)
            if consumed > 0 {
                state.elapsedSessionSeconds += consumed
                if state.intervalPhase == .focus {
                    state.completedWorkSeconds += consumed
                }
            }
            state.remainingSeconds = newRemaining
            publishState()
            return
        }

        guard state.remainingSeconds > 0 else {
            scheduleAdvanceAfterIntervalCompletion()
            return
        }

        state.remainingSeconds -= 1
        state.elapsedSessionSeconds += 1
        if state.intervalPhase == .focus {
            state.completedWorkSeconds += 1
        }
        publishState()

        if state.remainingSeconds == 0 {
            scheduleAdvanceAfterIntervalCompletion()
        }
    }

    /// Runs phase advancement outside the timer task so a just-cancelled ticker does not cancel
    /// the replacement task spawned at the end of `transitionToRunningInterval`.
    private func scheduleAdvanceAfterIntervalCompletion() {
        Task { await self.advanceAfterIntervalCompletion() }
    }

    func advanceAfterIntervalCompletion() async {
        guard !advanceInFlight else {
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H5",
                location: "TimerService.advanceAfterIntervalCompletion",
                message: "advance_skipped_reentrant",
                data: [
                    "phase": state.intervalPhase.map { String(describing: $0) } ?? "nil",
                    "round": String(state.currentRound),
                ]
            )
            // #endregion
            return
        }
        advanceInFlight = true
        defer { advanceInFlight = false }
        // #region agent log
        AgentDebugLog.write(
            hypothesisId: "H5",
            location: "TimerService.advanceAfterIntervalCompletion",
            message: "advance",
            data: [
                "phase": state.intervalPhase.map { String(describing: $0) } ?? "nil",
                "round": String(state.currentRound),
                "cycle": String(state.currentCycle),
            ]
        )
        // #endregion
        guard let activeConfiguration else {
            await resetToIdle()
            return
        }

        switch state.intervalPhase {
        case .focus:
            state.completedFocusMinutes += activeConfiguration.focusDurationSeconds / 60
            if state.currentRound < state.totalRounds {
                await transitionToRunningInterval(
                    .shortRest,
                    durationSeconds: activeConfiguration.shortRestDurationSeconds
                )
            } else {
                let cycles = max(1, activeConfiguration.cyclesPerSession)
                if state.currentCycle < cycles {
                    if activeConfiguration.longRestDurationSeconds > 0 {
                        await transitionToRunningInterval(
                            .longRest,
                            durationSeconds: activeConfiguration.longRestDurationSeconds
                        )
                    } else {
                        state.currentCycle += 1
                        state.currentRound = 1
                        await transitionToRunningInterval(
                            .focus,
                            durationSeconds: activeConfiguration.focusDurationSeconds
                        )
                    }
                } else if cycles == 1, activeConfiguration.longRestDurationSeconds > 0 {
                    await transitionToRunningInterval(
                        .longRest,
                        durationSeconds: activeConfiguration.longRestDurationSeconds
                    )
                } else {
                    await completeSession()
                }
            }
        case .shortRest:
            state.currentRound += 1
            await transitionToRunningInterval(
                .focus,
                durationSeconds: activeConfiguration.focusDurationSeconds
            )
        case .longRest:
            if state.currentCycle < state.totalCycles {
                state.currentCycle += 1
                state.currentRound = 1
                await transitionToRunningInterval(
                    .focus,
                    durationSeconds: activeConfiguration.focusDurationSeconds
                )
            } else {
                await completeSession()
            }
        case nil:
            await resetToIdle()
        }
    }

    func completeSession() async {
        timerTask?.cancel()
        timerTask = nil
        state.lifecycleState = .completed
        publishState()

        let focusMinutes = state.completedFocusMinutes
        let xpAwarded = max(0, focusMinutes * 2)
        let now = dateProvider()
        let startedAt = activeSessionStartedAt ?? now
        let totalFocusIntervals = max(0, state.totalRounds) * max(0, state.totalCycles)
        let completedSession = CompletedSessionRecord(
            startedAt: startedAt,
            endedAt: now,
            totalFocusMinutes: focusMinutes,
            roundsCompleted: totalFocusIntervals,
            configuredRounds: totalFocusIntervals,
            xpAwarded: xpAwarded
        )

        if let sessionUUID = activeSessionUUID {
            try? await sessionRecorder.recordSessionCompleted(completedSession, sessionUUID: sessionUUID)
        }
        publishTransition(.sessionCompleted(xpAwarded: xpAwarded))
        await resetToIdle()
    }

    func resetToIdle() async {
        timerTask?.cancel()
        timerTask = nil
        currentIntervalEndsAt = nil
        activeConfiguration = nil
        activeSessionStartedAt = nil
        activeSessionUUID = nil
        // Publish idle before awaiting `setBlockingActive(false)` so UI/state observers match "session over"
        // immediately; blocking teardown may still finish asynchronously on the blocker actor.
        state = TimerSessionState.idle
        publishState()
        await blockerService.setBlockingActive(false)
    }
}

