import XCTest
import UIKit
@testable import FractalLens

final class LiveObservationTests:XCTestCase {
    private func frame(signature:[Double]=[0.2,0.3,0.1,0.4],quality:Double=0.8)->LiveFrameEvidence {
        .init(data:Data(),graph:WorldLibrary.study("windows").graph,keyPoints:[],signature:signature,quality:quality,repetition:100,context:nil)
    }
    func testStableMultiFrameGateAndSingleCompletion() {
        var gate=LiveObservationGate()
        XCTAssertEqual(gate.consider(frame(),elapsed:0),.looking)
        XCTAssertEqual(gate.consider(frame(),elapsed:0.7),.settling)
        XCTAssertEqual(gate.consider(frame(),elapsed:1.4),.settling)
        XCTAssertEqual(gate.consider(frame(),elapsed:2.1),.reveal)
        XCTAssertEqual(gate.consider(frame(),elapsed:3),.looking)
        XCTAssertTrue(gate.finished)
    }
    func testMotionAndPoorEvidenceDoNotTriggerRecognition() {
        var gate=LiveObservationGate()
        for n in 0..<12 {
            let moving=frame(signature:n%2==0 ? [1,0,0,0]:[0,1,0,0])
            XCTAssertNotEqual(gate.consider(moving,elapsed:Double(n)*0.7),.reveal)
        }
        var blank=LiveObservationGate()
        for n in 0..<10 { XCTAssertEqual(blank.consider(frame(quality:0),elapsed:Double(n)),.looking) }
        XCTAssertEqual(blank.consider(nil,elapsed:12),.guidedExample)
    }
    func testTimeoutWithIntermittentSignalStillOpensLabelledExample() {
        var gate=LiveObservationGate()
        _=gate.consider(frame(),elapsed:10.9)
        XCTAssertEqual(gate.consider(frame(),elapsed:11.6),.settling)
        XCTAssertEqual(gate.consider(nil,elapsed:12),.guidedExample)
    }
    func testWorldStudiesDoNotConfuseRepetitionSpiralsAndFractals() {
        XCTAssertEqual(WorldLibrary.all.count,8)
        for study in WorldLibrary.all {
            let specimen=study.specimen()
            XCTAssertEqual(specimen.source.origin,.guided)
            XCTAssertEqual(specimen.analysis.evidence?.family,study.family)
            XCTAssertEqual(study.graph,study.graph)
            XCTAssertTrue(study.graph.allPoints.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
            if study.kind != .nested {
                XCTAssertNil(specimen.analysis.metrics.similarity)
                XCTAssertTrue(specimen.analysis.scaleRoots.isEmpty)
                XCTAssertFalse(specimen.comparesScales)
            }
        }
        XCTAssertEqual(WorldLibrary.study("windows").specimen().analysis.evidence?.repetition,100)
        XCTAssertNil(WorldLibrary.study("shell").specimen().analysis.evidence?.repetition)
    }
    @MainActor func testVisionContoursUseActualImageAndRejectBlankFrame() async throws {
        let study=WorldLibrary.study("windows")
        let data=try XCTUnwrap(study.image().jpegData(compressionQuality:0.9))
        let evidence=try await SceneAnalyzer.inspect(data:data,classify:false)
        XCTAssertTrue(evidence.canReveal)
        XCTAssertGreaterThan(evidence.graph.branches.count,8)
        XCTAssertNotEqual(evidence.graph,study.graph)
        XCTAssertNotNil(evidence.repetition)
        let output=try await SceneAnalyzer.analyze(data:data,liveFrames:4)
        XCTAssertNil(output.result.metrics.similarity)
        XCTAssertEqual(output.result.evidence?.frames,4)
        XCTAssertEqual(output.result.evidence?.isLive,true)
        let format=UIGraphicsImageRendererFormat();format.scale=1
        let blank=UIGraphicsImageRenderer(size:CGSize(width:320,height:320),format:format).image { context in UIColor.white.setFill();context.fill(CGRect(x:0,y:0,width:320,height:320)) }
        let empty=try await SceneAnalyzer.inspect(data:try XCTUnwrap(blank.jpegData(compressionQuality:0.9)),classify:false)
        XCTAssertFalse(empty.canReveal)
    }
    @MainActor func testNewEvidencePersistsAndOldArchiveStillDecodes() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:directory) }
        let store=SpecimenStore(directory:directory,loadExamples:false)
        let observation=WorldLibrary.study("windows").specimen()
        _=try store.save(observation,imageData:WorldLibrary.study("windows").image().jpegData(compressionQuality:0.9))
        let restored=try XCTUnwrap(SpecimenStore(directory:directory,loadExamples:false).specimens.first)
        XCTAssertEqual(restored.analysis.evidence,observation.analysis.evidence)
        XCTAssertFalse(restored.comparesScales)
        var json=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(observation.analysis)) as? [String:Any])
        json.removeValue(forKey:"evidence");json["version"]=1
        let old=try JSONDecoder().decode(AnalysisResult.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertNil(old.evidence);XCTAssertEqual(old.graph,observation.analysis.graph)
    }
    func testContourFittingPreservesAspectAndAllComponents() {
        let source=WorldLibrary.study("windows").graph
        let fit=source.fitted()
        XCTAssertEqual(fit.branches.count,source.branches.count)
        XCTAssertTrue(fit.allPoints.allSatisfy { (0.08...0.92).contains($0.x) && (0.08...0.92).contains($0.y) })
        XCTAssertEqual(fit.branches[0].length/source.branches[0].length,fit.branches[1].length/source.branches[1].length,accuracy:0.0001)
    }
}
