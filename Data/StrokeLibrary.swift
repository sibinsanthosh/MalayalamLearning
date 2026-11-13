import CoreGraphics
import Foundation

// Handwriting stroke data for Malayalam letters, vowel signs, chillu and digits:
// centre-line paths in writing order and direction (malayalam_strokes.json).
//
// Generated from the stroke SVGs of "Malayalam Mash" (മലയാളം മാഷ്) by
// Santhosh Thottingal, drawn from the Manjari typeface:
// https://github.com/santhoshtr/mlmash
//
// MIT License — Copyright (c) 2020 Santhosh Thottingal
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

enum StrokeLibrary {
    struct Glyph: Decodable {
        let advance: CGFloat
        /// Each stroke is a flat list of x, y pairs in font units (em = 1024, y down).
        let strokes: [[CGFloat]]
    }

    private struct File: Decodable { let glyphs: [String: Glyph] }

    /// Letter height in the 100-unit-tall design space, and the widest a letter may get.
    static let letterHeight: CGFloat = 76
    static let maxWidth: CGFloat = 150

    /// Override for tests / tools; defaults to the app bundle resource.
    static var dataURL: URL? = Bundle.main.url(forResource: "malayalam_strokes", withExtension: "json")

    static let glyphs: [String: Glyph] = {
        guard let url = dataURL, let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [:] }
        return file.glyphs
    }()

    /// Visual order of glyphs that make up `text` (vowel signs placed before/after the consonant).
    static func glyphSequence(for text: String) -> [String]? {
        if glyphs[text] != nil { return [text] }
        let scalars = text.unicodeScalars.map { String($0) }
        guard scalars.count == 2 else { return nil }
        let c = scalars[0], sign = scalars[1]
        guard glyphs[c] != nil else { return nil }
        switch sign {
        case "ാ", "ി", "ീ", "്":
            return [c, sign]
        case "ു", "ൂ", "ൃ":
            return glyphs[c + sign] != nil ? [c + sign] : [c, sign]
        case "െ", "േ", "ൈ":
            return [sign, c]
        case "\u{0D4A}": // ൊ
            return ["െ", c, "ാ"]
        case "\u{0D4B}": // ോ
            return ["േ", c, "ാ"]
        case "\u{0D57}", "\u{0D4C}": // ൗ / ൌ
            return ["െ", c, "ൗ"]
        default:
            return nil
        }
    }

    /// Strokes fitted into the tracing design space (100 units tall), plus the width needed.
    static func strokes(for text: String) -> (strokes: [[CGPoint]], width: CGFloat)? {
        guard let sequence = glyphSequence(for: text) else { return nil }
        var raw: [[CGPoint]] = []
        var x: CGFloat = 0
        for name in sequence {
            guard let g = glyphs[name] else { return nil }
            for flat in g.strokes {
                raw.append(stride(from: 0, to: flat.count - 1, by: 2).map { CGPoint(x: flat[$0] + x, y: flat[$0 + 1]) })
            }
            x += g.advance
        }
        let all = raw.flatMap { $0 }
        guard let minX = all.map(\.x).min(), let maxX = all.map(\.x).max(),
              let minY = all.map(\.y).min(), let maxY = all.map(\.y).max(),
              maxX > minX, maxY > minY else { return nil }
        let w = maxX - minX, h = maxY - minY
        let k = min(letterHeight / h, maxWidth / w)
        let width = max(100, (w * k + 24).rounded())
        let ox = (width - w * k) / 2, oy = (100 - h * k) / 2
        let fitted = raw.map { s in s.map { CGPoint(x: ($0.x - minX) * k + ox, y: ($0.y - minY) * k + oy) } }
        return (fitted, width)
    }
}
