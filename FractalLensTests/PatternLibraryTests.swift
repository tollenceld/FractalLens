import XCTest
@testable import FractalLens

final class PatternLibraryTests:XCTestCase {
    func testLibraryPreservesTenDistinctStudiesAndFourFamilies() {
        XCTAssertEqual(PatternLibrary.all.count,10)
        XCTAssertEqual(Set(PatternLibrary.all.map(\.id)).count,10)
        XCTAssertEqual(Set(PatternLibrary.all.map(\.family)).count,4)
        for pattern in PatternLibrary.all {
            let geometry=RuleInterpreter.geometry(pattern,generation:pattern.showcase)
            XCTAssertGreaterThan(geometry.segments.count,20,pattern.id)
            XCTAssertTrue(geometry.distance.isFinite,pattern.id)
            XCTAssertTrue(geometry.segments.allSatisfy { segment in
                [segment.from.x,segment.from.y,segment.to.x,segment.to.y].allSatisfy { $0.isFinite && $0>=0.08-0.0001 && $0<=0.92+0.0001 }
            },pattern.id)
            XCTAssertEqual(geometry.segments,RuleInterpreter.geometry(pattern,generation:pattern.showcase).segments,pattern.id)
        }
    }
    func testKochEdgeReplacementHasFourChildrenAndClosedOutline() {
        let snow=PatternLibrary.pattern("snow")
        for generation in 0...4 {
            let geometry=RuleInterpreter.geometry(snow,generation:generation)
            XCTAssertEqual(geometry.segments.count,3*Int(pow(4.0,Double(generation))))
            XCTAssertLessThan(geometry.segments.first!.from.distance(to:geometry.segments.last!.to),0.000001)
            XCTAssertFalse(geometry.isBranched)
        }
    }
    func testTurtleRestoresBranchOriginAndArrivalTime() {
        let pattern=RulePattern(id:"test",name:"Test",family:.branching,subtitle:"",insight:"",nature:"",axiom:"F[+F]F",rules:[:],drawn:["F"],moved:[],angle:45,heading:-90,minimum:0,maximum:1,showcase:0)
        let geometry=RuleInterpreter.geometry(pattern,generation:0)
        XCTAssertEqual(geometry.segments.count,3)
        XCTAssertEqual(geometry.segments[1].from,geometry.segments[2].from)
        XCTAssertEqual(geometry.segments[1].depth,1)
        XCTAssertEqual(geometry.segments[2].depth,0)
        XCTAssertEqual(geometry.segments[1].distance,geometry.segments[2].distance)
    }
    func testPlaygroundSemanticsIncludeDrawnXAndIgnoredLowercaseF() {
        let weed=PatternLibrary.pattern("weed")
        XCTAssertEqual(RuleInterpreter.geometry(weed,generation:0).segments.count,1)
        let frond=PatternLibrary.pattern("frond")
        XCTAssertFalse(frond.drawn.contains("f"));XCTAssertFalse(frond.moved.contains("f"))
        XCTAssertEqual(PatternLibrary.pattern("dragon").angle,30)
    }
}
