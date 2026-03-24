import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class StudySessionViewModel {
    var set: WordSet
    var queue: [Word] = []
    var current: Word?
    var answer: String = ""
    var feedback: Color = .clear
    var attemptedCount = 0
    var correctCount = 0
    var hasSaved = false
    
    // Dependencies
    private var repository: (any WordRepositoryProtocol)?
    private var sm2Service = SM2Service()
    
    init(set: WordSet) {
        self.set = set
    }
    
    func setup(repository: any WordRepositoryProtocol) {
        self.repository = repository
        resetSession()
    }
    
    func resetSession() {
        queue = set.words.shuffled()
        attemptedCount = 0
        correctCount = 0
        hasSaved = false
        feedback = .clear
        answer = ""
        nextWord()
    }
    
    func checkAnswer(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        attemptedCount += 1
        let isCorrect = match(answer, to: target)
        
        if isCorrect {
            correctCount += 1
            feedback = .green
            AudioFeedback.shared.playCorrect()
            if let w = current {
                sm2Service.rate(w, quality: 4)
            }
            onSuccess()
        } else {
            feedback = .red
            AudioFeedback.shared.playWrong()
            if let w = current {
                sm2Service.rate(w, quality: 1)
                queue.append(w)
            }
            onFailure()
        }
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
        
        repository?.insertSession(session)
        hasSaved = true
    }
    
    var prompt: String {
        guard let current else { return "" }
        return set.prompt(for: current)
    }
    
    var target: String {
        guard let current else { return "" }
        return set.target(for: current)
    }
    
    private func match(_ input: String, to target: String) -> Bool {
        let separators = CharacterSet(charactersIn: ",/-")
        let parts = target.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let normalizedInput = normalize(input)
        return parts.contains { normalize($0) == normalizedInput } || normalize(input) == normalize(target)
    }
    
    private func normalize(_ text: String) -> String {
        return text
            .lowercased()
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
    }
}
