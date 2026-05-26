import SwiftData
import XCTest
@testable import FocusHacker

@available(macOS 14.0, *)
final class GamificationProgressResetTests: XCTestCase {
    func testResetClearsProgressButKeepsDisplayName() throws {
        let suiteName = "GamificationProgressReset.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        store.profileDisplayName = "test123"

        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        let context = ModelContext(container)

        context.insert(
            Session(
                createdAt: Date(),
                focusDurationMinutes: 50,
                roundsCompleted: 1,
                xpAwarded: 50
            )
        )
        context.insert(XPRecord(xpAmount: 50, createdAt: Date()))
        let progress = PlayerProgress(
            defaultTargetStreak: 3,
            personalTargetStreak: 2,
            longestDefaultTargetStreak: 5,
            longestPersonalTargetStreak: 4
        )
        context.insert(progress)
        try context.save()

        try GamificationProgressReset.resetAllProgress(container: container, settingsStore: store)

        XCTAssertEqual(store.profileDisplayName, "test123")
        XCTAssertNil(store.personalTargetLastModified)
        XCTAssertNil(store.lifetimeXPResetAt)

        let resetContext = ModelContext(container)
        XCTAssertTrue(try resetContext.fetch(FetchDescriptor<Session>()).isEmpty)
        XCTAssertTrue(try resetContext.fetch(FetchDescriptor<XPRecord>()).isEmpty)
        XCTAssertTrue(try resetContext.fetch(FetchDescriptor<StreakRecord>()).isEmpty)

        let progressRows = try resetContext.fetch(FetchDescriptor<PlayerProgress>())
        XCTAssertEqual(progressRows.count, 1)
        XCTAssertEqual(progressRows[0].defaultTargetStreak, 0)
        XCTAssertEqual(progressRows[0].personalTargetStreak, 0)
        XCTAssertEqual(progressRows[0].longestDefaultTargetStreak, 0)
        XCTAssertEqual(progressRows[0].longestPersonalTargetStreak, 0)
        XCTAssertNil(progressRows[0].lastEvaluatedWeekStart)
        XCTAssertNil(progressRows[0].firstActivityWeekStart)

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testResetLifetimeXPClearsXPButKeepsSessionsAndStreaks() throws {
        let suiteName = "GamificationProgressReset.lifetimeXP.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        store.profileDisplayName = "test123"

        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        let context = ModelContext(container)

        context.insert(
            Session(
                createdAt: Date(),
                focusDurationMinutes: 50,
                roundsCompleted: 1,
                xpAwarded: 50
            )
        )
        context.insert(XPRecord(xpAmount: 238, createdAt: Date()))
        let progress = PlayerProgress(
            defaultTargetStreak: 3,
            personalTargetStreak: 2,
            longestDefaultTargetStreak: 5,
            longestPersonalTargetStreak: 4
        )
        context.insert(progress)
        try context.save()

        try GamificationProgressReset.resetLifetimeXP(container: container, settingsStore: store)

        XCTAssertEqual(store.profileDisplayName, "test123")
        XCTAssertNil(store.personalTargetLastModified)
        XCTAssertNotNil(store.lifetimeXPResetAt)

        let resetContext = ModelContext(container)
        XCTAssertTrue(try resetContext.fetch(FetchDescriptor<XPRecord>()).isEmpty)
        XCTAssertEqual(try resetContext.fetch(FetchDescriptor<Session>()).count, 1)

        let progressRows = try resetContext.fetch(FetchDescriptor<PlayerProgress>())
        XCTAssertEqual(progressRows.count, 1)
        XCTAssertEqual(progressRows[0].defaultTargetStreak, 3)
        XCTAssertEqual(progressRows[0].personalTargetStreak, 2)
        XCTAssertEqual(progressRows[0].longestDefaultTargetStreak, 5)
        XCTAssertEqual(progressRows[0].longestPersonalTargetStreak, 4)

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testResetLifetimeXP_setsWatermarkAndClearsDisplayedTotal() async throws {
        let suiteName = "GamificationProgressReset.watermark.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)
        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        let context = ModelContext(container)

        let legacyDate = Date(timeIntervalSince1970: 1_000_000)
        context.insert(XPRecord(xpAmount: 238, createdAt: legacyDate))
        try context.save()

        try GamificationProgressReset.resetLifetimeXP(container: container, settingsStore: store)
        XCTAssertNotNil(store.lifetimeXPResetAt)

        context.insert(XPRecord(xpAmount: 238, createdAt: legacyDate))
        try context.save()

        let reader = SwiftDataXPStatsReader(container: container, settingsStore: store)
        let total = try await reader.totalAccumulatedXP()
        XCTAssertEqual(total, 0)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
