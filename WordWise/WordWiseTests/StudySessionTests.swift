import XCTest
@testable import WordWise

final class StudySessionTests: XCTestCase {
    func testSessionInit() {
        let id = UUID()
        let session = StudySession(wordSetID: id)
        XCTAssertEqual(session.wordSetID, id)
        XCTAssertEqual(session.wordsStudied, 0)
        XCTAssertEqual(session.correctAnswers, 0)
        XCTAssertGreaterThan(session.date, Date().addingTimeInterval(-10))
    }
    
    func testAccuracy() {
        let session = StudySession(wordSetID: UUID())
        session.wordsStudied = 10
        session.correctAnswers = 7
        // Accuracy isn't a property yet, but we can verify it's valid if we add it.
        XCTAssertEqual(Double(session.correctAnswers) / Double(session.wordsStudied), 0.7)
    }
}
