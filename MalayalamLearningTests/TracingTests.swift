import CoreGraphics
import XCTest
@testable import Malayalam_Learning

final class TracingTests: XCTestCase {

    /// Drags a finger exactly along every stroke and reports whether the glyph completed.
    private func traceCompletes(_ strokes: [[CGPoint]]) -> Bool {
        var engine = TraceEngine(strokes: strokes)
        var done = false
        for stroke in engine.strokes {
            if engine.touchBegan(at: stroke[0]) == .glyphDone { done = true }
            for p in stroke.dropFirst() where engine.touchMoved(to: p) == .glyphDone { done = true }
            engine.touchEnded()
        }
        return done && engine.isComplete
    }

    func testEveryLetterHasHandwritingStrokes() {
        for item in Curriculum.letters + Curriculum.chillu + Curriculum.numbers {
            XCTAssertNotNil(StrokeLibrary.strokes(for: item.text), "No stroke data for \(item.text)")
        }
    }

    func testEveryLetterCanBeTracedToTheEnd() {
        for item in Curriculum.letters + Curriculum.chillu + Curriculum.numbers {
            let strokes = TraceGlyph.make(for: item.text).strokes
            XCTAssertFalse(strokes.isEmpty, item.text)
            XCTAssertTrue(traceCompletes(strokes), "Could not finish tracing \(item.text)")
        }
    }

    func testEveryVowelSignComboCanBeTraced() {
        for consonant in Curriculum.consonants {
            for combo in Curriculum.combos(for: consonant) {
                guard let data = StrokeLibrary.strokes(for: combo.text) else {
                    return XCTFail("No strokes for \(combo.text)")
                }
                XCTAssertTrue(traceCompletes(data.strokes), "Could not finish tracing \(combo.text)")
            }
        }
    }

    func testVowelSignsArePlacedInVisualOrder() {
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "കാ"), ["ക", "ാ"])
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "കെ"), ["െ", "ക"])
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "കൊ"), ["െ", "ക", "ാ"])
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "കോ"), ["േ", "ക", "ാ"])
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "കൗ"), ["െ", "ക", "ൗ"])
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "കു"), ["കു"], "Uses the joined ku shape")
        XCTAssertEqual(StrokeLibrary.glyphSequence(for: "ലു"), ["ല", "ു"])
    }

    func testStrokesFitTheDesignSpace() {
        for item in Curriculum.letters {
            let g = TraceGlyph.make(for: item.text)
            XCTAssertGreaterThanOrEqual(g.designWidth, 100)
            for p in g.strokes.flatMap({ $0 }) {
                XCTAssert((0...g.designWidth).contains(p.x) && (0...100).contains(p.y), "\(item.text) point \(p) outside")
            }
        }
    }

    func testLeavingThePathCountsAsASlip() {
        var engine = TraceEngine(strokes: [[CGPoint(x: 10, y: 50), CGPoint(x: 90, y: 50)]])
        XCTAssertTrue([.started, .advanced].contains(engine.touchBegan(at: CGPoint(x: 10, y: 50))))
        XCTAssertEqual(engine.touchMoved(to: CGPoint(x: 15, y: 95)), .offPath)
        XCTAssertFalse(engine.isComplete)
    }

    func testStartingAwayFromTheStartDotDoesNothing() {
        var engine = TraceEngine(strokes: [[CGPoint(x: 10, y: 50), CGPoint(x: 90, y: 50)]])
        XCTAssertEqual(engine.touchBegan(at: CGPoint(x: 90, y: 50)), .none, "Must begin at the start, not the end")
    }

    func testLearningPathCoversAllLettersOnce() {
        let path = Curriculum.pathItems.map(\.text)
        XCTAssertEqual(path.count, 49)
        XCTAssertEqual(Set(path), Set(Curriculum.letters.map(\.text)))
    }

    @MainActor
    func testFreeWritingScoresTheRightLetterHigher() {
        let glyph = TraceGlyph.make(for: "റ")
        let good = FreeWriteModel()
        good.strokes = glyph.strokes
        let bad = FreeWriteModel()
        bad.strokes = [[CGPoint(x: 5, y: 5), CGPoint(x: 20, y: 8)]]
        XCTAssertGreaterThanOrEqual(good.check(against: glyph), 90)
        XCTAssertLessThan(bad.check(against: glyph), 40)
        XCTAssertEqual(FreeWriteModel.stars(for: 95), 3)
        XCTAssertEqual(FreeWriteModel.stars(for: 10), 0)
    }
}

final class ProgressStoreTests: XCTestCase {
    private var url: URL!

    override func setUp() {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("progress-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: url)
    }

    func testRecordingATraceSavesStarsAndAwardsFirstSticker() {
        let store = ProgressStore(fileURL: url)
        let item = Curriculum.letters[0]
        let badges = store.recordTrace(item: item, stars: 2, slips: 1, mode: .guided)
        XCTAssertEqual(store.stars(for: item.id), 2)
        XCTAssertEqual(store.today.traced, 1)
        XCTAssertTrue(badges.contains { $0.id == "first" })
        // Best stars only go up.
        store.recordTrace(item: item, stars: 1, slips: 4, mode: .guided)
        XCTAssertEqual(store.stars(for: item.id), 2)
    }

    func testProgressPersistsAcrossLaunches() {
        let first = ProgressStore(fileURL: url)
        first.addProfile(name: "Anu", avatar: "🦋")
        first.recordTrace(item: Curriculum.letters[3], stars: 3, slips: 0, mode: .free, freeScore: 91)
        first.settings.leftHanded = true

        let second = ProgressStore(fileURL: url)
        XCTAssertEqual(second.active.name, "Anu")
        XCTAssertEqual(second.stars(for: Curriculum.letters[3].id), 3)
        XCTAssertEqual(second.record(for: Curriculum.letters[3].id).bestFreeScore, 91)
        XCTAssertTrue(second.settings.leftHanded)
        XCTAssertEqual(second.profiles.count, 2)
    }

    func testProfilesKeepSeparateProgress() {
        let store = ProgressStore(fileURL: url)
        let firstID = store.active.id
        store.recordTrace(item: Curriculum.letters[0], stars: 3, slips: 0, mode: .guided)
        store.addProfile(name: "Second", avatar: "🐯")
        XCTAssertEqual(store.stars(for: Curriculum.letters[0].id), 0)
        store.switchTo(firstID)
        XCTAssertEqual(store.stars(for: Curriculum.letters[0].id), 3)
    }

    func testNeedsPracticeListsWeakLetters() {
        let store = ProgressStore(fileURL: url)
        let weak = Curriculum.letters[5], strong = Curriculum.letters[6]
        store.recordTrace(item: weak, stars: 1, slips: 5, mode: .guided)
        store.recordTrace(item: strong, stars: 3, slips: 0, mode: .guided)
        let list = store.needsPractice(from: Curriculum.letters)
        XCTAssertEqual(list.first, weak)
        XCTAssertFalse(list.contains(strong))
    }

    func testStreakCountsConsecutiveDays() {
        let store = ProgressStore(fileURL: url)
        XCTAssertEqual(store.streak, 0)
        store.recordTrace(item: Curriculum.letters[0], stars: 3, slips: 0, mode: .guided)
        XCTAssertEqual(store.streak, 1)
    }

    func testDailyGoalStickerWhenGoalReached() {
        let store = ProgressStore(fileURL: url)
        store.settings.dailyGoal = 2
        store.recordTrace(item: Curriculum.letters[0], stars: 3, slips: 0, mode: .guided)
        let badges = store.recordTrace(item: Curriculum.letters[1], stars: 3, slips: 0, mode: .guided)
        XCTAssertTrue(badges.contains { $0.id == "goal" })
        XCTAssertEqual(store.goalProgress, 1)
    }
}
