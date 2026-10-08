import Foundation

struct LiveObservationGate {
    enum Decision:Equatable { case looking, settling, reveal, guidedExample }
    private(set) var stableFrames=0
    private(set) var frames=0
    private var previous:[Double]?
    private var previousCount=0
    private var stableSince:TimeInterval?
    private(set) var finished=false
    let timeout:TimeInterval
    init(timeout:TimeInterval=12) { self.timeout=timeout }
    mutating func consider(_ frame:LiveFrameEvidence?,elapsed:TimeInterval)->Decision {
        guard !finished else { return .looking }
        if let frame {
            frames += 1
            if frame.canReveal {
                if let previous,SceneGeometry.signatureDistance(previous,frame.signature)<0.028,abs(frame.graph.branches.count-previousCount)<max(3,previousCount/4) {
                    stableFrames += 1
                } else { stableFrames=1;stableSince=elapsed }
                previous=frame.signature;previousCount=frame.graph.branches.count
                if stableFrames>=4,elapsed-(stableSince ?? elapsed)>=1.6 { finished=true;return .reveal }
                
            } else { stableFrames=0;stableSince=nil;previous=nil }
        }
        if elapsed>=timeout { finished=true;return .guidedExample }
        return stableFrames>=2 ? .settling:.looking
    }
    var progress:Double { min(1,Double(stableFrames)/4) }
}
