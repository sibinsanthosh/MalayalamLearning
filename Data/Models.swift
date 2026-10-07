import Foundation

struct Letter: Identifiable, Hashable {
    let id: String
    let char: String
    let transliteration: String
    let example: String
    let exampleEn: String
    let imageName: String
    let category: String
    let sound: String
    
    init(id: String, char: String, transliteration: String, example: String, exampleEn: String, imageName: String, category: String, sound: String? = nil) {
        self.id = id
        self.char = char
        self.transliteration = transliteration
        self.example = example
        self.exampleEn = exampleEn
        self.imageName = imageName
        self.category = category
        self.sound = sound ?? id
    }
}

struct StoryPage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let imageName: String
    let highlight: String?
}

struct Story: Identifiable, Hashable {
    let id: String
    let title: String
    let titleEn: String
    let coverImageName: String
    let pages: [StoryPage]
}

struct Progress: Codable {
    var points: Int = 124
    var streak: Int = 5
    var unlockedBadges: [String] = ["badge1", "badge2"]
    var mastery: [String: Int] = [:]
}
