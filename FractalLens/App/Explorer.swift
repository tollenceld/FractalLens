import SwiftUI
import Observation

enum LensStage:String { case home,observe,capture,skeleton,dive,align,profile,replay,alter,detail }
@MainActor @Observable final class Explorer {
    var stage:LensStage = .home
    var specimen:Specimen?
    var image:UIImage?
    var sourceImage:UIImage?
    var imageData:Data?
    var selectedScale=0
    var selectedMetric:Metric = .similarity
    var selectedEvidence:EvidenceFocus = .contours
    var selectedRule:Metric = .angle
    var detailMode=0
    var rules=GrowthRuleSet(angle:36,scale:0.5,depth:4,seed:1)
    var growthGraph=StructureGraph(branches:[])
    var scales=[StructureGraph]()
    var normalizedGraph=StructureGraph(branches:[])
    var normalizedGrowth=StructureGraph(branches:[])
    var stageBegan=Date()
    var playbackBegan=Date()
    var playbackOffset=0.0
    var isPlaying=true
    var showOriginal=true
    var isDemo=false
    var reduceMotion=false
    var isActive=true
    var error:String?
    var saving=false
    var saved=false
    var showArchive=false
    var linkedPlant:UUID?
    private var sequence:Task<Void,Never>?
    private var suspendedPlayback=false

    func select(_ item:Specimen,image:UIImage?,data:Data?=nil,detail:Bool=false) {
        sequence?.cancel();isDemo=false
        specimen=item;self.sourceImage=image;self.image=PhotoPresentation.isolatePaper(image,enabled:item.exampleKey=="fern-study")
        imageData=data;rules=item.analysis.rules;growthGraph=item.analysis.graph;normalizedGraph=item.glyph;normalizedGrowth=normalizedGraph
        scales=item.analysis.scaleRoots.map { item.analysis.graph.subtree($0).normalized(root:$0) }
        selectedScale=0;selectedEvidence = .contours;selectedMetric = .similarity;detailMode=0;saved=item.savedAt != nil
        transition(to:detail ? .detail:.capture)
    }
    func transition(to stage:LensStage) {
        self.stage=stage;stageBegan=Date()
        if stage == .replay || stage == .alter { replay() }
    }
    func goHome() { sequence?.cancel();sequence=nil;isDemo=false;transition(to:.home) }
    func observe(plantID:UUID?=nil) { sequence?.cancel();linkedPlant=plantID;isDemo=false;transition(to:.observe) }
    func pauseSequence() { sequence?.cancel();sequence=nil;isDemo=false }
    func reveal() {
        sequence?.cancel()
        sequence=Task { @MainActor [weak self] in
            guard let self,!Task.isCancelled else { return }
            transition(to:.capture)
            guard await wait(1.8) else { return };transition(to:.skeleton)
            guard await wait(3.4) else { return }
            if specimen?.comparesScales == false { transition(to:.profile);return }
            transition(to:.dive);selectedScale=0
            guard await wait(1.2) else { return };withAnimation(.easeInOut(duration:reduceMotion ? 0.2:1.6)) { self.selectedScale=min(1,self.scales.count-1) }
            guard await wait(2.2) else { return };withAnimation(reduceMotion ? .easeInOut(duration:0.2):LensMotion.reveal) { self.selectedScale=min(2,self.scales.count-1) }
            guard await wait(2.2) else { return };transition(to:.align)
        }
    }
    func openStudy(_ study:WorldStudy) {
        let image=study.image()
        select(study.specimen(),image:image,data:image.jpegData(compressionQuality:0.92))
        reveal()
    }
    func demo(_ item:Specimen,image:UIImage?,save:@escaping()->Void) {
        select(item,image:image);isDemo=true
        sequence=Task { @MainActor [weak self] in
            guard let self,!Task.isCancelled else { return }
            guard await wait(3) else { return };transition(to:.skeleton)
            guard await wait(4) else { return };transition(to:.dive)
            guard await wait(1) else { return };withAnimation(.easeInOut(duration:1.8)) { self.selectedScale=min(1,self.scales.count-1) }
            guard await wait(2.5) else { return };withAnimation(.easeInOut(duration:1.8)) { self.selectedScale=min(2,self.scales.count-1) }
            guard await wait(2.5) else { return };transition(to:.align)
            guard await wait(4) else { return };transition(to:.replay)
            guard await wait(5) else { return };transition(to:.alter);rules.angle += 16;regenerate()
            guard await wait(4) else { return };save()
        }
    }
    private func wait(_ seconds:Double) async -> Bool {
        var remaining=seconds
        var previous=Date()
        while remaining>0 {
            do { try await Task.sleep(for:.milliseconds(100)) } catch { return false }
            if Task.isCancelled { return false }
            let now=Date()
            if isActive { remaining -= now.timeIntervalSince(previous) }
            previous=now
        }
        return true
    }
    func manual(_ next:LensStage) { pauseSequence();transition(to:next) }
    func chooseScale(_ index:Int) { pauseSequence();withAnimation(reduceMotion ? .easeInOut(duration:0.2):LensMotion.reveal) { selectedScale=index } }
    func replayProgress(at date:Date)->Double {
        let duration=stage == .alter ? 3.0:5.0
        return min(1,max(0,playbackOffset+(isPlaying ? date.timeIntervalSince(playbackBegan)/duration:0)))
    }
    func replay() { playbackOffset=0;playbackBegan=Date();isPlaying=true }
    func togglePlayback() {
        if isPlaying { playbackOffset=replayProgress(at:Date());isPlaying=false }
        else { if playbackOffset>=1 { playbackOffset=0 };playbackBegan=Date();isPlaying=true }
    }
    func scrub(_ progress:Double) { playbackOffset=progress;playbackBegan=Date();isPlaying=false }
    func setActive(_ active:Bool) {
        isActive=active
        if !active { suspendedPlayback=isPlaying;if isPlaying { togglePlayback() } }
        else if suspendedPlayback { playbackBegan=Date();isPlaying=true;suspendedPlayback=false }
    }
    func regenerate() {
        guard let specimen else { return }
        growthGraph=GrowthSimulation.generate(from:specimen.analysis.graph,baseline:specimen.analysis.rules,rules:rules)
        growthGraph=GrowthSimulation.scheduled(growthGraph)
        normalizedGrowth=growthGraph.normalized()
        replay()
    }
    func resetRules() { guard let specimen else { return };rules=specimen.analysis.rules;regenerate() }
}

enum PhotoPresentation {
    static func isolatePaper(_ image:UIImage?,enabled:Bool)->UIImage? {
        guard enabled,let image,let cg=image.cgImage else { return image }
        let w=cg.width,h=cg.height
        var bytes=[UInt8](repeating:0,count:w*h*4)
        guard let context=CGContext(data:&bytes,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
        context.draw(cg,in:CGRect(x:0,y:0,width:w,height:h))
        for i in stride(from:0,to:bytes.count,by:4) {
            let r=Double(bytes[i]),g=Double(bytes[i+1]),b=Double(bytes[i+2])
            let chroma=max(r,g,b)-min(r,g,b)
            // White paper and neutral cast shadows dissolve; plant pixels remain photographic.
            let alpha=min(1,max(0,(chroma-7)/23))*min(1,max(0,(250-min(r,g,b))/45))
            bytes[i]=UInt8(r*alpha);bytes[i+1]=UInt8(g*alpha);bytes[i+2]=UInt8(b*alpha);bytes[i+3]=UInt8(255*alpha)
        }
        guard let output=context.makeImage() else { return image }
        return UIImage(cgImage:output)
    }
}
