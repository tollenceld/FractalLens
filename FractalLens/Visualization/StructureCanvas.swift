import SwiftUI

struct StructureCanvas:View, Animatable {
    var graph:StructureGraph
    var progress:Double=1
    var color:Color=LensStyle.foreground
    var highlighted:Set<Int>=[]
    var metric:Metric?=nil
    var lineWidth:Double=1
    var pulse:Double=0
    var showNodes=false
    var viewportScale:Double=1
    var viewportOffset:CGSize = .zero
    var sourceSize:CGSize?=nil
    var animatableData:AnimatablePair<Double,AnimatablePair<Double,Double>> {
        get { .init(viewportScale,.init(viewportOffset.width,viewportOffset.height)) }
        set { viewportScale=newValue.first;viewportOffset=CGSize(width:newValue.second.first,height:newValue.second.second) }
    }
    var body:some View {
        Canvas(rendersAsynchronously:true) { context,size in
            let drawingSize=sourceSize ?? size
            func screen(_ p:Vector)->CGPoint { CGPoint(x:p.x*drawingSize.width*viewportScale+viewportOffset.width,y:p.y*drawingSize.height*viewportScale+viewportOffset.height) }
            for branch in graph.branches {
                let amount=GrowthSimulation.branchProgress(branch,graph:graph,progress:progress)
                guard amount>0 else { continue }
                let isHighlighted=highlighted.contains(branch.id)
                var path=Path()
                let samples=max(2,min(40,branch.points.count*3))
                if amount >= 0.999 {
                    for (i,p) in branch.points.enumerated() { let position=screen(p); if i==0 { path.move(to:position) } else { path.addLine(to:position) } }
                } else {
                for step in 0...samples {
                    let point=branch.point(at:Double(step)/Double(samples)*amount)
                    let position=screen(point)
                    if step==0 { path.move(to:position) } else { path.addLine(to:position) }
                }
                }
                let accent = isHighlighted || (metric == .depth && branch.depth==graph.depth-1) || (metric == .density && branch.depth>1)
                let opacity = highlighted.isEmpty || isHighlighted ? 1.0:0.2
                let width=max(0.45,lineWidth*(1.7-Double(branch.depth)*0.25))
                context.stroke(path,with:.color((accent ? LensStyle.green:color).opacity(opacity)),style:StrokeStyle(lineWidth:width,lineCap:.round,lineJoin:.round))
                if showNodes && branch.depth<3 && amount>0.35 {
                    let p=branch.start, radius=(accent ? 2.6:1.5)+sin(pulse+Double(branch.id))*0.35
                    let r=CGRect(x:screen(p).x-radius,y:screen(p).y-radius,width:radius*2,height:radius*2)
                    context.fill(Path(ellipseIn:r),with:.color(accent ? LensStyle.green:color.opacity(0.6)))
                }
                if metric == .angle && branch.depth==1 {
                    let p=branch.start
                    var arc=Path();arc.addArc(center:screen(p),radius:15,startAngle:.degrees(-90),endAngle:.radians(atan2(branch.direction.y,branch.direction.x)),clockwise:false)
                    context.stroke(arc,with:.color(LensStyle.green.opacity(0.65)),lineWidth:0.6)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
struct GlyphView:View {
    var graph:StructureGraph
    var active=true
    var preserveOrientation=false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body:some View {
        let normalized=preserveOrientation ? graph:graph.normalized()
        TimelineView(.animation(minimumInterval:1/24,paused:!active || reduceMotion || scenePhase != .active)) { time in
            let t=time.date.timeIntervalSinceReferenceDate
            StructureCanvas(graph:normalized,color:LensStyle.foreground.opacity(0.82),lineWidth:0.65,pulse:t*0.7)
                .scaleEffect(reduceMotion ? 1:1+sin(t*0.55)*0.009)
        }
    }
}
