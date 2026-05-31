// Probes Apple's offline word-embedding model for food-vocabulary coverage.
// Run: swift tools/probe_embedding.swift
import NaturalLanguage

guard let emb = NLEmbedding.wordEmbedding(for: .english) else {
    print("NO EMBEDDING AVAILABLE"); exit(1)
}
print("embedding loaded, dimension \(emb.dimension)")

let words = ["courgette", "zucchini", "aubergine", "eggplant", "haddock", "salmon",
             "cheddar", "hobnob", "biscoff", "prosecco", "kale", "quinoa",
             "halloumi", "gnocchi", "edamame", "sriracha", "marmite", "babybel"]
print("\n-- in-vocabulary? --")
for w in words { print(String(format: "  %-12@ %@", w as NSString, emb.contains(w) ? "yes" : "NO") as String) }

print("\n-- nearest neighbours --")
for w in ["courgette", "haddock", "cheddar", "prosecco", "kale", "broccoli"] {
    let n = emb.neighbors(for: w, maximumCount: 6).map { $0.0 }
    print("  \(w) -> \(n)")
}

print("\n-- sample distances (lower = closer) --")
let pairs = [("courgette", "zucchini"), ("aubergine", "eggplant"), ("haddock", "fish"),
             ("cheddar", "cheese"), ("prosecco", "wine"), ("kale", "lettuce"),
             ("sirloin", "beef"), ("courgette", "car"), ("haddock", "chair")]
for (a, b) in pairs {
    print("  \(a) ~ \(b): \(emb.distance(between: a, and: b))")
}
