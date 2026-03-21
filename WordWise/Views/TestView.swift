import SwiftUI
import SwiftData

struct TestView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var isSetup = true
    @State private var isFinished = false
    @State private var questionCount = 10.0
    @State private var isMultipleChoice = true
    
    @State private var queue: [Word] = []
    @State private var currentIdx = 0
    @State private var score = 0
    @State private var answer = ""
    @State private var mcOptions: [String] = []
    @State private var feedbackColor: Color = .clear
    
    @Environment(\.dismiss) private var dismiss
    
    var current: Word? { queue.indices.contains(currentIdx) ? queue[currentIdx] : nil }
    var prompt: String {
        get { set.translationDirectionRaw == 0 ? current?.polish ?? "" : current?.english ?? "" }
    }
    var target: String {
        get { set.translationDirectionRaw == 0 ? current?.english ?? "" : current?.polish ?? "" }
    }
    
    var body: some View {
        VStack {
            if isSetup {
                Text(lm.t("test_setup")).font(.largeTitle).foregroundColor(.white).padding()
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(lm.t("questions")) \(Int(questionCount))").foregroundColor(.glassCyan)
                    Slider(value: $questionCount, in: 5...Double(max(5, set.words.count)), step: 1).tint(.glassCyan)
                    
                    Toggle(lm.t("multiple_choice"), isOn: $isMultipleChoice)
                        .toggleStyle(SwitchToggleStyle(tint: .glassCyan)).foregroundColor(.white)
                }.padding().glassEffect()
                
                Button(lm.t("start")) { startTest() }.buttonStyle(GlassButtonStyle()).padding()
            } else if isFinished {
                Text(lm.t("test_results")).font(.largeTitle).foregroundColor(.white)
                Text("\(score) / \(queue.count)").font(.system(size: 80, weight: .bold)).foregroundColor(.glassCyan)
                Button(lm.t("finish")) { dismiss() }.buttonStyle(GlassButtonStyle()).padding()
            } else {
                ProgressView(value: Double(currentIdx), total: Double(queue.count)).tint(.glassCyan).padding()
                Spacer()
                if let _ = current {
                    Text(prompt).font(.system(size: 60, weight: .bold)).foregroundColor(.white).glassEffect().padding()
                    
                    if isMultipleChoice {
                        VStack(spacing: 15) {
                            ForEach(mcOptions, id: \.self) { opt in
                                Button(action: { submitMC(opt) }) {
                                    Text(opt).font(.title).frame(maxWidth: .infinity)
                                }.buttonStyle(GlassButtonStyle())
                            }
                        }.padding()
                    } else {
                        TextField("...", text: $answer)
                            .textFieldStyle(.plain).padding().glassEffect().font(.title)
                            .onSubmit { submitOpen() }
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(feedbackColor.opacity(0.3).ignoresSafeArea())
        .background(Color.deepNavy.ignoresSafeArea())
    }
    
    private func startTest() {
        queue = Array(set.words.shuffled().prefix(Int(questionCount)))
        currentIdx = 0
        score = 0
        isFinished = false
        isSetup = false
        prepareOptions()
    }
    
    private func prepareOptions() {
        guard let curr = current else { finishTest(); return }
        if isMultipleChoice {
            let correct = target
            var others = set.words.filter { $0.id != curr.id }.map { set.translationDirectionRaw == 0 ? $0.english : $0.polish }
            others.shuffle()
            mcOptions = Array(others.prefix(3)) + [correct]
            mcOptions.shuffle()
        }
    }
    
    private func submitMC(_ option: String) {
        if option == target {
            score += 1; feedbackColor = .green; AudioFeedback.shared.playCorrect()
        } else {
            feedbackColor = .red; AudioFeedback.shared.playWrong()
        }
        nextStep()
    }
    
    private func submitOpen() {
        if answer.lowercased().trimmingCharacters(in: .whitespaces) == target.lowercased() {
            score += 1; feedbackColor = .green; AudioFeedback.shared.playCorrect()
        } else {
            feedbackColor = .red; AudioFeedback.shared.playWrong()
        }
        answer = ""
        nextStep()
    }
    
    private func nextStep() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            feedbackColor = .clear
            currentIdx += 1
            if currentIdx >= queue.count { finishTest() }
            else { prepareOptions() }
        }
    }
    
    private func finishTest() {
        isFinished = true
        for w in queue { SM2Engine.rate(w, quality: 3) }
    }
}
