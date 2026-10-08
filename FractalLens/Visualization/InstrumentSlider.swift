import SwiftUI

struct InstrumentSlider:View {
    @Binding var value:Double
    var range:ClosedRange<Double>
    var step:Double=0.01
    var label:String
    var onCommit:()->Void = {}
    var body:some View {
        Slider(value:$value,in:range,step:step,onEditingChanged:{ editing in if !editing { onCommit() } })
            .tint(LensStyle.green).accessibilityLabel(label).frame(minHeight:44)
    }
}
