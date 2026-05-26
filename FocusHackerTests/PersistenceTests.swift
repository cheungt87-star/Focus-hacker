import SwiftData
import XCTest
@testable import FocusHacker

final class PersistenceTests: XCTestCase {
    func testUserDefaultsSettingsStoreRegistersExpectedDefaults() {
        let suiteName = "PersistenceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)

        XCTAssertEqual(store.focusDurationSeconds, 25 * 60)
        XCTAssertEqual(store.shortRestDurationSeconds, 5 * 60)
        XCTAssertEqual(store.longRestDurationSeconds, 15 * 60)
        XCTAssertEqual(store.roundsPerSession, 4)
        XCTAssertEqual(store.cyclesPerSession, 1)
    }

    func testApproximateSessionWallClockCalculation() {
        let fourByTwentyFive = TimerConfiguration(
            focusDurationSeconds: 25 * 60,
            shortRestDurationSeconds: 5 * 60,
            longRestDurationSeconds: 15 * 60,
            roundsPerSession: 4,
            cyclesPerSession: 1
        )
        XCTAssertEqual(fourByTwentyFive.approximateWallClockMinutes, 130)

        let quickSingleRestless = TimerConfiguration(
            focusDurationSeconds: 50 * 60,
            shortRestDurationSeconds: 5 * 60,
            longRestDurationSeconds: 0,
            roundsPerSession: 1,
            cyclesPerSession: 1
        )
        XCTAssertEqual(quickSingleRestless.approximateWallClockMinutes, 50)

        let twoCyclesSameDurations = TimerConfiguration(
            focusDurationSeconds: 25 * 60,
            shortRestDurationSeconds: 5 * 60,
            longRestDurationSeconds: 15 * 60,
            roundsPerSession: 4,
            cyclesPerSession: 2
        )
        XCTAssertEqual(twoCyclesSameDurations.approximateWallClockMinutes, 245)
    }

    func testFullOnboardingMigratesFromLegacyBlockerFlag() {
        let suiteName = "PersistenceTests.OnboardingMigration.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)

        XCTAssertFalse(store.hasCompletedFullOnboarding)

        store.didPresentBlockerOnboarding = true
        XCTAssertTrue(store.hasCompletedFullOnboarding)

        store.hasCompletedFullOnboarding = false
        XCTAssertFalse(store.hasCompletedFullOnboarding)

        store.hasCompletedFullOnboarding = true
        store.didPresentBlockerOnboarding = false
        XCTAssertTrue(store.hasCompletedFullOnboarding)

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testBlockedDomainsMirrorIntoAppGroupSuite() {
        let standardSuite = "PersistenceTests.Std.\(UUID().uuidString)"
        let sharedSuite = "group.PersistenceTests.\(UUID().uuidString)"
        guard let standardDefaults = UserDefaults(suiteName: standardSuite),
              let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suites")
            return
        }
        standardDefaults.removePersistentDomain(forName: standardSuite)

        let store = UserDefaultsSettingsStore(userDefaults: standardDefaults, appGroupSuiteName: sharedSuite)
        store.blockedDomains = ["twitter.com"]
        store.blockedBundleIdentifiers = ["com.example.app"]

        XCTAssertEqual(
            sharedDefaults.stringArray(forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains),
            ["twitter.com"]
        )
        XCTAssertEqual(
            sharedDefaults.stringArray(forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs),
            ["com.example.app"]
        )
    }

    func testUserDefaultsSettingsStoreClampsTimerConfigurationRanges() {
        let suiteName = "PersistenceTests.Clamp.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)

        store.focusDurationSeconds = 0
        store.shortRestDurationSeconds = 9_999
        store.longRestDurationSeconds = 0
        store.roundsPerSession = 100
        store.cyclesPerSession = 100

        XCTAssertEqual(store.focusDurationSeconds, 1)
        XCTAssertEqual(store.shortRestDurationSeconds, 1_859)
        XCTAssertEqual(store.longRestDurationSeconds, 1)
        XCTAssertEqual(store.roundsPerSession, 99)
        XCTAssertEqual(store.cyclesPerSession, 10)
    }

    func testDurationSecondsFallsBackToLegacyMinuteKeysWhenSecondsKeyMissing() {
        let suiteName = "PersistenceTests.LegacyDurationMigration.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(42, forKey: "settings.timer.focusDurationMinutes")
        defaults.set(7, forKey: "settings.timer.shortRestDurationMinutes")
        defaults.set(18, forKey: "settings.timer.longRestDurationMinutes")
        defaults.removeObject(forKey: "settings.timer.focusDurationSeconds")
        defaults.removeObject(forKey: "settings.timer.shortRestDurationSeconds")
        defaults.removeObject(forKey: "settings.timer.longRestDurationSeconds")

        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)

        XCTAssertEqual(store.focusDurationSeconds, 42 * 60)
        XCTAssertEqual(store.shortRestDurationSeconds, 7 * 60)
        XCTAssertEqual(store.longRestDurationSeconds, 18 * 60)
    }

    /// Regression: lease renewal calls `persistSuiteBlockingFieldsToSharedFile` frequently; it must not
    /// wipe `blockedIPLiterals` (Chrome IP-only flows depend on this set).
    func testLeasePersistPreservesBlockedIPLiterals() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-BlockerSharedState-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let sharedSuite = "group.PersistenceTests.IPPreserve.\(UUID().uuidString)"
        guard let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suite")
            return
        }
        sharedDefaults.removePersistentDomain(forName: sharedSuite)
        sharedDefaults.set(["example.com"], forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains)
        sharedDefaults.set([String](), forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs)

        let markerIPs = ["203.0.113.1"]
        BlockerSharedStateFile.mergeBlockedIPLiteralsOnly(markerIPs, hostBlockerSuite: sharedDefaults)
        XCTAssertEqual(BlockerSharedStateFile.read()?.blockedIPLiterals, markerIPs)

        let lease = Date().timeIntervalSinceReferenceDate + 1_000
        BlockerSharedStateFile.persistSuiteBlockingFieldsToSharedFile(
            suiteDefaults: sharedDefaults,
            blockingIsActive: true,
            leaseUntilReference: lease
        )
        guard let payload = BlockerSharedStateFile.read() else {
            XCTFail("Expected shared state after persist")
            return
        }
        XCTAssertEqual(payload.blockedIPLiterals, markerIPs)
        XCTAssertEqual(payload.blockedDomains, ["example.com"])
        XCTAssertTrue(payload.blockingIsActive)
        XCTAssertEqual(payload.blockingLeaseExpiresAtReference, lease, accuracy: 0.001)
    }

    func testBlockingEpochMirroredIntoSharedJSON() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-Epoch-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let sharedSuite = "group.PersistenceTests.Epoch.\(UUID().uuidString)"
        guard let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suite")
            return
        }
        sharedDefaults.removePersistentDomain(forName: sharedSuite)
        let epoch = "epoch-\(UUID().uuidString)"
        sharedDefaults.set(epoch, forKey: BlockerAppGroup.UserDefaultsKey.blockingEpoch)
        sharedDefaults.set(["a.com"], forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains)
        sharedDefaults.set([String](), forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs)
        sharedDefaults.set(true, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        let lease = Date().timeIntervalSinceReferenceDate + 800
        sharedDefaults.set(lease, forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)

        BlockingSnapshotWriter.commitHostSuiteProjectionToSharedJSON(suite: sharedDefaults)

        guard let out = BlockerSharedStateFile.read() else {
            XCTFail("Expected shared JSON")
            return
        }
        XCTAssertEqual(out.blockingEpoch, epoch)
        XCTAssertTrue(out.blockingIsActive)
        XCTAssertEqual(out.blockingLeaseExpiresAtReference, lease, accuracy: 0.001)
    }

    /// Regression: a long-running IP refresh can finish after pause/resume; the merge must not republish a
    /// paused `blockingIsActive` / lease from an on-disk snapshot when the App Group suite already reflects resume.
    func testMergeBlockedIPLiteralsReconcilesBlockingInstructionFromSuite() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-IPMergeReconcile-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let sharedSuite = "group.PersistenceTests.IPMergeReconcile.\(UUID().uuidString)"
        guard let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suite")
            return
        }
        sharedDefaults.removePersistentDomain(forName: sharedSuite)
        sharedDefaults.set(["example.com"], forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains)
        sharedDefaults.set([String](), forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs)

        let resumedLease = Date().timeIntervalSinceReferenceDate + 2_000
        sharedDefaults.set(true, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        sharedDefaults.set(resumedLease, forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)

        // Simulate stale shared JSON (paused) left on disk while suite already shows resumed focus.
        BlockerSharedStateFile.write(
            BlockerSharedStateFile.Payload(
                blockingIsActive: false,
                blockingLeaseExpiresAtReference: 0,
                blockedDomains: ["example.com"],
                blockedBundleIDs: [],
                blockedIPLiterals: ["192.0.2.1"]
            )
        )

        BlockerSharedStateFile.mergeBlockedIPLiteralsOnly(["192.0.2.2"], hostBlockerSuite: sharedDefaults)

        guard let after = BlockerSharedStateFile.read() else {
            XCTFail("Expected shared state after IP merge")
            return
        }
        XCTAssertEqual(after.blockedIPLiterals, ["192.0.2.2"])
        XCTAssertTrue(after.blockingIsActive)
        XCTAssertEqual(after.blockingLeaseExpiresAtReference, resumedLease, accuracy: 0.001)
    }

    func testMergeBlockedIPLiteralsPreservesValidDiskLeaseWhenSuiteInactive() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-IPMergePreserveLease-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let sharedSuite = "group.PersistenceTests.IPMergePreserve.\(UUID().uuidString)"
        guard let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suite")
            return
        }
        sharedDefaults.removePersistentDomain(forName: sharedSuite)
        sharedDefaults.set(false, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        sharedDefaults.set(0, forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)

        let activeLease = Date().timeIntervalSinceReferenceDate + 2_000
        BlockerSharedStateFile.write(
            BlockerSharedStateFile.Payload(
                blockingIsActive: true,
                blockingLeaseExpiresAtReference: activeLease,
                blockedDomains: ["example.com"],
                blockedBundleIDs: [],
                blockedIPLiterals: ["192.0.2.1"]
            )
        )

        BlockerSharedStateFile.mergeBlockedIPLiteralsOnly(
            ["192.0.2.2"],
            hostBlockerSuite: sharedDefaults,
            preserveValidDiskLeaseWhenSuiteInactive: true
        )

        guard let after = BlockerSharedStateFile.read() else {
            XCTFail("Expected shared state after IP merge")
            return
        }
        XCTAssertEqual(after.blockedIPLiterals, ["192.0.2.2"])
        XCTAssertTrue(after.blockingIsActive)
        XCTAssertEqual(after.blockingLeaseExpiresAtReference, activeLease, accuracy: 0.001)
    }

    func testMergeBlockedIPLiteralsClearsStaleDiskLeaseAfterRestWhenSuiteInactive() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-IPMergeClearRest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let sharedSuite = "group.PersistenceTests.IPMergeClearRest.\(UUID().uuidString)"
        guard let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suite")
            return
        }
        sharedDefaults.removePersistentDomain(forName: sharedSuite)
        sharedDefaults.set(false, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        sharedDefaults.set(0, forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)

        let staleLease = Date().timeIntervalSinceReferenceDate + 2_000
        BlockerSharedStateFile.write(
            BlockerSharedStateFile.Payload(
                blockingIsActive: true,
                blockingLeaseExpiresAtReference: staleLease,
                blockedDomains: ["example.com"],
                blockedBundleIDs: [],
                blockedIPLiterals: ["192.0.2.1"]
            )
        )

        BlockerSharedStateFile.mergeBlockedIPLiteralsOnly(["192.0.2.2"], hostBlockerSuite: sharedDefaults)

        guard let after = BlockerSharedStateFile.read() else {
            XCTFail("Expected shared state after IP merge")
            return
        }
        XCTAssertEqual(after.blockedIPLiterals, ["192.0.2.2"])
        XCTAssertFalse(after.blockingIsActive)
        XCTAssertEqual(after.blockingLeaseExpiresAtReference, 0, accuracy: 0.001)
    }

    func testHostQuitDeactivationClearsSharedBlocking() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-HostQuit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let sharedSuite = "group.PersistenceTests.HostQuit.\(UUID().uuidString)"
        guard let sharedDefaults = UserDefaults(suiteName: sharedSuite) else {
            XCTFail("Could not allocate UserDefaults suite")
            return
        }
        sharedDefaults.removePersistentDomain(forName: sharedSuite)
        sharedDefaults.set(["x.com"], forKey: BlockerAppGroup.UserDefaultsKey.blockedDomains)
        sharedDefaults.set([String](), forKey: BlockerAppGroup.UserDefaultsKey.blockedBundleIDs)
        sharedDefaults.set(true, forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive)
        let lease = Date().timeIntervalSinceReferenceDate + 999
        sharedDefaults.set(lease, forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference)

        BlockerSharedStateFile.persistSuiteBlockingFieldsToSharedFile(
            suiteDefaults: sharedDefaults,
            blockingIsActive: true,
            leaseUntilReference: lease
        )
        XCTAssertTrue(BlockerSharedStateFile.read()?.blockingIsActive ?? false)

        BlockerSharedStateFile.deactivateBlockingForHostQuit(suiteDefaults: sharedDefaults)

        XCTAssertFalse(sharedDefaults.bool(forKey: BlockerAppGroup.UserDefaultsKey.blockingIsActive))
        XCTAssertNil(sharedDefaults.object(forKey: BlockerAppGroup.UserDefaultsKey.blockingLeaseExpiresAtReference))
        XCTAssertNil(sharedDefaults.object(forKey: BlockerAppGroup.UserDefaultsKey.blockingEpoch))
        guard let payload = BlockerSharedStateFile.read() else {
            XCTFail("Expected shared state after quit teardown")
            return
        }
        XCTAssertFalse(payload.blockingIsActive)
        XCTAssertEqual(payload.blockingLeaseExpiresAtReference, 0, accuracy: 0.001)
        XCTAssertNil(payload.blockingEpoch)
        XCTAssertEqual(payload.blockedDomains, ["x.com"])
    }

    /// Regression: `mergeBlocklistsOnly` must not write `blockingIsActive=false` when the JSON exists but
    /// decode fails — that produced extension-side `leaseValid=false` with domains still present (pause/resume).
    func testMergeBlocklistsOnlySkipsWhenSharedFileUnreadable() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusHackerTests-MergeBl-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let envKey = "BLOCKER_SHARED_STATE_DIR"
        let previousEnv = getenv(envKey).map { String(cString: $0) }
        setenv(envKey, tmpDir.path, 1)
        defer {
            if let previousEnv, !previousEnv.isEmpty {
                setenv(envKey, previousEnv, 1)
            } else {
                unsetenv(envKey)
            }
            try? FileManager.default.removeItem(at: tmpDir)
        }

        let url = tmpDir.appendingPathComponent(BlockerSharedStateFile.filename)
        try "{ not valid json at all".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertNil(BlockerSharedStateFile.read())

        BlockerSharedStateFile.mergeBlocklistsOnly(domains: ["z.com"], bundleIDs: ["com.z"])

        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("not valid json"), "Corrupt file should be left untouched when decode fails")
        XCTAssertNil(BlockerSharedStateFile.read())
    }

    func testInMemorySwiftDataPersistsWithinContainerLifetime() throws {
        guard #available(macOS 14.0, *) else {
            XCTAssertTrue(true)
            return
        }
        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        context.insert(Session(
            createdAt: Date(),
            focusDurationMinutes: 25,
            roundsCompleted: 1,
            xpAwarded: 25,
            startedAt: Date(),
            endedAt: Date(),
            configuredRounds: 4,
            didComplete: true,
            totalFocusMinutes: 25
        ))
        try context.save()

        let descriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(descriptor)
        XCTAssertEqual(sessions.count, 1)
    }

    @available(macOS 14.0, *)
    func testSwiftDataSessionLifecycleLinksXPToSession() async throws {
        let suiteName = "PersistenceTests.sessionXP.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsSettingsStore(userDefaults: defaults, appGroupSuiteName: nil)

        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        let recorder = SwiftDataSessionLifecycleRecorder(container: container, settingsStore: store)
        let sessionUUID = UUID()
        let startedAt = Date()
        try await recorder.recordSessionBegan(sessionUUID: sessionUUID, startedAt: startedAt)
        let completed = CompletedSessionRecord(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(120),
            totalFocusMinutes: 100,
            roundsCompleted: 1,
            configuredRounds: 1,
            xpAwarded: 150,
            naturallyConcluded: true
        )
        try await recorder.recordSessionCompleted(completed, sessionUUID: sessionUUID)
        let reader = SwiftDataGamificationDashboardReader(container: container, settingsStore: store)
        let total = try await reader.totalAccumulatedXP()
        XCTAssertEqual(total, 150)

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testMigrationFixtureSeedsV1Entities() {
        guard #available(macOS 14.0, *) else {
            XCTAssertTrue(true)
            return
        }
        let fixture = MigrationFixture.v1Seed()
        XCTAssertEqual(fixture.sessions.count, 1)
        XCTAssertEqual(fixture.xpRecords.count, 1)
        XCTAssertEqual(fixture.streakRecords.count, 1)
        XCTAssertEqual(fixture.playerProgressRows.count, 1)
    }
}

@available(macOS 14.0, *)
struct MigrationFixture {
    let sessions: [Session]
    let xpRecords: [XPRecord]
    let streakRecords: [StreakRecord]
    let playerProgressRows: [PlayerProgress]

    static func v1Seed() -> MigrationFixture {
        MigrationFixture(
            sessions: [Session(createdAt: Date(), focusDurationMinutes: 25, roundsCompleted: 1, xpAwarded: 25, sessionUUID: nil)],
            xpRecords: [XPRecord(xpAmount: 50, createdAt: Date(), focusMinutesContributing: 25, session: nil)],
            streakRecords: [StreakRecord(streakValue: 1, evaluatedAt: Date(), missedDaysBeforeEvaluation: 0)],
            playerProgressRows: [PlayerProgress()]
        )
    }
}
