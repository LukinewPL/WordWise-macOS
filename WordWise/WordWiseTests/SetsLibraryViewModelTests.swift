import XCTest
@testable import WordWise

@MainActor
final class SetsLibraryViewModelTests: XCTestCase {
    var sut: SetsLibraryViewModel!
    var repository: MockWordRepository!
    
    override func setUp() {
        super.setUp()
        repository = MockWordRepository()
        sut = SetsLibraryViewModel()
        sut.setup(repository: repository)
    }
    
    func testCreateFolder() {
        sut.newFolderName = "Test Folder"
        sut.createFolder()
        
        XCTAssertEqual(repository.folders.count, 1)
        XCTAssertEqual(repository.folders.first?.name, "Test Folder")
    }
    
    func testDeleteFolder() {
        let folder = Folder(name: "To delete")
        repository.insertFolder(folder)
        sut.refresh()
        
        sut.deleteFolder(folder)
        XCTAssertTrue(repository.folders.isEmpty)
    }
    
    func testRenameFolder() {
        let folder = Folder(name: "Old")
        repository.insertFolder(folder)
        sut.refresh()
        
        sut.renameFolder(folder, to: "New")
        XCTAssertEqual(folder.name, "New")
    }
    
    func testHandleDrop() {
        let set = WordSet(name: "Drag Set")
        repository.sets = [set]
        sut.refresh()
        
        let folder = Folder(name: "Target")
        repository.folders = [folder]
        
        _ = sut.handleDrop(ids: [set.id.uuidString], to: folder)
        
        XCTAssertEqual(set.folder?.id, folder.id)
    }
    
    func testUngroupedSets() {
        let set1 = WordSet(name: "In Folder")
        let folder = Folder(name: "F")
        set1.folder = folder
        
        let set2 = WordSet(name: "Loose")
        repository.sets = [set1, set2]
        sut.refresh()
        
        XCTAssertEqual(sut.ungroupedSets.count, 1)
        XCTAssertEqual(sut.ungroupedSets.first?.name, "Loose")
    }
}
