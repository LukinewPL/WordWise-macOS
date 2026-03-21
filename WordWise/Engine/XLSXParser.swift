import Foundation
import SwiftData

struct XLSXParser {
    static func parse(url: URL) throws -> [[String]] {
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

        var sharedStrings: [String] = []
        let sharedStringsURL = tempDir.appendingPathComponent("xl/sharedStrings.xml")
        if let sharedXML = try? String(contentsOf: sharedStringsURL, encoding: .utf8) {
            let siSplit = sharedXML.components(separatedBy: "<si")
            for i in 1..<siSplit.count {
                var fullString = ""
                let tSplit = siSplit[i].components(separatedBy: "<t")
                for j in 1..<tSplit.count {
                    if let closeIdx = tSplit[j].range(of: ">")?.upperBound,
                       let endIdx = tSplit[j].range(of: "</t>")?.lowerBound {
                        fullString += String(tSplit[j][closeIdx..<endIdx])
                    }
                }
                sharedStrings.append(fullString
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'"))
            }
        }

        var rows: [[String]] = []
        let sheetURL = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        if let sheetXML = try? String(contentsOf: sheetURL, encoding: .utf8) {
            let sheetSplit = sheetXML.components(separatedBy: "<row")
            for i in 1..<sheetSplit.count {
                let rowContent = sheetSplit[i]
                if let rowEnd = rowContent.range(of: "</row>")?.lowerBound {
                    let cells = String(rowContent[..<rowEnd]).components(separatedBy: "<c r=\"")
                    var wordA = "", wordB = ""
                    for j in 1..<cells.count {
                        let cellContent = cells[j]
                        guard let colEndIdx = cellContent.range(of: "\"")?.lowerBound,
                              let vStart = cellContent.range(of: "<v>"),
                              let vEnd = cellContent.range(of: "</v>") else { continue }
                        let colRef = String(cellContent[..<colEndIdx])
                        let col = colRef.trimmingCharacters(in: .decimalDigits)
                        
                        var type = ""
                        if let typeAttrRawUpper = cellContent.range(of: " t=\"")?.upperBound {
                            let remain = cellContent[typeAttrRawUpper...]
                            if let typeEnd = remain.range(of: "\"")?.lowerBound {
                                type = String(remain[..<typeEnd])
                            }
                        }
                        
                        let valStr = String(cellContent[vStart.upperBound..<vEnd.lowerBound])
                        var cellValue = valStr
                        if type == "s", let idx = Int(valStr), idx < sharedStrings.count {
                            cellValue = sharedStrings[idx]
                        }
                        if col == "A" { wordA = cellValue }
                        if col == "B" { wordB = cellValue }
                    }
                    let cleanA = wordA.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanB = wordB.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanA.isEmpty && !cleanB.isEmpty {
                        rows.append([cleanB, cleanA]) // [Polish, English]
                    }
                }
            }
        }
        return rows
    }
}
