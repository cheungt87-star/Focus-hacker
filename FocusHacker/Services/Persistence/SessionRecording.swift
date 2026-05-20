import Foundation
import SwiftData

struct CompletedSessionRecord: Sendable {
    let startedAt: Date
    let endedAt: Date
    let totalFocusMinutes: Int
    let roundsCompleted: Int
    let configuredRounds: Int
    let xpAwarded: Int
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

    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
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
            sessionUUID: sessionUUID
        )
        modelContext.insert(session)
        try modelContext.save()
    }

    func recordSessionCompleted(_ completedSession: CompletedSessionRecord, sessionUUID: UUID) async throws {
        let xpAmount = max(0, completedSession.xpAwarded)
        let focusMinutes = max(0, completedSession.totalFocusMinutes)

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

            let xpRecord = XPRecord(
                xpAmount: xpAmount,
                createdAt: completedSession.endedAt,
                focusMinutesContributing: focusMinutes,
                session: existing
            )
            modelContext.insert(xpRecord)
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
                sessionUUID: sessionUUID
            )
            modelContext.insert(session)
            let xpRecord = XPRecord(
                xpAmount: xpAmount,
                createdAt: completedSession.endedAt,
                focusMinutesContributing: focusMinutes,
                session: session
            )
            modelContext.insert(xpRecord)
        }
        try modelContext.save()
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

        if let existing = try findSession(sessionUUID: sessionUUID) {
            existing.focusDurationMinutes = focusMinutes
            existing.roundsCompleted = rounds
            existing.xpAwarded = 0
            existing.startedAt = startedAt
            existing.endedAt = endedAt
            existing.didComplete = false
            existing.totalFocusMinutes = focusMinutes
        } else {
            let session = Session(
                createdAt: endedAt,
                focusDurationMinutes: focusMinutes,
                roundsCompleted: rounds,
                xpAwarded: 0,
                startedAt: startedAt,
                endedAt: endedAt,
                configuredRounds: nil,
                didComplete: false,
                totalFocusMinutes: focusMinutes,
                sessionUUID: sessionUUID
            )
            modelContext.insert(session)
        }
        try modelContext.save()
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
