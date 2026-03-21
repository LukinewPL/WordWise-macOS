import SwiftUI
struct MainCoordinatorView: View {
    @Environment(LanguageManager.self) private var lm
    @State private var sel = 0
    var body: some View {
        NavigationSplitView {
            List(selection: $sel) {
                NavigationLink(value: 0) { Label(lm.t("home"), systemImage: "house") }
                NavigationLink(value: 1) { Label(lm.t("sets_library"), systemImage: "books.vertical") }
                NavigationLink(value: 2) { Label(lm.t("settings"), systemImage: "gearshape") }
            }.navigationTitle(lm.t("WordWise"))
        } detail: {
            ZStack {
                LinearGradient(colors: [.deepNavy, .glassBack], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                Group {
                    if sel == 0 { HomeView() }
                    else if sel == 1 { SetsLibraryView() }
                    else if sel == 2 { SettingsView() }
                }
            }
        }
    }
}
