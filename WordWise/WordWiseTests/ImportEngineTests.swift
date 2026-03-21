import XCTest; import SwiftData
@testable import WordWise

final class ImportEngineTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: WordSet.self, Word.self, configurations: config)
        context = ModelContext(container)
    }
    
    func testTXTImportStructure() throws {
        let txt = "dog\tpies\ncat\tkot"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".txt")
        try txt.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        try ImportEngine.importFile(url: tempURL, context: context, existingSets: [])
        
        let descriptor = FetchDescriptor<WordSet>()
        let sets = try context.fetch(descriptor)
        
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets.first?.words.count, 2)
        XCTAssertEqual(sets.first?.words.first(where: { $0.english == "dog" })?.polish, "pies")
    }
    
    func testDuplicateSetReplacement() throws {
        let existing = WordSet(name: "test")
        context.insert(existing)
        try context.save()
        
        let txt = "bird\tptak"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        try txt.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        try ImportEngine.importFile(url: tempURL, context: context, existingSets: [existing])
        
        let descriptor = FetchDescriptor<WordSet>()
        let sets = try context.fetch(descriptor)
        
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets.first?.words.count, 1)
        XCTAssertEqual(sets.first?.words.first?.english, "bird")
    }
}
