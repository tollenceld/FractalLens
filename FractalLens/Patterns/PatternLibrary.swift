import SwiftUI

enum PatternFamily:String,CaseIterable,Identifiable {
    case branching="Branching",edges="Repeating edges",folding="Folding curves",nested="Nested forms"
    var id:String { rawValue }
    var verb:String {
        switch self { case .branching:return "Divide & grow";case .edges:return "Replace & repeat";case .folding:return "Turn & unfold";case .nested:return "Nest & echo" }
    }
    var subtitle:String {
        switch self { case .branching:return "One branch becomes a world.";case .edges:return "A small gesture reshapes every edge.";case .folding:return "A turn, repeated, finds a new direction.";case .nested:return "A form holds smaller forms within." }
    }
    var symbol:String {
        switch self { case .branching:return "leaf";case .edges:return "snowflake";case .folding:return "point.topleft.down.to.point.bottomright.curvepath";case .nested:return "square.on.square" }
    }
    var color:Color {
        switch self { case .branching:return LensStyle.green;case .edges:return LensStyle.blue;case .folding:return Color(red:0.58,green:0.39,blue:0.72);case .nested:return Color(red:0.80,green:0.43,blue:0.25) }
    }
}

struct RulePattern:Identifiable,Hashable {
    let id:String
    let name:String
    let family:PatternFamily
    let subtitle:String
    let insight:String
    let nature:String
    let axiom:String
    let rules:[Character:String]
    let drawn:Set<Character>
    let moved:Set<Character>
    let angle:Double
    let heading:Double
    let minimum:Int
    let maximum:Int
    let showcase:Int
    var alternatingHeading=false
    var color:Color { family.color }
    static func ==(lhs:Self,rhs:Self)->Bool { lhs.id==rhs.id }
    func hash(into hasher:inout Hasher) { hasher.combine(id) }
}

enum PatternLibrary {
    // Production rules adapted from the user's Stories Of Plant playground.
    // Geometric rule studies are intentionally separate from observed specimens.
    static let all:[RulePattern]=[
        .init(id:"fern",name:"Feathered fern",family:.branching,subtitle:"A branch inside a branch",insight:"The stem extends, then leaves two smaller paths. Each path repeats the same gesture.",nature:"Look for this rhythm in fern fronds and finely divided leaves.",axiom:"F",rules:["F":"F[-F]F[+F][F]"],drawn:["F"],moved:[],angle:25,heading:-90,minimum:0,maximum:5,showcase:4),
        .init(id:"tree",name:"The branching tree",family:.branching,subtitle:"One becomes two",insight:"Every tip divides. Older branches lengthen while the newest branches begin again.",nature:"A simple model for the repeated forks of a winter tree.",axiom:"0",rules:["0":"1[-0]+0","1":"11"],drawn:["0","1"],moved:[],angle:45,heading:-90,minimum:0,maximum:8,showcase:7),
        .init(id:"weed",name:"Wild growth",family:.branching,subtitle:"An asymmetrical rhythm",insight:"The main axis reaches forward. Side branches echo it, each beginning at a different moment.",nature:"Compare the alternating branches of a wild herb or young shrub.",axiom:"X",rules:["F":"FF","X":"F[+X]F[-X]+X"],drawn:["F","X"],moved:[],angle:25,heading:-90,minimum:0,maximum:6,showcase:5),
        .init(id:"frond",name:"The unfolding frond",family:.branching,subtitle:"Growth has a sequence",insight:"A longer sequence of instructions places each pinna along a growing axis. Repetition can have memory.",nature:"The idealised rhythm of a mature, feather-shaped fern.",axiom:"aF",rules:["a":"FFFFFv[+++h][---q]fb","b":"FFFFFv[+++h][---q]fc","c":"FFFFFv[+++fa]fd","d":"FFFFFv[+++h][---q]fe","e":"FFFFFv[+++h][---q]fg","g":"FFFFFv[---fa]fa","h":"ifFF","i":"fFFF[--m]j","j":"fFFF[--n]k","k":"fFFF[--o]l","l":"fFFF[--p]","m":"fFn","n":"fFo","o":"fFp","p":"fF","q":"rfF","r":"fFFF[++m]s","s":"fFFF[++n]t","t":"fFFF[++o]u","u":"fFFF[++p]","v":"Fv"],drawn:["F"],moved:Set("abcdeghijklmnopqrstu v".filter { $0 != " " }),angle:12,heading:-90,minimum:4,maximum:18,showcase:16),
        .init(id:"snow",name:"Koch snowflake",family:.edges,subtitle:"An infinite coastline",insight:"Each straight edge becomes four smaller edges. The outline grows richer without leaving its original world.",nature:"An exact mathematical study, offering a lens for irregular natural boundaries.",axiom:"A--A--A",rules:["A":"A+A--A+A"],drawn:["A"],moved:[],angle:60,heading:0,minimum:0,maximum:5,showcase:4),
        .init(id:"sierpinski",name:"Sierpiński weave",family:.nested,subtitle:"A triangle of triangles",insight:"Two alternating gestures weave a triangle, then three smaller triangles, then three within each.",nature:"A study of repeated spaces and the relationship between part and whole.",axiom:"A",rules:["A":"B-A-B","B":"A+B+A"],drawn:["A","B"],moved:[],angle:60,heading:0,minimum:0,maximum:8,showcase:7,alternatingHeading:true),
        .init(id:"dragon",name:"Dragon variation",family:.folding,subtitle:"Every turn leaves a trace",insight:"Two complementary turns fold a line into a winding form. A 30-degree variation from Stories Of Plant.",nature:"An idealised folding study, rather than a model of a specific plant.",axiom:"FX",rules:["X":"X+YF+","Y":"-FX-Y"],drawn:["F"],moved:[],angle:30,heading:0,minimum:0,maximum:12,showcase:10),
        .init(id:"levy",name:"Lévy curve",family:.folding,subtitle:"The line learns to fold",insight:"A line bends into two equal pieces. Repeated bends reveal a delicate arch of smaller arches.",nature:"Look for echoes of this idea in curling tips and winding growth.",axiom:"F",rules:["F":"-F++F-"],drawn:["F"],moved:[],angle:45,heading:0,minimum:0,maximum:11,showcase:10),
        .init(id:"pentagon",name:"Pentagonal bloom",family:.nested,subtitle:"Five-fold repetition",insight:"A five-sided beginning expands into smaller rotated forms, leaving a lacework of nested spaces.",nature:"Five-fold geometry recalls petals; this is a rule study, not a measured flower.",axiom:"F++F++F++F++F",rules:["F":"F++F++F|F-F++F"],drawn:["F"],moved:[],angle:36,heading:180,minimum:0,maximum:4,showcase:3),
        .init(id:"tiles",name:"Recursive tiles",family:.nested,subtitle:"A rhythm of squares",insight:"Each edge follows a square-shaped detour. Local repetition builds an intricate continuous grid.",nature:"An abstract study of hierarchy and repeating spaces.",axiom:"F+F+F+F",rules:["F":"FF+F+F+F+FF"],drawn:["F"],moved:[],angle:90,heading:0,minimum:0,maximum:4,showcase:3)
    ]
    static func pattern(_ id:String)->RulePattern { all.first { $0.id==id } ?? all[0] }
}

struct PatternSegment:Equatable {
    var from:Vector
    var to:Vector
    var depth:Int
    var distance:Double
}
struct PatternGeometry {
    var segments:[PatternSegment]
    var distance:Double
    var isBranched:Bool
    static let empty=Self(segments:[],distance:0,isBranched:false)
}

enum RuleInterpreter {
    static func word(_ pattern:RulePattern,generation:Int)->String {
        var word=pattern.axiom
        for _ in 0..<max(0,generation) {
            var next="";next.reserveCapacity(min(150_000,word.count*4))
            for letter in word { next.append(pattern.rules[letter] ?? String(letter)) }
            guard next.count<200_000 else { break }
            word=next
        }
        return word
    }
    static func geometry(_ pattern:RulePattern,generation:Int)->PatternGeometry {
        let word=word(pattern,generation:generation)
        var position=Vector(x:0,y:0)
        var heading=(pattern.alternatingHeading && generation%2==1 ? -60:pattern.heading)*Double.pi/180
        var depth=0,distance=0.0
        var stack=[(Vector,Double,Int,Double)]()
        var segments=[PatternSegment]()
        for letter in word {
            if pattern.drawn.contains(letter) || pattern.moved.contains(letter) {
                let next=position+Vector(x:cos(heading),y:sin(heading))
                if pattern.drawn.contains(letter) { segments.append(.init(from:position,to:next,depth:depth,distance:distance));distance += 1 }
                position=next
            } else {
                switch letter {
                case "+":heading += pattern.angle*Double.pi/180
                case "-":heading -= pattern.angle*Double.pi/180
                case "|":heading += Double.pi
                case "[":stack.append((position,heading,depth,distance));depth += 1
                case "]":if let state=stack.popLast() { position=state.0;heading=state.1;depth=state.2;distance=state.3 }
                default:break // Lowercase f is intentionally ignored, as in the supplied playground.
                }
            }
        }
        guard !segments.isEmpty else { return .empty }
        let points=segments.flatMap { [$0.from,$0.to] }
        let minX=points.map(\.x).min()!,maxX=points.map(\.x).max()!,minY=points.map(\.y).min()!,maxY=points.map(\.y).max()!
        let scale=0.82/max(maxX-minX,maxY-minY,1)
        let center=Vector(x:(minX+maxX)/2,y:(minY+maxY)/2)
        let normalized=segments.map { segment in
            PatternSegment(from:(segment.from-center)*scale+Vector(x:0.5,y:0.5),to:(segment.to-center)*scale+Vector(x:0.5,y:0.5),depth:segment.depth,distance:segment.distance)
        }
        return .init(segments:normalized,distance:(segments.map(\.distance).max() ?? 0)+1,isBranched:word.contains("["))
    }
}

@MainActor final class PatternCache {
    static let shared=PatternCache()
    private var values=[String:PatternGeometry]()
    func geometry(_ pattern:RulePattern,generation:Int)->PatternGeometry {
        let key="\(pattern.id)-\(generation)"
        if let value=values[key] { return value }
        let value=RuleInterpreter.geometry(pattern,generation:generation);values[key]=value;return value
    }
}
