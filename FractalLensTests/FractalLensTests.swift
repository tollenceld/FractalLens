import XCTest
@testable import FractalLens

final class FractalLensTests:XCTestCase {
    let tree=StructureGraph(branches:[
        Branch(id:0,parent:nil,depth:0,points:[.init(x:0.5,y:0.9),.init(x:0.5,y:0.2)]),
        Branch(id:1,parent:0,depth:1,points:[.init(x:0.5,y:0.6),.init(x:0.2,y:0.3)]),
        Branch(id:2,parent:0,depth:1,points:[.init(x:0.5,y:0.4),.init(x:0.8,y:0.2)]),
        Branch(id:3,parent:1,depth:2,points:[.init(x:0.35,y:0.45),.init(x:0.1,y:0.4)]),
        Branch(id:4,parent:1,depth:2,points:[.init(x:0.25,y:0.35),.init(x:0.3,y:0.15)])])
    func testSimilarityIsTransformInvariantAndDistinguishesDifferentShapes() {
        let base=tree.normalized()
        var transformed=tree
        transformed.branches=tree.branches.map { b in var copy=b;copy.points=b.points.map { $0.rotated(0.7)*1.4+Vector(x:0.8,y:0.3) };return copy }
        XCTAssertEqual(StructuralAnalysis.similarity(base,transformed.normalized()),100,accuracy:0.001)
        let line=StructureGraph(branches:[tree.branches[0]]).normalized()
        XCTAssertLessThan(StructuralAnalysis.similarity(base,line),90)
    }
    func testRuleChangePreservesOriginalAndIsDeterministic() {
        let result=StructuralAnalysis.evaluate(tree)
        var rules=result.rules;rules.angle += 20
        let a=GrowthSimulation.generate(from:tree,baseline:result.rules,rules:rules)
        let b=GrowthSimulation.generate(from:tree,baseline:result.rules,rules:rules)
        XCTAssertEqual(a,b);XCTAssertNotEqual(a,tree)
        XCTAssertEqual(a.branches[0],tree.branches[0])
        XCTAssertEqual(rules.scale,result.rules.scale);XCTAssertEqual(rules.depth,result.rules.depth)
        XCTAssertEqual(GrowthSimulation.generate(from:tree,baseline:result.rules,rules:result.rules),tree)
    }
    func testScaleSelectionsAreNestedRealSubgraphs() {
        let result=StructuralAnalysis.evaluate(tree)
        XCTAssertEqual(result.scaleRoots,[0,1])
        XCTAssertEqual(Set(tree.subtree(1).branches.map(\.id)),[1,3,4])
        XCTAssertEqual(result.metrics.depth,3)
        XCTAssertEqual(StructuralAnalysis.evaluate(tree),result)
    }
    func testSkeletonPreservesBranchedConnectivity() {
        let w=65,h=65
        var pixels=[UInt8](repeating:0,count:w*h)
        for y in 10...58 { for x in 30...34 { pixels[y*w+x]=1 } }
        for n in 0...20 { for offset in -2...2 { pixels[(35-n)*w+32-n+offset]=1;pixels[(35-n)*w+32+n+offset]=1 } }
        SkeletonExtractor.thin(&pixels,width:w,height:h)
        let graph=SkeletonExtractor.graph(pixels,width:w,height:h,selection:.init(x:0.5,y:0.7))
        XCTAssertGreaterThanOrEqual(graph.branches.count,3)
        XCTAssertTrue(graph.allPoints.allSatisfy { $0.x>=0 && $0.x<=1 && $0.y>=0 && $0.y<=1 })
    }
    @MainActor func testPersistenceDuplicateSaveHistoryAndFailure() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:directory) }
        let store=SpecimenStore(directory:directory,loadExamples:false)
        var specimen=Specimen(id:UUID(),plantID:UUID(),title:"Test",subtitle:"",source:.init(imageName:"",origin:.imported,date:Date()),analysis:StructuralAnalysis.evaluate(tree))
        let saved=try store.save(specimen,imageData:Data([1,2,3]))
        _=try store.save(specimen)
        XCTAssertEqual(store.specimens.count,1)
        let reopened=SpecimenStore(directory:directory,loadExamples:false)
        XCTAssertEqual(reopened.specimens.first,saved)
        specimen.id=UUID();specimen.source.date=Date().addingTimeInterval(100)
        _=try reopened.save(specimen)
        XCTAssertEqual(reopened.observations(of:saved).count,2)
        let blockingFile=directory.appendingPathComponent("not-a-directory")
        try Data([1]).write(to:blockingFile)
        let broken=SpecimenStore(directory:blockingFile,loadExamples:false)
        XCTAssertThrowsError(try broken.save(specimen));XCTAssertTrue(broken.specimens.isEmpty)
    }
    @MainActor func testSixBundledExamplesHaveImagesAndTraceableMetrics() {
        let store=SpecimenStore()
        XCTAssertEqual(store.examples.count,6)
        for example in store.examples {
            XCTAssertNotNil(store.image(for:example));XCTAssertFalse(example.source.attribution?.isEmpty ?? true)
            XCTAssertEqual(example.analysis.metrics,StructuralAnalysis.evaluate(example.analysis.graph).metrics)
            XCTAssertGreaterThanOrEqual(example.analysis.scaleRoots.count,2)
            let ids=Set(example.analysis.graph.branches.map(\.id))
            XCTAssertTrue(example.analysis.graph.branches.allSatisfy { $0.parent==nil || ids.contains($0.parent!) })
        }
    }
    @MainActor func testCancelRevealCannotNavigateAfterHome() async {
        let model=Explorer()
        let specimen=Specimen(id:UUID(),plantID:UUID(),title:"Test",subtitle:"",source:.init(imageName:"",origin:.example,date:Date()),analysis:StructuralAnalysis.evaluate(tree))
        model.select(specimen,image:nil);model.reveal();model.goHome()
        try? await Task.sleep(for:.seconds(2))
        XCTAssertEqual(model.stage,.home)
    }
    func testGrowthWaitsForParentAttachment() {
        let scheduled=GrowthSimulation.scheduled(tree)
        let parent=scheduled.branches[0],child=scheduled.branches[1]
        let time=child.birth ?? 0
        let parentProgress=GrowthSimulation.branchProgress(parent,graph:scheduled,progress:time)
        XCTAssertGreaterThanOrEqual(parentProgress,parent.fraction(nearest:child.start))
        XCTAssertEqual(GrowthSimulation.branchProgress(child,graph:scheduled,progress:time-0.001),0)
    }
    @MainActor func testRealPhotoAnalysisUsesImageOrReportsAnExplicitFailure() async throws {
        let store=SpecimenStore()
        let sample=try XCTUnwrap(store.examples.first)
        let image=try XCTUnwrap(store.image(for:sample))
        let data=try XCTUnwrap(image.jpegData(compressionQuality:0.9))
        do {
            let result=try await PhotoAnalyzer.analyze(data:data)
            XCTAssertGreaterThanOrEqual(result.result.graph.branches.count,4)
            XCTAssertNotEqual(result.result.graph,sample.analysis.graph)
            XCTAssertFalse(result.data.isEmpty)
        } catch let error as AnalysisFailure {
            XCTAssertTrue(error == .noStructure || error == .unavailable)
        }
    }

}
