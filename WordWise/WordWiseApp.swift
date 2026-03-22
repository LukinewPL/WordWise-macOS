import SwiftUI
import SwiftData

@main struct WordWiseApp: App {
    @State private var languageManager = LanguageManager.shared
    var body: some Scene {
        WindowGroup {
            MainCoordinatorView()
                .preferredColorScheme(.dark)
                .environment(languageManager)
        }
        .modelContainer(for: [WordSet.self, Word.self, StudySession.self, Folder.self])
        .windowResizability(.contentMinSize)
        .defaultSize(width: 800, height: 600)
    }
}
