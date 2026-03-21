import SwiftUI; import SwiftData

struct StudySessionView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var queue: [Word] = []
    @State private var current: Word?
    @State private var answer: String = ""
    @State private var feedback: Color = .clear
    @FocusState private var isFocused: Bool
    
    var prompt: String {
        get { set.translationDirectionRaw == 0 ? current?.polish ?? "" : current?.english ?? "" }
    }
    var target: String {
        get { set.translationDirectionRaw == 0 ? current?.english ?? "" : current?.polish ?? "" }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            if let _ = current {
                Text(prompt).font(.system(size: 60, weight: .bold)).foregroundColor(.white).glassEffect().padding()
                TextField("...", text: $answer)
                    .textFieldStyle(.plain).padding().glassEffect().font(.title)
                    .focused($isFocused)
                    .onSubmit { checkAnswer() }
                    .disabled(feedback != .clear)
                
                if feedback == .red {
                    Text(target)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.glassCyan)
                        .padding(.top, 10)
                        .transition(.opacity)
                }
            } else { 
                VStack(spacing: 20) {
                    Text(lm.t("done")).font(.largeTitle).foregroundColor(.white)
                    Button(lm.t("finish")) { dismiss() }.buttonStyle(GlassButtonStyle())
                }
            }
            Spacer()
        }.background(feedback.opacity(0.3).ignoresSafeArea())
        .onAppear { 
            queue = set.words.filter { Calendar.current.isDateInToday($0.nextReview) || $0.nextReview < Date() }
            nextWord()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
        }
    }
    
    func checkAnswer() {
        let cleanAns = answer.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanTar = target.lowercased().trimmingCharacters(in: .whitespaces)
        
        if cleanAns == cleanTar {
            feedback = .green; AudioFeedback.shared.playCorrect()
            if let w = current { SM2Engine.rate(w, quality: 4) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                feedback = .clear; answer = ""; nextWord(); isFocused = true
            }
        } else {
            feedback = .red; AudioFeedback.shared.playWrong()
            if let w = current { SM2Engine.rate(w, quality: 1) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                feedback = .clear; answer = ""; nextWord(); isFocused = true
            }
        }
    }
    func nextWord() {
        current = queue.isEmpty ? nil : queue.removeFirst()
    }
}
