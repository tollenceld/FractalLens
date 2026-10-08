import Foundation
import CoreGraphics

struct Vector: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
    static let zero = Vector(x: 0, y: 0)
    var cg: CGPoint { CGPoint(x: x, y: y) }
    var length: Double { hypot(x, y) }
    static func + (a: Self, b: Self) -> Self { .init(x: a.x+b.x, y: a.y+b.y) }
    static func - (a: Self, b: Self) -> Self { .init(x: a.x-b.x, y: a.y-b.y) }
    static func * (a: Self, s: Double) -> Self { .init(x: a.x*s, y: a.y*s) }
    func rotated(_ angle: Double) -> Self { .init(x: x*cos(angle)-y*sin(angle), y: x*sin(angle)+y*cos(angle)) }
    func distance(to other: Self) -> Double { (self-other).length }
    static func lerp(_ a: Self, _ b: Self, _ t: Double) -> Self { a+(b-a)*t }
}

struct Branch: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var parent: Int?
    var depth: Int
    var points: [Vector]
    var birth:Double? = nil
    var duration:Double? = nil
    var length: Double { zip(points, points.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) } }
    var start: Vector { points.first ?? .zero }
    var end: Vector { points.last ?? .zero }
    var direction: Vector { end-start }
    func point(at fraction: Double) -> Vector {
        guard points.count > 1 else { return start }
        let target = length * min(1,max(0,fraction))
        var passed = 0.0
        for (a,b) in zip(points, points.dropFirst()) {
            let d = a.distance(to: b)
            if passed+d >= target { return .lerp(a,b,d > 0 ? (target-passed)/d : 0) }
            passed += d
        }
        return end
    }
    func fraction(nearest p: Vector) -> Double {
        var best=Double.greatestFiniteMagnitude, result=0.0, traveled=0.0
        let total=length
        for (a,b) in zip(points,points.dropFirst()) {
            let d=b-a,den=d.x*d.x+d.y*d.y
            let local=den>0 ? min(1,max(0,((p.x-a.x)*d.x+(p.y-a.y)*d.y)/den)):0
            let distance=(a+d*local).distance(to:p)
            if distance<best { best=distance;result=(traveled+d.length*local)/max(0.000001,total) }
            traveled += d.length
        }
        return result
    }
}

struct StructureGraph: Codable, Hashable, Sendable {
    var branches: [Branch]
    var aspectRatio: Double = 1
    var rootID: Int { branches.first(where: { $0.parent == nil })?.id ?? 0 }
    var depth: Int { (branches.map(\.depth).max() ?? 0)+1 }
    var allPoints: [Vector] { branches.flatMap(\.points) }
    func subtree(_ id: Int) -> StructureGraph {
        var found: Set<Int> = [id]
        var changed = true
        while changed {
            changed = false
            for b in branches where b.parent.map({ found.contains($0) }) == true && !found.contains(b.id) {
                found.insert(b.id); changed = true
            }
        }
        return .init(branches: branches.filter { found.contains($0.id) }, aspectRatio: aspectRatio)
    }
    var bounds: CGRect {
        let points = allPoints
        guard let p = points.first else { return CGRect(x:0,y:0,width:1,height:1) }
        let minX = points.map(\.x).min() ?? p.x, maxX = points.map(\.x).max() ?? p.x
        let minY = points.map(\.y).min() ?? p.y, maxY = points.map(\.y).max() ?? p.y
        return CGRect(x:minX,y:minY,width:max(0.001,maxX-minX),height:max(0.001,maxY-minY))
    }
    // Similarity transform only: translate to the root, rotate axis upward, scale uniformly.
    func normalized(root id: Int? = nil) -> StructureGraph {
        let root = branches.first(where: { $0.id == (id ?? rootID) }) ?? branches.first
        guard let root else { return self }
        let angle = -.pi/2 - atan2(root.direction.y, root.direction.x * aspectRatio)
        let shifted = branches.map { b -> Branch in
            var c=b; c.points=b.points.map { p in let d=p-root.start; return Vector(x:d.x*aspectRatio,y:d.y).rotated(angle) }; return c
        }
        let temp = StructureGraph(branches:shifted)
        let bounds = temp.bounds
        let scale = min(0.43 / max(abs(bounds.minX),abs(bounds.maxX),0.001), 0.78 / max(abs(bounds.minY),abs(bounds.maxY),0.001))
        return .init(branches: shifted.map { b in
            var c=b; c.points=b.points.map { .init(x:0.5+$0.x*scale,y:0.88+$0.y*scale) }; return c
        })
    }
    func fitted() -> StructureGraph {
        let bounds=bounds
        let width=bounds.width*aspectRatio,height=bounds.height
        let scale=0.82/max(width,height,0.001)
        var copy=self
        copy.branches=branches.map { b in var c=b;c.points=b.points.map { p in Vector(x:0.5+(p.x-bounds.midX)*aspectRatio*scale,y:0.5+(p.y-bounds.midY)*scale) };return c }
        copy.aspectRatio=1
        return copy
    }
    func sampled(countPerBranch: Int = 8) -> [Vector] {
        branches.flatMap { b in (0...countPerBranch).map { b.point(at:Double($0)/Double(countPerBranch)) } }
    }
}

enum CaptureOrigin: String, Codable, Sendable { case example, camera, imported, guided }
struct CaptureSource: Codable, Hashable, Sendable {
    var imageName: String
    var origin: CaptureOrigin
    var date: Date
    var attribution: String?
}
struct GrowthRuleSet: Codable, Hashable, Sendable {
    var angle: Double
    var scale: Double
    var depth: Int
    var seed: UInt64
}
struct StructuralMetrics: Codable, Hashable, Sendable {
    var similarity: Double?
    var angle: Double
    var scale: Double
    var depth: Int
    var density: Double
    var complexity: Double
}
struct AnalysisResult: Codable, Hashable, Sendable {
    var graph: StructureGraph
    var scaleRoots: [Int]
    var metrics: StructuralMetrics
    var rules: GrowthRuleSet
    var confidence: Double
    var version = 2
    var evidence: ObservationEvidence? = nil
}
struct Specimen: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var plantID: UUID
    var title: String
    var subtitle: String
    var source: CaptureSource
    var analysis: AnalysisResult
    var savedAt: Date?
    var exampleKey: String?
    var isExample: Bool { source.origin == .example }
    var glyph: StructureGraph { analysis.evidence?.comparesScales == false ? analysis.graph.fitted():analysis.graph.normalized() }
}

enum Metric: String, CaseIterable, Identifiable {
    case similarity = "Self similarity", angle = "Branch angle", scale = "Scale ratio", depth = "Recursive depth", density = "Density", complexity = "Complexity"
    var id: Self { self }
    var explanation: String {
        switch self {
        case .similarity: return "The branch resembles the whole."
        case .angle: return "A direction, repeated at each fork."
        case .scale: return "Each new branch carries a smaller rhythm."
        case .depth: return "One structure, nested inside another."
        case .density: return "Structure fills the space between lines."
        case .complexity: return "Simple divisions build a rich whole."
        }
    }
    func value(_ m: StructuralMetrics) -> String {
        switch self {
        case .similarity: return m.similarity.map { "\(Int($0.rounded()))%" } ?? "—"
        case .angle: return "\(Int(m.angle.rounded()))°"
        case .scale: return String(format:"%.2f",m.scale)
        case .depth: return String(m.depth)
        case .density: return String(format:"%.0f%%",m.density*100)
        case .complexity: return String(format:"%.2f",m.complexity)
        }
    }
}
