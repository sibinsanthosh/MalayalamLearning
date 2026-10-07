import SwiftUI

struct DictionaryScreen: View {
    @StateObject private var dictionaryManager = DictionaryManager()
    @State private var searchText = ""
    @State private var results: [DictionaryEntry] = []

    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var body: some View {
        if hSizeClass == .regular {
            IPadDictionaryView(dictionaryManager: dictionaryManager)
        } else {
            iPhoneDictionaryView
        }
    }

    private var iPhoneDictionaryView: some View {
        VStack {
            if !dictionaryManager.isLoaded {
                ProgressView("Loading Dictionary Data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if results.isEmpty && !searchText.isEmpty {
                    Text("No results found for '\(searchText)'")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if searchText.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.5))
                        Text("Search for an English word to find its Malayalam meaning.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.word)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !entry.partOfSpeech.isEmpty {
                                    Text(entry.partOfSpeech)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(entry.meaning)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationTitle("Dictionary")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search English word...")
        .onChange(of: searchText) { newValue in
            performSearch(query: newValue)
        }
    }
    
    private func performSearch(query: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            let newResults = dictionaryManager.search(query: query)
            DispatchQueue.main.async {
                self.results = newResults
            }
        }
    }
}

// MARK: - ==========================================
// MARK: - IPAD TWO-PANE DICTIONARY EXPLORER
// MARK: - ==========================================

struct IPadDictionaryView: View {
    @ObservedObject var dictionaryManager: DictionaryManager
    @State private var searchText = ""
    @State private var results: [DictionaryEntry] = []
    @State private var selectedEntry: DictionaryEntry?
    
    // Quick starter words
    let popularWords = [
        ("Water", "വെള്ളം"),
        ("Sun", "സൂര്യൻ"),
        ("Mother", "അമ്മ"),
        ("Tree", "മരം"),
        ("Flower", "പൂവ്"),
        ("Friend", "സുഹൃത്ത്"),
        ("Book", "പുസ്തകം"),
        ("Star", "നക്ഷത്രം")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // ── LEFT PANE: Search & Word List (380 pt) ──────────────────
            VStack(spacing: 0) {
                // Top Search Bar in Left Pane
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search 10,000+ words...", text: $searchText)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    
                    if !results.isEmpty {
                        HStack {
                            Text("\(results.count) results found")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(16)
                .background(Color(hex: "F4F6F9"))
                
                Divider()
                
                // List of Words
                if !dictionaryManager.isLoaded {
                    ProgressView("Loading Dictionary Data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No matching words for '\(searchText)'")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    // Starter / Popular words suggestion
                    VStack(alignment: .leading, spacing: 14) {
                        Text("POPULAR WORDS")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(popularWords, id: \.0) { word, ml in
                                    Button(action: {
                                        searchText = word
                                    }) {
                                        HStack {
                                            Text(word)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(Color(hex: "222222"))
                                            Spacer()
                                            Text(ml)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Color(hex: "0288D1"))
                                        }
                                        .padding(14)
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { entry in
                        let isSelected = selectedEntry?.id == entry.id
                        Button(action: {
                            selectedEntry = entry
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.word)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(isSelected ? .white : Color(hex: "222222"))
                                    
                                    Text(entry.meaning)
                                        .font(.system(size: 13))
                                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if !entry.partOfSpeech.isEmpty {
                                    Text(entry.partOfSpeech)
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(isSelected ? Color.white.opacity(0.25) : Color.blue.opacity(0.1))
                                        .foregroundColor(isSelected ? .white : .blue)
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(isSelected ? Color(hex: "0288D1") : Color.white)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .frame(width: 380)
            .background(Color(hex: "FAFAFC"))
            
            Divider()
            
            // ── RIGHT PANE: Word Detail Showcase ────────────────────────
            ZStack {
                Color(hex: "F8F9FA").ignoresSafeArea()
                
                if let entry = displayedWord {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Card
                        VStack(alignment: .leading, spacing: 14) {
                            if !entry.partOfSpeech.isEmpty {
                                Text(entry.partOfSpeech.uppercased())
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Color(hex: "0288D1"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "0288D1").opacity(0.12))
                                    .cornerRadius(10)
                            }
                            
                            Text(entry.word)
                                .font(.system(size: 52, weight: .heavy))
                                .foregroundColor(Color(hex: "1A1A1A"))
                        }
                        .padding(28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                        
                        // Meaning Showcase Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MALAYALAM MEANING • മലയാള അർത്ഥം")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                            
                            Text(entry.meaning)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(hex: "0288D1"))
                                .lineSpacing(8)
                        }
                        .padding(28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                        
                        Spacer()
                    }
                    .padding(32)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "character.book.closed.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "0288D1").opacity(0.4))
                        Text("Select a word from the list to view its Malayalam meaning")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                }
            }
        }
        .navigationTitle("Dictionary Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { newValue in
            performSearch(query: newValue)
        }
        .onAppear {
            if results.isEmpty && !searchText.isEmpty {
                performSearch(query: searchText)
            }
        }
    }
    
    private var displayedWord: DictionaryEntry? {
        if let selected = selectedEntry {
            return selected
        }
        return results.first
    }
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            let newResults = dictionaryManager.search(query: query)
            DispatchQueue.main.async {
                self.results = newResults
                if self.selectedEntry == nil || !newResults.contains(where: { $0.id == self.selectedEntry?.id }) {
                    self.selectedEntry = newResults.first
                }
            }
        }
    }
}


