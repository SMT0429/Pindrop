import SwiftUI

@main
struct ToMapApp: App {
    private let container = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
