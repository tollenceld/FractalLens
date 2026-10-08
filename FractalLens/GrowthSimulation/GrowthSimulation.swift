import Foundation

struct GrowthSimulation {
    // Preserve measured attachment positions and local curvature while re-running rules.
    static func generate(from source: StructureGraph, baseline: GrowthRuleSet, rules: GrowthRuleSet) -> StructureGraph {
        if rules == baseline { return source }
        var output=[Branch](), lookup=[Int:Branch]()
        let aspect=source.aspectRatio
        func physical(_ v:Vector)->Vector { .init(x:v.x*aspect,y:v.y) }
        func imageVector(_ v:Vector)->Vector { .init(x:v.x/aspect,y:v.y) }
        let original=Dictionary(uniqueKeysWithValues:source.branches.map { ($0.id,$0) })
        let angleDelta=(rules.angle-baseline.angle) * .pi/180
        let ratio=rules.scale / max(0.02,baseline.scale)
        for branch in source.branches.sorted(by:{ $0.depth == $1.depth ? $0.id < $1.id : $0.depth < $1.depth }) where branch.depth < rules.depth {
            var result=branch
            if let parentID=branch.parent, let parent=lookup[parentID],let oldParent=original[parentID] {
                let attachment=oldParent.fraction(nearest:branch.start)
                let anchor=parent.point(at:attachment)
                let parentRotation=atan2(parent.direction.y,parent.direction.x*aspect)-atan2(oldParent.direction.y,oldParent.direction.x*aspect)
                let cross=oldParent.direction.x*branch.direction.y-oldParent.direction.y*branch.direction.x
                let rotation=parentRotation+angleDelta*(cross >= 0 ? 1 : -1)
                let multiplier=pow(ratio,Double(branch.depth))
                result.points=branch.points.map { anchor+imageVector(physical($0-branch.start).rotated(rotation)*multiplier) }
            }
            output.append(result); lookup[result.id]=result
        }
        // Additional generations repeat the last measured branching rule, bounded for rendering.
        if rules.depth > source.depth {
            var frontier=output.filter { b in !output.contains(where:{ $0.parent==b.id }) }
            var nextID=(output.map(\.id).max() ?? 0)+1
            for level in source.depth..<min(8,rules.depth) {
                var next=[Branch]()
                for parent in frontier where output.count+next.count < 1800 {
                    for side in [-1.0,1.0] {
                        let direction=imageVector(physical(parent.direction).rotated(side*rules.angle * .pi/180)*rules.scale)
                        let end=parent.end+direction
                        let mid=Vector.lerp(parent.end,end,0.5)+Vector(x:direction.y,y:-direction.x)*0.035
                        let b=Branch(id:nextID,parent:parent.id,depth:level,points:[parent.end,mid,end])
                        nextID += 1; next.append(b)
                    }
                }
                output += next; frontier=next
            }
        }
        return StructureGraph(branches:output,aspectRatio:source.aspectRatio)
    }
    static func scheduled(_ graph:StructureGraph)->StructureGraph {
        var result=graph, timings=[Int:(Double,Double)]()
        let lookup=Dictionary(uniqueKeysWithValues:graph.branches.map { ($0.id,$0) })
        for branch in graph.branches.sorted(by:{ $0.depth < $1.depth }) {
            var start=0.0
            let duration=0.52/pow(1.5,Double(branch.depth))
            if let id=branch.parent,let parent=lookup[id],let timing=timings[id] {
                let attachment=parent.fraction(nearest:branch.start)
                let arrival=1-pow(1-attachment,1/2.4)
                start=timing.0+timing.1*arrival+0.025
            }
            timings[branch.id]=(start,duration)
        }
        let end=timings.values.map { $0.0+$0.1 }.max() ?? 1
        for i in result.branches.indices {
            if let t=timings[result.branches[i].id] { result.branches[i].birth=t.0/end;result.branches[i].duration=t.1/end }
        }
        return result
    }
    static func branchProgress(_ branch:Branch, graph:StructureGraph, progress:Double) -> Double {
        if progress >= 1 { return 1 }
        let start=branch.birth ?? Double(branch.depth)/Double(max(1,graph.depth))*0.68
        let duration=branch.duration ?? (1-start)
        let t=max(0,min(1,(progress-start)/max(0.0001,duration)))
        return 1-pow(1-t,2.4)
    }
}
