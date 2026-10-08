import SwiftUI

struct PatternAtlasView:View {
    var onWorldReveal:(WorldStudy)->Void = { _ in }
    @State private var section=0
    @State private var family:PatternFamily?=nil
    @State private var query=""
    @State private var showStory=false
    @State private var previewPattern=false
    @State private var previewHandled=false
    @State private var previewItem=PatternLibrary.all[0]
    private var patterns:[RulePattern] {
        PatternLibrary.all.filter { (family == nil || $0.family==family) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query)) }
    }
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:26) {
                Picker("Pattern library",selection:$section) { Text("In the world").tag(0);Text("Rule studies").tag(1) }.pickerStyle(.segmented).accessibilityIdentifier("patternLibrary")
                if section==0 { WorldAtlasContent(query:query,onReveal:onWorldReveal) }
                else {
                VStack(alignment:.leading,spacing:9) {
                    Text("Small rules.\nExtraordinary worlds.").font(.system(size:30,weight:.bold)).tracking(-0.7)
                    Text("Ten ways to see repetition, inspired by Stories Of Plant.").font(.subheadline).foregroundStyle(LensStyle.secondary)
                }.padding(.top,8)
                ScrollView(.horizontal,showsIndicators:false) {
                    GlassGroup(spacing:6) {
                        HStack(spacing:12) {
                            familyButton(nil,title:"All patterns")
                            ForEach(PatternFamily.allCases) { item in familyButton(item,title:item.rawValue) }
                        }.padding(.vertical,8)
                    }
                }.scrollClipDisabled().padding(.horizontal,-2)
                ForEach(PatternFamily.allCases.filter { group in patterns.contains { $0.family==group } }) { group in
                    VStack(alignment:.leading,spacing:16) {
                        HStack {
                            VStack(alignment:.leading,spacing:4) {
                                Text(group.rawValue).font(.title2.bold())
                                Text(group.verb).font(.caption).foregroundStyle(LensStyle.secondary)
                            }
                            Spacer()
                            Image(systemName:group.symbol).font(.title3).foregroundStyle(group.color)
                        }
                        LazyVGrid(columns:[GridItem(.flexible(),spacing:16),GridItem(.flexible(),spacing:16)],spacing:24) {
                            ForEach(patterns.filter { $0.family==group }) { pattern in
                                NavigationLink(value:pattern) {
                                    VStack(alignment:.leading,spacing:10) {
                                        PatternThumb(pattern:pattern)
                                        Text(pattern.name).font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.foreground)
                                        Text(pattern.subtitle).font(.caption).foregroundStyle(LensStyle.secondary)
                                    }
                                }.buttonStyle(.plain).accessibilityIdentifier("pattern-\(pattern.id)")
                            }
                        }
                    }
                }
                Button { showStory=true } label: {
                    HStack(spacing:14) {
                        Image(systemName:"book.pages").font(.title2)
                        VStack(alignment:.leading,spacing:4) { Text("The story of a rule").font(.headline);Text("From a line to a living structure").font(.caption).foregroundStyle(LensStyle.secondary) }
                        Spacer();Image(systemName:"chevron.right").font(.caption.weight(.semibold))
                    }.padding(20).background(.white.opacity(0.8),in:RoundedRectangle(cornerRadius:24))
                }.buttonStyle(.plain)
                }
            }.padding(.horizontal,20).padding(.bottom,28)
        }.background(InstrumentBackdrop()).navigationTitle("Patterns")
            .searchable(text:$query,prompt:"Find a pattern")
            .navigationDestination(for:RulePattern.self) { PatternStudyView(pattern:$0) }
            .navigationDestination(isPresented:$previewPattern) { PatternStudyView(pattern:previewItem) }
            .sheet(isPresented:$showStory) { PatternStoryView() }
            .task {
                #if DEBUG
                if !previewHandled,let argument=ProcessInfo.processInfo.arguments.first(where:{$0.hasPrefix("--pattern=")}) {
                    previewHandled=true;section=1
                    let id=String(argument.dropFirst(10))
                    if id != "atlas" { previewItem=PatternLibrary.pattern(id);previewPattern=true }
                }
                #endif
            }
    }
    @ViewBuilder private func familyButton(_ item:PatternFamily?,title:String)->some View {
        Button { withAnimation(LensMotion.settle) { family=item } } label: {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal,14).frame(height:40)
                .foregroundStyle(family==item ? .white:LensStyle.foreground)
                .lensGlass(tint:family==item ? LensStyle.green:nil,interactive:true)
        }.buttonStyle(.plain)
    }
}

struct PatternStudyView:View {
    let pattern:RulePattern
    @State private var generation=0
    @State private var running=false
    @State private var showMotif=false
    @State private var showStory=false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var controls
    var body:some View {
        GeometryReader { proxy in
            VStack(spacing:0) {
                VStack(alignment:.leading,spacing:8) {
                    Text(pattern.family.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(pattern.color)
                    Text(pattern.subtitle).font(.system(size:30,weight:.bold)).tracking(-0.7)
                    Text("A rule study · Stories Of Plant").font(.caption).foregroundStyle(LensStyle.secondary)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,24).padding(.top,14)
                ZStack {
                    Ellipse().fill(pattern.color.opacity(0.055)).blur(radius:45).padding(40)
                    PatternArtwork(pattern:pattern,generation:generation,lineWidth:1.65)
                        .scaleEffect(showMotif && !reduceMotion ? 1.8:1)
                        .animation(LensMotion.settle,value:showMotif)
                    VStack {
                        Spacer()
                        HStack {
                            Label(showMotif ? "Looking closer":"Whole structure",systemImage:showMotif ? "plus.magnifyingglass":"viewfinder")
                            Spacer()
                            Text("Generation \(generation)").monospacedDigit()
                        }.font(.caption).foregroundStyle(LensStyle.secondary).padding(.horizontal,28).padding(.bottom,10)
                    }
                }.frame(maxWidth:.infinity,maxHeight:.infinity).clipped()
                studyControls
                VStack(alignment:.leading,spacing:8) {
                    Text(generation==pattern.minimum ? "Start with a simple gesture.":generation<pattern.showcase ? "The same gesture, repeated.":"Small rules become a whole world.")
                        .font(.headline).contentTransition(.opacity)
                    Text(pattern.insight).font(.subheadline).foregroundStyle(LensStyle.secondary).fixedSize(horizontal:false,vertical:true)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,24).padding(.top,22).padding(.bottom,24)
            }
        }.background(InstrumentBackdrop())
            .navigationTitle(pattern.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button { showStory=true } label: { Image(systemName:"info") }.accessibilityLabel("About this pattern")
                }
            }
            .toolbar(.hidden,for:.tabBar)
            .onAppear {
                generation=pattern.minimum;running=true
                #if DEBUG
                if let argument=ProcessInfo.processInfo.arguments.first(where:{$0.hasPrefix("--generation=")}),let level=Int(argument.dropFirst(13)) {
                    generation=min(pattern.maximum,max(pattern.minimum,level));running=false
                }
                #endif
            }
            .task(id:running) {
                guard running else { return }
                while !Task.isCancelled {
                    do { try await Task.sleep(for:.seconds(reduceMotion ? 2.0:2.2)) } catch { return }
                    guard running else { return }
                    if scenePhase != .active { continue }
                    if generation>=pattern.showcase { running=false;return }
                    generation += 1
                }
            }
            .sheet(isPresented:$showStory) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment:.leading,spacing:24) {
                            PatternArtwork(pattern:pattern,generation:pattern.showcase,animate:false).frame(height:250)
                            Text(pattern.name).font(.largeTitle.bold())
                            Text(pattern.insight).font(.title3)
                            Label("Look for it in nature",systemImage:"leaf").font(.headline).foregroundStyle(pattern.color)
                            Text(pattern.nature).foregroundStyle(LensStyle.secondary)
                            Text("This is a generated rule study. Real plants repeat with variation; their structure is explored through observed photographs in Discover.").font(.footnote).foregroundStyle(LensStyle.secondary)
                            Text("Adapted from your Stories Of Plant playground.").font(.caption).foregroundStyle(LensStyle.secondary)
                        }.padding(24)
                    }.background(InstrumentBackdrop()).navigationTitle("Pattern notes").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { showStory=false } } }
                }.presentationDetents([.large])
            }
    }
    private var studyControls:some View {
        VStack(spacing:16) {
            HStack(spacing:6) {
                ForEach(pattern.minimum...pattern.maximum,id:\.self) { level in
                    Button { running=false;generation=level } label: {
                        Capsule().fill(level<=generation ? pattern.color:pattern.color.opacity(0.13))
                            .frame(height:4).frame(maxWidth:.infinity,minHeight:44)
                    }.accessibilityLabel("Generation \(level)")
                }
            }.padding(.horizontal,26)
            GlassGroup {
                HStack(spacing:14) {
                    Button { running=false;generation=pattern.minimum } label: {
                        Image(systemName:"arrow.counterclockwise").frame(width:48,height:48).lensGlass(interactive:true)
                    }.accessibilityLabel("Restart pattern")
                    Button {
                        if generation>=pattern.showcase { generation=pattern.minimum }
                        running.toggle()
                    } label: {
                        Label(running ? "Pause":"Watch it grow",systemImage:running ? "pause.fill":"play.fill")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth:.infinity).frame(height:48)
                            .lensGlass(tint:pattern.color.opacity(0.12),interactive:true)
                    }.accessibilityIdentifier("playPattern")
                    Button { withAnimation(LensMotion.settle) { showMotif.toggle() } } label: {
                        Image(systemName:showMotif ? "arrow.down.right.and.arrow.up.left":"plus.magnifyingglass").frame(width:48,height:48).lensGlass(interactive:true)
                    }.accessibilityLabel("Look closer at pattern")
                }.buttonStyle(.plain).padding(.horizontal,24)
            }
            Button { running=false;generation=min(pattern.maximum,generation+1) } label: {
                Label("One more repetition",systemImage:"plus").font(.subheadline.weight(.semibold)).frame(minHeight:44)
            }.tint(pattern.color).disabled(generation>=pattern.maximum).accessibilityIdentifier("nextGeneration")
        }
    }
}

struct PatternStoryView:View {
    @Environment(\.dismiss) private var dismiss
    @State private var chapter=0
    private let titles=["A small beginning.","Repeat the gesture.","Let it branch.","Look at the whole."]
    private let copies=["Begin with one line. A direction and a single step are enough.","Replace each line with the same smaller gesture. Do it again. Complexity arrives through repetition.","Remember a point, grow a side branch, then return. One path becomes many connected paths.","The part carries an echo of the whole. In living plants, that echo includes difference and variation."]
    var body:some View {
        NavigationStack {
            VStack(alignment:.leading,spacing:16) {
                HStack { Text("Stories Of Plant").font(.subheadline.weight(.semibold)).foregroundStyle(LensStyle.green);Spacer();Text("\(chapter+1) of 4").font(.subheadline).foregroundStyle(LensStyle.secondary) }.padding(.top,20)
                Text(titles[chapter]).font(.largeTitle.bold()).contentTransition(.opacity)
                PatternArtwork(pattern:PatternLibrary.pattern(chapter<2 ? "snow":"fern"),generation:chapter==0 ? 0:chapter==1 ? 2:chapter==2 ? 2:4).id(chapter<2).frame(maxHeight:.infinity)
                Text(copies[chapter]).font(.title3).foregroundStyle(LensStyle.secondary).fixedSize(horizontal:false,vertical:true)
                HStack {
                    ForEach(0..<4) { index in Circle().fill(index==chapter ? LensStyle.green:LensStyle.muted).frame(width:6,height:6) }
                    Spacer()
                    QuietButton(title:chapter==3 ? "Keep exploring":"Continue",icon:"arrow.right",primary:true) {
                        if chapter==3 { dismiss() } else { withAnimation(LensMotion.settle) { chapter += 1 } }
                    }.frame(width:180)
                }.padding(.top,16).padding(.bottom,20)
            }.padding(.horizontal,24).background(InstrumentBackdrop())
                .navigationTitle("The story of a rule").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
