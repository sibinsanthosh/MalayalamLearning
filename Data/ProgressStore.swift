import Combine
import Foundation

// MARK: - Model

struct LetterRecord: Codable, Hashable {
    var bestStars = 0
    var attempts = 0
    var completions = 0
    var totalSlips = 0
    var bestFreeScore = 0
    var lastPracticed: Date?

    /// Average slips per finished trace; high means the letter needs practice.
    var averageSlips: Double { completions == 0 ? 0 : Double(totalSlips) / Double(completions) }
}

struct DayRecord: Codable, Hashable {
    var traced = 0
    var seconds = 0
}

struct ChildProfile: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var avatar: String
    var createdAt = Date()
    var points = 0
    var records: [String: LetterRecord] = [:]
    /// Keyed by "yyyy-MM-dd".
    var days: [String: DayRecord] = [:]
    var badges: [String: Date] = [:]
    var gamesFinished = 0
    var storiesRead: Set<String> = []
}

struct AppSettings: Codable, Hashable {
    var soundOn = true
    var hapticsOn = true
    var showHints = true
    var leftHanded = false
    var dailyGoal = 3
}

enum TraceMode: String, Codable, CaseIterable, Identifiable {
    case guided, faded, free
    var id: String { rawValue }
    var label: String {
        switch self {
        case .guided: return "Guided"
        case .faded: return "Dots"
        case .free: return "Free"
        }
    }
    var icon: String {
        switch self {
        case .guided: return "hand.point.up.left.fill"
        case .faded: return "circle.dotted"
        case .free: return "scribble.variable"
        }
    }
}

// MARK: - Store

/// On-device progress for every child profile, saved as JSON in Application Support.
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var profiles: [ChildProfile] = []
    @Published var activeProfileID: UUID?
    @Published var settings = AppSettings() { didSet { save() } }

    private let fileURL: URL
    private let calendar = Calendar.current

    static let avatars = ["🐘", "🦁", "🐯", "🐼", "🦊", "🐰", "🐵", "🦜", "🐢", "🦋", "🐬", "🦄"]

    init(fileURL: URL? = nil) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? dir.appendingPathComponent("progress.json")
        load()
        if profiles.isEmpty {
            let first = ChildProfile(name: "Little Learner", avatar: "🐘")
            profiles = [first]
            activeProfileID = first.id
            save()
        }
    }

    // MARK: Active profile

    var active: ChildProfile {
        profiles.first { $0.id == activeProfileID } ?? profiles[0]
    }

    private func mutateActive(_ change: (inout ChildProfile) -> Void) {
        guard let i = profiles.firstIndex(where: { $0.id == active.id }) else { return }
        change(&profiles[i])
        save()
    }

    func record(for itemID: String) -> LetterRecord { active.records[itemID] ?? LetterRecord() }
    func stars(for itemID: String) -> Int { record(for: itemID).bestStars }

    // MARK: Days, streaks, goals

    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var today: DayRecord { active.days[Self.dayKey(Date())] ?? DayRecord() }

    var goalProgress: Double { min(1, Double(today.traced) / Double(max(1, settings.dailyGoal))) }

    /// Consecutive days with any practice, counting today or (if not yet) yesterday.
    var streak: Int { streak(asOf: Date()) }

    func streak(asOf date: Date) -> Int {
        var day = date
        if (active.days[Self.dayKey(day)]?.traced ?? 0) == 0 && (active.days[Self.dayKey(day)]?.seconds ?? 0) < 60 {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var count = 0
        while let rec = active.days[Self.dayKey(day)], rec.traced > 0 || rec.seconds >= 60 {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    /// The last `count` days, oldest first, for charts.
    func recentDays(_ count: Int = 7) -> [(date: Date, record: DayRecord)] {
        (0..<count).reversed().map { offset in
            let d = calendar.date(byAdding: .day, value: -offset, to: Date())!
            return (d, active.days[Self.dayKey(d)] ?? DayRecord())
        }
    }

    // MARK: Recording

    /// Records a finished trace and returns any newly earned badges.
    @discardableResult
    func recordTrace(item: TraceItem, stars: Int, slips: Int, mode: TraceMode, freeScore: Int? = nil) -> [Badge] {
        let goalBefore = today.traced >= settings.dailyGoal
        mutateActive { p in
            var r = p.records[item.id] ?? LetterRecord()
            r.attempts += 1
            r.completions += 1
            r.totalSlips += slips
            r.bestStars = max(r.bestStars, stars)
            if let freeScore { r.bestFreeScore = max(r.bestFreeScore, freeScore) }
            r.lastPracticed = Date()
            p.records[item.id] = r
            p.points += 5 + stars * 5 + (mode == .guided ? 0 : 5)
            let key = Self.dayKey(Date())
            var d = p.days[key] ?? DayRecord()
            d.traced += 1
            p.days[key] = d
        }
        var extra: [String] = []
        if mode == .free { extra.append("free") }
        if !goalBefore && today.traced >= settings.dailyGoal { extra.append("goal") }
        return awardBadges(extra: extra)
    }

    func recordAttemptStarted(itemID: String) {
        mutateActive { p in
            var r = p.records[itemID] ?? LetterRecord()
            r.attempts += 1
            p.records[itemID] = r
        }
    }

    func addTime(seconds: Int) {
        guard seconds > 0 else { return }
        mutateActive { p in
            let key = Self.dayKey(Date())
            var d = p.days[key] ?? DayRecord()
            d.seconds += min(seconds, 60 * 60)
            p.days[key] = d
        }
    }

    @discardableResult
    func recordGameFinished(points: Int = 10) -> [Badge] {
        mutateActive { p in
            p.gamesFinished += 1
            p.points += points
        }
        return awardBadges()
    }

    @discardableResult
    func recordStoryRead(_ storyID: String) -> [Badge] {
        mutateActive { p in
            if !p.storiesRead.contains(storyID) { p.points += 15 }
            p.storiesRead.insert(storyID)
        }
        return awardBadges()
    }

    func addPoints(_ n: Int) { mutateActive { $0.points += n } }

    // MARK: Insights

    func tracedCount(of items: [TraceItem]) -> Int {
        items.filter { (active.records[$0.id]?.completions ?? 0) > 0 }.count
    }

    /// Letters that were traced but with low stars or many slips, worst first.
    func needsPractice(from items: [TraceItem], limit: Int = 6) -> [TraceItem] {
        items.compactMap { item -> (TraceItem, Double)? in
            guard let r = active.records[item.id], r.completions > 0 else { return nil }
            let score = Double(3 - r.bestStars) * 2 + r.averageSlips
            return score >= 2 ? (item, score) : nil
        }
        .sorted { $0.1 > $1.1 }
        .prefix(limit)
        .map(\.0)
    }

    /// First item on the learning path that hasn't been traced yet.
    var nextPathItem: TraceItem? {
        let path = Curriculum.pathItems
        return path.first { (active.records[$0.id]?.completions ?? 0) == 0 } ?? path.first
    }

    var totalStars: Int { active.records.values.reduce(0) { $0 + $1.bestStars } }

    // MARK: Badges

    private func awardBadges(extra: [String] = []) -> [Badge] {
        let p = active
        let traced = Set(p.records.filter { $0.value.completions > 0 }.keys)
        let letters = Set(Curriculum.letters.map(\.id))
        let vowels = Set(Curriculum.vowels.map(\.id))
        let consonants = Set(Curriculum.consonants.map(\.id))
        let tracedLetters = traced.intersection(letters)
        var earned = Set(extra)
        if !tracedLetters.isEmpty { earned.insert("first") }
        if tracedLetters.count >= 5 { earned.insert("five") }
        if tracedLetters.count >= 25 { earned.insert("elephant") }
        if vowels.isSubset(of: traced) { earned.insert("vowels") }
        if consonants.isSubset(of: traced) { earned.insert("consonants") }
        if p.records.filter({ letters.contains($0.key) && $0.value.bestStars == 3 }).count >= 10 { earned.insert("perfect10") }
        if streak >= 3 { earned.insert("streak3") }
        if streak >= 7 { earned.insert("streak7") }
        let signItems = traced.filter { $0.unicodeScalars.count == 2 }
        if signItems.count >= 10 { earned.insert("signs") }
        if Set(Curriculum.chillu.map(\.id)).isSubset(of: traced) { earned.insert("chillu") }
        if Set(Curriculum.numbers.map(\.id)).isSubset(of: traced) { earned.insert("numbers") }
        if !p.storiesRead.isEmpty { earned.insert("story") }
        if p.storiesRead.count >= DataRepository.shared.stories.count { earned.insert("stories") }
        if p.gamesFinished >= 5 { earned.insert("games") }

        let new = earned.subtracting(p.badges.keys)
        guard !new.isEmpty else { return [] }
        mutateActive { profile in
            for id in new { profile.badges[id] = Date() }
            profile.points += 20 * new.count
        }
        return Badge.all.filter { new.contains($0.id) }
    }

    // MARK: Profiles

    func addProfile(name: String, avatar: String) {
        let p = ChildProfile(name: name.isEmpty ? "Learner" : name, avatar: avatar)
        profiles.append(p)
        activeProfileID = p.id
        save()
    }

    func switchTo(_ id: UUID) {
        activeProfileID = id
        save()
    }

    func updateProfile(_ id: UUID, name: String, avatar: String) {
        guard let i = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[i].name = name.isEmpty ? profiles[i].name : name
        profiles[i].avatar = avatar
        save()
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        if activeProfileID == id { activeProfileID = profiles.first?.id }
        save()
    }

    func resetProgress(_ id: UUID) {
        guard let i = profiles.firstIndex(where: { $0.id == id }) else { return }
        let p = profiles[i]
        profiles[i] = ChildProfile(id: p.id, name: p.name, avatar: p.avatar, createdAt: p.createdAt)
        save()
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var profiles: [ChildProfile]
        var activeProfileID: UUID?
        var settings: AppSettings
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        profiles = snap.profiles
        activeProfileID = snap.activeProfileID ?? snap.profiles.first?.id
        settings = snap.settings
    }

    private func save() {
        guard !profiles.isEmpty else { return }
        let snap = Snapshot(profiles: profiles, activeProfileID: activeProfileID, settings: settings)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snap)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Could not save progress: \(error)")
        }
    }
}
