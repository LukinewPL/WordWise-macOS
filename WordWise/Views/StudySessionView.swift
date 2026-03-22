import SwiftUI; import SwiftData

struct StudySessionView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var queue: [Word] = []
    @State private var current: Word?
    @State private var answer: String = ""
    @State private var feedback: Color = .clear
    @FocusState private var isFocused: Bool
    @State private var attemptedCount = 0
    @State private var correctCount = 0
    @State private var hasSaved = false
    @Environment(\.modelContext) private var ctx
    
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
                    .textFieldStyle(.plain)
                    .padding()
                    .glassEffect()
                    .font(.title)
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 40)
                    .focused($isFocused)
                    .onSubmit { checkAnswer() }
                    .disabled(feedback != .clear)
                
                if feedback == .red {
                    Text(target)
                        .font(.system(size: 32, weight: .bold))
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(feedback.opacity(0.3).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: feedback)
        .background(Color.deepNavy.ignoresSafeArea())
        .onAppear { 
            Task { @MainActor in
                resetSession()
                try? await Task.sleep(nanoseconds: 500_000_000)
                isFocused = true
            }
        }
        .onDisappear { saveSession() }
    }
    
    private func resetSession() {
        queue = set.words.shuffled()
        attemptedCount = 0
        correctCount = 0
        hasSaved = false
        feedback = .clear
        answer = ""
        nextWord()
    }
    
    func checkAnswer() {
        let isCorrect = match(answer, to: target)
        
        if isCorrect {
            attemptedCount += 1
            correctCount += 1
            feedback = .green; AudioFeedback.shared.playCorrect()
            if let w = current { SM2Engine.rate(w, quality: 4) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                feedback = .clear; answer = ""; nextWord(); isFocused = true
            }
        } else {
            feedback = .red; AudioFeedback.shared.playWrong()
            if let w = current { 
                SM2Engine.rate(w, quality: 1) 
                queue.append(w) // Move to end of queue
            }
            // Note: attemptedCount increments only for correct or first time? 
            // Usually attemptedCount in sessions counts total attempts. 
            // But let's follow the logic of "keep in queue until right".
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                feedback = .clear; answer = ""; nextWord(); isFocused = true
            }
        }
    }
    
    func match(_ input: String, to target: String) -> Bool {
        let separators = CharacterSet(charactersIn: ",/-")
        let parts = target.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let normalizedInput = normalize(input)
        return parts.contains { normalize($0) == normalizedInput } || normalize(input) == normalize(target)
    }
    
    func normalize(_ text: String) -> String {
        return text
            .lowercased()
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    func nextWord() {
        if queue.isEmpty {
            current = nil
            if attemptedCount > 0 && !hasSaved {
                NSSound(named: "Glass")?.play()
            }
        } else {
            current = queue.removeFirst()
        }
    }
    
    func saveSession() {
        guard !hasSaved && attemptedCount > 0 else { return }
        let session = StudySession(wordSetID: set.id)
        session.wordsStudied = attemptedCount
        session.correctAnswers = correctCount
        ctx.insert(session)
        try? ctx.save()
        hasSaved = true
    }
}
