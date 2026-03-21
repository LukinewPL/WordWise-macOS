import SwiftUI; import SwiftData; import UniformTypeIdentifiers

struct SetsLibraryView: View {
    @Environment(LanguageManager.self) private var lm
    @Query var sets: [WordSet]
    @Environment(\.modelContext) var ctx
    @State private var showFilePicker = false
    @State private var importError: String? = nil
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Group {
                if sets.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.questionmark").font(.system(size: 60)).foregroundColor(.glassCyan)
                        Text(lm.t("no_sets_yet")).font(.title.bold()).foregroundColor(.white)
                        Button(lm.t("import_file")) { showFilePicker = true }.buttonStyle(GlassButtonStyle())
                    }.padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 350))]) {
                            ForEach(sets) { s in
                                NavigationLink(destination: SetDetailView(set: s)) {
                                    SetCard(set: s)
                                }.buttonStyle(.plain)
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle(lm.t("sets_library"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showFilePicker = true }) { Image(systemName: "plus") }
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: allowedContentTypes) { result in
            switch result {
            case .success(let url): importSet(url: url)
            case .failure(let error): 
                importError = error.localizedDescription
                showError = true
            }
        }
        .alert(lm.t("import_error"), isPresented: $showError, presenting: importError) { _ in
            Button(lm.t("ok"), role: .cancel) { }
        } message: { msg in
            Text(msg)
        }
    }
    
    private var allowedContentTypes: [UTType] {
        var types: [UTType] = [.plainText, .commaSeparatedText, .spreadsheet]
        if let xlsx = UTType(filenameExtension: "xlsx") {
            types.append(xlsx)
        }
        return types
    }
    
    func importSet(url: URL) {
        do {
            try ImportEngine.importFile(url: url, context: ctx, existingSets: sets)
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }
}
