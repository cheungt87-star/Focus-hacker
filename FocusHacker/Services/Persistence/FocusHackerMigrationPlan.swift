import Foundation
import SwiftData

@available(macOS 14.0, *)
enum FocusHackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [V2.self, V3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV2toV3]
    }

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: V2.self,
        toVersion: V3.self
    )
}

@available(macOS 14.0, *)
enum V2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Session.self, XPRecord.self, StreakRecord.self, PlayerProgress.self]
    }
}

@available(macOS 14.0, *)
enum V3: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Session.self, XPRecord.self, StreakRecord.self, PlayerProgress.self]
    }
}
