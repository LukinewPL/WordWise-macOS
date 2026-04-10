import Foundation
import SwiftData

struct XLSXParser {
    static func parse(url: URL) throws -> [[String]] {
        let extensionLowercased = url.pathExtension.lowercased()
        if extensionLowercased == "csv" {
            return try parseCSV(url: url)
        }
        guard extensionLowercased == "xlsx" else {
            throw NSError(
                domain: "Verba",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unsupported spreadsheet format."]
            )
        }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let tempFile = tempDir.appendingPathComponent("import.xlsx")
        try FileManager.default.copyItem(at: url, to: tempFile)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", tempFile.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()

        // 1. Parse Shared Strings
        var sharedStrings: [String] = []
        let sharedStringsURL = tempDir.appendingPathComponent("xl/sharedStrings.xml")
        if let sharedData = try? Data(contentsOf: sharedStringsURL),
           let xml = try? XMLDocument(data: sharedData, options: []) {
            let siNodes = (try? xml.nodes(forXPath: ".//si")) ?? []
            for node in siNodes {
                var text = ""
                // XLSX can have multiple <t> nodes for formatted text
                if let tNodes = try? node.nodes(forXPath: ".//t") {
                    text = tNodes.compactMap { $0.stringValue }.joined()
                }
                sharedStrings.append(text)
            }
        }

        // 2. Parse Sheet1
        var rows: [[String]] = []
        let sheetURL = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        if let sheetData = try? Data(contentsOf: sheetURL),
           let xml = try? XMLDocument(data: sheetData, options: []) {
            let rowNodes = (try? xml.nodes(forXPath: ".//row")) ?? []
            for rowNode in rowNodes {
                guard let cellNodes = try? rowNode.nodes(forXPath: "./c") else { continue }
                
                var wordA = "", wordB = ""
                for cell in cellNodes as! [XMLElement] {
                    let colRef = cell.attribute(forName: "r")?.stringValue ?? ""
                    let col = colRef.trimmingCharacters(in: .decimalDigits)
                    let type = cell.attribute(forName: "t")?.stringValue ?? ""
                    let value = cell.elements(forName: "v").first?.stringValue ?? ""
                    
                    var cellValue = value
                    if type == "s", let idx = Int(value), idx < sharedStrings.count {
                        cellValue = sharedStrings[idx]
                    }
                    
                    if col == "A" { wordA = cellValue }
                    if col == "B" { wordB = cellValue }
                }
                
                let cleanA = sanitize(wordA)
                let cleanB = sanitize(wordB)
                if !cleanA.isEmpty && !cleanB.isEmpty {
                    rows.append([cleanB, cleanA]) // [Polish, English]
                }
            }
        }
        return rows
    }

    static func parseCSV(url: URL) throws -> [[String]] {
        let data = try Data(contentsOf: url)
        let rawText = try decodeText(data)
        return parseCSVRows(from: rawText)
    }
    
    nonisolated static func sanitize(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static func decodeText(_ data: Data) throws -> String {
        let encodings: [String.Encoding] = [.utf8, .windowsCP1250, .isoLatin2, .isoLatin1]
        for encoding in encodings {
            if let text = String(data: data, encoding: encoding), !text.contains("\u{FFFD}") {
                return text
            }
        }
        if let fallback = String(data: data, encoding: .isoLatin1) {
            return fallback
        }
        throw NSError(
            domain: "Verba",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Cannot determine file encoding."]
        )
    }

    private static func parseCSVRows(from text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        var index = text.startIndex

        func flushRow() {
            let sanitized = currentRow.map(sanitize)
            if sanitized.count == 2, !sanitized[0].isEmpty, !sanitized[1].isEmpty {
                rows.append([sanitized[0], sanitized[1]])
            }
            currentRow.removeAll(keepingCapacity: true)
        }

        while index < text.endIndex {
            let character = text[index]

            if character == "\"" {
                if insideQuotes {
                    let nextIndex = text.index(after: index)
                    if nextIndex < text.endIndex, text[nextIndex] == "\"" {
                        currentField.append("\"")
                        index = nextIndex
                    } else {
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            } else if character == ",", !insideQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if (character == "\n" || character == "\r"), !insideQuotes {
                currentRow.append(currentField)
                currentField = ""
                flushRow()

                if character == "\r" {
                    let nextIndex = text.index(after: index)
                    if nextIndex < text.endIndex, text[nextIndex] == "\n" {
                        index = nextIndex
                    }
                }
            } else {
                currentField.append(character)
            }

            index = text.index(after: index)
        }

        currentRow.append(currentField)
        flushRow()
        return rows
    }
}
