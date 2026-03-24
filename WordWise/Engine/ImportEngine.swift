import Foundation
import SwiftData
import UniformTypeIdentifiers

class ImportService {
    func importFile(url: URL, context: ModelContext, existingSets: [WordSet], mergeExisting: Bool = false) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        let name = url.deletingPathExtension().lastPathComponent
        let wset = getOrCreateSet(name: name, context: context, existingSets: existingSets, merge: mergeExisting)
        
        let rows: [[String]]
        if url.pathExtension.lowercased() == "xlsx" {
            rows = try XLSXParser.parse(url: url)
        } else {
            rows = try parseTXT(url: url)
        }
        
        var importedCount = 0
        for p in rows {
            if p.count == 2 {
                let polish = p[0]
                let english = p[1]
                
                // Basic deduplication if merging
                if mergeExisting && wset.words.contains(where: { $0.polish == polish && $0.english == english }) {
                    continue
                }
                
                let word = Word(polish: polish, english: english)
                word.set = wset
                wset.words.append(word)
                context.insert(word)
                importedCount += 1
            }
        }
        
        if importedCount == 0 && !mergeExisting {
            throw NSError(domain: "WordWise", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid new words found in file."])
        }
        try context.save()
    }
    
    private func parseTXT(url: URL) throws -> [[String]] {
        let data = try Data(contentsOf: url)
        var parsedText: String? = nil
        
        let encodings: [String.Encoding] = [.utf8, .windowsCP1250, .isoLatin2, .isoLatin1]
        for enc in encodings {
            if let text = String(data: data, encoding: enc), !text.contains("\u{FFFD}") {
                parsedText = text
                break
            }
        }
        
        if parsedText == nil { parsedText = String(data: data, encoding: .isoLatin1) }
        guard let rawText = parsedText else {
            throw NSError(domain: "WordWise", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot determine file encoding."])
        }
        
        var rows: [[String]] = []
        let lines = rawText.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            let sep: String
            if trimmedLine.contains("\t") { sep = "\t" }
            else if trimmedLine.contains("=") { sep = "=" }
            else if trimmedLine.contains(";") { sep = ";" }
            else { continue }
            
            let p = trimmedLine.components(separatedBy: sep).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if p.count == 2, !p[0].isEmpty, !p[1].isEmpty {
                // Heuristic: check if common order English=Polish or Polish=English
                // In this app, Word(polish: p[0], english: p[1])
                // So if file is English=Polish, we should swap.
                // But let's stay consistent with whatever user format was before.
                // Previous code: rows.append([p[1], p[0]]) // [Polish, English]
                // This means input was Expected: [English, Polish] -> Output: [Polish, English]
                rows.append([p[1], p[0]]) 
            }
        }
        return rows
    }
    
    private func getOrCreateSet(name: String, context: ModelContext, existingSets: [WordSet], merge: Bool) -> WordSet {
        if let existing = existingSets.first(where: { $0.name == name }) {
            if !merge {
                for word in existing.words { context.delete(word) }
                existing.words.removeAll()
            }
            return existing
        } else {
            let newSet = WordSet(name: name)
            context.insert(newSet)
            return newSet
        }
    }
}

