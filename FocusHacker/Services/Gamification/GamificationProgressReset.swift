import Foundation
import SwiftData

@available(macOS 14.0, *)
struct SwiftDataGamificationProgressResetter: GamificationProgressResetting {
    let container: ModelContainer

    func resetAllProgress(settingsStore: UserDefaultsSettingsStore) throws {
        try GamificationProgressReset.resetAllProgress(container: container, settingsStore: settingsStore)
    }

    func resetLifetimeXP(settingsStore: UserDefaultsSettingsStore) throws {
        try GamificationProgressReset.resetLifetimeXP(container: container, settingsStore: settingsStore)
    }
}

/// Wipes local gamification progress while preserving profile display name and app settings.
@available(macOS 14.0, *)
enum GamificationProgressReset {
    static func resetAllProgress(
        container: ModelContainer,
        settingsStore: UserDefaultsSettingsStore
    ) throws {
        let context = ModelContext(container)

        for record in try context.fetch(FetchDescriptor<XPRecord>()) {
            context.delete(record)
        }
        for session in try context.fetch(FetchDescriptor<Session>()) {
            context.delete(session)
        }
        for streak in try context.fetch(FetchDescriptor<StreakRecord>()) {
            context.delete(streak)
        }
        for progress in try context.fetch(FetchDescriptor<PlayerProgress>()) {
            context.delete(progress)
        }

        context.insert(PlayerProgress())
        try context.save()

        settingsStore.personalTargetLastModified = nil
        settingsStore.lifetimeXPResetAt = nil
    }

    /// Clears lifetime XP and badge progress; sessions, charts, and streaks are preserved.
    static func resetLifetimeXP(
        container: ModelContainer,
        settingsStore: UserDefaultsSettingsStore
    ) throws {
        let context = ModelContext(container)
        for record in try context.fetch(FetchDescriptor<XPRecord>()) {
            context.delete(record)
        }
        try context.save()
        settingsStore.lifetimeXPResetAt = Date()
    }
}
