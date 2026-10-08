import SwiftUI

struct ExperienceView:View {
    let store:SpecimenStore
    @Bindable var explorer:Explorer
    var namespace:Namespace.ID
    var onSave:()->Void
    @State private var resultVisible=false
    @State private var showSource=false
    private var item:Specimen? { explorer.specimen }
    private var hierarchical:Bool { item?.comparesScales ?? true }
    private var stage:LensStage { explorer.stage }
    var body:some View {
        VStack(spacing:0) {
            VStack(alignment:.leading,spacing:9) {
                Eyebrow(text:chapter)
                Text(title).font(.system(size:30,weight:.bold)).tracking(-0.7)
                    .contentTransition(.opacity).accessibilityAddTraits(.isHeader)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,28).padding(.top,12)
            StageArtwork(explorer:explorer)
                .matchedGeometryEffect(id:item?.id.uuidString ?? "stage",in:namespace)
                .frame(maxWidth:.infinity,maxHeight:.infinity).padding(.horizontal,12).padding(.top,8)
            GlassGroup { footer }.padding(.horizontal,24).padding(.bottom,16)
        }
        .background(InstrumentBackdrop())
        .navigationTitle(stage == .detail ? "Discovery":"A closer look").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement:.topBarLeading) {
                Button { explorer.goHome() } label: { Image(systemName:"xmark") }.accessibilityLabel("Return to collection")
            }
            ToolbarItem(placement:.topBarTrailing) {
                Button { showSource=true } label: { Image(systemName:"ellipsis") }.accessibilityLabel("Specimen source and information")
            }
        }
        .task(id:stage) {
            resultVisible=false
            if stage == .align { try? await Task.sleep(for:.seconds(explorer.reduceMotion ? 0.3:2.8));guard !Task.isCancelled else { return };withAnimation(.easeIn(duration:0.7)) { resultVisible=true };UIImpactFeedbackGenerator(style:.soft).impactOccurred() }
        }
        .sheet(isPresented:$showSource) { sourceSheet.presentationDetents([.medium,.large]).presentationDragIndicator(.visible) }
    }
    private var chapter:String {
        switch stage {
        case .capture:return "Observe"
        case .skeleton:return "Reveal the structure"
        case .dive:return "Whole → Branch → Twig"
        case .align:return "Across three scales"
        case .profile:return hierarchical ? "Structural fingerprint":"Image evidence"
        case .replay:return hierarchical ? "Replay growth":"Replay the trace"
        case .alter:return "Living syntax"
        case .detail:return item?.source.origin == .guided ? "An illustrated study":item?.source.origin == .example ? "From the field · Example":"From your collection"
        default:return ""
        }
    }
    private var title:String {
        switch stage {
        case .capture:return "Look closer."
        case .skeleton:return "Beneath the surface."
        case .dive:return "A world within."
        case .align:return (item?.analysis.metrics.similarity ?? 0)>65 ? "A familiar pattern.":"A different rhythm."
        case .profile:return hierarchical ? "A living signature.":(item?.evidence?.kind.title ?? "A noticed shape.")
        case .replay:return hierarchical ? "Now replay the rule.":"Follow it once more."
        case .alter:return "What if it changed?"
        case .detail:return item?.title ?? "A new observation"
        default:return ""
        }
    }
    @ViewBuilder private var footer:some View {
        switch stage {
        case .capture:
            VStack(alignment:.leading,spacing:16) {
                originLine
                Text(hierarchical ? "Every branch holds a smaller story.":"A familiar shape becomes a way of seeing.").font(.system(size:16,weight:.light)).foregroundStyle(LensStyle.secondary)
                QuietButton(title:"Reveal the structure",icon:"arrow.right",primary:true) { explorer.reveal() }.accessibilityIdentifier("revealStructure")
            }
        case .skeleton:
            VStack(spacing:15) {
                HStack { Eyebrow(text:"Surface → Structure");Spacer();Image(systemName:"arrow.up.right").font(.system(size:12)).foregroundStyle(LensStyle.green) }
                Text("Follow the line from its beginning.").font(.system(size:14)).foregroundStyle(LensStyle.secondary).frame(maxWidth:.infinity,alignment:.leading)
                QuietButton(title:hierarchical ? "Look across scales":"See the evidence",icon:"arrow.right",primary:true) { explorer.manual(hierarchical ? .dive:.profile) }
            }
        case .dive:
            VStack(spacing:22) {
                scalePicker
                Text(explorer.selectedScale==0 ? "Begin with the whole.":explorer.selectedScale==1 ? "A branch carries the same rhythm.":"And inside it, another.").font(.system(size:15,weight:.light)).foregroundStyle(LensStyle.secondary)
                QuietButton(title:"Bring them together",icon:"arrow.down.right.and.arrow.up.left",primary:true) { explorer.manual(.align) }.accessibilityIdentifier("alignScales")
            }
        case .align:
            VStack(alignment:.leading,spacing:14) {
                HStack(alignment:.firstTextBaseline) {
                    VStack(alignment:.leading,spacing:7) { Eyebrow(text:"Self similarity");Text("Estimated across \(explorer.scales.count) scales").font(.system(size:11)).foregroundStyle(LensStyle.secondary) }
                    Spacer()
                    Text(item.map { Metric.similarity.value($0.analysis.metrics) } ?? "—").font(.system(size:48,weight:.medium,design:.rounded)).tracking(-2).foregroundStyle(LensStyle.green)
                }.opacity(resultVisible ? 1:0)
                Text((item?.analysis.metrics.similarity ?? 0)>65 ? "A pattern repeats across scales.":"Each scale holds its own differences.").font(.system(size:15,weight:.light)).foregroundStyle(LensStyle.secondary).opacity(resultVisible ? 1:0)
                HStack(spacing:22) {
                    QuietButton(title:"Profile",icon:"plus") { explorer.manual(.profile) }
                    QuietButton(title:"Replay the rule",icon:"arrow.right",primary:true) { explorer.manual(.replay) }.accessibilityIdentifier("replayRule")
                }
            }
        case .profile:
            if hierarchical { profileFooter } else { evidenceFooter }
        case .replay:
            VStack(spacing:16) {
                if hierarchical { HStack {
                    ruleLabel("ANGLE",value:String(format:"%.0f°",explorer.rules.angle))
                    Spacer();ruleLabel("SCALE",value:String(format:"%.2f",explorer.rules.scale))
                    Spacer();ruleLabel("DEPTH",value:String(explorer.rules.depth))
                } } else { Text("Replaying the extracted paths. No growth rule is inferred.").font(.subheadline).foregroundStyle(LensStyle.secondary) }
                playbackControls
                if hierarchical { QuietButton(title:"What if the rule changed?",icon:"arrow.right",primary:true) { explorer.manual(.alter) }.accessibilityIdentifier("alterRule") } else { QuietButton(title:"Back to the evidence",icon:"arrow.left",primary:true) { explorer.manual(.profile) } }
                saveRow
            }
        case .alter:
            alterFooter
        case .detail:
            detailFooter
        default:EmptyView()
        }
    }
    private var originLine:some View {
        HStack(spacing:7) {
            Circle().fill(LensStyle.green).frame(width:4,height:4)
            Text(item?.sourceLabel ?? "On-device observation")
                .font(.caption).foregroundStyle(LensStyle.secondary)
        }
    }
    private var scalePicker:some View {
        HStack(spacing:0) {
            ForEach(Array(explorer.scales.indices),id:\.self) { index in
                if index>0 { Rectangle().fill(LensStyle.secondary.opacity(0.35)).frame(width:25,height:0.5) }
                Button { explorer.chooseScale(index) } label: {
                    Text(["Whole","Branch","Twig"][min(index,2)]).font(.system(size:14,weight:.semibold)).foregroundStyle(explorer.selectedScale==index ? LensStyle.green:LensStyle.secondary)
                        .frame(maxWidth:.infinity,minHeight:48)
                }.accessibilityIdentifier("scale-\(index)")
            }
        }.padding(.horizontal,6).lensGlass()
    }
    private var evidenceFooter:some View {
        VStack(alignment:.leading,spacing:16) {
            HStack(spacing:12) {
                ForEach(EvidenceFocus.allCases) { focus in
                    Button { explorer.selectedEvidence=focus;UISelectionFeedbackGenerator().selectionChanged() } label: {
                        VStack(alignment:.leading,spacing:6) {
                            Text(focus == .contours ? "\(item?.analysis.graph.branches.count ?? 0)":focus == .keyPoints ? "\(item?.evidence?.keyPoints.count ?? 0)":item?.evidence?.repetition.map { "\(Int($0.rounded()))%" } ?? "—")
                                .font(.system(size:27,weight:.medium,design:.rounded)).foregroundStyle(explorer.selectedEvidence==focus ? LensStyle.green:LensStyle.foreground)
                            Text(focus.rawValue).font(.caption).foregroundStyle(LensStyle.secondary)
                        }.frame(maxWidth:.infinity,minHeight:64,alignment:.leading)
                    }.buttonStyle(.plain).accessibilityIdentifier("evidence-\(focus.rawValue)")
                }
            }
            Text(item?.evidence?.kind.explanation ?? "The image is the evidence.").font(.subheadline).foregroundStyle(LensStyle.secondary)
            originLine
            if item?.evidence?.isLive == true { Text("Noticed across \(item?.evidence?.frames ?? 0) video frames").font(.caption).foregroundStyle(LensStyle.secondary) }
            QuietButton(title:"Replay the trace",icon:"play",primary:true) { explorer.manual(.replay) }.accessibilityIdentifier("replayTrace")
            saveRow
        }
    }
    private var profileFooter:some View {
        VStack(alignment:.leading,spacing:14) {
            Text(explorer.selectedMetric.explanation).font(.system(size:14,weight:.light)).foregroundStyle(LensStyle.secondary)
            LazyVGrid(columns:[GridItem(.flexible(),alignment:.leading),GridItem(.flexible(),alignment:.leading),GridItem(.flexible(),alignment:.leading)],spacing:16) {
                ForEach(Metric.allCases) { metric in
                    Button { explorer.selectedMetric=metric;UISelectionFeedbackGenerator().selectionChanged() } label: {
                        VStack(alignment:.leading,spacing:6) {
                            Text(item.map { metric.value($0.analysis.metrics) } ?? "—").font(.system(size:24,weight:.light)).foregroundStyle(explorer.selectedMetric==metric ? LensStyle.green:LensStyle.foreground)
                            Text(metric.rawValue).font(.system(size:10)).foregroundStyle(LensStyle.secondary)
                        }.frame(maxWidth:.infinity,minHeight:50,alignment:.leading)
                    }.accessibilityIdentifier("metric-\(metric.id)")
                }
            }
            QuietButton(title:"Replay growth",icon:"arrow.right",primary:true) { explorer.manual(.replay) }
        }
    }
    private var playbackControls:some View {
        TimelineView(.animation(minimumInterval:1/15,paused:!explorer.isPlaying || !explorer.isActive)) { time in
            let progress=explorer.replayProgress(at:time.date)
            HStack(spacing:12) {
                Button { explorer.togglePlayback() } label: { Image(systemName:explorer.isPlaying && progress<1 ? "pause":"play").font(.system(size:13)).frame(width:32,height:44) }.accessibilityLabel("Pause or resume growth")
                InstrumentSlider(value:Binding(get:{ progress },set:{ explorer.scrub($0) }),range:0...1,label:"Growth progress").frame(height:44)
                Button { explorer.replay() } label: { Image(systemName:"arrow.counterclockwise").font(.system(size:13)).frame(width:32,height:44) }.accessibilityLabel("Restart growth")
            }
        }
    }
    private var alterFooter:some View {
        VStack(spacing:14) {
            HStack(spacing:0) {
                ForEach([Metric.angle,.scale,.depth]) { metric in
                    Button { explorer.selectedRule=metric } label: { Text(metric.rawValue).font(.system(size:12,weight:.semibold)).foregroundStyle(explorer.selectedRule==metric ? LensStyle.green:LensStyle.secondary).frame(maxWidth:.infinity,minHeight:44) }
                }
            }.lensGlass()
            HStack(alignment:.firstTextBaseline) {
                Text(originalRuleValue).font(.system(size:23,weight:.light)).foregroundStyle(LensStyle.secondary)
                Image(systemName:"arrow.right").font(.system(size:12)).foregroundStyle(LensStyle.secondary)
                Text(currentRuleValue).font(.system(size:34,weight:.light)).foregroundStyle(LensStyle.green).contentTransition(.numericText())
                Spacer()
                Button("Reset") { explorer.resetRules() }.font(.system(size:12)).foregroundStyle(LensStyle.secondary).frame(minHeight:44)
            }
            InstrumentSlider(value:ruleBinding,range:ruleRange,step:explorer.selectedRule == .scale ? 0.01:1,label:"Change \(explorer.selectedRule.rawValue)",onCommit:{ explorer.regenerate();UIImpactFeedbackGenerator(style:.soft).impactOccurred() }).frame(height:44)
            HStack {
                Button { explorer.showOriginal.toggle() } label: { Label("Original trace",systemImage:explorer.showOriginal ? "circle.dotted.circle.fill":"circle.dotted").font(.system(size:11)).foregroundStyle(explorer.showOriginal ? LensStyle.green:LensStyle.secondary).frame(minHeight:44) }.accessibilityLabel(explorer.showOriginal ? "Hide original trace":"Show original trace")
                Spacer()
                QuietButton(title:"Regrow",icon:"arrow.counterclockwise") { explorer.regenerate() }
            }
            saveRow
        }
    }
    private var ruleBinding:Binding<Double> {
        Binding(get:{ switch explorer.selectedRule { case .angle:return explorer.rules.angle;case .scale:return explorer.rules.scale;default:return Double(explorer.rules.depth) } },set:{ value in switch explorer.selectedRule { case .angle:explorer.rules.angle=value;case .scale:explorer.rules.scale=value;default:explorer.rules.depth=Int(value) } })
    }
    private var ruleRange:ClosedRange<Double> { explorer.selectedRule == .angle ? 5...110:explorer.selectedRule == .scale ? 0.05...0.9:2...8 }
    private var currentRuleValue:String { explorer.selectedRule == .angle ? String(format:"%.0f°",explorer.rules.angle):explorer.selectedRule == .scale ? String(format:"%.2f",explorer.rules.scale):String(explorer.rules.depth) }
    private var originalRuleValue:String {
        guard let r=item?.analysis.rules else { return "" }
        return explorer.selectedRule == .angle ? String(format:"%.0f°",r.angle):explorer.selectedRule == .scale ? String(format:"%.2f",r.scale):String(r.depth)
    }
    private var saveRow:some View {
        HStack {
            Text("Keep this way of seeing.").font(.system(size:12)).foregroundStyle(LensStyle.secondary)
            Spacer()
            QuietButton(title:explorer.saved ? "Collected":"Collect",icon:explorer.saved ? "checkmark":"plus") { onSave() }.disabled(explorer.saved || explorer.saving).accessibilityIdentifier("collectSpecimen")
        }
    }
    private var detailFooter:some View {
        VStack(alignment:.leading,spacing:14) {
            HStack(spacing:0) {
                ForEach(Array([item?.source.origin == .guided ? "Illustration":"Moment","Structure","Glyph"].enumerated()),id:\.offset) { index,label in
                    Button { withAnimation(LensMotion.settle) { explorer.detailMode=index } } label: { Text(label).font(.system(size:13,weight:.semibold)).foregroundStyle(explorer.detailMode==index ? LensStyle.green:LensStyle.secondary).frame(maxWidth:.infinity,minHeight:44) }
                }
            }.lensGlass()
            if let item {
                HStack(alignment:.firstTextBaseline) {
                    Text(item.observationValue).font(.system(size:32,weight:.light)).foregroundStyle(LensStyle.green)
                    Text(hierarchical ? "self similarity":item.evidence?.repetition == nil ? "observed form":"spatial repetition").font(.system(size:12)).foregroundStyle(LensStyle.secondary)
                    Spacer()
                    Text(hierarchical ? "\(item.analysis.metrics.depth) layers":"\(item.analysis.graph.branches.count) paths").font(LensStyle.label(10)).foregroundStyle(LensStyle.secondary)
                }
                let observations=store.observations(of:item)
                if observations.count>1 {
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack(spacing:16) {
                            ForEach(observations) { record in
                                Button(record.source.date.formatted(.dateTime.month(.abbreviated).day().hour().minute())) { explorer.select(record,image:store.image(for:record),detail:true) }
                                    .font(LensStyle.label(10)).foregroundStyle(record.id==item.id ? LensStyle.green:LensStyle.secondary).frame(minHeight:44)
                            }
                        }
                    }
                }
            }
            originLine
            HStack(spacing:18) {
                QuietButton(title:"Reveal",icon:"arrow.up.right",primary:true) { explorer.reveal() }.accessibilityIdentifier("detailReveal")
                QuietButton(title:"Replay",icon:"play") { explorer.manual(.replay) }
                QuietButton(title:"Profile",icon:"plus") { explorer.manual(.profile) }
            }
            if explorer.saved {
                QuietButton(title:"Observe this subject again",icon:"arrow.up.right") { explorer.observe(plantID:item?.plantID) }.accessibilityIdentifier("observeAgain")
            } else { saveRow }
        }
    }
    private func ruleLabel(_ label:String,value:String)->some View {
        VStack(alignment:.leading,spacing:7) { Eyebrow(text:label);Text(value).font(.system(size:21,weight:.light)).foregroundStyle(LensStyle.green) }
    }
    private var sourceSheet:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                Eyebrow(text:"Observation notes")
                Text(item?.title ?? "Specimen").font(.system(size:28,weight:.light))
                Text(item?.sourceLabel ?? "An observation").font(.headline)
                Text(item?.source.origin == .guided ? "An original procedural illustration. The drawn geometry drives this guided experience; it is not a camera recognition result.":item?.source.origin == .example ? "A real photograph with manually traced branch geometry. The same trace drives the reveal, estimates and growth study.":"Video or photo frames are analysed locally with Apple Vision. Contours and key points describe visible image geometry; object labels provide optional context, not proof of a fractal.").font(.system(size:15)).foregroundStyle(LensStyle.secondary)
                if let evidence=item?.evidence {
                    Text(evidence.note).font(.subheadline).foregroundStyle(LensStyle.secondary)
                    if let context=evidence.objectHint { Text("Scene context: \(context)").font(.caption).foregroundStyle(LensStyle.secondary) }
                    Text("Method: \(evidence.algorithm)").font(.caption).foregroundStyle(LensStyle.secondary)
                }
                if let attribution=item?.source.attribution { Text(.init(attribution)).font(.system(size:13)).tint(LensStyle.green) }
                Text(hierarchical ? "Self similarity compares aligned nested branch geometry. Density counts occupied cells. Rule replay is a structural study, not a biological forecast.":"Repetition compares contour lengths and proportions at the same scale. A single image does not establish fractal behaviour or fractal dimension. Trace replay follows the extracted paths.").font(.system(size:12)).foregroundStyle(LensStyle.secondary)
                if let item { Text("Observed \(item.source.date.formatted(date:.long,time:.shortened))").font(LensStyle.label(10)).foregroundStyle(LensStyle.secondary) }
            }.padding(28)
        }.background(LensStyle.background).foregroundStyle(LensStyle.foreground)
    }
}
