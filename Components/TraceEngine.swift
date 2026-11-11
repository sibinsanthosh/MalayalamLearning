import CoreGraphics
import CoreText
import Foundation

// Tracing mechanism ported from the ABC Trace project (TraceEngine + Glyph helpers).
// All coordinates live in a 100×100 design space (y grows downward).

// MARK: - Trace engine

/// Pure tracing logic: tracks how far along each stroke the child has traced.
struct TraceEngine {
    enum Event: Equatable {
        case none
        case started
        case advanced
        case strokeDone
        case glyphDone
        case offPath
    }

    static let spacing: CGFloat = 1.5

    let strokes: [[CGPoint]]
    /// How close (design units) the finger must be to the path.
    var tolerance: CGFloat
    /// How far ahead (design units) the finger may jump along the path in one move.
    var lookahead: CGFloat = 16

    private(set) var strokeIndex = 0
    private(set) var progress = 0
    private(set) var isTracing = false

    init(strokes raw: [[CGPoint]], tolerance: CGFloat = 11) {
        self.strokes = raw.map { resample($0, spacing: Self.spacing) }
        self.tolerance = tolerance
    }

    var isComplete: Bool { strokeIndex >= strokes.count }

    var currentStroke: [CGPoint]? { isComplete ? nil : strokes[strokeIndex] }

    /// Point the finger should touch next.
    var nextPoint: CGPoint? { currentStroke?[progress] }

    /// Fraction of the whole glyph traced, 0...1.
    var fractionComplete: Double {
        let total = strokes.reduce(0) { $0 + $1.count }
        guard total > 0 else { return 1 }
        let done = strokes.prefix(strokeIndex).reduce(0) { $0 + $1.count }
            + (isComplete ? 0 : progress)
        return Double(done) / Double(total)
    }

    /// Points already traced for the stroke at `index`.
    func tracedPoints(of index: Int) -> ArraySlice<CGPoint> {
        if index < strokeIndex { return strokes[index][...] }
        if index == strokeIndex, !isComplete { return strokes[index][...progress] }
        return []
    }

    mutating func reset() {
        strokeIndex = 0
        progress = 0
        isTracing = false
    }

    mutating func touchBegan(at p: CGPoint) -> Event {
        isTracing = false
        return touchMoved(to: p)
    }

    mutating func touchMoved(to p: CGPoint) -> Event {
        guard let stroke = currentStroke else { return .none }

        if !isTracing {
            // Must (re)start from where the stroke left off.
            guard stroke[progress].distance(to: p) <= tolerance * 1.4 else { return .none }
            isTracing = true
            if stroke.count == 1 { return finishStroke() } // a dot: just tap it
            let advanced = advance(along: stroke, to: p)
            return advanced == .none ? .started : advanced
        }
        return advance(along: stroke, to: p)
    }

    mutating func touchEnded() {
        isTracing = false
    }

    private mutating func advance(along stroke: [CGPoint], to p: CGPoint) -> Event {
        let window = Int(lookahead / Self.spacing)
        let upper = min(stroke.count - 1, progress + window)
        var best: Int?
        if upper > progress {
            for j in (progress + 1)...upper where stroke[j].distance(to: p) <= tolerance {
                best = j
            }
        }
        if let best {
            progress = best
            if progress >= stroke.count - 2 { return finishStroke() }
            return .advanced
        }
        if stroke[progress].distance(to: p) > tolerance * 2.2 {
            isTracing = false
            return .offPath
        }
        return .none
    }

    private mutating func finishStroke() -> Event {
        strokeIndex += 1
        progress = 0
        isTracing = false
        return isComplete ? .glyphDone : .strokeDone
    }
}

// MARK: - Glyph

/// A traceable Malayalam letter: strokes in the 100×100 design space.
struct TraceGlyph: Identifiable, Hashable {
    let id: String
    let symbol: String
    let strokes: [[CGPoint]]
    var designWidth: CGFloat = 100

    static func == (lhs: TraceGlyph, rhs: TraceGlyph) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    private static var cache: [String: TraceGlyph] = [:]
    private static let lock = NSLock()

    /// Builds (and caches) the stroke paths for a letter. Uses the handwriting stroke
    /// data (correct writing order and direction); letters without it fall back to
    /// strokes extracted from the font outline.
    static func make(for symbol: String) -> TraceGlyph {
        lock.lock(); defer { lock.unlock() }
        if let g = cache[symbol] { return g }
        let (strokes, width) = StrokeLibrary.strokes(for: symbol).map { ($0.strokes, $0.width) }
            ?? StrokeExtractor.extract(symbol)
        let g = TraceGlyph(id: symbol, symbol: symbol, strokes: strokes, designWidth: width)
        cache[symbol] = g
        return g
    }
}

// MARK: - Geometry helpers

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

/// Resample a polyline into evenly spaced points.
func resample(_ points: [CGPoint], spacing: CGFloat) -> [CGPoint] {
    guard points.count > 1 else { return points }
    var out = [points[0]]
    var carry: CGFloat = 0
    for i in 1..<points.count {
        let a = points[i - 1], b = points[i]
        let seg = a.distance(to: b)
        guard seg > 0 else { continue }
        var d = spacing - carry
        while d <= seg {
            let t = d / seg
            out.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
            d += spacing
        }
        carry = seg - (d - spacing)
    }
    if let last = points.last, let o = out.last, o.distance(to: last) > 0.01 {
        out.append(last)
    }
    return out
}

// MARK: - Stroke extraction

/// Turns a letter's font outline into centre-line strokes: render → thin to a
/// one-pixel skeleton → split the skeleton into paths → join paths that continue
/// smoothly through junctions → order them left to right.
enum StrokeExtractor {
    static let fontNames = ["MalayalamSangamMN", "MalayalamMN"]
    /// Bitmap pixels per design unit.
    static let pixelsPerUnit: CGFloat = 2
    /// Letter height in design units (the design space is 100 tall).
    static let letterHeight: CGFloat = 76
    static let maxWidth: CGFloat = 150
    /// Side of the square bitmap for the letter being processed. Only touched
    /// from `TraceGlyph.make`, which serialises extraction.
    private static var grid = 200

    /// Centre-line strokes plus the design-space width they need (≥ 100, wider letters get more room).
    static func extract(_ text: String) -> (strokes: [[CGPoint]], width: CGFloat) {
        guard let (bitmap, width) = render(text) else { return ([], 100) }
        var skel = thin(bitmap)
        cleanStaircases(&skel)
        let px = pixelsPerUnit
        let raw = trace(skel)
        let strokes = raw
            .map { smooth($0).map { CGPoint(x: (CGFloat($0.x) + 0.5) / px, y: (CGFloat($0.y) + 0.5) / px) } }
            .map { simplify($0, epsilon: 0.4) }
            .filter { length($0) >= 4 }
            .map(orientLeftToRight)
            .sorted { writingOrder($0) < writingOrder($1) }
        return (strokes, width)
    }

    static func strokes(for text: String) -> [[CGPoint]] { extract(text).strokes }

    // MARK: Render

    private static func render(_ text: String) -> ([Bool], CGFloat)? {
        let font = fontNames.lazy.map { CTFontCreateWithName($0 as CFString, 200, nil) }
            .first { (CTFontCopyPostScriptName($0) as String).hasPrefix("Malayalam") }
            ?? CTFontCreateWithName(fontNames[0] as CFString, 200, nil)
        let attr = NSAttributedString(string: text, attributes: [kCTFontAttributeName as NSAttributedString.Key: font])
        let ctLine = CTLineCreateWithAttributedString(attr)
        let glyphPath = CGMutablePath()
        for run in CTLineGetGlyphRuns(ctLine) as! [CTRun] {
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            let attrs = CTRunGetAttributes(run) as NSDictionary
            let runFont = attrs[kCTFontAttributeName].map { $0 as! CTFont } ?? font
            for i in 0..<count {
                if let p = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                    glyphPath.addPath(p, transform: CGAffineTransform(translationX: positions[i].x, y: positions[i].y))
                }
            }
        }
        let bounds = glyphPath.boundingBoxOfPath
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let units = min(letterHeight / bounds.height, maxWidth / bounds.width)
        let designWidth = max(100, (bounds.width * units + 24).rounded())
        grid = Int(designWidth * pixelsPerUnit)
        let n = grid
        let k = units * pixelsPerUnit
        let w = bounds.width * k, h = bounds.height * k
        // Centre in the designWidth × 100 area. Bitmap rows run top-down while CG
        // draws y-up, so the vertical offset is measured from the bitmap's bottom.
        let ox = (CGFloat(n) - w) / 2
        let oy = CGFloat(n) - (100 * pixelsPerUnit + h) / 2
        var t = CGAffineTransform(translationX: ox, y: oy).scaledBy(x: k, y: k)
            .translatedBy(x: -bounds.minX, y: -bounds.minY)
        guard let scaled = glyphPath.copy(using: &t) else { return nil }

        var data = [UInt8](repeating: 0, count: n * n)
        let ok: Bool = data.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: n, height: n, bitsPerComponent: 8,
                                      bytesPerRow: n, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.addPath(scaled)
            ctx.fillPath()
            return true
        }
        guard ok else { return nil }
        return (data.map { $0 >= 128 }, designWidth)
    }

    // MARK: Thinning (Zhang–Suen)

    private static func thin(_ src: [Bool]) -> [Bool] {
        let n = grid
        var img = src
        // Clear the border so neighbour lookups never leave the grid.
        for i in 0..<n { img[i] = false; img[(n - 1) * n + i] = false; img[i * n] = false; img[i * n + n - 1] = false }
        var changed = true
        while changed {
            changed = false
            for step in 0..<2 {
                var remove: [Int] = []
                for y in 1..<(n - 1) {
                    for x in 1..<(n - 1) where img[y * n + x] {
                        let p2 = img[(y - 1) * n + x], p3 = img[(y - 1) * n + x + 1]
                        let p4 = img[y * n + x + 1], p5 = img[(y + 1) * n + x + 1]
                        let p6 = img[(y + 1) * n + x], p7 = img[(y + 1) * n + x - 1]
                        let p8 = img[y * n + x - 1], p9 = img[(y - 1) * n + x - 1]
                        let ring = [p2, p3, p4, p5, p6, p7, p8, p9]
                        let b = ring.filter { $0 }.count
                        guard b >= 2, b <= 6 else { continue }
                        var a = 0
                        for i in 0..<8 where !ring[i] && ring[(i + 1) % 8] { a += 1 }
                        guard a == 1 else { continue }
                        if step == 0 {
                            guard !(p2 && p4 && p6), !(p4 && p6 && p8) else { continue }
                        } else {
                            guard !(p2 && p4 && p8), !(p2 && p6 && p8) else { continue }
                        }
                        remove.append(y * n + x)
                    }
                }
                if !remove.isEmpty { changed = true }
                for i in remove { img[i] = false }
            }
        }
        return img
    }

    // MARK: Skeleton graph

    /// Ring offsets: N, NE, E, SE, S, SW, W, NW.
    private static let ring: [(Int, Int)] = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]

    /// Number of separate branches leaving a pixel (8-connected groups among its neighbours).
    private static func branches(_ img: [Bool], _ x: Int, _ y: Int) -> Int {
        let n = grid
        let on = ring.map { img[(y + $0.1) * n + x + $0.0] }
        var parent = Array(0..<8)
        func find(_ i: Int) -> Int { var i = i; while parent[i] != i { i = parent[i] }; return i }
        for i in 0..<8 where on[i] {
            for j in (i + 1)..<8 where on[j] {
                let (ax, ay) = ring[i], (bx, by) = ring[j]
                if max(abs(ax - bx), abs(ay - by)) == 1 { parent[find(j)] = find(i) }
            }
        }
        return Set((0..<8).filter { on[$0] }.map(find)).count
    }

    /// Remove corner pixels of diagonal staircases so lines are strictly one pixel wide.
    private static func cleanStaircases(_ img: inout [Bool]) {
        let n = grid
        for y in 1..<(n - 1) {
            for x in 1..<(n - 1) where img[y * n + x] {
                let count = ring.filter { img[(y + $0.1) * n + x + $0.0] }.count
                if count >= 2, branches(img, x, y) == 1 { img[y * n + x] = false }
            }
        }
    }

    private struct Px: Hashable { let x: Int; let y: Int }

    private struct Edge {
        var a: Int   // node id at start
        var b: Int   // node id at end
        var pts: [Px]
    }

    private static func trace(_ img: [Bool]) -> [[Px]] {
        let n = grid
        func on(_ p: Px) -> Bool { img[p.y * n + p.x] }
        func nbrs(_ p: Px) -> [Px] {
            ring.map { Px(x: p.x + $0.0, y: p.y + $0.1) }.filter(on)
        }

        // Classify pixels. Nodes are endpoints (1 branch) or junctions (3+), clustered.
        var nodeOf: [Px: Int] = [:]
        var nodeDegree: [Int] = []
        var junctionPx: [Px] = []
        for y in 1..<(n - 1) {
            for x in 1..<(n - 1) where img[y * n + x] {
                let p = Px(x: x, y: y)
                let br = branches(img, x, y)
                if br == 1 || nbrs(p).count == 1 {
                    nodeOf[p] = nodeDegree.count
                    nodeDegree.append(1)
                } else if br >= 3 {
                    junctionPx.append(p)
                }
            }
        }
        var clusters: [Int: Set<Px>] = [:]
        var junctionSet = Set(junctionPx)
        while let seed = junctionSet.min(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            let id = nodeDegree.count
            nodeDegree.append(3)
            var stack = [seed]
            junctionSet.remove(seed)
            while let p = stack.popLast() {
                nodeOf[p] = id
                clusters[id, default: []].insert(p)
                for q in nbrs(p) where junctionSet.contains(q) {
                    junctionSet.remove(q); stack.append(q)
                }
            }
        }

        // Walk edges between nodes.
        var visited = Set<Px>()
        var edges: [Edge] = []
        let nodePixels = nodeOf.keys.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        for start in nodePixels {
            let id = nodeOf[start]!
            for q in nbrs(start) {
                if let qid = nodeOf[q] {
                    if qid != id, id < qid { edges.append(Edge(a: id, b: qid, pts: [start, q])) }
                    continue
                }
                guard !visited.contains(q) else { continue }
                var path = [start, q]
                visited.insert(q)
                var prev = start, cur = q
                var endNode: Int?
                while true {
                    let next = nbrs(cur).filter { $0 != prev && !(path.count < 3 && $0 == start) }
                    if let nodePx = next.first(where: { nodeOf[$0] != nil && !(nodeOf[$0] == id && path.count < 4) }) {
                        path.append(nodePx); endNode = nodeOf[nodePx]; break
                    }
                    guard let step = next.first(where: { !visited.contains($0) && nodeOf[$0] == nil }) else { break }
                    visited.insert(step); path.append(step)
                    prev = cur; cur = step
                }
                if endNode == nil {
                    endNode = nodeDegree.count
                    nodeDegree.append(1)
                }
                edges.append(Edge(a: id, b: endNode!, pts: path))
            }
        }
        // Closed loops with no nodes on them.
        for y in 1..<(n - 1) {
            for x in 1..<(n - 1) where img[y * n + x] {
                let p = Px(x: x, y: y)
                guard nodeOf[p] == nil, !visited.contains(p) else { continue }
                var path = [p]; visited.insert(p)
                var cur = p
                while let step = nbrs(cur).first(where: { !visited.contains($0) && nodeOf[$0] == nil }) {
                    visited.insert(step); path.append(step); cur = step
                }
                let id = nodeDegree.count
                if path.count > 2, max(abs(cur.x - p.x), abs(cur.y - p.y)) <= 1 {
                    path.append(p)
                    nodeDegree.append(2)
                    edges.append(Edge(a: id, b: id, pts: path))
                } else {
                    nodeDegree.append(1); nodeDegree.append(1)
                    edges.append(Edge(a: id, b: id + 1, pts: path))
                }
            }
        }

        // Prune short spurs (endpoint → junction) left by thinning at corners.
        let spur = grid / 14
        for _ in 0..<2 {
            var degree = [Int](repeating: 0, count: nodeDegree.count)
            for e in edges { degree[e.a] += 1; degree[e.b] += 1 }
            edges.removeAll { e in
                let tip = degree[e.a] == 1 || degree[e.b] == 1
                let joined = degree[e.a] >= 3 || degree[e.b] >= 3
                return tip && joined && e.pts.count < spur
            }
        }
        edges.removeAll { $0.pts.count < 3 && $0.a == $0.b }

        return chain(edges, nodes: nodeDegree.count) { node, a, b in
            bridge(from: a, to: b, within: clusters[node] ?? [])
        }
    }

    /// Join edges into long strokes, continuing straight through junctions.
    /// Shortest pixel path between two pixels of the same junction cluster.
    private static func bridge(from a: Px, to b: Px, within cluster: Set<Px>) -> [Px] {
        guard a != b else { return [] }
        var cameFrom: [Px: Px] = [a: a]
        var queue = [a], head = 0
        while head < queue.count {
            let p = queue[head]; head += 1
            if p == b { break }
            for (dx, dy) in ring {
                let q = Px(x: p.x + dx, y: p.y + dy)
                guard cluster.contains(q), cameFrom[q] == nil else { continue }
                cameFrom[q] = p; queue.append(q)
            }
        }
        guard cameFrom[b] != nil else { return [] }
        var path: [Px] = []
        var p = b
        while p != a { path.append(p); p = cameFrom[p]! }
        return path.reversed().dropLast()
    }

    private static func chain(_ edges: [Edge], nodes: Int,
                              bridge: (Int, Px, Px) -> [Px]) -> [[Px]] {
        var used = [Bool](repeating: false, count: edges.count)
        var byNode = [[Int]](repeating: [], count: nodes)
        for (i, e) in edges.enumerated() { byNode[e.a].append(i); byNode[e.b].append(i) }
        func degree(_ node: Int) -> Int { byNode[node].count }

        func direction(_ pts: [Px], fromEnd: Bool) -> CGVector {
            let k = min(pts.count - 1, grid / 20)
            guard k > 0 else { return .zero }
            let (a, b) = fromEnd ? (pts[pts.count - 1 - k], pts[pts.count - 1]) : (pts[0], pts[k])
            let v = CGVector(dx: b.x - a.x, dy: b.y - a.y)
            let len = hypot(v.dx, v.dy)
            return len > 0 ? CGVector(dx: v.dx / len, dy: v.dy / len) : .zero
        }
        func oriented(_ i: Int, from node: Int) -> [Px] {
            edges[i].a == node ? edges[i].pts : edges[i].pts.reversed()
        }
        func otherEnd(_ i: Int, from node: Int) -> Int { edges[i].a == node ? edges[i].b : edges[i].a }

        var strokes: [[Px]] = []
        while used.contains(false) {
            // Start from the left-most free end (an endpoint if there is one).
            var best: (edge: Int, node: Int, score: CGFloat)?
            for (i, e) in edges.enumerated() where !used[i] {
                for (node, p) in [(e.a, e.pts.first!), (e.b, e.pts.last!)] {
                    let tipBonus: CGFloat = degree(node) == 1 ? 0 : CGFloat(grid)
                    let score = tipBonus + CGFloat(p.x) + CGFloat(p.y) * 0.25
                    if best == nil || score < best!.score { best = (i, node, score) }
                }
            }
            guard let start = best else { break }
            used[start.edge] = true
            var stroke = oriented(start.edge, from: start.node)
            var node = otherEnd(start.edge, from: start.node)
            while degree(node) >= 3 {
                let incoming = direction(stroke, fromEnd: true)
                var pick: (Int, CGFloat)?
                for i in byNode[node] where !used[i] {
                    let out = direction(oriented(i, from: node), fromEnd: false)
                    let dot = incoming.dx * out.dx + incoming.dy * out.dy
                    if pick == nil || dot > pick!.1 { pick = (i, dot) }
                }
                guard let (next, dot) = pick, dot > cos(.pi * 75 / 180) else { break }
                used[next] = true
                let piece = oriented(next, from: node)
                stroke += bridge(node, stroke.last!, piece.first!)
                stroke += piece
                node = otherEnd(next, from: node)
            }
            strokes.append(stroke)
        }
        return strokes
    }

    // MARK: Direction and order

    /// Malayalam is written left to right: begin each open stroke at its left end.
    private static func orientLeftToRight(_ pts: [CGPoint]) -> [CGPoint] {
        guard let a = pts.first, let b = pts.last, a.distance(to: b) > 3 else { return pts }
        return b.x + b.y * 0.25 < a.x + a.y * 0.25 ? pts.reversed() : pts
    }

    private static func writingOrder(_ pts: [CGPoint]) -> CGFloat {
        guard let a = pts.first else { return 0 }
        return a.x + a.y * 0.25
    }

    // MARK: Polyline clean-up

    private static func smooth(_ pts: [Px]) -> [CGPoint] {
        let p = pts.map { CGPoint(x: $0.x, y: $0.y) }
        guard p.count > 4 else { return p }
        let closed = pts.first == pts.last
        let r = 2
        return p.indices.map { i in
            if !closed, i < r || i >= p.count - r { return p[i] }
            var sx: CGFloat = 0, sy: CGFloat = 0
            for d in -r...r {
                var j = i + d
                if closed { j = (j + p.count - 1) % (p.count - 1) }
                sx += p[j].x; sy += p[j].y
            }
            return CGPoint(x: sx / CGFloat(2 * r + 1), y: sy / CGFloat(2 * r + 1))
        }
    }

    private static func simplify(_ pts: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard pts.count > 2 else { return pts }
        let a = pts.first!, b = pts.last!
        var maxD: CGFloat = 0, idx = 0
        for i in 1..<(pts.count - 1) {
            let d = perpendicular(pts[i], a, b)
            if d > maxD { maxD = d; idx = i }
        }
        if maxD > epsilon {
            let left = simplify(Array(pts[...idx]), epsilon: epsilon)
            let right = simplify(Array(pts[idx...]), epsilon: epsilon)
            return left.dropLast() + right
        }
        return [a, b]
    }

    private static func perpendicular(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = hypot(dx, dy)
        guard len > 0 else { return p.distance(to: a) }
        return abs(dy * p.x - dx * p.y + b.x * a.y - b.y * a.x) / len
    }

    private static func length(_ pts: [CGPoint]) -> CGFloat {
        zip(pts, pts.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) }
    }
}
