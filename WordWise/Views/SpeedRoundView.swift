import SwiftUI
import SwiftData

struct SpeedRoundView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var queue: [Word] = []
    @State private var current: Word?
    @State private var answer = ""
    @State private var attemptedCount = 0
    @State private var correctCount = 0
    @State private var timeLeft = 60
    @State private var isActive = false
    @State private var isFinished = false
    @State private var feedbackColor: Color = .clear
    @State private var showWrongAnswer = false
    @State private var timer: Timer?
    @State private var hasSaved = false
    @FocusState private var isFocused: Bool
    @Environment(\.modelContext) private var ctx
    
    @Environment(\.dismiss) private var dismiss
    
    var prompt: String {
        get { set.translationDirectionRaw == 0 ? current?.polish ?? "" : current?.english ?? "" }
    }
    var target: String {
        get { set.translationDirectionRaw == 0 ? current?.english ?? "" : current?.polish ?? "" }
    }
    
    var body: some View {
        VStack {
            if isFinished {
                Text(lm.t("time_up")).font(.largeTitle).foregroundColor(.white).padding()
                Text("\(lm.t("score")) \(correctCount)").font(.title).foregroundColor(.glassCyan).padding()
                Button(lm.t("done")) { dismiss() }.buttonStyle(GlassButtonStyle())
            } else {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 5)
                        Circle().trim(from: 0, to: CGFloat(timeLeft) / 60.0)
                            .stroke(Color.glassCyan, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(timeLeft)").font(.title3).foregroundColor(.white).bold()
                    }.frame(width: 60, height: 60)
                }.padding()
                
                Spacer()
                if let _ = current {
                    Text(prompt).font(.system(size: 60, weight: .bold)).foregroundColor(.white).glassEffect().padding()
                    
                    if showWrongAnswer {
                        Text(target).font(.title).foregroundColor(.red).padding()
                    } else {
                        TextField("...", text: $answer)
                            .textFieldStyle(.plain)
                            .padding()
                            .glassEffect()
                            .font(.title)
                            .frame(maxWidth: 600)
                            .padding(.horizontal, 40)
                            .focused($isFocused)
                            .onSubmit { checkAnswer() }
                    }
                }
                Spacer()
                Text("\(lm.t("score")) \(correctCount)").foregroundColor(.white).font(.headline).padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(feedbackColor.opacity(0.3).ignoresSafeArea())
        .background(Color.deepNavy.ignoresSafeArea())
        .onAppear { startGame() }
        .onDisappear { 
            timer?.invalidate()
            saveSession()
        }
    }
    
    private func startGame() {
        queue = set.words.shuffled()
        correctCount = 0
        attemptedCount = 0
        timeLeft = 60
        isFinished = false
        isActive = true
        nextWord()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 { timeLeft -= 1 } 
            else { finishGameView() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
    }
    
    private func nextWord() {
        if queue.isEmpty { queue = set.words.shuffled() }
        current = queue.isEmpty ? nil : queue.removeFirst()
    }
    
    private func finishGameView() {
        isActive = false
        isFinished = true
        timer?.invalidate()
        current = nil
    }
    
    private func checkAnswer() {
        let cleanAns = answer.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanTar = target.lowercased().trimmingCharacters(in: .whitespaces)
        attemptedCount += 1
        
        if cleanAns == cleanTar {
            correctCount += 1
            if let w = current { SM2Engine.rate(w, quality: 4) }
            feedbackColor = .green; AudioFeedback.shared.playCorrect()
            answer = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { feedbackColor = .clear; nextWord(); isFocused = true }
        } else {
            if let w = current { SM2Engine.rate(w, quality: 1) }
            feedbackColor = .red; AudioFeedback.shared.playWrong()
            showWrongAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showWrongAnswer = false
                feedbackColor = .clear
                answer = ""
                nextWord()
                isFocused = true
            }
        }
    }
    
    private func saveSession() {
        guard !hasSaved && attemptedCount > 0 else { return }
        let session = StudySession(wordSetID: set.id)
        session.wordsStudied = attemptedCount
        session.correctAnswers = correctCount
        ctx.insert(session)
        try? ctx.save()
        hasSaved = true
    }
}
