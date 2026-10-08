import Foundation
import Vision
import UIKit

struct LiveFrameEvidence:Sendable {
    var data:Data
    var graph:StructureGraph
    var keyPoints:[Vector]
    var signature:[Double]
    var quality:Double
    var repetition:Double?
    var context:String?
    var canReveal:Bool { graph.branches.count>=3 && quality>0.2 }
}

enum SceneGeometry {
    /// Repeated contour proportions and lengths, independent of their positions.
    /// This measures repetition at one scale. It is deliberately not self-similarity.
    static func repetition(in graph:StructureGraph)->Double? {
        let usable=graph.branches.filter { $0.length>0.02 && $0.points.count>=3 }
        guard usable.count>=3 else { return nil }
        let matched=repeatedIDs(in:graph)
        guard matched.count>=3 else { return nil }
        return 100*Double(matched.count)/Double(usable.count)
    }
    static func repeatedIDs(in graph:StructureGraph)->Set<Int> {
        let usable=graph.branches.filter { $0.length>0.02 && $0.points.count>=3 }
        struct Descriptor {
            var length:Double
            var ratio:Double
            var compactness:Double
            var closed:Bool
        }
        let descriptions=Dictionary(uniqueKeysWithValues:usable.map { b -> (Int,Descriptor) in
            let bounds=StructureGraph(branches:[b]).bounds
            let area=abs(zip(b.points,b.points.dropFirst()).reduce(0) { $0+$1.0.x*$1.1.y-$1.1.x*$1.0.y })/2
            return (b.id,Descriptor(length:b.length,ratio:max(bounds.width,bounds.height)/max(0.002,min(bounds.width,bounds.height)),compactness:area/max(0.00001,b.length*b.length),closed:b.start.distance(to:b.end)<b.length*0.08))
        })
        return Set(usable.filter { b in
            guard let d=descriptions[b.id] else { return false }
            return usable.filter { other in
                guard let e=descriptions[other.id] else { return false }
                return d.closed==e.closed && abs(log(d.length/e.length))<0.16 && abs(log(d.ratio/e.ratio))<0.18 && abs(d.compactness-e.compactness)<0.018
            }.count>=3
        }.map(\.id))
    }
    static func signatureDistance(_ a:[Double],_ b:[Double])->Double {
        guard a.count==b.count,!a.isEmpty else { return .infinity }
        return zip(a,b).reduce(0) { $0+abs($1.0-$1.1) }/Double(a.count)
    }
    static func keyPoints(in graph:StructureGraph)->[Vector] {
        var points=[Vector]()
        for b in graph.branches {
            guard b.points.count>2 else { continue }
            for i in stride(from:1,to:b.points.count-1,by:max(1,b.points.count/8)) {
                let a=b.points[i]-b.points[i-1],c=b.points[i+1]-b.points[i]
                let bend=abs(atan2(a.x*c.y-a.y*c.x,a.x*c.x+a.y*c.y))
                if bend>0.35 { points.append(b.points[i]) }
            }
            if points.count<20 { points.append(b.start) }
        }
        return Array(points.prefix(28))
    }
}

enum SceneAnalyzer {
    static func inspect(data:Data,classify:Bool=true) async throws -> LiveFrameEvidence {
        let worker=Task.detached(priority:.userInitiated) { try inspectSync(data:data,classify:classify) }
        return try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
    }
    static func inspectSync(data:Data,classify:Bool) throws -> LiveFrameEvidence {
        try Task.checkCancellation()
        guard let image=UIImage(data:data) else { throw AnalysisFailure.unreadable }
        let normalized=normalize(image,maxSide:640)
        guard let cg=normalized.cgImage,let bytes=normalized.jpegData(compressionQuality:0.86) else { throw AnalysisFailure.unreadable }
        let handler=VNImageRequestHandler(cgImage:cg,options:[:])
        let request=VNDetectContoursRequest();request.maximumImageDimension=320;request.contrastAdjustment=1.4
        try handler.perform([request]);try Task.checkCancellation()
        var paths=[[Vector]]()
        func visit(_ contour:VNContour) {
            let raw=contour.normalizedPoints
            if raw.count>=5 {
                let strideSize=max(1,raw.count/90)
                let points=raw.enumerated().filter { $0.offset%strideSize==0 || $0.offset==raw.count-1 }.map { Vector(x:Double($0.element.x),y:1-Double($0.element.y)) }
                let branch=Branch(id:0,parent:nil,depth:0,points:points)
                if branch.length>0.035 && branch.length<8 && points.filter({$0.x<0.005 || $0.x>0.995 || $0.y<0.005 || $0.y>0.995}).count<points.count/2 { paths.append(points) }
            }
            for child in contour.childContours { visit(child) }
        }
        if let result=request.results?.first { for contour in result.topLevelContours { visit(contour) } }
        paths.sort { Branch(id:0,parent:nil,depth:0,points:$0).length>Branch(id:0,parent:nil,depth:0,points:$1).length }
        let graph=StructureGraph(branches:Array(paths.prefix(75)).enumerated().map { Branch(id:$0.offset,parent:nil,depth:0,points:$0.element) },aspectRatio:Double(cg.width)/Double(cg.height))
        let field=imageField(cg)
        var context:String?
        if classify {
            let classification=VNClassifyImageRequest()
            if (try? handler.perform([classification])) != nil,let label=classification.results?.first, label.confidence>0.45 {
                context=label.identifier.replacingOccurrences(of:"_",with:" ")
            }
        }
        try Task.checkCancellation()
        return LiveFrameEvidence(data:bytes,graph:graph,keyPoints:SceneGeometry.keyPoints(in:graph),signature:field.signature,quality:field.quality,repetition:SceneGeometry.repetition(in:graph),context:context)
    }
    static func analyze(data:Data,selection:Vector = .init(x:0.5,y:0.5),liveFrames:Int=0) async throws -> PhotoAnalysisOutput {
        let frame=try await inspect(data:data)
        guard frame.canReveal else { throw AnalysisFailure.noStructure }
        let context=frame.context?.lowercased() ?? ""
        let botanical=["plant","tree","fern","leaf","flower","vegetation","shrub","herb"].contains { context.contains($0) }
        if botanical,let output=try? await PhotoAnalyzer.analyze(data:data,selection:selection),output.result.scaleRoots.count>1 {
            try Task.checkCancellation()
            var result=output.result
            result.evidence = .init(family:.branching,kind:.nested,repetition:nil,keyPoints:Array(result.graph.branches.map(\.start).prefix(24)),objectHint:frame.context,note:"A foreground skeleton reveals connected branches. Scale estimates compare real nested subgraphs.",frames:max(1,liveFrames),isLive:liveFrames>0,algorithm:"Vision foreground + medial skeleton v2")
            return .init(data:output.data,result:result)
        }
        try Task.checkCancellation()
        var result=StructuralAnalysis.evaluate(frame.graph,confidence:min(0.8,frame.quality))
        result.scaleRoots=[];result.metrics.similarity=nil
        let repeated=(frame.repetition ?? 0)>=50
        result.evidence = .init(family:repeated ? .repetition:.boundaries,kind:repeated ? .repeated:.outline,repetition:frame.repetition,keyPoints:frame.keyPoints,objectHint:frame.context,note:repeated ? "Similar contour proportions and lengths recur in this frame. This is spatial repetition, not a cross-scale fractal measurement.":"Image contours were extracted directly from this frame. No reliable recursive hierarchy was found.",frames:max(1,liveFrames),isLive:liveFrames>0,algorithm:"Vision contours + shape descriptors v1")
        return .init(data:frame.data,result:result)
    }
    static func normalize(_ source:UIImage,maxSide:Double)->UIImage {
        let factor=min(1,maxSide/max(source.size.width,source.size.height))
        let size=CGSize(width:source.size.width*factor,height:source.size.height*factor)
        let format=UIGraphicsImageRendererFormat();format.scale=1
        return UIGraphicsImageRenderer(size:size,format:format).image { _ in source.draw(in:CGRect(origin:.zero,size:size)) }
    }
    private static func imageField(_ cg:CGImage)->(signature:[Double],quality:Double) {
        let side=96
        var pixels=[UInt8](repeating:0,count:side*side)
        pixels.withUnsafeMutableBytes { raw in
            guard let c=CGContext(data:raw.baseAddress,width:side,height:side,bitsPerComponent:8,bytesPerRow:side,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:0) else { return }
            c.translateBy(x:0,y:CGFloat(side));c.scaleBy(x:1,y:-1);c.draw(cg,in:CGRect(x:0,y:0,width:side,height:side))
        }
        let values=pixels.map { Double($0)/255 }
        let mean=values.reduce(0,+)/Double(values.count)
        let variance=values.reduce(0) { $0+pow($1-mean,2) }/Double(values.count)
        var bins=[Double](repeating:0,count:16),energy=0.0
        for y in 1..<side-1 { for x in 1..<side-1 {
            let i=y*side+x,gx=values[i+1]-values[i-1],gy=values[i+side]-values[i-side]
            let edge=hypot(gx,gy);energy += edge;bins[(y/24)*4+x/24] += edge
        } }
        let total=max(0.0001,bins.reduce(0,+))
        let quality=min(1,min(variance/0.012,(energy/Double(side*side))/0.012))
        return (bins.map { $0/total },quality)
    }
}
