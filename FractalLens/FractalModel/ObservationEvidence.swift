import Foundation
import SwiftUI

enum WorldFamily:String,Codable,CaseIterable,Identifiable,Sendable {
    case branching="Branching",boundaries="Irregular edges",spirals="Spirals",repetition="Everyday repetition"
    var id:String { rawValue }
    var symbol:String { switch self { case .branching:return "point.3.connected.trianglepath.dotted";case .boundaries:return "water.waves";case .spirals:return "hurricane";case .repetition:return "square.grid.3x3" } }
    var color:Color { switch self { case .branching:return LensStyle.green;case .boundaries:return LensStyle.blue;case .spirals:return Color(red:0.65,green:0.43,blue:0.29);case .repetition:return Color(red:0.58,green:0.43,blue:0.73) } }
    var invitation:String { switch self { case .branching:return "Follow a river, a vein, a fork.";case .boundaries:return "Look at clouds, cracks and coastlines.";case .spirals:return "Find a shell, a curl, a turning form.";case .repetition:return "Notice windows, tiles and woven things." } }
}
enum EvidenceKind:String,Codable,Sendable {
    case nested, repeated, winding, outline
    var title:String { switch self { case .nested:return "A smaller echo.";case .repeated:return "A rhythm, repeated.";case .winding:return "A turning rhythm.";case .outline:return "An edge worth following." } }
    var explanation:String { switch self {
    case .nested:return "Compare the part with the whole. Their differences matter, too."
    case .repeated:return "Similar forms appear in different places. Repetition alone is not a fractal."
    case .winding:return "The curve turns as it grows. A spiral alone is not evidence of a fractal."
    case .outline:return "These contours come from the image. More scale evidence is needed to call them fractal."
    } }
}
struct ObservationEvidence:Codable,Hashable,Sendable {
    var family:WorldFamily
    var kind:EvidenceKind
    var repetition:Double?
    var keyPoints:[Vector]
    var objectHint:String?
    var note:String
    var frames:Int = 1
    var isLive:Bool = false
    var algorithm:String = "Scene geometry v1"
    var comparesScales:Bool { kind == .nested }
}
extension Specimen {
    var evidence:ObservationEvidence? { analysis.evidence }
    var comparesScales:Bool { evidence?.comparesScales ?? (analysis.scaleRoots.count>1) }
    var sourceLabel:String {
        switch source.origin {
        case .example:return "Curated photograph · traced structure"
        case .guided:return "Guided study · illustrated structure"
        case .camera:return "Live observation · on-device estimate"
        case .imported:return "Photo observation · on-device estimate"
        }
    }
    var observationValue:String {
        if comparesScales { return Metric.similarity.value(analysis.metrics) }
        if let score=evidence?.repetition { return "\(Int(score.rounded()))%" }
        return evidence?.family.rawValue ?? "Contour"
    }
}

enum EvidenceFocus:String,CaseIterable,Identifiable {
    case contours="Contours",keyPoints="Key points",repetition="Repetition"
    var id:Self { self }
}
