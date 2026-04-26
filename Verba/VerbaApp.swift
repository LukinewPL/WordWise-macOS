import SwiftUI
import SwiftData

// MARK: - App

private enum AppWindowMetrics {
    static let width: CGFloat = 1580
    static let height: CGFloat = 980
}

@main struct VerbaApp: App {
    @State private var languageManager = LanguageManager.shared
    @State private var coordinator = AppCoordinator()
    
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: WordSet.self, Word.self, StudySession.self, Folder.self)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainCoordinatorView()
                .frame(width: AppWindowMetrics.width, height: AppWindowMetrics.height)
                .preferredColorScheme(.dark)
                .environment(languageManager)
                .environment(coordinator)
                .environment(WordRepository(modelContext: container.mainContext))
        }
        .modelContainer(container)
        .windowResizability(.contentSize)
        .defaultSize(width: AppWindowMetrics.width, height: AppWindowMetrics.height)
    }
}
