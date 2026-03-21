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
    @State private var wrongAnswers: [(String, String)] = []
    @State private var selectedOption: String? = nil
    @Environment(\.modelContext) private var ctx
    
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
                VStack(spacing: 30) {
                    Text(lm.t("test_setup"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 25) {
                        VStack(spacing: 12) {
                            Text("\(lm.t("questions")): \(Int(questionCount))")
                                .font(.headline)
                                .foregroundColor(.glassCyan)
                            
                            Slider(value: $questionCount, in: 5...50, step: 5)
                                .tint(.glassCyan)
                                .frame(maxWidth: 400)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            Image(systemName: isMultipleChoice ? "list.bullet" : "pencil")
                                .font(.title3)
                                .foregroundColor(.glassCyan)
                                .frame(width: 30)
                            
                            Toggle(lm.t("multiple_choice"), isOn: $isMultipleChoice)
                                .toggleStyle(SwitchToggleStyle(tint: .glassCyan))
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    .padding(30)
                    .glassEffect()
                    .frame(maxWidth: 500)
                    
                    Button(action: { 
                        withAnimation(.spring()) { startTest() }
                    }) {
                        Text(lm.t("start"))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.glassCyan.opacity(0.8))
                            .cornerRadius(14)
                            .glassEffect()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pressAnimation()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isFinished {
                VStack(spacing: 30) {
                    Text(lm.t("test_results")).font(.largeTitle).foregroundColor(.white)
                    
                    let percentage = Double(score) / Double(max(1, queue.count))
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 100, weight: .black))
                        .foregroundColor(percentage >= 0.7 ? .green : (percentage >= 0.5 ? .orange : .red))
                    
                    Text("\(score) / \(queue.count)").font(.title).foregroundColor(.white.opacity(0.8))
                    
                    if !wrongAnswers.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(lm.t("review_wrong")).font(.headline).foregroundColor(.glassCyan).padding(.bottom, 5)
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(0..<wrongAnswers.count, id: \.self) { i in
                                        HStack {
                                            Text(wrongAnswers[i].0).foregroundColor(.white)
                                            Spacer()
                                            Text(wrongAnswers[i].1).foregroundColor(.glassCyan).bold()
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            }.frame(maxHeight: 250)
                        }
                        .padding().glassEffect().frame(maxWidth: 600)
                    }
                    
                    Button(lm.t("finish")) { finishTestAndSave() }.buttonStyle(GlassButtonStyle()).padding()
                }
            } else {
                VStack(spacing: 5) {
                    Text("\(currentIdx + 1) / \(queue.count)")
                        .font(.caption).bold().foregroundColor(.white.opacity(0.5))
                    
                    ProgressView(value: Double(currentIdx), total: Double(queue.count))
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(.glassCyan)
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                        .frame(height: 4)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                Spacer()
                
                if let _ = current {
                    Text(prompt)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 700)
                        .padding(.vertical, 40)
                        .glassEffect()
                        .padding()
                    
                    if isMultipleChoice {
                        VStack(spacing: 15) {
                            ForEach(mcOptions, id: \.self) { opt in
                                Button(action: { submitMC(opt) }) {
                                    Text(opt)
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: 500)
                                        .background(buttonBackground(for: opt))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(selectedOption == opt ? 1.05 : 1.0)
                                .animation(.spring(), value: selectedOption)
                                .disabled(selectedOption != nil)
                            }
                        }.padding()
                    } else {
                        TextField("...", text: $answer)
                            .textFieldStyle(.plain).padding().glassEffect().font(.title)
                            .frame(maxWidth: 600)
                            .padding(.horizontal, 40)
                            .onSubmit { submitOpen() }
                            .disabled(selectedOption != nil)
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(feedbackColor.opacity(0.3).ignoresSafeArea())
        .background(Color.deepNavy.ignoresSafeArea())
    }
    
    private func buttonBackground(for opt: String) -> some View {
        Group {
            if let selected = selectedOption {
                if opt == target {
                    Color.green.opacity(0.6)
                } else if opt == selected {
                    Color.red.opacity(0.6)
                } else {
                    Color.white.opacity(0.1)
                }
            } else {
                Color.white.opacity(0.1)
            }
        }
    }
    
    private func startTest() {
        queue = Array(set.words.shuffled().prefix(Int(questionCount)))
        currentIdx = 0
        score = 0
        isFinished = false
        isSetup = false
        wrongAnswers = []
        prepareOptions()
    }
    
    private func prepareOptions() {
        guard let curr = current else { finishTest(); return }
        if isMultipleChoice {
            let correct = target
            var others = set.words.filter { $0.id != curr.id }.map { set.translationDirectionRaw == 0 ? $0.english : $0.polish }
            others = Array(Set(others)) // Unique options
            others.shuffle()
            mcOptions = Array(others.prefix(3)) + [correct]
            mcOptions.shuffle()
        }
        selectedOption = nil
    }
    
    private func submitMC(_ option: String) {
        selectedOption = option
        if option == target {
            score += 1; feedbackColor = .green; AudioFeedback.shared.playCorrect()
        } else {
            feedbackColor = .red; AudioFeedback.shared.playWrong()
            wrongAnswers.append((prompt, target))
        }
        nextStep()
    }
    
    private func submitOpen() {
        selectedOption = answer
        if answer.lowercased().trimmingCharacters(in: .whitespaces) == target.lowercased() {
            score += 1; feedbackColor = .green; AudioFeedback.shared.playCorrect()
        } else {
            feedbackColor = .red; AudioFeedback.shared.playWrong()
            wrongAnswers.append((prompt, target))
        }
        nextStep()
    }
    
    private func nextStep() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                feedbackColor = .clear
                answer = ""
                currentIdx += 1
                if currentIdx >= queue.count { finishTest() }
                else { prepareOptions() }
            }
        }
    }
    
    private func finishTest() {
        isFinished = true
        for w in queue { SM2Engine.rate(w, quality: 3) }
    }
    
    private func finishTestAndSave() {
        if !queue.isEmpty {
            let session = StudySession(wordSetID: set.id)
            session.wordsStudied = queue.count
            session.correctAnswers = score
            ctx.insert(session)
            try? ctx.save()
        }
        dismiss()
    }
}
