import Foundation
import SwiftData

struct CompletedSessionRecord: Sendable {
    let startedAt: Date
    let endedAt: Date
    let totalFocusMinutes: Int
    let roundsCompleted: Int
    let configuredRounds: Int
    let xpAwarded: Int
    let naturallyConcluded: Bool
}

protocol SessionRecording: Sendable {
    func recordSessionBegan(sessionUUID: UUID, startedAt: Date) async throws
    func recordSessionCompleted(_ completedSession: CompletedSessionRecord, sessionUUID: UUID) async throws
    func recordSessionEndedEarly(
        sessionUUID: UUID,
        startedAt: Date,
        endedAt: Date,
        partialFocusMinutes: Int,
        partialRoundsCompleted: Int
    ) async throws
}

@available(macOS 14.0, *)
struct SwiftDataSessionLifecycleRecorder: SessionRecording, @unchecked Sendable {
    private let modelContext: ModelContext
    private let settingsStore: UserDefaultsSettingsStore

    init(container: ModelContainer, settingsStore: UserDefaultsSettingsStore) {
        self.modelContext = ModelContext(container)
        self.settingsStore = settingsStore
    }

    func recordSessionBegan(sessionUUID: UUID, startedAt: Date) async throws {
        let session = Session(
            createdAt: startedAt,
            focusDurationMinutes: 0,
            roundsCompleted: 0,
            xpAwarded: 0,
            startedAt: startedAt,
            endedAt: nil,
            configuredRounds: nil,
            didComplete: false,
            totalFocusMinutes: nil,
            sessionUUID: sessionUUID,
            naturallyConcluded: false
        )
        modelContext.insert(session)
        try modelContext.save()
    }

    func recordSessionCompleted(_ completedSession: CompletedSessionRecord, sessionUUID: UUID) async throws {
        let focusMinutes = max(0, completedSession.totalFocusMinutes)
        let xpAmount = max(0, completedSession.xpAwarded)
        let natural = completedSession.naturallyConcluded

        if let existing = try findSession(sessionUUID: sessionUUID) {
            existing.focusDurationMinutes = focusMinutes
            existing.roundsCompleted = completedSession.roundsCompleted
            existing.xpAwarded = xpAmount
            existing.startedAt = completedSession.startedAt
            existing.endedAt = completedSession.endedAt
            existing.configuredRounds = completedSession.configuredRounds
            existing.didComplete = true
            existing.totalFocusMinutes = focusMinutes
            existing.createdAt = completedSession.endedAt
            existing.naturallyConcluded = natural
            try insertXPRecord(
                amount: xpAmount,
                minutes: focusMinutes,
                natural: natural,
                endedAt: completedSession.endedAt,
                session: existing
            )
        } else {
            let session = Session(
                createdAt: completedSession.endedAt,
                focusDurationMinutes: focusMinutes,
                roundsCompleted: completedSession.roundsCompleted,
                xpAwarded: xpAmount,
                startedAt: completedSession.startedAt,
                endedAt: completedSession.endedAt,
                configuredRounds: completedSession.configuredRounds,
                didComplete: true,
                totalFocusMinutes: focusMinutes,
                sessionUUID: sessionUUID,
                naturallyConcluded: natural
            )
            modelContext.insert(session)
            try insertXPRecord(
                amount: xpAmount,
                minutes: focusMinutes,
                natural: natural,
                endedAt: completedSession.endedAt,
                session: session
            )
        }
        try modelContext.save()
        // #region agent log
        let savedCount = (try? modelContext.fetch(FetchDescriptor<Session>()))?.count ?? -1
        DebugSessionLogAfdf58.write(
            hypothesisId: "H2",
            location: "SessionRecording.recordSessionCompleted",
            message: "saved",
            data: [
                "xpAmount": "\(xpAmount)",
                "focusMinutes": "\(focusMinutes)",
                "sessionCount": "\(savedCount)",
            ]
        )
        DebugSessionLogAc92a4.write(
            hypothesisId: "H2",
            location: "SessionRecording.recordSessionCompleted",
            message: "saved",
            data: [
                "xpAmount": "\(xpAmount)",
                "focusMinutes": "\(focusMinutes)",
                "endedAt": "\(Int(completedSession.endedAt.timeIntervalSince1970))",
                "didComplete": "true",
                "sessionCount": "\(savedCount)",
            ]
        )
        // #endregion
    }

    func recordSessionEndedEarly(
        sessionUUID: UUID,
        startedAt: Date,
        endedAt: Date,
        partialFocusMinutes: Int,
        partialRoundsCompleted: Int
    ) async throws {
        let focusMinutes = max(0, partialFocusMinutes)
        let rounds = max(0, partialRoundsCompleted)
        let natural = NaturalCompletionPolicy.naturallyConcludedOnEarlyEnd
        let xpAmount = FocusXPCalculator.xp(forFocusMinutes: focusMinutes, naturallyConcluded: natural)

        if let existing = try findSession(sessionUUID: sessionUUID) {
            existing.focusDurationMinutes = focusMinutes
            existing.roundsCompleted = rounds
            existing.xpAwarded = xpAmount
            existing.startedAt = startedAt
            existing.endedAt = endedAt
            existing.didComplete = false
            existing.totalFocusMinutes = focusMinutes
            existing.naturallyConcluded = natural
            if xpAmount > 0 {
                try insertXPRecord(amount: xpAmount, minutes: focusMinutes, natural: natural, endedAt: endedAt, session: existing)
            }
        } else {
            let session = Session(
                createdAt: endedAt,
                focusDurationMinutes: focusMinutes,
                roundsCompleted: rounds,
                xpAwarded: xpAmount,
                startedAt: startedAt,
                endedAt: endedAt,
                configuredRounds: nil,
                didComplete: false,
                totalFocusMinutes: focusMinutes,
                sessionUUID: sessionUUID,
                naturallyConcluded: natural
            )
            modelContext.insert(session)
            if xpAmount > 0 {
                try insertXPRecord(amount: xpAmount, minutes: focusMinutes, natural: natural, endedAt: endedAt, session: session)
            }
        }
        try modelContext.save()
    }

    private func insertXPRecord(
        amount: Int,
        minutes: Int,
        natural: Bool,
        endedAt: Date,
        session: Session
    ) throws {
        guard amount > 0 else { return }
        guard session.xpRecords.isEmpty else { return }
        guard LifetimeXPFiltering.shouldAwardLifetimeXP(
            forSessionEndedAt: endedAt,
            resetAt: settingsStore.lifetimeXPResetAt
        ) else {
            return
        }
        let xpRecord = XPRecord(
            xpAmount: amount,
            createdAt: endedAt,
            focusMinutesContributing: minutes,
            naturallyConcluded: natural,
            session: session
        )
        modelContext.insert(xpRecord)
    }

    private func findSession(sessionUUID: UUID) throws -> Session? {
        let descriptor = FetchDescriptor<Session>()
        let sessions = try modelContext.fetch(descriptor)
        return sessions.first { $0.sessionUUID == sessionUUID }
    }
}

struct NoOpSessionRecorder: SessionRecording {
    func recordSessionBegan(sessionUUID: UUID, startedAt: Date) async throws {}

    func recordSessionCompleted(_ completedSession: CompletedSessionRecord, sessionUUID: UUID) async throws {}

    func recordSessionEndedEarly(
        sessionUUID: UUID,
        startedAt: Date,
        endedAt: Date,
        partialFocusMinutes: Int,
        partialRoundsCompleted: Int
    ) async throws {}
}
