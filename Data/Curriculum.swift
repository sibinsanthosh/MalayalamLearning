import Foundation

/// Anything a child can trace: a letter, a consonant + vowel sign, a chillu or a digit.
struct TraceItem: Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case vowel, consonant, sign, chillu, number
    }

    /// The Malayalam text itself; also the progress key.
    var id: String { text }
    let text: String
    let kind: Kind
    /// Romanised name, e.g. "Ka", "Kaa".
    let title: String
    /// Extra line, e.g. the example word or the number's value.
    var subtitle: String = ""
    /// Bundled audio file name, if there is a recording.
    var sound: String? = nil
    /// Picture asset for the example word, if any.
    var imageName: String? = nil
    /// Words spoken by text-to-speech when there is no recording (and no Malayalam voice).
    var spokenFallback: String? = nil

    init(text: String, kind: Kind, title: String, subtitle: String = "", sound: String? = nil,
         imageName: String? = nil, spokenFallback: String? = nil) {
        self.text = text
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.sound = sound
        self.imageName = imageName
        self.spokenFallback = spokenFallback
    }

    init(letter: Letter) {
        self.init(text: letter.char,
                  kind: letter.category == "vowel" ? .vowel : .consonant,
                  title: letter.transliteration,
                  subtitle: "\(letter.example) • \(letter.exampleEn)",
                  sound: letter.sound,
                  imageName: letter.imageName)
    }
}

enum Curriculum {
    static var vowels: [TraceItem] { DataRepository.shared.vowels.map(TraceItem.init(letter:)) }
    static var consonants: [TraceItem] { DataRepository.shared.consonants.map(TraceItem.init(letter:)) }
    static var letters: [TraceItem] { vowels + consonants }

    static func letter(_ text: String) -> TraceItem? { letters.first { $0.text == text } }

    // MARK: Learning path
    // Easiest shapes first, building to the most complex — the order suggested by
    // Malayalam Mash (Santhosh Thottingal) for learning to write.

    struct Stage: Identifiable {
        let id: Int
        let name: String
        let letters: [String]
    }

    static let stages: [Stage] = [
        Stage(id: 1, name: "First curves", letters: ["റ", "ന"]),
        Stage(id: 2, name: "Little hills", letters: ["ര", "ത"]),
        Stage(id: 3, name: "Round and round", letters: ["ഠ", "ണ"]),
        Stage(id: 4, name: "Up and down", letters: ["പ", "വ", "ഖ", "ബ", "ഹ", "ച", "ഛ"]),
        Stage(id: 5, name: "Loops and tails", letters: ["ഥ", "ല", "ഘ", "ഫ", "ഷ", "എ", "ഏ"]),
        Stage(id: 6, name: "Swirls", letters: ["ഗ", "ശ", "ട"]),
        Stage(id: 7, name: "Mirror shapes", letters: ["ധ", "സ", "ഡ", "ഢ", "ഝ"]),
        Stage(id: 8, name: "Big bellies", letters: ["ദ", "ഭ", "ഒ"]),
        Stage(id: 9, name: "Twins", letters: ["ങ", "ഞ"]),
        Stage(id: 10, name: "Curly tails", letters: ["ഉ", "ഇ", "ജ", "ള"]),
        Stage(id: 11, name: "Tricky ones", letters: ["ഴ", "യ", "ക", "മ"]),
        Stage(id: 12, name: "Long sounds", letters: ["ഈ", "ഊ", "ഐ", "ഓ", "ഔ"]),
        Stage(id: 13, name: "Grand finale", letters: ["അ", "ആ", "ഋ"]),
    ]

    static var pathItems: [TraceItem] { stages.flatMap(\.letters).compactMap(letter) }

    // MARK: Vowel signs

    struct Sign {
        let mark: String
        let name: String
        let sound: String
        /// Builds the text for consonant + this sign.
        func apply(to consonant: String) -> String { consonant + mark }
    }

    static let signs: [Sign] = [
        Sign(mark: "ാ", name: "aa", sound: "aa"),
        Sign(mark: "ി", name: "i", sound: "i"),
        Sign(mark: "ീ", name: "ee", sound: "ee"),
        Sign(mark: "ു", name: "u", sound: "u"),
        Sign(mark: "ൂ", name: "oo", sound: "oo"),
        Sign(mark: "ൃ", name: "ru", sound: "ru"),
        Sign(mark: "െ", name: "e", sound: "e"),
        Sign(mark: "േ", name: "ae", sound: "ae"),
        Sign(mark: "ൈ", name: "ai", sound: "ai"),
        Sign(mark: "\u{0D4A}", name: "o", sound: "o"),
        Sign(mark: "\u{0D4B}", name: "oa", sound: "oa"),
        Sign(mark: "\u{0D57}", name: "au", sound: "au"),
    ]

    /// The consonant on its own plus every vowel sign, e.g. ക കാ കി … കൗ.
    static func combos(for consonant: TraceItem) -> [TraceItem] {
        let base = consonant.title.hasSuffix("a") ? String(consonant.title.dropLast()) : consonant.title
        let plain = TraceItem(text: consonant.text, kind: .sign, title: consonant.title,
                              subtitle: "\(consonant.text) + അ", sound: consonant.sound)
        return [plain] + signs.map { sign in
            TraceItem(text: sign.apply(to: consonant.text), kind: .sign, title: base + sign.sound,
                      subtitle: "\(consonant.text) + \(sign.mark == "\u{0D57}" ? "ൗ" : sign.mark)",
                      spokenFallback: base + sign.sound)
        }
    }

    // MARK: Chillu & numbers

    static let chillu: [TraceItem] = [
        TraceItem(text: "ൺ", kind: .chillu, title: "ṇ", subtitle: "ണ് — as in കൺ (eye)", spokenFallback: "n"),
        TraceItem(text: "ൻ", kind: .chillu, title: "n", subtitle: "ന് — as in അവൻ (he)", spokenFallback: "n"),
        TraceItem(text: "ർ", kind: .chillu, title: "r", subtitle: "ര് — as in അവർ (they)", spokenFallback: "r"),
        TraceItem(text: "ൽ", kind: .chillu, title: "l", subtitle: "ല് — as in കാൽ (leg)", spokenFallback: "l"),
        TraceItem(text: "ൾ", kind: .chillu, title: "ḷ", subtitle: "ള് — as in അവൾ (she)", spokenFallback: "l"),
    ]

    static let numberNames = ["പൂജ്യം", "ഒന്ന്", "രണ്ട്", "മൂന്ന്", "നാല്", "അഞ്ച്", "ആറ്", "ഏഴ്", "എട്ട്", "ഒമ്പത്"]
    static let numberNamesEn = ["Poojyam", "Onnu", "Randu", "Moonnu", "Naalu", "Anchu", "Aaru", "Ezhu", "Ettu", "Onpathu"]

    static let numbers: [TraceItem] = (0...9).map { n in
        let digit = String(UnicodeScalar(0x0D66 + n)!)
        return TraceItem(text: digit, kind: .number, title: "\(n)",
                         subtitle: "\(numberNames[n]) • \(numberNamesEn[n])",
                         spokenFallback: "\(n)")
    }

    static var allItems: [TraceItem] {
        letters + chillu + numbers + consonants.flatMap { combos(for: $0).dropFirst() }
    }
}

// MARK: - Badges / stickers

struct Badge: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String
    let detail: String

    static let all: [Badge] = [
        Badge(id: "first", emoji: "✏️", title: "First Trace", detail: "Trace your first letter"),
        Badge(id: "five", emoji: "🖐️", title: "High Five", detail: "Trace 5 different letters"),
        Badge(id: "vowels", emoji: "🌈", title: "Vowel Champ", detail: "Trace all 13 vowels"),
        Badge(id: "consonants", emoji: "🏰", title: "Consonant King", detail: "Trace all 36 consonants"),
        Badge(id: "perfect10", emoji: "🌟", title: "Super Star", detail: "Get 3 stars on 10 letters"),
        Badge(id: "streak3", emoji: "🔥", title: "On Fire", detail: "Practise 3 days in a row"),
        Badge(id: "streak7", emoji: "🚀", title: "Rocket Week", detail: "Practise 7 days in a row"),
        Badge(id: "goal", emoji: "🎯", title: "Goal Getter", detail: "Reach your daily goal"),
        Badge(id: "signs", emoji: "🎶", title: "Sign Singer", detail: "Trace 10 vowel-sign letters"),
        Badge(id: "chillu", emoji: "🐚", title: "Chillu Collector", detail: "Trace all 5 chillu letters"),
        Badge(id: "numbers", emoji: "🔢", title: "Number Ninja", detail: "Trace all 10 numbers"),
        Badge(id: "free", emoji: "🦋", title: "Free Writer", detail: "Write a letter on your own"),
        Badge(id: "story", emoji: "📖", title: "Bookworm", detail: "Finish a story"),
        Badge(id: "stories", emoji: "📚", title: "Library Hero", detail: "Finish every story"),
        Badge(id: "games", emoji: "🎮", title: "Game Fan", detail: "Finish 5 games"),
        Badge(id: "elephant", emoji: "🐘", title: "Appu's Friend", detail: "Trace 25 different letters"),
    ]

    static func badge(_ id: String) -> Badge? { all.first { $0.id == id } }
}
