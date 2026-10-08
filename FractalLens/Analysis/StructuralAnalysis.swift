import Foundation

struct StructuralAnalysis {
    static func evaluate(_ input: StructureGraph, confidence: Double = 1) -> AnalysisResult {
        let graph=GrowthSimulation.scheduled(input)
        let physical = graph.normalized()
        let lookup = Dictionary(uniqueKeysWithValues:physical.branches.map { ($0.id,$0) })
        let pairs = physical.branches.compactMap { b -> (Branch,Branch)? in
            guard let id=b.parent, let parent=lookup[id] else { return nil }; return (b,parent)
        }
        let angles = pairs.map { child,parent in
            let a=atan2(child.direction.y,child.direction.x)-atan2(parent.direction.y,parent.direction.x)
            return abs(atan2(sin(a),cos(a)))*180 / .pi
        }
        let ratios = pairs.filter { $0.1.length > 0.001 }.map { $0.0.length/$0.1.length }.filter { $0 > 0.03 && $0 < 1 }
        func median(_ values:[Double], fallback:Double) -> Double {
            let sorted=values.sorted(); return sorted.isEmpty ? fallback : sorted[sorted.count/2]
        }
        var roots = [graph.rootID]
        var current = graph.rootID
        for _ in 0..<2 {
            let children=graph.branches.filter { $0.parent==current && graph.subtree($0.id).branches.count > 2 }
            guard let best=children.max(by:{ graph.subtree($0.id).branches.count < graph.subtree($1.id).branches.count }) else { break }
            roots.append(best.id); current=best.id
        }
        var scores=[Double]()
        for (a,b) in zip(roots,roots.dropFirst()) {
            scores.append(similarity(graph.subtree(a).normalized(root:a),graph.subtree(b).normalized(root:b)))
        }
        let bounds=graph.bounds
        let cells=Set(graph.sampled(countPerBranch:16).map { p in "\(Int((p.x-bounds.minX)/bounds.width*24)),\(Int((p.y-bounds.minY)/bounds.height*24))" })
        let density=min(1,Double(cells.count)/(25*25))
        let metrics=StructuralMetrics(similarity:scores.isEmpty ? nil : scores.reduce(0,+)/Double(scores.count),angle:median(angles,fallback:35),scale:median(ratios,fallback:0.5),depth:graph.depth,density:density,complexity:log2(Double(graph.branches.count)+1))
        // Hash coordinates, rather than process-randomized Swift Hasher.
        var seed:UInt64=1469598103934665603
        for p in graph.allPoints { for v in [p.x,p.y] { seed = (seed ^ UInt64(max(0,v+10)*100000)) &* 1099511628211 } }
        return AnalysisResult(graph:graph,scaleRoots:roots,metrics:metrics,rules:.init(angle:metrics.angle,scale:metrics.scale,depth:metrics.depth,seed:seed),confidence:confidence)
    }
    static func similarity(_ a: StructureGraph, _ b: StructureGraph) -> Double {
        let aa=a.sampled(countPerBranch:6), bb=b.sampled(countPerBranch:6)
        guard !aa.isEmpty && !bb.isEmpty else { return 0 }
        func distance(_ x:[Vector], _ y:[Vector]) -> Double { x.reduce(0) { sum,p in sum + (y.map { p.distance(to:$0) }.min() ?? 1) } / Double(x.count) }
        let chamfer=(distance(aa,bb)+distance(bb,aa))/2
        func branching(_ g:StructureGraph) -> Double {
            let parents=Set(g.branches.compactMap(\.parent)); return Double(g.branches.count-1)/Double(max(1,parents.count))
        }
        let topology=abs(log(max(1,branching(a))/max(1,branching(b))))
        return min(100,max(0,100 * exp(-6*chamfer-0.12*topology)))
    }
}
