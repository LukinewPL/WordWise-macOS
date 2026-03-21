import XCTest
@testable import WordWise

final class SM2EngineTests: XCTestCase {
    func testInitialRating() {
        let word = Word(polish: "test", english: "test")
        SM2Engine.rate(word, quality: 4)
        XCTAssertEqual(word.repetitions, 1)
        XCTAssertEqual(word.interval, 1)
        XCTAssertGreaterThan(word.lastReviewed, Date().addingTimeInterval(-10))
    }
    
    func testSecondRating() {
        let word = Word(polish: "test", english: "test")
        SM2Engine.rate(word, quality: 5)
        SM2Engine.rate(word, quality: 5)
        XCTAssertEqual(word.repetitions, 2)
        XCTAssertEqual(word.interval, 6)
    }
    
    func testDifficultyReset() {
        let word = Word(polish: "test", english: "test")
        SM2Engine.rate(word, quality: 5)
        XCTAssertEqual(word.repetitions, 1)
        SM2Engine.rate(word, quality: 2)
        XCTAssertEqual(word.repetitions, 0)
        XCTAssertEqual(word.interval, 1)
    }
    
    func testMasteryThreshold() {
        let word = Word(polish: "test", english: "test")
        XCTAssertFalse(word.isMastered)
        SM2Engine.rate(word, quality: 4)
        SM2Engine.rate(word, quality: 4)
        SM2Engine.rate(word, quality: 4)
        XCTAssertTrue(word.isMastered)
    }
    
    func testEaseFactorBounds() {
        let word = Word(polish: "test", english: "test")
        for _ in 0...10 { SM2Engine.rate(word, quality: 0) }
        XCTAssertGreaterThanOrEqual(word.easeFactor, 1.3)
    }
}
