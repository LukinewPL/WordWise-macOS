import SwiftUI

struct SetDetailView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @Bindable var set: WordSet
    
    var body: some View {
        VStack {
            HStack {
                Button(lm.t("study")) {
                    coordinator.navigate(to: .studySession(set))
                }
                .buttonStyle(GlassButtonStyle())

                Button(lm.t("speed_round")) {
                    coordinator.navigate(to: .speedRound(set))
                }
                .buttonStyle(GlassButtonStyle())

                Button(lm.t("test")) {
                    coordinator.navigate(to: .test(set))
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding()

            Picker(
                lm.t("translation"),
                selection: $set.translationDirectionRaw
            ) {
                Text("PL → EN").tag(0)
                Text("EN → PL").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List(set.words) { w in
                HStack {
                    Text(w.polish)
                    Spacer()
                    Text(w.english)
                    if w.isMastered {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(set.name)
        .background(Color.deepNavy.ignoresSafeArea())
    }
}

