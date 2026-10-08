import SwiftUI

struct PatternCanvas:View {
    var geometry:PatternGeometry
    var previous:PatternGeometry = .empty
    var phase:Double=1
    var color:Color
    var lineWidth:Double=1.3
    var body:some View {
        Canvas(rendersAsynchronously:true) { context,size in
            let side=min(size.width,size.height)
            let origin=CGPoint(x:(size.width-side)/2,y:(size.height-side)/2)
            func point(_ vector:Vector)->CGPoint { CGPoint(x:origin.x+vector.x*side,y:origin.y+vector.y*side) }
            var paths=[Int:Path]()
            let count=geometry.segments.count
            let oldCount=previous.segments.count
            let canMorph = !geometry.isBranched && !previous.isBranched && count>0 && oldCount>0 && max(count,oldCount).isMultiple(of:min(count,oldCount))
            let renderCount=canMorph && phase<1 ? max(count,oldCount):count
            for index in 0..<renderCount {
                let factor=renderCount/max(1,count)
                let segment=geometry.segments[index/max(1,factor)]
                let a=Double(index%max(1,factor))/Double(max(1,factor)),b=Double(index%max(1,factor)+1)/Double(max(1,factor))
                var start=segment.from+(segment.to-segment.from)*a,end=segment.from+(segment.to-segment.from)*b
                if canMorph && phase<1 {
                    let oldFactor=renderCount/oldCount
                    let old=previous.segments[index/oldFactor]
                    let oldA=Double(index%oldFactor)/Double(oldFactor),oldB=Double(index%oldFactor+1)/Double(oldFactor)
                    let from=old.from+(old.to-old.from)*oldA,to=old.from+(old.to-old.from)*oldB
                    start=from+(start-from)*phase;end=to+(end-to)*phase
                } else if phase<1 {
                    // Arrival advances through the parent axis before its smaller offshoots.
                    let frontier=LensMotion.smooth(phase)*geometry.distance
                    let local=min(1,max(0,frontier-segment.distance))
                    guard local>0 else { continue }
                    end=start+(end-start)*local
                }
                var path=paths[segment.depth] ?? Path()
                path.move(to:point(start));path.addLine(to:point(end));paths[segment.depth]=path
            }
            for depth in paths.keys.sorted() {
                let gradient=Gradient(colors:[color.opacity(0.7),color,Color(red:0.24,green:0.67,blue:0.58)])
                context.stroke(paths[depth]!,with:.linearGradient(gradient,startPoint:CGPoint(x:0,y:0),endPoint:CGPoint(x:side,y:side)),style:StrokeStyle(lineWidth:max(0.55,lineWidth-Double(depth)*0.13),lineCap:.round,lineJoin:.round))
            }
        }.accessibilityHidden(true)
    }
}

struct PatternArtwork:View {
    let pattern:RulePattern
    var generation:Int
    var animate=true
    var lineWidth:Double=1.3
    @State private var previous=PatternGeometry.empty
    @State private var current=PatternGeometry.empty
    @State private var began=Date()
    @State private var settled=true
    @State private var suspendedAt:Date?
    @State private var transitionTask:Task<Void,Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body:some View {
        TimelineView(.animation(minimumInterval:1/60,paused:settled || scenePhase != .active)) { time in
            let elapsed=max(0,Date().timeIntervalSince(began))
            let duration=reduceMotion ? 0.25:1.35
            let phase=settled ? 1:LensMotion.revealProgress(elapsed/duration)
            ZStack {
                if current.isBranched && !reduceMotion {
                    PatternCanvas(geometry:previous,color:pattern.color.opacity(0.13),lineWidth:lineWidth).opacity(1-phase)
                }
                PatternCanvas(geometry:current,previous:reduceMotion ? .empty:previous,phase:reduceMotion ? 1:phase,color:pattern.color,lineWidth:lineWidth)
                    .opacity(reduceMotion ? phase:1)
            }
        }.id(began).onChange(of:generation,initial:true) { _,value in
            transitionTask?.cancel()
            previous=current
            current=PatternCache.shared.geometry(pattern,generation:value)
            guard animate && !previous.segments.isEmpty else { settled=true;return }
            began=Date();settled=false
            transitionTask=Task { @MainActor in
                while !Task.isCancelled {
                    do { try await Task.sleep(for:.milliseconds(80)) } catch { return }
                    if scenePhase == .active && Date().timeIntervalSince(began)>=(reduceMotion ? 0.25:1.35) { settled=true;return }
                }
            }
        }
        .onChange(of:scenePhase) { _,phase in
            if phase != .active { suspendedAt=Date() }
            else if let suspendedAt { began=began.addingTimeInterval(Date().timeIntervalSince(suspendedAt));self.suspendedAt=nil }
        }
        .onDisappear { transitionTask?.cancel() }
    }
}

struct PatternThumb:View {
    let pattern:RulePattern
    var body:some View {
        ZStack {
            RoundedRectangle(cornerRadius:26).fill(pattern.color.opacity(0.065))
            PatternArtwork(pattern:pattern,generation:pattern.showcase,animate:false,lineWidth:1.05).padding(8)
        }.aspectRatio(1,contentMode:.fit)
    }
}
