import SwiftUI

struct HomeView:View {
    let store:SpecimenStore
    let explorer:Explorer
    var namespace:Namespace.ID
    var onSave:()->Void
    var onPatterns:()->Void
    @State private var showStory=false
    var body:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:28) {
                VStack(alignment:.leading,spacing:8) {
                    Text("See how the world repeats itself.").font(.title3).foregroundStyle(LensStyle.secondary)
                    hero
                }
                GlassGroup {
                    HStack(spacing:12) {
                        QuietButton(title:"Find a pattern",icon:"viewfinder",primary:true) { explorer.observe() }
                            .accessibilityIdentifier("findPattern")
                        Button {
                            let study=WorldLibrary.study("river"),image=study.image()
                            explorer.demo(study.specimen(),image:image,save:onSave)
                            explorer.imageData=image.jpegData(compressionQuality:0.92)
                        } label: { Image(systemName:"play.fill").frame(width:52,height:52).lensGlass(interactive:true) }
                        .buttonStyle(.plain).accessibilityLabel("A 30-second discovery").accessibilityIdentifier("playDemo")
                    }
                }
                VStack(alignment:.leading,spacing:16) {
                    sectionHeading("All around you",action:"Explore",onTap:onPatterns)
                    Text("Look beyond the leaf.").font(.subheadline).foregroundStyle(LensStyle.secondary)
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:16) {
                            ForEach([WorldLibrary.study("river"),WorldLibrary.study("shell"),WorldLibrary.study("coast"),WorldLibrary.study("windows")]) { study in
                                NavigationLink(value:study) {
                                    VStack(alignment:.leading,spacing:9) {
                                        WorldThumb(study:study).frame(width:158,height:158)
                                        Text(study.name).font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.foreground)
                                        Text(study.family.rawValue).font(.caption).foregroundStyle(LensStyle.secondary)
                                    }.frame(width:158,alignment:.leading)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                VStack(alignment:.leading,spacing:16) {
                    sectionHeading("The language of repetition",action:"See all",onTap:onPatterns)
                    HStack(spacing:14) {
                        ForEach([PatternLibrary.pattern("fern"),PatternLibrary.pattern("snow")]) { pattern in
                            NavigationLink(value:pattern) {
                                VStack(alignment:.leading,spacing:10) {
                                    PatternThumb(pattern:pattern)
                                    Text(pattern.family.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.foreground)
                                    Text(pattern.family.verb).font(.caption).foregroundStyle(LensStyle.secondary)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Button { showStory=true } label: {
                    HStack(spacing:16) {
                        Image(systemName:"book.pages").font(.title2).foregroundStyle(LensStyle.green)
                        VStack(alignment:.leading,spacing:4) { Text("A world from a single line").font(.headline);Text("A story in four small discoveries").font(.caption).foregroundStyle(LensStyle.secondary) }
                        Spacer();Image(systemName:"chevron.right").font(.caption.weight(.semibold))
                    }.padding(20).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:24))
                }.buttonStyle(.plain)
                if !store.specimens.isEmpty {
                    VStack(alignment:.leading,spacing:16) {
                        Text("Recently noticed").font(.title2.bold())
                        SpecimenGrid(items:Array(store.specimens.prefix(2)),example:false,store:store,explorer:explorer,namespace:namespace)
                    }
                }
                VStack(alignment:.leading,spacing:16) {
                    Text("From the living world").font(.title2.bold())
                    Text("Real photographs. A closer look at their structure.").font(.subheadline).foregroundStyle(LensStyle.secondary)
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:16) {
                            ForEach(store.examples) { item in
                                Button { explorer.select(item,image:store.image(for:item),detail:true) } label: {
                                    VStack(alignment:.leading,spacing:10) {
                                        if let image=store.image(for:item) {
                                            Image(uiImage:image).resizable().scaledToFill().frame(width:220,height:180).clipped().clipShape(RoundedRectangle(cornerRadius:24))
                                        }
                                        Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.foreground)
                                        Text("Curated example").font(.caption).foregroundStyle(LensStyle.secondary)
                                    }
                                }.buttonStyle(.plain).accessibilityIdentifier("example-\(item.exampleKey ?? "sample")")
                            }
                        }.padding(.bottom,4)
                    }.contentMargins(.horizontal,0)
                }
            }.padding(.horizontal,20).padding(.top,8).padding(.bottom,32)
        }.background(InstrumentBackdrop()).navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) { Button { showStory=true } label: { Image(systemName:"book") }.accessibilityLabel("Stories Of Plant") }
            }
            .navigationDestination(for:WorldStudy.self) { study in WorldStudyView(study:study,onReveal:{ explorer.openStudy(study) }) }
            .navigationDestination(for:RulePattern.self) { PatternStudyView(pattern:$0) }
            .sheet(isPresented:$showStory) { PatternStoryView() }
    }
    private var hero:some View {
        ZStack(alignment:.bottomLeading) {
            RoundedRectangle(cornerRadius:32).fill(LinearGradient(colors:[Color(red:0.86,green:0.93,blue:0.83),Color(red:0.93,green:0.96,blue:0.87)],startPoint:.topLeading,endPoint:.bottomTrailing))
            Circle().fill(.white.opacity(0.4)).frame(width:210,height:210).blur(radius:2).offset(x:135,y:-80)
            WorldArtwork(study:WorldLibrary.study("river"),lineWidth:1.7)
                .frame(width:200,height:200).offset(x:145,y:-112)
            WorldArtwork(study:WorldLibrary.study("shell"),lineWidth:1.0)
                .frame(width:100,height:100).offset(x:38,y:-195).opacity(0.8)
                .shadow(color:LensStyle.green.opacity(0.15),radius:12,x:0,y:8)
            VStack(alignment:.leading,spacing:8) {
                Label("A living lens",systemImage:"sparkle").font(.caption.weight(.semibold)).foregroundStyle(LensStyle.green)
                Text("The world\nis repeating.").font(.system(size:30,weight:.bold)).tracking(-0.8).lineSpacing(-1)
                Text("Point your lens. Follow the pattern.").font(.subheadline).foregroundStyle(LensStyle.secondary)
            }.padding(24)
        }.frame(height:310).clipShape(RoundedRectangle(cornerRadius:32)).padding(.top,12)
    }
    private func sectionHeading(_ title:String,action:String,onTap:@escaping()->Void)->some View {
        HStack { Text(title).font(.title2.bold());Spacer();Button(action,action:onTap).font(.subheadline.weight(.semibold)).tint(LensStyle.green).frame(minHeight:44) }
    }
}

struct CollectionView:View {
    let store:SpecimenStore
    let explorer:Explorer
    var namespace:Namespace.ID
    @State private var sort:Metric?=nil
    @State private var showExamples=true
    private var items:[Specimen] {
        guard let sort else { return store.specimens.sorted { ($0.savedAt ?? .distantPast)>($1.savedAt ?? .distantPast) } }
        func value(_ item:Specimen)->Double {
            let m=item.analysis.metrics
            switch sort { case .similarity:return m.similarity ?? -1;case .depth:return Double(m.depth);case .complexity:return m.complexity;case .density:return m.density;default:return 0 }
        }
        return store.specimens.sorted { value($0)>value($1) }
    }
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:26) {
                HStack {
                    VStack(alignment:.leading,spacing:6) {
                        Text("Your pattern collection").font(.title3.weight(.semibold))
                        Text("\(items.count) observed \(items.count==1 ? "structure":"structures")").font(.subheadline).foregroundStyle(LensStyle.secondary)
                    }
                    Spacer()
                    Menu {
                        Button("Recently observed") { sort=nil }
                        ForEach([Metric.similarity,.complexity,.depth,.density]) { metric in Button(metric.rawValue) { sort=metric } }
                    } label: { Image(systemName:"line.3.horizontal.decrease").frame(width:44,height:44).lensGlass(interactive:true) }.accessibilityLabel("Sort collection")
                }.padding(.top,8)
                if items.isEmpty {
                    VStack(spacing:20) {
                        PatternArtwork(pattern:PatternLibrary.pattern("tree"),generation:5,animate:false).frame(height:210)
                        Text("A collection starts\nwith a closer look.").font(.title2.bold()).multilineTextAlignment(.center)
                        QuietButton(title:"Find a pattern",icon:"viewfinder",primary:true) { explorer.observe() }
                    }.padding(24).background(.white.opacity(0.5),in:RoundedRectangle(cornerRadius:28))
                } else { SpecimenGrid(items:items,example:false,store:store,explorer:explorer,namespace:namespace) }
                VStack(alignment:.leading,spacing:16) {
                    HStack {
                        Text("Botanical examples").font(.title2.bold());Spacer()
                        Button { withAnimation(LensMotion.settle) { showExamples.toggle() } } label: { Image(systemName:showExamples ? "chevron.up":"chevron.down").frame(width:44,height:44) }.accessibilityLabel("Toggle curated examples")
                    }
                    Text("Six photographs, six different growth signatures.").font(.subheadline).foregroundStyle(LensStyle.secondary)
                    if showExamples { SpecimenGrid(items:store.examples,example:true,store:store,explorer:explorer,namespace:namespace) }
                }
            }.padding(20).padding(.bottom,20)
        }.background(InstrumentBackdrop()).navigationTitle("Collection")
    }
}

struct SpecimenGrid:View {
    let items:[Specimen]
    let example:Bool
    let store:SpecimenStore
    let explorer:Explorer
    let namespace:Namespace.ID
    var body:some View {
        LazyVGrid(columns:[GridItem(.flexible(),spacing:16),GridItem(.flexible(),spacing:16)],spacing:24) {
            ForEach(Array(items.enumerated()),id:\.element.id) { index,item in
                Button { explorer.select(item,image:store.image(for:item),detail:true) } label: {
                    VStack(alignment:.leading,spacing:9) {
                        ZStack {
                            RoundedRectangle(cornerRadius:26).fill(LensStyle.green.opacity(0.055))
                            GlyphView(graph:item.glyph,preserveOrientation:true).padding(8)
                                .matchedGeometryEffect(id:example ? "example-"+item.id.uuidString:item.id.uuidString,in:namespace)
                        }.aspectRatio(1,contentMode:.fit)
                        Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.foreground)
                        HStack {
                            Text(example ? "Example":item.source.origin == .guided ? "Guided study":item.source.date.formatted(date:.abbreviated,time:.omitted))
                            Spacer()
                            Text(item.comparesScales ? Metric.similarity.value(item.analysis.metrics):(item.evidence?.family.rawValue ?? "Structure")).foregroundStyle(LensStyle.green)
                        }.font(.caption).foregroundStyle(LensStyle.secondary)
                    }
                }.buttonStyle(.plain).accessibilityIdentifier(example ? "example-\(index)":"specimen-\(index)")
            }
        }
    }
}
