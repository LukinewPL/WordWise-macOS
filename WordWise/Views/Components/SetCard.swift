import SwiftUI; import SwiftData

struct SetCard: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @Environment(\.modelContext) private var ctx
    @State private var navigateStudy = false
    @State private var navigateSpeedRound = false
    @State private var navigateTest = false
    @State private var showDeleteConfirm = false
    @State private var showRenameAlert = false
    @State private var newName = ""
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var appearing = false
    
    // Explicitly compute to ensure reactivity when underlying words change
    private var masteredCount: Int {
        get { set.words.filter { $0.isMastered }.count }
    }
    private var totalCount: Int {
        get { set.words.count }
    }
    private var progress: Double {
        get { Double(masteredCount) / Double(max(1, totalCount)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            headerSection
            
            HStack(spacing: DesignSystem.Spacing.small) {
                actionButton(lm.t("study"), icon: "book.fill") { navigateStudy = true }
                actionButton(lm.t("speed_round"), icon: "bolt.fill") { navigateSpeedRound = true }
                actionButton(lm.t("test"), icon: "checkmark.circle.fill") { navigateTest = true }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(minWidth: 280, maxWidth: .infinity)
        .premiumGlass()
        .onAppear { withAnimation { appearing = true } }
        .transition(.scale(0.95).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appearing)
        .draggable(set.id.uuidString) {
            dragPreview
        }
        .contextMenu {
            contextMenuContent
        }
        .alert(lm.t("rename_set"), isPresented: $showRenameAlert) {
            TextField(lm.t("new_name"), text: $newName)
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("save")) {
                set.name = newName
                try? ctx.save()
            }
        }
        .navigationDestination(isPresented: $navigateStudy) { StudySessionView(set: set) }
        .navigationDestination(isPresented: $navigateSpeedRound) { SpeedRoundView(set: set) }
        .navigationDestination(isPresented: $navigateTest) { TestView(set: set) }
        .alert(lm.t("delete_set_q"), isPresented: $showDeleteConfirm) {
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("delete"), role: .destructive) { deleteSet() }
        } message: { Text(lm.t("undone_msg")) }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(totalCount) \(lm.t("words"))")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary.opacity(0.8))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.glassCyan, .blue, .glassCyan], center: .center),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
        }
    }
    
    private var dragPreview: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(set.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(set.words.count) \(lm.t("words"))")
                    .font(.caption)
                    .foregroundStyle(.cyan.opacity(0.8))
            }
        }
        .padding()
        .background(DesignSystem.Colors.background.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2)))
    }
    
    private var contextMenuContent: some View {
        Group {
            Button {
                newName = set.name
                showRenameAlert = true
            } label: {
                Label(lm.t("rename"), systemImage: "pencil")
            }
            
            Menu {
                Button {
                    set.folder = nil
                    try? ctx.save()
                } label: { Label(lm.t("none"), systemImage: "xmark") }
                
                ForEach(folders) { f in
                    Button(f.name) {
                        set.folder = f
                        try? ctx.save()
                    }
                }
            } label: { Label(lm.t("move_to_folder"), systemImage: "folder") }
            
            Divider()
            
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label(lm.t("delete"), systemImage: "trash")
            }
        }
    }
    
    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private func deleteSet() {
        for word in set.words { ctx.delete(word) }
        ctx.delete(set)
        do {
            try ctx.save()
        } catch {
            print("WordWise: Save failed — \(error)")
        }
    }
}
