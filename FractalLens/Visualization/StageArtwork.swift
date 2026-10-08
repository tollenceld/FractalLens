import SwiftUI

struct StageArtwork:View {
    let explorer:Explorer
    @State private var settled=false
    private var animated:Bool { [.capture,.skeleton,.dive,.align,.replay,.alter].contains(explorer.stage) }
    var body:some View {
        TimelineView(.animation(minimumInterval:1/60,paused:!explorer.isActive || !animated || settled)) { timeline in
            let elapsed=max(0,timeline.date.timeIntervalSince(explorer.stageBegan))
            GeometryReader { proxy in
                let size=proxy.size
                if let specimen=explorer.specimen {
                    switch explorer.stage {
                    case .capture,.skeleton,.dive:
                        photographicScene(specimen,size:size,elapsed:elapsed)
                    case .align:
                        alignmentScene(size:size,elapsed:elapsed)
                    case .replay,.alter:
                        growthScene(specimen,elapsed:elapsed,date:timeline.date)
                    case .detail:
                        if explorer.detailMode==0 { photo.frame(width:size.width,height:size.height) }
                        else { StructureCanvas(graph:explorer.normalizedGraph,color:explorer.detailMode==2 ? LensStyle.green:LensStyle.foreground,lineWidth:explorer.detailMode==2 ? 0.85:1.0,pulse:elapsed,showNodes:explorer.detailMode==1) }
                    default:
                        if specimen.comparesScales {
                            let highlights=highlighted(specimen)
                            StructureCanvas(graph:explorer.normalizedGraph,highlighted:highlights,metric:explorer.selectedMetric,lineWidth:0.9,pulse:elapsed,showNodes:true)
                        } else { evidenceScene(specimen) }
                    }
                }
            }
        }.id("\(explorer.stage.rawValue)-\(settled)-\(explorer.playbackBegan.timeIntervalSinceReferenceDate)-\(explorer.isActive)")
        .aspectRatio(1,contentMode:.fit).frame(maxWidth:.infinity,maxHeight:.infinity).clipped()
        .task(id:explorer.stage) {
            settled=false
            let duration=explorer.stage == .align ? 3.5:explorer.stage == .capture ? 3.0:60.0
            try? await Task.sleep(for:.seconds(duration))
            if !Task.isCancelled { settled=true }
        }
        .task(id:explorer.playbackBegan) {
            if explorer.stage == .replay || explorer.stage == .alter {
                settled=false
                try? await Task.sleep(for:.seconds(6))
                if !Task.isCancelled && explorer.replayProgress(at:Date())>=1 { settled=true }
            }
        }
    }
    private var photo:some View {
        Group { if let image=explorer.image { Image(uiImage:image).resizable().aspectRatio(contentMode:.fit) } }
    }
    private func photographicScene(_ item:Specimen,size:CGSize,elapsed:Double)->some View {
        let imageSize=explorer.image?.size ?? CGSize(width:1,height:1)
        let fit=min(size.width/imageSize.width,size.height/imageSize.height)
        let w=imageSize.width*fit,h=imageSize.height*fit
        let isDive=explorer.stage == .dive
        let roots=item.analysis.scaleRoots
        let index=max(0,min(explorer.selectedScale,roots.count-1))
        let selected=isDive && !roots.isEmpty ? item.analysis.graph.subtree(roots[index]):item.analysis.graph
        let bounds=selected.bounds
        let zoom=isDive ? min(7,min(size.width*0.86/(bounds.width*w),size.height*0.85/(bounds.height*h))):1
        let x=isDive ? size.width/2-bounds.midX*w*zoom:(size.width-w)/2
        let y=isDive ? size.height/2-bounds.midY*h*zoom:(size.height-h)/2
        let extraction=explorer.stage == .capture ? 0:min(1,elapsed/3)
        return ZStack(alignment:.topLeading) {
            if isDive {
                StructureCanvas(graph:item.analysis.graph,color:LensStyle.foreground.opacity(0.1),lineWidth:0.65).frame(width:w,height:h).offset(x:(size.width-w)/2,y:(size.height-h)/2)
            }
            photo.saturation(explorer.stage == .capture ? max(0,1-elapsed/3):0)
                .opacity(isDive ? 0:1-extraction*0.98)
                .frame(width:w,height:h)
                .scaleEffect(zoom,anchor:.topLeading).offset(x:x,y:y)
            StructureCanvas(graph:isDive && index>0 ? selected:item.analysis.graph,progress:isDive ? 1:extraction,color:isDive && index>0 ? LensStyle.green:LensStyle.foreground,lineWidth:isDive ? 1.0:0.9,pulse:elapsed,showNodes:!isDive,viewportScale:zoom,viewportOffset:CGSize(width:x,height:y),sourceSize:CGSize(width:w,height:h))
                .opacity(explorer.stage == .capture ? 0:1)
        }.frame(width:size.width,height:size.height)
    }
    private func alignmentScene(size:CGSize,elapsed:Double)->some View {
        let t=explorer.reduceMotion ? 1:min(1,max(0,(elapsed-0.4)/2.0))
        let ease=t*t*(3-2*t)
        let side=min(size.width,max(1,size.height-40))
        return ZStack {
            ForEach(Array(explorer.scales.enumerated()),id:\.offset) { index,graph in
                let offset=Double(index-1)
                StructureCanvas(graph:graph,color:index==1 ? LensStyle.green:(index==0 ? LensStyle.blue.opacity(0.30):Color.orange.opacity(0.70)),lineWidth:index==1 ? 1.5:0.95)
                    .frame(width:side,height:side)
                    .scaleEffect(0.46+0.54*ease)
                    .rotationEffect(.degrees(offset*22*(1-ease)))
                    .offset(x:offset*size.width*0.27*(1-ease),y:abs(offset)*24*(1-ease)-20)
                    .blendMode(.multiply)
                    .opacity(index==0 ? 1:explorer.reduceMotion ? 1:min(1,max(0,(elapsed-Double(index)*0.25)/0.65)))
            }
            VStack { Spacer();HStack(spacing:20) {
                ForEach(Array(explorer.scales.indices),id:\.self) { i in
                    HStack(spacing:6) { Circle().fill(i==1 ? LensStyle.green:(i==0 ? LensStyle.blue:Color.orange)).frame(width:5,height:5);Text(["Whole","Branch","Twig"][min(i,2)]).font(.caption) }
                }
            }.opacity(min(1,max(0,elapsed-2.2))).padding(.bottom,10) }
        }
    }
    private func growthScene(_ item:Specimen,elapsed:Double,date:Date)->some View {
        let graph=explorer.normalizedGrowth
        let progress=explorer.reduceMotion ? (explorer.replayProgress(at:date)>0.5 ? 1:0.3):explorer.replayProgress(at:date)
        return ZStack {
            if explorer.stage == .alter && explorer.showOriginal { StructureCanvas(graph:explorer.normalizedGraph,color:LensStyle.foreground.opacity(0.12),lineWidth:0.65) }
            StructureCanvas(graph:graph,progress:progress,color:LensStyle.foreground,lineWidth:0.95,pulse:elapsed,showNodes:true)
            if progress<0.05,let root=graph.branches.first { GeometryReader { p in Circle().fill(LensStyle.green).frame(width:4,height:4).position(x:root.start.x*p.size.width,y:root.start.y*p.size.height) } }
        }
    }
    private func evidenceScene(_ item:Specimen)->some View {
        let focus=explorer.selectedEvidence
        let highlighted=focus == .repetition ? SceneGeometry.repeatedIDs(in:item.analysis.graph):[]
        let graph=explorer.normalizedGraph
        let bounds=item.analysis.graph.bounds
        let scale=0.82/max(bounds.width*item.analysis.graph.aspectRatio,bounds.height,0.001)
        return ZStack {
            StructureCanvas(graph:graph,color:focus == .keyPoints ? LensStyle.foreground.opacity(0.25):LensStyle.foreground,highlighted:highlighted,lineWidth:1.2)
            if focus == .keyPoints {
                Canvas { context,size in
                    for p in item.evidence?.keyPoints ?? [] {
                        let x=(0.5+(p.x-bounds.midX)*item.analysis.graph.aspectRatio*scale)*size.width
                        let y=(0.5+(p.y-bounds.midY)*scale)*size.height
                        context.fill(Path(ellipseIn:CGRect(x:x-3,y:y-3,width:6,height:6)),with:.color(LensStyle.green))
                    }
                }
            }
        }
    }
    private func highlighted(_ item:Specimen)->Set<Int> {
        switch explorer.selectedMetric {
        case .similarity:
            return item.analysis.scaleRoots.count>1 ? Set(item.analysis.graph.subtree(item.analysis.scaleRoots[1]).branches.map(\.id)):[]
        case .scale,.angle: return Set(item.analysis.graph.branches.filter { $0.depth==1 }.map(\.id))
        case .depth:return Set(item.analysis.graph.branches.filter { $0.depth==item.analysis.graph.depth-1 }.map(\.id))
        case .density,.complexity:return []
        }
    }
}
