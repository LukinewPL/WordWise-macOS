import SwiftUI
import SwiftData

// MARK: - View

struct HomeView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @State private var vm = HomeViewModel()
    @State private var animateCircles = false
    
    var body: some View {
        ZStack {
            // Premium background
            DesignSystem.Colors.background.ignoresSafeArea()
            
            ZStack {
                Circle().fill(Color.glassCyan.opacity(0.12)).frame(width: 400).offset(x: animateCircles ? 150 : -50, y: animateCircles ? -200 : 100)
                Circle().fill(Color.blue.opacity(0.1)).frame(width: 300).offset(x: animateCircles ? -200 : 100, y: animateCircles ? 150 : -100)
            }
            .blur(radius: 80)
            .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animateCircles)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    headerSection
                    
                    HStack(spacing: DesignSystem.Spacing.large) {
                        statCard(
                            icon: "flame.fill",
                            value: vm.streak,
                            label: lm.t("streak"),
                            iconColor: vm.streak > 0 ? Color.orange : Color.gray
                        )
                        
                        statCard(
                            icon: "checkmark.circle.fill",
                            value: vm.todayWords,
                            label: lm.t("words_today"),
                            iconColor: .glassCyan
                        )
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text(lm.t("activity"))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        HStack {
                            Spacer()
                            HeatmapView(sessions: vm.sessions)
                                .padding(.vertical, DesignSystem.Spacing.medium)
                                .premiumGlass()
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.large)
            }
        }
        .onAppear {
            vm.setup(repository: repository)
            animateCircles = true
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lm.t("welcome_back"))
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
            Text(lm.t(vm.greeting))
                .vibrantTitle()
        }
        .padding(.horizontal)
    }
    
    private func statCard(icon: String?, value: Int, label: String, iconColor: Color = .white, valueColor: Color = .white) -> some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            Text("\(value)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
                .contentTransition(.numericText())
                .animation(.spring, value: value)
            
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .premiumGlass()
    }
}
