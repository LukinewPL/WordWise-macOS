import SwiftUI
import SwiftData
import Observation

@Observable @MainActor final class FlashcardsViewModel {
    var set: WordSet
    var queue: [Word] {
        guard !orderedWords.isEmpty else { return [] }

        var result: [Word] = []
        var included = Set<Int>()

        // Cards temporarily deferred by "previous" should appear first.
        for index in forwardIndices.reversed() where included.insert(index).inserted {
            result.append(orderedWords[index])
        }

        guard let currentIndex else { return result }

        let start = currentIndex + 1
        guard start < orderedWords.count else { return result }

        for index in start..<orderedWords.count where included.insert(index).inserted {
            result.append(orderedWords[index])
        }

        return result
    }
    var current: Word? {
        guard let currentIndex else { return nil }
        guard orderedWords.indices.contains(currentIndex) else { return nil }
        return orderedWords[currentIndex]
    }
    var isFlipped: Bool = false
    private var historyIndices: [Int] = []
    private var orderedWords: [Word] = []
    private var currentIndex: Int?
    private var forwardIndices: [Int] = []
    
    init(set: WordSet) {
        self.set = set
        reset()
    }
    
    func reset() {
        orderedWords = set.words.shuffled()
        historyIndices = []
        forwardIndices = []
        currentIndex = orderedWords.isEmpty ? nil : 0
        isFlipped = false
    }
    
    func nextWord() {
        advanceToNextWord(recordCurrent: true)
    }

    func goToNextWord() {
        nextWord()
    }

    @discardableResult
    func goToPreviousWord() -> Bool {
        guard let previousIndex = historyIndices.popLast() else { return false }

        if let currentIndex {
            forwardIndices.append(currentIndex)
        }

        currentIndex = previousIndex
        isFlipped = false
        return true
    }
    
    func flip() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isFlipped.toggle()
        }
    }
    
    var frontText: String {
        guard let current else { return "" }
        return set.translationDirection == .polishToEnglish ? current.polish : current.english
    }
    
    var backText: String {
        guard let current else { return "" }
        return set.translationDirection == .polishToEnglish ? current.english : current.polish
    }
    
    var totalCount: Int {
        orderedWords.count
    }
    
    var currentPosition: Int {
        guard totalCount > 0 else { return 0 }
        if current == nil { return totalCount }
        return min(totalCount, historyIndices.count + 1)
    }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentPosition) / Double(totalCount)
    }
    
    var frontLanguageCode: String {
        self.set.translationDirection == .polishToEnglish ? "pl" : "en"
    }
    
    var backLanguageCode: String {
        self.set.translationDirection == .polishToEnglish ? "en" : "pl"
    }

    var canGoBack: Bool {
        !historyIndices.isEmpty
    }

    private func advanceToNextWord(recordCurrent: Bool) {
        if recordCurrent, let currentIndex {
            let currentWord = orderedWords[currentIndex]
            markWordAsReviewed(currentWord)
            historyIndices.append(currentIndex)
        }

        if let deferredIndex = forwardIndices.popLast() {
            currentIndex = deferredIndex
            isFlipped = false
            return
        }

        guard let currentIndex else {
            self.currentIndex = nil
            isFlipped = false
            return
        }

        let nextIndex = currentIndex + 1
        if nextIndex < orderedWords.count {
            self.currentIndex = nextIndex
        } else {
            self.currentIndex = nil
        }
        isFlipped = false
    }

    private func markWordAsReviewed(_ word: Word) {
        guard word.lastReviewed == nil else { return }
        let now = Date()
        word.lastReviewed = now
        if word.nextReview < now {
            word.nextReview = now
        }
    }
}
