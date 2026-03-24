import Foundation
import SwiftData

protocol WordRepositoryProtocol: AnyObject {
    func fetchAllSets() -> [WordSet]
    func insertSet(_ set: WordSet)
    func deleteSet(_ set: WordSet)
    
    func fetchFolders() -> [Folder]
    func insertFolder(_ folder: Folder)
    func deleteFolder(_ folder: Folder)
    
    func fetchAllSessions() -> [StudySession]
    func insertSession(_ session: StudySession)
    
    func importFile(url: URL) throws
    
    func save()
}
