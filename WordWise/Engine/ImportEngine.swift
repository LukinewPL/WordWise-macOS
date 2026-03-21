import Foundation
import SwiftData
import UniformTypeIdentifiers

struct ImportEngine {
    static func importFile(url: URL, context: ModelContext, existingSets: [WordSet]) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        let name = url.deletingPathExtension().lastPathComponent
        let wset = getOrCreateSet(name: name, context: context, existingSets: existingSets)
        
        let rows: [[String]]
        if url.pathExtension.lowercased() == "xlsx" {
            rows = try XLSXParser.parse(url: url)
        } else {
            rows = try parseTXT(url: url)
        }
        
        var importedCount = 0
        for p in rows {
            if p.count == 2 {
                let word = Word(polish: p[0], english: p[1])
                word.set = wset
                wset.words.append(word)
                context.insert(word)
                importedCount += 1
            }
        }
        
        if importedCount == 0 {
            throw NSError(domain: "WordWise", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid words found in file."])
        }
        try context.save()
    }
    
    private static func parseTXT(url: URL) throws -> [[String]] {
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
            
            let sep = trimmedLine.contains("=") ? "=" : (trimmedLine.contains(";") ? ";" : "\t")
            let p = trimmedLine.components(separatedBy: sep).map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if p.count == 2, !p[0].isEmpty, !p[1].isEmpty {
                rows.append([p[1], p[0]]) // [Polish, English]
            }
        }
        return rows
    }
    
    private static func getOrCreateSet(name: String, context: ModelContext, existingSets: [WordSet]) -> WordSet {
        if let existing = existingSets.first(where: { $0.name == name }) {
            for word in existing.words { context.delete(word) }
            existing.words.removeAll()
            return existing
        } else {
            let newSet = WordSet(name: name)
            context.insert(newSet)
            return newSet
        }
    }
}
