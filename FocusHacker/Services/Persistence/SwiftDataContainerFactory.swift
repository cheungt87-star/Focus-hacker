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
                configurations: [configuration]
            )
        } catch {
            removePersistentStoreFiles(for: configuration)
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                )
            } catch {
                fatalError("Failed to create persistent container after store reset: \(error)")
            }
        }
    }

    private static func removePersistentStoreFiles(for configuration: ModelConfiguration) {
        let baseURL = configuration.url
        let manager = FileManager.default
        let candidates = [
            baseURL,
            baseURL.appendingPathExtension("shm"),
            baseURL.appendingPathExtension("wal")
        ]
        for url in candidates where manager.fileExists(atPath: url.path) {
            try? manager.removeItem(at: url)
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
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }
}
