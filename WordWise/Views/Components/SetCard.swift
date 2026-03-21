import SwiftUI; import SwiftData

struct SetCard: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @Environment(\.modelContext) private var ctx
    @State private var navigateStudy = false
    @State private var navigateSpeedRound = false
    @State private var navigateTest = false
    @State private var showDeleteConfirm = false
    
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
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text(set.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(totalCount) \(lm.t("words"))")
                        .font(.subheadline)
                        .foregroundColor(.glassCyan)
                }
                Spacer()
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.cyan)
                .frame(height: 6)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            
            HStack {
                Button(lm.t("study")) { navigateStudy = true }.buttonStyle(GlassButtonStyle())
                Button(lm.t("speed_round")) { navigateSpeedRound = true }.buttonStyle(GlassButtonStyle())
                Button(lm.t("test")) { navigateTest = true }.buttonStyle(GlassButtonStyle())
            }
        }
        .padding()
        .glassEffect()
        .navigationDestination(isPresented: $navigateStudy) { StudySessionView(set: set) }
        .navigationDestination(isPresented: $navigateSpeedRound) { SpeedRoundView(set: set) }
        .navigationDestination(isPresented: $navigateTest) { TestView(set: set) }
        .alert(lm.t("delete_set_q"), isPresented: $showDeleteConfirm) {
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("delete"), role: .destructive) { deleteSet() }
        } message: { Text(lm.t("undone_msg")) }
    }
    
    func deleteSet() {
        for word in set.words { ctx.delete(word) }
        ctx.delete(set)
        try? ctx.save()
    }
}
