import SwiftData
import SwiftUI

@main
struct Score3DApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Archer.self,
            ShootingRound.self,
            ScoreEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
