import SwiftData
import SwiftUI

@main
struct Score3DApp: App {
    private let modelContainerResult = Score3DModelContainer.make()

    var body: some Scene {
        WindowGroup {
            switch modelContainerResult {
            case .success(let modelContainer):
                ContentView()
                    .environment(\.locale, Locale(identifier: "fr_FR"))
                    .modelContainer(modelContainer)
            case .failure(let error):
                PersistenceUnavailableView(errorDescription: error.localizedDescription)
                    .environment(\.locale, Locale(identifier: "fr_FR"))
            }
        }
    }
}

private enum Score3DModelContainer {
    static func make() -> Result<ModelContainer, Error> {
        let schema = Schema([
            Archer.self,
            ShootingRound.self,
            ScoreEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return .success(try ModelContainer(for: schema, configurations: [modelConfiguration]))
        } catch {
            return .failure(error)
        }
    }
}

private struct PersistenceUnavailableView: View {
    let errorDescription: String

    var body: some View {
        ContentUnavailableView {
            Label("Données indisponibles", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Score3D ne peut pas ouvrir la base locale. Fermez l’app puis réessayez.")
        } actions: {
            Text(errorDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
