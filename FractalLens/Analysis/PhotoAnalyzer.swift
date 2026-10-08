import Foundation
import Vision
import UIKit
import CoreImage

struct PhotoAnalysisOutput:Sendable { let data:Data; let result:AnalysisResult }
enum AnalysisFailure:LocalizedError {
    case unreadable, noStructure, unavailable
    var errorDescription:String? {
        switch self {
        case .unreadable:return "This photo could not be opened. Try another image."
        case .noStructure:return "A clear structure has not emerged yet. Try stronger contrast, move closer, or explore a guided study."
        case .unavailable:return "Foreground analysis is unavailable here. Try this photo on iPhone, or explore a curated specimen."
        }
    }
}
enum PhotoAnalyzer {
    static func analyze(data:Data,selection:Vector = .init(x:0.5,y:0.5)) async throws -> PhotoAnalysisOutput {
        let worker=Task.detached(priority:.userInitiated) {
            try Task.checkCancellation()
            guard let source=UIImage(data:data) else { throw AnalysisFailure.unreadable }
            let size=source.size, maxSide=1600.0, factor=min(1,maxSide/max(size.width,size.height))
            let renderer=UIGraphicsImageRenderer(size:CGSize(width:size.width*factor,height:size.height*factor),format: {
                let format=UIGraphicsImageRendererFormat(); format.scale=1;return format
            }())
            let image=renderer.image { _ in source.draw(in:CGRect(origin:.zero,size:CGSize(width:size.width*factor,height:size.height*factor))) }
            guard let cg=image.cgImage,let normalizedData=image.jpegData(compressionQuality:0.9) else { throw AnalysisFailure.unreadable }
            let handler=VNImageRequestHandler(cgImage:cg,options:[:])
            let request=VNGenerateForegroundInstanceMaskRequest()
            do { try handler.perform([request]) } catch { throw AnalysisFailure.unavailable }
            try Task.checkCancellation()
            guard let observation=request.results?.first else { throw AnalysisFailure.noStructure }
            var instances=observation.allInstances
            let labels=observation.instanceMask
            CVPixelBufferLockBaseAddress(labels,.readOnly)
            if let base=CVPixelBufferGetBaseAddress(labels) {
                let w=CVPixelBufferGetWidth(labels),h=CVPixelBufferGetHeight(labels),row=CVPixelBufferGetBytesPerRow(labels)
                let x=min(w-1,max(0,Int(selection.x*Double(w)))),y=min(h-1,max(0,Int(selection.y*Double(h))))
                let label=Int(base.assumingMemoryBound(to:UInt8.self)[y*row+x])
                if label > 0 { instances=IndexSet(integer:label) }
            }
            CVPixelBufferUnlockBaseAddress(labels,.readOnly)
            let pixelMask=try observation.generateScaledMaskForImage(forInstances:instances,from:handler)
            let mask=CIImage(cvPixelBuffer:pixelMask)
            let ciContext=CIContext(options:[.useSoftwareRenderer:false])
            guard let maskCG=ciContext.createCGImage(mask,from:mask.extent) else { throw AnalysisFailure.noStructure }
            let width=256,height=max(32,Int(Double(cg.height)/Double(cg.width)*256))
            let limitedHeight=min(512,height)
            var bytes=[UInt8](repeating:0,count:width*limitedHeight)
            bytes.withUnsafeMutableBytes { raw in
                if let ctx=CGContext(data:raw.baseAddress,width:width,height:limitedHeight,bitsPerComponent:8,bytesPerRow:width,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:CGImageAlphaInfo.none.rawValue) {
                    ctx.translateBy(x:0,y:CGFloat(limitedHeight));ctx.scaleBy(x:1,y:-1)
                    ctx.draw(maskCG,in:CGRect(x:0,y:0,width:width,height:limitedHeight))
                }
            }
            var binary=bytes.map { $0 > 150 ? UInt8(1):UInt8(0) }
            let area=binary.reduce(0) { $0+Int($1) }
            guard area>100,Double(area)/Double(binary.count)<0.9 else { throw AnalysisFailure.noStructure }
            // Contours are evidence for foreground quality, not a substitute for a medial skeleton.
            let contours=VNDetectContoursRequest();contours.maximumImageDimension=256
            try? handler.perform([contours])
            try Task.checkCancellation()
            SkeletonExtractor.thin(&binary,width:width,height:limitedHeight)
            let graph=SkeletonExtractor.graph(binary,width:width,height:limitedHeight,selection:selection)
            guard graph.branches.count >= 4,graph.depth >= 2 else { throw AnalysisFailure.noStructure }
            try Task.checkCancellation()
            return PhotoAnalysisOutput(data:normalizedData,result:StructuralAnalysis.evaluate(graph,confidence:0.65))
        }
        return try await withTaskCancellationHandler { try await worker.value } onCancel: { worker.cancel() }
    }
}
enum SkeletonExtractor {
    static func thin(_ image:inout [UInt8],width:Int,height:Int) {
        guard width>2,height>2 else { return }
        for _ in 0..<160 {
            if Task.isCancelled { return }
            var changed=false
            for phase in 0...1 {
                var remove=[Int]()
                for y in 1..<(height-1) { for x in 1..<(width-1) {
                    let i=y*width+x
                    guard image[i]==1 else { continue }
                    let p=[image[i-width],image[i-width+1],image[i+1],image[i+width+1],image[i+width],image[i+width-1],image[i-1],image[i-width-1]]
                    let sum=p.reduce(0) { $0+Int($1) }
                    guard (2...6).contains(sum) else { continue }
                    var transitions=0
                    for k in 0..<8 where p[k]==0 && p[(k+1)%8]==1 { transitions += 1 }
                    guard transitions==1 else { continue }
                    let a=phase==0 ? p[0]*p[2]*p[4] : p[0]*p[2]*p[6]
                    let b=phase==0 ? p[2]*p[4]*p[6] : p[0]*p[4]*p[6]
                    if a==0 && b==0 { remove.append(i) }
                } }
                if !remove.isEmpty { changed=true;for i in remove { image[i]=0 } }
            }
            if !changed { break }
        }
    }
    static func graph(_ pixels:[UInt8],width:Int,height:Int,selection:Vector)->StructureGraph {
        func neighbors(_ i:Int)->[Int] {
            let x=i%width,y=i/width
            return (-1...1).flatMap { dy in (-1...1).compactMap { dx -> Int? in
                guard dx != 0 || dy != 0,x+dx>=0,x+dx<width,y+dy>=0,y+dy<height else { return nil }
                let n=(y+dy)*width+x+dx;return pixels[n]==1 ? n:nil
            } }
        }
        let active=pixels.indices.filter { pixels[$0]==1 }
        guard !active.isEmpty else { return .init(branches:[]) }
        var visited=Set<Int>(),components=[[Int]]()
        for p in active where !visited.contains(p) {
            var queue=[p],head=0;visited.insert(p)
            while head<queue.count { let q=queue[head];head += 1; for n in neighbors(q) where !visited.contains(n) { visited.insert(n);queue.append(n) } }
            if queue.count>12 { components.append(queue) }
        }
        let selected=components.min { a,b in
            func distance(_ c:[Int])->Double { c.map { hypot(Double($0%width)/Double(width)-selection.x,Double($0/width)/Double(height)-selection.y) }.min() ?? 10 }
            return distance(a)<distance(b)
        } ?? []
        guard selected.count>15 else { return .init(branches:[]) }
        let endpoints=selected.filter { neighbors($0).count==1 }
        let root=(endpoints.isEmpty ? selected:endpoints).max(by:{ $0/width < $1/width }) ?? selected[0]
        var edges=[Branch](),seen:Set<Int>=[root]
        var pending:[(Int,Int?,Int)]=[(root,nil,0)],cursor=0
        func point(_ i:Int)->Vector { .init(x:Double(i%width)/Double(width),y:Double(i/width)/Double(height)) }
        while cursor<pending.count && edges.count<650 {
            let (start,parent,depth)=pending[cursor];cursor += 1
            for neighbor in neighbors(start) where !seen.contains(neighbor) {
                var path=[start,neighbor],current=neighbor;seen.insert(neighbor)
                while true {
                    let next=neighbors(current).filter { !seen.contains($0) }
                    guard next.count==1 else { break }
                    current=next[0];seen.insert(current);path.append(current)
                }
                // Short junction runs still carry connectivity; collapse them onto the parent.
                if path.count<3 {
                    pending.append((current,parent,depth));continue
                }
                let id=edges.count
                let simplified=path.enumerated().filter { $0.offset%2==0 || $0.offset==path.count-1 }.map { point($0.element) }
                edges.append(Branch(id:id,parent:parent,depth:min(depth,12),points:simplified))
                pending.append((current,id,depth+1))
            }
        }
        // Prune insignificant terminal spurs only. Keep parent IDs stable.
        let parents=Set(edges.compactMap(\.parent))
        edges.removeAll { !parents.contains($0.id) && $0.length<0.018 }
        return .init(branches:edges,aspectRatio:Double(width)/Double(height))
    }
}
