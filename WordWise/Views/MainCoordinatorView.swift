import SwiftUI

// MARK: - View

struct MainCoordinatorView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @State private var errorHandler = ErrorHandler.shared

    var body: some View {
        @Bindable var coordinator = coordinator
        @Bindable var eh = errorHandler
        
        NavigationSplitView {
            List(selection: $coordinator.selectedTab) {
                NavigationLink(value: AppCoordinator.Tab.home) {
                    Label(lm.t("home"), systemImage: "house")
                }
                NavigationLink(value: AppCoordinator.Tab.library) {
                    Label(lm.t("sets_library"), systemImage: "books.vertical")
                }
                NavigationLink(value: AppCoordinator.Tab.settings) {
                    Label(lm.t("settings"), systemImage: "gearshape")
                }
            }
            .navigationTitle(lm.t("WordWise"))
        } detail: {
            ZStack {
                LinearGradient(
                    colors: [.deepNavy, .glassBack],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                NavigationStack(path: $coordinator.path) {
                    Group {
                        switch coordinator.selectedTab {
                        case .home:
                            HomeView()
                        case .library:
                            SetsLibraryView()
                        case .settings:
                            SettingsView()
                        }
                    }
                .navigationDestination(for: AppScreen.self) { screen in
                    screenView(for: screen)
                }
                .toolbarBackground(.hidden, for: .windowToolbar)
            }
            .background(Color.clear)
        }
    }
        .frame(minWidth: 700, minHeight: 500)
        .alert(lm.t("error_occurred"), isPresented: $eh.showErrorMessage) {
            Button(lm.t("ok"), role: .cancel) { eh.clear() }
        } message: {
            if let error = eh.currentError {
                Text(error.localizedDescription)
            }
        }
    }
    
    @ViewBuilder
    private func screenView(for screen: AppScreen) -> some View {
        switch screen {
        case .home: HomeView()
        case .library: SetsLibraryView()
        case .setDetail(let set): SetDetailView(set: set)
        case .studySession(let set): StudySessionView(set: set)
        case .speedRound(let set): SpeedRoundView(set: set)
        case .test(let set): TestView(set: set)
        case .flashcards(let set): FlashcardsView(set: set)
        case .settings: SettingsView()
        }
    }
}
