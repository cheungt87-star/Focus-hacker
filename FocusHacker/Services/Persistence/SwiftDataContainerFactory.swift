import Foundation
import SwiftData

@available(macOS 14.0, *)
enum SwiftDataContainerFactory {
    static var schema: Schema {
        Schema([
            Session.self,
            XPRecord.self,
            StreakRecord.self,
            PlayerProgress.self,
        ])
    }

    static func makePersistentContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            "FocusHackerData",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: FocusHackerMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create persistent container: \(error)")
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            "FocusHackerDataInMemory",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: FocusHackerMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }
}
