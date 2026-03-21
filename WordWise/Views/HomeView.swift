import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(LanguageManager.self) private var lm
    @Query(sort: \StudySession.date, order: .reverse) var sessions: [StudySession]
    
    var todayWords: Int {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.wordsStudied }
    }
    
    var streak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let datesWithStudy = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        
        if datesWithStudy.isEmpty { return 0 }
        
        var currentStreak = 0
        var checkDate = today
        
        if !datesWithStudy.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            if !datesWithStudy.contains(yesterday) { return 0 }
            checkDate = yesterday
        }
        
        while datesWithStudy.contains(checkDate) {
            currentStreak += 1
            guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = nextDate
        }
        
        return currentStreak
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text(greeting)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                HStack(spacing: 30) {
                    Spacer()
                    statCard(
                        icon: "flame.fill",
                        value: "\(streak)",
                        label: lm.t("streak"),
                        iconColor: streak > 0 ? Color.orange : Color.gray
                    )
                    
                    statCard(
                        icon: nil,
                        value: "\(todayWords)",
                        label: lm.t("words_today"),
                        valueColor: .glassCyan
                    )
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(lm.t("activity"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    VStack {
                        HeatmapView(sessions: sessions)
                            .padding(.vertical, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .glassEffect()
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
        }
        .background(Color.deepNavy.ignoresSafeArea())
    }
    
    private func statCard(icon: String?, value: String, label: String, iconColor: Color = .white, valueColor: Color = .white) -> some View {
        VStack(spacing: 8) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(iconColor)
            }
            
            Text(value)
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(valueColor)
            
            Text(label)
                .font(.headline.bold())
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 280, height: 200)
        .glassEffect()
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? lm.t("good_morning") : lm.t("good_evening")
    }
}
