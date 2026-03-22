import SwiftUI; import SwiftData; import UniformTypeIdentifiers

struct SetsLibraryView: View {
    @Environment(LanguageManager.self) private var lm
    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query(sort: \WordSet.name) private var allSets: [WordSet]
    @Environment(\.modelContext) var ctx
    @State private var showFilePicker = false
    @State private var importError: String? = nil
    @State private var showError = false
    @State private var showNewFolderAlert = false
    @State private var dragOverFolderID: UUID? = nil
    @State private var dragOverUnfiled = false
    @State private var newFolderName: String = ""
    @State private var expandedFolders: Set<UUID> = []
    @State private var renamingFolderID: UUID? = nil
    @State private var folderRenameText: String = ""
    
    private var ungroupedSets: [WordSet] {
        allSets.filter { $0.folder == nil }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allSets.isEmpty && folders.isEmpty {
                    DropZoneView(showFilePicker: $showFilePicker)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(folders) { folder in
                                FolderSectionView(
                                    folder: folder,
                                    dragOverFolderID: $dragOverFolderID,
                                    expandedFolders: $expandedFolders,
                                    renamingFolderID: $renamingFolderID,
                                    folderRenameText: $folderRenameText,
                                    onDrop: { ids in handleDrop(ids: ids, to: folder) }
                                )
                            }
                            
                            if !allSets.isEmpty {
                                UngroupedSectionView(
                                    ungroupedSets: ungroupedSets,
                                    dragOverUnfiled: $dragOverUnfiled,
                                    onDrop: { ids in handleDrop(ids: ids, to: nil) }
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(lm.t("sets_library"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: { showNewFolderAlert = true }) {
                            Label(lm.t("new_folder"), systemImage: "folder.badge.plus")
                        }
                        Button(action: { showFilePicker = true }) {
                            Label(lm.t("import"), systemImage: "plus")
                        }
                    }
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
        .alert(lm.t("new_folder"), isPresented: $showNewFolderAlert) {
            TextField(lm.t("new_folder_name"), text: $newFolderName)
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("create")) { createFolder() }
        }
    }
    
    private func handleDrop(ids: [String], to folder: Folder?) -> Bool {
        let allWordSets = (try? ctx.fetch(FetchDescriptor<WordSet>())) ?? []
        withAnimation(.easeInOut(duration: 0.25)) {
            for idString in ids {
                if let set = allWordSets.first(where: { $0.id.uuidString == idString }) {
                    set.folder = folder
                }
            }
        }
        try? ctx.save()
        return true
    }
    
    private func createFolder() {
        let folder = Folder(name: newFolderName)
        ctx.insert(folder)
        try? ctx.save()
        newFolderName = ""
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
            try ImportEngine.importFile(url: url, context: ctx, existingSets: allSets)
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }
}

private struct DropZoneView: View {
    @Binding var showFilePicker: Bool
    @Environment(LanguageManager.self) private var lm
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.glassCyan)
            Text(lm.t("no_sets_yet"))
                .font(.title.bold())
                .foregroundColor(.white)
            Button(lm.t("import_file")) { 
                showFilePicker = true 
            }
            .buttonStyle(GlassButtonStyle())
        }
        .padding()
    }
}

private struct FolderSectionView: View {
    let folder: Folder
    @Binding var dragOverFolderID: UUID?
    @Binding var expandedFolders: Set<UUID>
    @Binding var renamingFolderID: UUID?
    @Binding var folderRenameText: String
    let onDrop: ([String]) -> Bool
    
    @Environment(LanguageManager.self) private var lm
    @Environment(\.modelContext) private var ctx

    var body: some View {
        let isExpanded = !expandedFolders.contains(folder.id)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundColor(.secondary)
                    .animation(.spring(bounce: 0.2), value: isExpanded)
                
                if renamingFolderID == folder.id {
                    TextField("", text: $folderRenameText)
                        .textFieldStyle(.plain)
                        .font(.title3.bold())
                        .onSubmit {
                            folder.name = folderRenameText
                            renamingFolderID = nil
                            try? ctx.save()
                        }
                } else {
                    Label(folder.name, systemImage: "folder.fill")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .onTapGesture(count: 2) {
                            folderRenameText = folder.name
                            renamingFolderID = folder.id
                        }
                }
                
                Spacer()
                
                if dragOverFolderID == folder.id {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.glassCyan)
                }
            }
            .padding()
            .background(dragOverFolderID == folder.id ? Color.glassCyan.opacity(0.15) : Color.white.opacity(0.01))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(bounce: 0.2)) {
                    if expandedFolders.contains(folder.id) {
                        _ = expandedFolders.remove(folder.id)
                    } else {
                        expandedFolders.insert(folder.id)
                    }
                }
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(dragOverFolderID == folder.id ? Color.cyan : Color.clear, lineWidth: 2)
            )
            
            if isExpanded && !folder.sets.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(folder.sets.sorted(by: { $0.name < $1.name })) { s in
                                NavigationLink(destination: SetDetailView(set: s)) {
                                    SetCard(set: s)
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                    }
                    .transition(.opacity)
                }
                .clipped()
            }
        }
        .padding(.horizontal)
        .contextMenu {
            Button(lm.t("rename")) {
                folderRenameText = folder.name
                renamingFolderID = folder.id
            }
            Button(lm.t("delete"), role: .destructive) {
                ctx.delete(folder)
                try? ctx.save()
            }
        }
        .dropDestination(for: String.self) { ids, _ in
            onDrop(ids)
        } isTargeted: { targeted in
            dragOverFolderID = targeted ? folder.id : nil
            if targeted && !isExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if dragOverFolderID == folder.id {
                        withAnimation(.spring(bounce: 0.2)) {
                            _ = expandedFolders.remove(folder.id)
                        }
                    }
                }
            }
        }
    }
}

private struct UngroupedSectionView: View {
    let ungroupedSets: [WordSet]
    @Binding var dragOverUnfiled: Bool
    let onDrop: ([String]) -> Bool
    @Environment(LanguageManager.self) private var lm

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(lm.t("unfiled"))
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Spacer()
                if dragOverUnfiled {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.glassCyan)
                }
            }
            .padding()
            .background(dragOverUnfiled ? Color.glassCyan.opacity(0.15) : Color.white.opacity(0.01))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(dragOverUnfiled ? Color.cyan : Color.clear, lineWidth: 2)
            )
            .dropDestination(for: String.self) { ids, _ in
                onDrop(ids)
            } isTargeted: { targeted in
                dragOverUnfiled = targeted
            }
                
            if !ungroupedSets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.fixed(350))], alignment: .leading) {
                        HStack(spacing: 20) {
                            ForEach(ungroupedSets) { s in
                                NavigationLink(destination: SetDetailView(set: s)) {
                                    SetCard(set: s)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal)
    }
}
