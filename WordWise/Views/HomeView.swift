import SwiftUI; import SwiftData
struct HomeView: View {
    @Environment(LanguageManager.self) private var lm
    @Query var sessions: [StudySession]
    var todayWords: Int { sessions.filter { Calendar.current.isDateInToday($0.date) }.reduce(0){$0 + $1.wordsStudied} }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(Date().hour < 12 ? lm.t("good_morning") : lm.t("good_evening")).font(.largeTitle.bold()).foregroundColor(.white)
                HStack(spacing: 20) {
                    VStack { Image(systemName: "flame.fill").foregroundColor(.orange).font(.largeTitle); Text("\(lm.t("streak")): 0").font(.title) }.glassEffect()
                    VStack { Text("\(todayWords)").font(.system(size: 40, weight: .bold)).foregroundColor(.glassCyan); Text(lm.t("words_today")).font(.headline) }.glassEffect()
                }
                Text(lm.t("activity")).font(.title2.bold())
                HeatmapView(sessions: sessions).glassEffect()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}
extension Date { var hour: Int { Calendar.current.component(.hour, from: self) } }
