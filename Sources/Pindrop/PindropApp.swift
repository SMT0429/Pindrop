import SwiftUI

@main
struct PindropApp: App {
    private let container = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
