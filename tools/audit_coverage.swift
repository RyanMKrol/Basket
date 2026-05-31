// Audits emoji coverage of the global grocery corpus in tools/corpus/*.txt.
// For each unique item it reports whether it resolved via the curated table, the
// semantic embedding fallback, or the basket default, and lists the gaps.
// Build (from repo root):
//   mkdir -p /tmp/ab && cp tools/audit_coverage.swift /tmp/ab/main.swift
//   swiftc Sources/Services/EmojiTable.swift Sources/Services/SemanticEmoji.swift \
//          Sources/Services/Emoji.swift /tmp/ab/main.swift -o /tmp/audit && /tmp/audit
import Foundation

let dir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "tools/corpus"
let fm = FileManager.default
let files = ((try? fm.contentsOfDirectory(atPath: dir)) ?? []).filter { $0.hasSuffix(".txt") }.sorted()

var seen = Set<String>()
var items: [String] = []
for file in files {
    guard let text = try? String(contentsOfFile: "\(dir)/\(file)", encoding: .utf8) else { continue }
    for line in text.split(separator: "\n") {
        let t = line.trimmingCharacters(in: CharacterSet(charactersIn: " \t.-"))
        let key = t.lowercased()
        if t.count > 1, seen.insert(key).inserted { items.append(t) }
    }
}

var curated = 0, semantic = 0, fallbackItems: [String] = []
var semanticSamples: [(String, String)] = []
for item in items {
    if EmojiTable.match(item) != nil {
        curated += 1
    } else if let s = SemanticEmoji.match(item) {
        semantic += 1
        if semanticSamples.count < 80 { semanticSamples.append((item, s)) }
    } else {
        fallbackItems.append(item)
    }
}

print("Corpus files: \(files.count)  |  unique items: \(items.count)")
let pct = items.isEmpty ? 0 : Int(Double(curated + semantic) / Double(items.count) * 1000) / 10
print("  curated:  \(curated)")
print("  semantic: \(semantic)")
print("  fallback: \(fallbackItems.count)   (coverage \(pct)%)")
print("\n-- resolved by SEMANTIC embedding (sample) --")
for (i, e) in semanticSamples { print("  \(e)  \(i)") }
print("\n-- fell through to basket (gaps: \(fallbackItems.count)) --")
print(fallbackItems.isEmpty ? "  (none)" : fallbackItems.map { "  \($0)" }.joined(separator: "\n"))
