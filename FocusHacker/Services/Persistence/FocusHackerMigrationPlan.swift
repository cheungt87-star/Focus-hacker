import Foundation
import SwiftData

@available(macOS 14.0, *)
enum FocusHackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [V2.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

@available(macOS 14.0, *)
enum V2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Session.self, XPRecord.self, StreakRecord.self, PlayerProgress.self]
    }
}
