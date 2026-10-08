import SwiftUI

enum LensStyle {
    static let background=Color(red:0.965,green:0.971,blue:0.952)
    static let foreground=Color(red:0.13,green:0.21,blue:0.19)
    static let secondary=Color(red:0.40,green:0.47,blue:0.43)
    static let green=Color(red:0.13,green:0.48,blue:0.36)
    static let muted=Color(red:0.83,green:0.91,blue:0.83)
    static let blue=Color(red:0.22,green:0.49,blue:0.68)
    static func label(_ size:CGFloat=11)->Font { .system(size:size,weight:.medium) }
}
struct Eyebrow:View {
    var text:String
    var body:some View { Text(text).font(LensStyle.label()).foregroundStyle(LensStyle.secondary) }
}
struct QuietButton:View {
    var title:String
    var icon:String?=nil
    var primary=false
    var action:()->Void
    var body:some View {
        if #available(iOS 26, *) {
            if primary { content.buttonStyle(.glassProminent).tint(LensStyle.green).foregroundStyle(.white) }
            else { content.buttonStyle(.glass) }
        } else { content.buttonStyle(.bordered).tint(LensStyle.green) }
    }
    private var content:some View {
        Button(action:action) {
            HStack(spacing:9) {
                Text(title).font(.system(size:15,weight:.semibold))
                if let icon { Image(systemName:icon).font(.system(size:14,weight:.semibold)) }
            }.frame(maxWidth:primary ? .infinity:nil,minHeight:36).padding(.horizontal,primary ? 10:2)
        }
    }
}
struct GlassGroup<Content:View>:View {
    var spacing:CGFloat=18
    @ViewBuilder var content:()->Content
    var body:some View {
        if #available(iOS 26, *) { GlassEffectContainer(spacing:spacing) { content() } }
        else { content() }
    }
}
struct LensGlass:ViewModifier {
    var tint:Color?=nil
    var interactive=false
    func body(content:Content)->some View {
        if #available(iOS 26, *) {
            content.glassEffect(interactive ? .regular.tint(tint ?? .clear).interactive():.regular.tint(tint ?? .clear),in:.capsule)
        } else { content.background(.regularMaterial,in:Capsule()) }
    }
}
extension View {
    func lensGlass(tint:Color?=nil,interactive:Bool=false)->some View { modifier(LensGlass(tint:tint,interactive:interactive)) }
}
struct LensMark:View {
    var body:some View { Image(systemName:"leaf.fill").font(.system(size:19,weight:.medium)).foregroundStyle(LensStyle.green).accessibilityHidden(true) }
}
struct InstrumentBackdrop:View {
    var body:some View {
        ZStack {
            LensStyle.background
            RadialGradient(colors:[LensStyle.muted.opacity(0.50),.clear],center:.init(x:0.72,y:0.35),startRadius:5,endRadius:400)
            RadialGradient(colors:[Color.white.opacity(0.9),.clear],center:.init(x:0.05,y:0.75),startRadius:1,endRadius:380)
        }.ignoresSafeArea()
    }
}
enum LensMotion {
    static let settle=Animation.spring(response:0.72,dampingFraction:0.86)
    static let reveal=Animation.timingCurve(0.22,0.0,0.18,1.0,duration:1.35)
    static func smooth(_ t:Double)->Double { let x=min(1,max(0,t));return x*x*(3-2*x) }
    static func revealProgress(_ time:Double)->Double {
        let target=min(1,max(0,time))
        func bezier(_ t:Double,_ a:Double,_ b:Double)->Double { 3*(1-t)*(1-t)*t*a+3*(1-t)*t*t*b+t*t*t }
        var low=0.0,high=1.0
        for _ in 0..<14 { let midpoint=(low+high)/2;if bezier(midpoint,0.22,0.18)<target { low=midpoint } else { high=midpoint } }
        return bezier((low+high)/2,0,1)
    }
}
