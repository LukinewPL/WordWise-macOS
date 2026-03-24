import XCTest
@testable import WordWise

final class WordSetTests: XCTestCase {
    func testPromptTargetLogic() {
        let set = WordSet(name: "Test Set")
        let word = Word(polish: "jabłko", english: "apple")
        set.words.append(word)
        
        // Default direction (pl -> en)
        set.direction = .toEnglish
        XCTAssertEqual(set.prompt(for: word), "jabłko")
        XCTAssertEqual(set.target(for: word), "apple")
        
        // Reverse direction (en -> pl)
        set.direction = .toPolish
        XCTAssertEqual(set.prompt(for: word), "apple")
        XCTAssertEqual(set.target(for: word), "jabłko")
        
        // Mix mode
        // Note: Mix mode is pseudo-random per call, so it's harder to test deterministically without a seeded generator.
        // But we can check that it returns either one or the other.
        set.direction = .mixed
        let prompt = set.prompt(for: word)
        XCTAssertTrue(prompt == "jabłko" || prompt == "apple")
    }
}
