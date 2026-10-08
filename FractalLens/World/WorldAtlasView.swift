import SwiftUI

struct WorldArtwork:View {
    let study:WorldStudy
    var progress:Double=1
    var lineWidth:Double=1.15
    var body:some View {
        ZStack {
            Ellipse().fill(study.family.color.opacity(0.05)).blur(radius:30).padding(24)
            StructureCanvas(graph:study.graph,progress:progress,color:study.family.color,lineWidth:lineWidth)
        }.accessibilityHidden(true)
    }
}
struct WorldThumb:View {
    let study:WorldStudy
    var body:some View {
        WorldArtwork(study:study).aspectRatio(1,contentMode:.fit)
            .background(study.family.color.opacity(0.055),in:RoundedRectangle(cornerRadius:26))
    }
}
struct WorldAtlasContent:View {
    var query=""
    var onReveal:(WorldStudy)->Void
    @State private var family:WorldFamily?
    private var studies:[WorldStudy] { WorldLibrary.all.filter { (family==nil || $0.family==family) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.family.rawValue.localizedCaseInsensitiveContains(query)) } }
    var body:some View {
        VStack(alignment:.leading,spacing:26) {
            VStack(alignment:.leading,spacing:8) {
                Text("Patterns are\neverywhere.").font(.system(size:30,weight:.bold)).tracking(-0.7)
                Text("From a river basin to the street you live on.").font(.subheadline).foregroundStyle(LensStyle.secondary)
            }
            ScrollView(.horizontal,showsIndicators:false) {
                GlassGroup(spacing:6) {
                    HStack(spacing:12) {
                        filter(nil,title:"All around us")
                        ForEach(WorldFamily.allCases) { f in filter(f,title:f.rawValue) }
                    }.padding(.vertical,8)
                }
            }.scrollClipDisabled()
            ForEach(WorldFamily.allCases.filter { f in studies.contains { $0.family==f } }) { family in
                VStack(alignment:.leading,spacing:16) {
                    HStack { VStack(alignment:.leading,spacing:4) { Text(family.rawValue).font(.title2.bold());Text(family.invitation).font(.caption).foregroundStyle(LensStyle.secondary) };Spacer();Image(systemName:family.symbol).foregroundStyle(family.color) }
                    LazyVGrid(columns:[GridItem(.flexible(),spacing:16),GridItem(.flexible(),spacing:16)],spacing:24) {
                        ForEach(studies.filter { $0.family==family }) { study in
                            NavigationLink(value:study) {
                                VStack(alignment:.leading,spacing:10) {
                                    WorldThumb(study:study)
                                    Text(study.name).font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.foreground)
                                    Text(study.place).font(.caption).foregroundStyle(LensStyle.secondary)
                                }
                            }.buttonStyle(.plain).accessibilityIdentifier("world-\(study.id)")
                        }
                    }
                }
            }
            VStack(alignment:.leading,spacing:9) {
                Label("Repetition is the beginning",systemImage:"sparkle").font(.headline)
                Text("A fractal echoes across scales. A repeating tile or a spiral is a useful pattern to notice, even when there is no fractal evidence.").font(.subheadline).foregroundStyle(LensStyle.secondary)
                Text("These are original illustrated studies. Your camera observations use their own image evidence.").font(.caption).foregroundStyle(LensStyle.secondary)
            }.padding(20).background(.white.opacity(0.65),in:RoundedRectangle(cornerRadius:24))
        }.navigationDestination(for:WorldStudy.self) { study in WorldStudyView(study:study,onReveal:{ onReveal(study) }) }
    }
    private func filter(_ f:WorldFamily?,title:String)->some View {
        Button { withAnimation(LensMotion.settle) { family=f } } label: {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal,14).frame(height:40)
                .foregroundStyle(family==f ? .white:LensStyle.foreground).lensGlass(tint:family==f ? (f?.color ?? LensStyle.green):nil,interactive:true)
        }.buttonStyle(.plain)
    }
}
struct WorldStudyView:View {
    let study:WorldStudy
    var onReveal:()->Void
    @State private var began=Date()
    @State private var trace=false
    @State private var closer=false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    var body:some View {
        VStack(spacing:0) {
            VStack(alignment:.leading,spacing:8) {
                Text(study.place).font(.subheadline).foregroundStyle(study.family.color)
                Text(study.question).font(.system(size:28,weight:.bold)).tracking(-0.6)
                Text("Illustrated study · \(study.kind == .nested ? "Across scales":"A pattern to notice")").font(.caption).foregroundStyle(LensStyle.secondary)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,24).padding(.top,14)
            TimelineView(.animation(minimumInterval:1/60,paused:!trace || reduceMotion || phase != .active)) { time in
                let t=trace ? min(1,max(0,time.date.timeIntervalSince(began)/3)):1
                WorldArtwork(study:study,progress:reduceMotion ? 1:t,lineWidth:1.8)
                    .scaleEffect(closer && !reduceMotion ? 1.65:1).animation(LensMotion.settle,value:closer)
                    .overlay(alignment:.bottom) { Text(closer ? "Look at the smaller gesture":"Follow the shape with your eye").font(.caption).foregroundStyle(LensStyle.secondary).padding(.bottom,18) }
            }.id(began).frame(maxWidth:.infinity,maxHeight:.infinity).clipped()
            GlassGroup {
                HStack(spacing:16) {
                    Button { began=Date();trace=true } label: { Label("Trace",systemImage:"play").frame(minHeight:44).padding(.horizontal,16).lensGlass(interactive:true) }.buttonStyle(.plain)
                    Button { closer.toggle() } label: { Label(closer ? "Whole":"Closer",systemImage:closer ? "arrow.down.right.and.arrow.up.left":"plus.magnifyingglass").frame(minHeight:44).padding(.horizontal,16).lensGlass(interactive:true) }.buttonStyle(.plain)
                }
            }.padding(.bottom,22)
            VStack(alignment:.leading,spacing:12) {
                Text(study.kind.explanation).font(.headline)
                Text(study.insight).font(.subheadline).foregroundStyle(LensStyle.secondary)
                QuietButton(title:"Reveal this study",icon:"arrow.right",primary:true,action:onReveal).accessibilityIdentifier("revealWorldStudy")
            }.padding(.horizontal,24).padding(.bottom,24)
        }.background(InstrumentBackdrop()).navigationTitle(study.name).navigationBarTitleDisplayMode(.inline).toolbar(.hidden,for:.tabBar)
    }
}
