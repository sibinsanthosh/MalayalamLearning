import Foundation

struct DictionaryEntry: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let partOfSpeech: String
    let meaning: String
}

class DictionaryManager: ObservableObject {
    @Published var isLoaded = false
    private var rawText: String = ""
    
    init() {
        loadData()
    }
    
    private func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "olam-enml", withExtension: "csv") else {
                print("Failed to find dictionary CSV in bundle.")
                return
            }
            
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                self.rawText = text
                DispatchQueue.main.async {
                    self.isLoaded = true
                }
            } catch {
                print("Failed to load dictionary text: \(error.localizedDescription)")
            }
        }
    }
    
    func search(query: String) -> [DictionaryEntry] {
        guard !query.isEmpty else { return [] }
        
        let lowerQuery = query.lowercased()
        var results: [DictionaryEntry] = []
        
        self.rawText.enumerateLines { line, stop in
            if line.lowercased().contains(lowerQuery) {
                let components = line.components(separatedBy: "\t")
                if components.count >= 4 {
                    let word = components[1]
                    // Strict prefix or exact match to keep results relevant
                    if word.lowercased().hasPrefix(lowerQuery) {
                        let entry = DictionaryEntry(
                            word: word,
                            partOfSpeech: components[2],
                            meaning: components[3]
                        )
                        results.append(entry)
                    }
                }
            }
            
            if results.count >= 50 {
                stop = true
            }
        }
        
        return results.sorted { $0.word < $1.word }
    }
}
