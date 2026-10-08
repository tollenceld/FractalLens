import SwiftUI

struct WorldStudy:Identifiable,Hashable {
    let id:String
    let name:String
    let family:WorldFamily
    let place:String
    let insight:String
    let question:String
    let kind:EvidenceKind
    var graph:StructureGraph { WorldGeometry.make(id) }
    var relatedRule:String { switch family { case .branching:return "tree";case .boundaries:return "snow";case .spirals:return "levy";case .repetition:return "tiles" } }
    func specimen() -> Specimen {
        let graph=graph
        var analysis=StructuralAnalysis.evaluate(graph,confidence:1)
        if kind != .nested { analysis.scaleRoots=[];analysis.metrics.similarity=nil }
        analysis.evidence = .init(family:family,kind:kind,repetition:kind == .repeated ? SceneGeometry.repetition(in:graph):nil,keyPoints:Array(graph.branches.map(\.start).prefix(24)),note:insight,algorithm:"Illustrated geometry v1")
        return Specimen(id:UUID(),plantID:UUID(),title:name,subtitle:"A guided study",source:.init(imageName:"",origin:.guided,date:Date(),attribution:"Original procedural illustration · Fractal Lens"),analysis:analysis)
    }
    @MainActor func image() -> UIImage {
        let size=CGSize(width:900,height:900)
        let format=UIGraphicsImageRendererFormat();format.scale=1
        return UIGraphicsImageRenderer(size:size,format:format).image { renderer in
            let c=renderer.cgContext
            UIColor(LensStyle.background).setFill();c.fill(CGRect(origin:.zero,size:size))
            c.setStrokeColor(UIColor(family.color).cgColor);c.setLineCap(.round);c.setLineJoin(.round)
            for b in graph.branches {
                c.setLineWidth(max(1.4,4-Double(b.depth)*0.55));c.beginPath()
                for (i,p) in b.points.enumerated() { let point=CGPoint(x:p.x*900,y:p.y*900);if i==0 { c.move(to:point) } else { c.addLine(to:point) } }
                c.strokePath()
            }
        }
    }
}
enum WorldLibrary {
    static let all:[WorldStudy]=[
        .init(id:"river",name:"River networks",family:.branching,place:"From above · Water",insight:"Tributaries meet larger channels. Small networks can resemble the drainage basin they belong to.",question:"Does this tributary echo the whole?",kind:.nested),
        .init(id:"lightning",name:"A path through the sky",family:.branching,place:"In the sky · Energy",insight:"A discharge divides into smaller paths. The shape is a branching study, not a prediction of a storm.",question:"Where does one path become many?",kind:.nested),
        .init(id:"coast",name:"The restless coastline",family:.boundaries,place:"At the water’s edge",insight:"An irregular boundary reveals new turns as you look closer. This illustration invites a scale comparison; a single contour cannot establish a fractal dimension.",question:"What does a smaller edge reveal?",kind:.outline),
        .init(id:"cracks",name:"Cracks in the ground",family:.boundaries,place:"Under your feet · Earth",insight:"A surface divides into irregular regions. Trace a junction and notice how the surrounding edges connect.",question:"How does this surface divide?",kind:.outline),
        .init(id:"shell",name:"A spiral in a shell",family:.spirals,place:"By the shore · Form",insight:"A spiral turns while its distance from the centre increases. This growth rhythm is beautiful, but a spiral is not automatically a fractal.",question:"What changes with every turn?",kind:.winding),
        .init(id:"curl",name:"A curl unfolding",family:.spirals,place:"In a garden · Motion",insight:"A curling form carries a direction through space. Look for the turning rhythm before looking for self-similarity.",question:"Can you follow its turning rhythm?",kind:.winding),
        .init(id:"windows",name:"Windows within the city",family:.repetition,place:"On your street · Architecture",insight:"One shape returns in a grid. Repetition at one size is a pattern; smaller copies within larger ones would add evidence of self-similarity.",question:"Does it repeat, or repeat at smaller scales?",kind:.repeated),
        .init(id:"woven",name:"The rhythm of a weave",family:.repetition,place:"Close at hand · Texture",insight:"Interlaced lines create a repeating surface. Follow a repeated unit and compare its shape with a neighbour.",question:"What is the smallest repeating gesture?",kind:.repeated)
    ]
    static func study(_ id:String)->WorldStudy { all.first { $0.id==id } ?? all[0] }
}
enum WorldGeometry {
    private static let graphs: [String:StructureGraph] = Dictionary(uniqueKeysWithValues:["river","lightning","coast","cracks","shell","curl","windows","woven"].map { ($0,build($0)) })
    static func make(_ id:String)->StructureGraph { graphs[id] ?? graphs["river"]! }
    private static func build(_ id:String)->StructureGraph {
        var branches=[Branch]()
        func add(_ points:[Vector],parent:Int?=nil,depth:Int=0)->Int { let index=branches.count;branches.append(.init(id:index,parent:parent,depth:depth,points:points));return index }
        func fork(start:Vector,direction:Vector,parent:Int?,depth:Int,maximum:Int) {
            let end=start+direction
            let index=add([start,Vector.lerp(start,end,0.45)+Vector(x:sin(Double(branches.count))*0.008,y:0),end],parent:parent,depth:depth)
            guard depth<maximum else { return }
            for (n,f) in [0.45,0.72].enumerated() {
                let turn=(n==0 ? -1.0:1.0)*(id=="lightning" ? 0.60:0.72)
                fork(start:Vector.lerp(start,end,f),direction:direction.rotated(turn)*(id=="lightning" ? 0.54:0.57),parent:index,depth:depth+1,maximum:maximum)
            }
        }
        switch id {
        case "river":fork(start:.init(x:0.50,y:0.9),direction:.init(x:0,y:-0.61),parent:nil,depth:0,maximum:4)
        case "lightning":fork(start:.init(x:0.48,y:0.12),direction:.init(x:0.06,y:0.53),parent:nil,depth:0,maximum:4)
        case "coast":
            var points=[Vector(x:0.12,y:0.12),Vector(x:0.30,y:0.42),Vector(x:0.61,y:0.58),Vector(x:0.85,y:0.88)]
            for level in 0..<5 {
                var next=[Vector]()
                for (i,pair) in zip(points,points.dropFirst()).enumerated() {
                    next.append(pair.0)
                    let d=pair.1-pair.0
                    let bend=sin(Double(i*7+level*13)+0.7)*0.44
                    next.append((pair.0+pair.1)*0.5+Vector(x:-d.y,y:d.x)*bend)
                }
                next.append(points.last!);points=next
            }
            _=add(points)
        case "shell","curl":
            let center=Vector(x:0.48,y:0.51)
            let turns=id=="shell" ? 3.2:1.8
            let count=360
            let points=(0...count).map { n -> Vector in
                let t=Double(n)/Double(count),angle=t*turns*2*Double.pi
                let radius=0.025*exp(t*2.75)
                return center+Vector(x:cos(angle),y:sin(angle))*radius
            }
            _=add(points)
            if id=="shell" { for i in stride(from:150,to:360,by:10) { let a=points[i],b=points[max(0,i-Int(Double(count)/turns))];_=add([b,Vector.lerp(b,a,0.5)+Vector(x:0.012,y:-0.01),a]) } }
        case "windows":
            for row in 0..<5 { for col in 0..<4 {
                let x=0.19+Double(col)*0.16,y=0.12+Double(row)*0.155
                _=add([.init(x:x,y:y),.init(x:x+0.10,y:y),.init(x:x+0.10,y:y+0.105),.init(x:x,y:y+0.105),.init(x:x,y:y)])
            } }
        case "woven":
            for n in 0..<10 {
                let a=0.14+Double(n)*0.075
                _=add((0...100).map { i in let t=Double(i)/100;return .init(x:0.12+t*0.76,y:a+sin(t*Double.pi*20)*0.013) })
                _=add((0...100).map { i in let t=Double(i)/100;return .init(x:a+sin(t*Double.pi*20)*0.013,y:0.12+t*0.76) })
            }
        default:
            let points=[Vector(x:0.16,y:0.18),.init(x:0.48,y:0.12),.init(x:0.78,y:0.24),.init(x:0.87,y:0.52),.init(x:0.74,y:0.82),.init(x:0.38,y:0.9),.init(x:0.12,y:0.66)]
            let center=Vector(x:0.48,y:0.48)
            for (i,p) in points.enumerated() {
                _=add([center+Vector(x:sin(Double(i))*0.035,y:cos(Double(i))*0.028),p])
                _=add([p,points[(i+1)%points.count]])
                let q=Vector.lerp(center,p,0.65)
                _=add([q,Vector.lerp(p,points[(i+1)%points.count],0.5)])
            }
        }
        return GrowthSimulation.scheduled(.init(branches:branches))
    }
}
