import SwiftUI; import SwiftData
struct HeatmapView: View {
    let sessions: [StudySession]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<12) { week in
                VStack(spacing: 4) {
                    ForEach(0..<7) { day in RoundedRectangle(cornerRadius: 3).fill(Color.glassCyan.opacity(0.3)).frame(width: 15, height: 15) }
                }
            }
        }
    }
}
