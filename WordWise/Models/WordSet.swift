import SwiftData
import Foundation

enum TranslationDirection: Int, Codable {
    case polishToEnglish = 0
    case englishToPolish = 1
}

@Model final class WordSet {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade) var words: [Word] = []
    var translationDirectionRaw: Int = TranslationDirection.polishToEnglish.rawValue

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), words: [Word] = [], dir: Int = TranslationDirection.polishToEnglish.rawValue) {
        self.id = id; self.name = name; self.createdAt = createdAt; self.words = words; self.translationDirectionRaw = dir
    }
}
