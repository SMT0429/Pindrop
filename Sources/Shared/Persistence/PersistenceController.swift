import SwiftData
import Foundation

enum PersistenceController {
    static let appGroupIdentifier = "group.com.smt.tomap"

    static func makeContainer() -> ModelContainer {
        let schema = Schema([HistoryEntry.self, RestaurantList.self, RestaurantItem.self])

        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("[ToMap] App Group container not found: \(appGroupIdentifier)")
        }

        let storeURL = groupURL.appendingPathComponent("tomap.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[ToMap] Failed to create ModelContainer: \(error)")
        }
    }
}
