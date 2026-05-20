@testable import FocusHacker
import XCTest

final class FocusHackerSmokeTests: XCTestCase {
    func testInMemoryContainerCanInitialize() {
        guard #available(macOS 14.0, *) else {
            XCTAssertTrue(true)
            return
        }
        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        XCTAssertNotNil(container)
    }

    func testTimerServiceCompletesSessionAndAwardsXP() async {
        let blockerSpy = BlockerServiceSpy()
        let recorderSpy = SessionRecorderSpy()
        let timerService = TimerService(
            blockerService: blockerSpy,
            sessionRecorder: recorderSpy,
            tickIntervalNanoseconds: 1_000_000
        )

        let stateStream = await timerService.sessionStateStream()
        var iterator = stateStream.makeAsyncIterator()
        _ = await iterator.next()

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 60,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        ))

        let completedExpectation = expectation(description: "timer session completes")
        Task {
            while let state = await iterator.next() {
                if state.lifecycleState == .completed {
                    completedExpectation.fulfill()
                    break
                }
            }
        }

        await fulfillment(of: [completedExpectation], timeout: 2.0)

        let recordedCompleted = await recorderSpy.completedSessions
        XCTAssertEqual(recordedCompleted.count, 1)
        XCTAssertEqual(recordedCompleted.first?.record.xpAwarded, 2)
        XCTAssertEqual(recordedCompleted.first?.record.roundsCompleted, 1)
    }

    func testTimerPauseAndResumeKeepsRemainingTimeStableWhilePaused() async {
        let timerService = TimerService(
            blockerService: BlockerServiceSpy(),
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )

        let stateStream = await timerService.sessionStateStream()
        var iterator = stateStream.makeAsyncIterator()
        _ = await iterator.next()

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 60,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        ))

        try? await Task.sleep(nanoseconds: 5_000_000)
        await timerService.pauseSession()
        let pausedState = await timerService.currentStateForTesting()
        let pausedRemaining = pausedState.remainingSeconds

        try? await Task.sleep(nanoseconds: 5_000_000)
        let stillPausedState = await timerService.currentStateForTesting()
        XCTAssertEqual(stillPausedState.lifecycleState, .paused)
        XCTAssertEqual(stillPausedState.remainingSeconds, pausedRemaining)

        await timerService.resumeSession()
        try? await Task.sleep(nanoseconds: 5_000_000)
        let resumedState = await timerService.currentStateForTesting()
        XCTAssertLessThan(resumedState.remainingSeconds, pausedRemaining)
    }

    func testSkipToNextPhase() async {
        let blocker = BlockerServiceSpy()
        let timerService = TimerService(
            blockerService: blocker,
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 3600,
            shortRestDurationSeconds: 60,
            longRestDurationSeconds: 1,
            roundsPerSession: 2,
            cyclesPerSession: 1
        ))

        let midFocus = await timerService.currentStateForTesting()
        XCTAssertEqual(midFocus.intervalPhase, .focus)
        XCTAssertGreaterThan(midFocus.remainingSeconds, 0)

        await timerService.skipToNextPhase()

        let afterSkip = await timerService.currentStateForTesting()
        XCTAssertEqual(afterSkip.intervalPhase, .shortRest)
        XCTAssertEqual(afterSkip.remainingSeconds, 60)
        let actives = await blocker.activeStates
        XCTAssertTrue(actives.contains(false), "Blocking should turn off when entering rest")
    }

    func testRestartCurrentIntervalWhilePausedRestoresFullConfiguredDuration() async {
        let timerService = TimerService(
            blockerService: BlockerServiceSpy(),
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 120,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        ))

        try? await Task.sleep(nanoseconds: 5_000_000)
        await timerService.pauseSession()
        let pausedRemaining = await timerService.currentStateForTesting().remainingSeconds
        XCTAssertLessThan(pausedRemaining, 120)

        await timerService.restartCurrentInterval()
        let restarted = await timerService.currentStateForTesting()
        XCTAssertEqual(restarted.lifecycleState, .paused)
        XCTAssertEqual(restarted.remainingSeconds, 120)
    }

    func testEndSessionEarlyDoesNotAwardXP() async {
        let recorderSpy = SessionRecorderSpy()
        let timerService = TimerService(
            blockerService: BlockerServiceSpy(),
            sessionRecorder: recorderSpy,
            tickIntervalNanoseconds: 1_000_000
        )

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 60,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        ))
        await timerService.endSession()

        let completed = await recorderSpy.completedSessions
        XCTAssertTrue(completed.isEmpty)
        let early = await recorderSpy.earlyEndedSessions
        XCTAssertEqual(early.count, 1)
    }

    /// Regression: after ending a session, a new session must call `setBlockingActive(true)` again.
    func testStartSessionAfterEndSessionRearmsBlocking() async {
        let blocker = BlockerServiceSpy()
        let timerService = TimerService(
            blockerService: blocker,
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )
        let configuration = TimerConfiguration(
            focusDurationSeconds: 60,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        )

        await timerService.startSession(configuration: configuration)
        await timerService.endSession()
        await timerService.startSession(configuration: configuration)

        let states = await blocker.activeStates
        XCTAssertEqual(states, [true, false, true])

        let final = await timerService.currentStateForTesting()
        XCTAssertEqual(final.lifecycleState, .running)
        XCTAssertEqual(final.intervalPhase, .focus)
    }

    /// Regression: resume must set `.running` and spawn the ticker before awaiting slow blocking work,
    /// so `tick()` can run while `setBlockingActive` suspends on the blocker actor (same idea as
    /// `transitionToRunningInterval`).
    func testResumeTicksWhileSetBlockingActiveIsSlow() async {
        let holdNanos: UInt64 = 200_000_000 // 200ms on `setBlockingActive(true)`
        let slowBlocker = SlowWhenTrueBlockerSpy(holdNanos: holdNanos)
        let timerService = TimerService(
            blockerService: slowBlocker,
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )

        let stateStream = await timerService.sessionStateStream()
        var iterator = stateStream.makeAsyncIterator()
        _ = await iterator.next()

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 3600,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        ))

        try? await Task.sleep(nanoseconds: 15_000_000)
        await timerService.pauseSession()
        let pausedRemaining = await timerService.currentStateForTesting().remainingSeconds

        let resumeTask = Task { await timerService.resumeSession() }
        try? await Task.sleep(nanoseconds: 80_000_000)
        let mid = await timerService.currentStateForTesting()
        XCTAssertEqual(mid.lifecycleState, .running, "UI should show running while blocker work is in flight")
        XCTAssertLessThan(
            mid.remainingSeconds,
            pausedRemaining,
            "Ticker must advance during slow setBlockingActive after resume"
        )
        await resumeTask.value
    }

    /// Regression: rest → second focus must tick while `setBlockingActive(true)` is in flight (same as resume).
    func testSecondFocusAfterRestTicksWhileSetBlockingActiveIsSlow() async {
        let holdNanos: UInt64 = 400_000_000
        let slowBlocker = SlowWhenTrueBlockerSpy(holdNanos: holdNanos)
        let timerService = TimerService(
            blockerService: slowBlocker,
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000_000
        )

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 2,
            shortRestDurationSeconds: 2,
            longRestDurationSeconds: 0,
            roundsPerSession: 2,
            cyclesPerSession: 1
        ))

        let deadline = Date().addingTimeInterval(8)
        var atSecondFocus: TimerSessionState?
        while Date() < deadline {
            let snapshot = await timerService.currentStateForTesting()
            if snapshot.lifecycleState == .running,
               snapshot.intervalPhase == .focus,
               snapshot.currentRound == 2 {
                atSecondFocus = snapshot
                break
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
        guard let atSecondFocus else {
            XCTFail("Timed out waiting for round-2 focus")
            return
        }

        let remainingBefore = atSecondFocus.remainingSeconds
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        let afterTicks = await timerService.currentStateForTesting()
        XCTAssertEqual(afterTicks.lifecycleState, .running)
        XCTAssertEqual(afterTicks.intervalPhase, .focus)
        XCTAssertEqual(afterTicks.currentRound, 2)
        XCTAssertLessThan(
            afterTicks.remainingSeconds,
            remainingBefore,
            "Second focus countdown must advance while slow setBlockingActive runs"
        )
    }

    /// Rest → focus requests sysext restart / stale teardown (not filter bounce); cold start stays bounce-off.
    func testRestToFocusUsesDataPlaneNotFilterBounceWhenBlocking() async {
        let blocker = BlockerServiceSpy()
        let timerService = TimerService(
            blockerService: blocker,
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 1,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 2,
            cyclesPerSession: 1
        ))
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        let actives = await blocker.activeStates
        let bounces = await blocker.bounceOnActivateArgs
        let tearDownStale = await blocker.tearDownStaleOnActivateArgs
        XCTAssertGreaterThanOrEqual(actives.count, 3)
        XCTAssertGreaterThanOrEqual(bounces.count, 3)
        XCTAssertGreaterThanOrEqual(tearDownStale.count, 3)
        XCTAssertEqual(bounces[0], false, "Cold focus start avoids bounce")
        XCTAssertEqual(bounces[2], false, "fe1347: Pomodoro rest→focus uses sysext restart, not filter bounce")
        XCTAssertEqual(tearDownStale[0], false, "Cold focus start does not request stale teardown")
        XCTAssertEqual(tearDownStale[2], true, "Second focus after short rest requests stale socket provider refresh")
    }

    /// Resume into focus requests a filter bounce so Chromium can reopen sockets; cold start stays bounce-off.
    func testResumeIntoFocusRequestsFilterBounceWhenBlocking() async {
        let blocker = BlockerServiceSpy()
        let timerService = TimerService(
            blockerService: blocker,
            sessionRecorder: SessionRecorderSpy(),
            tickIntervalNanoseconds: 1_000_000
        )

        await timerService.startSession(configuration: TimerConfiguration(
            focusDurationSeconds: 60,
            shortRestDurationSeconds: 1,
            longRestDurationSeconds: 1,
            roundsPerSession: 1,
            cyclesPerSession: 1
        ))
        await timerService.pauseSession()
        await timerService.resumeSession()

        let actives = await blocker.activeStates
        let bounces = await blocker.bounceOnActivateArgs
        XCTAssertEqual(actives, [true, false, true])
        XCTAssertEqual(
            bounces,
            [false, false, true],
            "Cold focus activation avoids bounce; resume into focus bounces so allowed pause sockets are torn down"
        )
    }
}

private actor SlowWhenTrueBlockerSpy: BlockerServiceProtocol {
    private let holdNanos: UInt64

    init(holdNanos: UInt64) {
        self.holdNanos = holdNanos
    }

    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async {
        if isActive {
            try? await Task.sleep(nanoseconds: holdNanos)
        }
        _ = bounceFilterConnectionsOnActivate
        _ = blockingEpoch
    }

    func refreshBlockingLeaseIfActive() async {}


    func refreshBlockedIPLiteralsAfterBlocklistChange() async {}

    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async {}
}

private actor BlockerServiceSpy: BlockerServiceProtocol {
    private(set) var activeStates: [Bool] = []
    private(set) var bounceOnActivateArgs: [Bool] = []
    private(set) var tearDownStaleOnActivateArgs: [Bool] = []

    func setBlockingActive(
        _ isActive: Bool,
        bounceFilterConnectionsOnActivate: Bool,
        blockingEpoch: String?,
        tearDownStaleConnectionsOnActivate: Bool
    ) async {
        activeStates.append(isActive)
        bounceOnActivateArgs.append(bounceFilterConnectionsOnActivate)
        tearDownStaleOnActivateArgs.append(tearDownStaleConnectionsOnActivate)
        _ = blockingEpoch
    }

    func refreshBlockingLeaseIfActive() async { }

    func refreshBlockedIPLiteralsAfterBlocklistChange() async { }

    func syncSharedBlocklistMirror(domains: [String], bundleIDs: [String]) async {}
}

private actor SessionRecorderSpy: SessionRecording {
    private(set) var beganSessions: [(UUID, Date)] = []
    private(set) var completedSessions: [(record: CompletedSessionRecord, sessionUUID: UUID)] = []
    private(set) var earlyEndedSessions: [(sessionUUID: UUID, startedAt: Date, endedAt: Date, focusMinutes: Int, rounds: Int)] = []

    func recordSessionBegan(sessionUUID: UUID, startedAt: Date) async throws {
        beganSessions.append((sessionUUID, startedAt))
    }

    func recordSessionCompleted(_ completedSession: CompletedSessionRecord, sessionUUID: UUID) async throws {
        completedSessions.append((record: completedSession, sessionUUID: sessionUUID))
    }

    func recordSessionEndedEarly(
        sessionUUID: UUID,
        startedAt: Date,
        endedAt: Date,
        partialFocusMinutes: Int,
        partialRoundsCompleted: Int
    ) async throws {
        earlyEndedSessions.append(
            (sessionUUID: sessionUUID, startedAt: startedAt, endedAt: endedAt, focusMinutes: partialFocusMinutes, rounds: partialRoundsCompleted)
        )
    }
}
