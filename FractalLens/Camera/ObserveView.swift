import SwiftUI
import PhotosUI

struct ObserveView:View {
    let store:SpecimenStore
    let explorer:Explorer
    @Environment(\.scenePhase) private var scenePhase
    @State private var camera=CameraController()
    @State private var photoItem:PhotosPickerItem?
    @State private var reviewData:Data?
    @State private var reviewImage:UIImage?
    @State private var selection=Vector(x:0.5,y:0.5)
    @State private var analyzing=false
    @State private var frameTask:Task<Void,Never>?
    @State private var requestID=UUID()
    @State private var showExamples=false
    @State private var gate=LiveObservationGate()
    @State private var frame:LiveFrameEvidence?
    @State private var liveBegan=ProcessInfo.processInfo.systemUptime
    @State private var elapsed=0.0
    @State private var paused=false
    @State private var completing=false
    @State private var message="Let your eye wander."
    @State private var frozenImage:UIImage?
    @State private var guidedImage:UIImage?
    @State private var guide=WorldLibrary.study("river")
        @State private var guideFallback=false
    @State private var fallbackTimedOut=false
    @State private var showInfo=false
    private var live:Bool { reviewImage==nil }
    var body:some View {
        VStack(spacing:0) {
            VStack(alignment:.leading,spacing:9) {
                Text(reviewImage==nil ? "The world is repeating.":"Look at this moment.").font(.system(size:30,weight:.bold)).tracking(-0.7)
                Text(reviewImage==nil ? "Point at a shape. Let the lens follow it.":"Tap the structure you want to explore.").font(.subheadline).foregroundStyle(LensStyle.secondary)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,24).padding(.top,16)
            stage.aspectRatio(1,contentMode:.fit).frame(maxWidth:.infinity,maxHeight:.infinity).padding(.horizontal,12).padding(.top,12)
            VStack(spacing:16) {
                if reviewImage != nil { photoControls }
                else { liveControls }
                HStack(spacing:24) {
                    PhotosPicker(selection:$photoItem,matching:.images,photoLibrary:.shared()) {
                        Label("Open a photo",systemImage:"photo").font(.subheadline).frame(minHeight:44)
                    }.accessibilityIdentifier("openPhoto")
                    if explorer.linkedPlant==nil {
                        Button { paused=true;showExamples=true } label: { Label("Try a specimen",systemImage:"sparkle").font(.subheadline).frame(minHeight:44) }.accessibilityIdentifier("trySpecimen")
                    }
                }.foregroundStyle(LensStyle.green).disabled(completing)
            }.padding(.horizontal,24).padding(.bottom,18)
        }.background(InstrumentBackdrop()).foregroundStyle(LensStyle.foreground)
        .navigationTitle(explorer.linkedPlant==nil ? "Live lens":"Observe again").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement:.topBarLeading) { Button { cancel();camera.stop();explorer.goHome() } label: { Image(systemName:"xmark") }.accessibilityLabel("Return to collection") }
            ToolbarItem(placement:.topBarTrailing) { Button { paused=true;showInfo=true } label: { Image(systemName:"info") }.accessibilityLabel("About the live lens") }
        }
        .task(id:scenePhase) {
            guard scenePhase == .active else { cancel();camera.stop();return }
            #if DEBUG
            if let a=ProcessInfo.processInfo.arguments.first(where:{$0.hasPrefix("--live-preview=")}) { guide=WorldLibrary.study(String(a.dropFirst(15))) }
            #endif
            guidedImage=guide.image()
            await camera.start();startClock()
            while !Task.isCancelled {
                do { try await Task.sleep(for:.milliseconds(200)) } catch { break }
                guard scenePhase == .active,!paused,live,!completing,!showExamples,!showInfo else { continue }
                elapsed=ProcessInfo.processInfo.systemUptime-liveBegan
                if gate.consider(nil,elapsed:elapsed) == .guidedExample { finishGuided(timedOut:true);continue }
                if !camera.available,Int(elapsed*10)%7<2,frameTask==nil,let image=guidedImage,let data=image.jpegData(compressionQuality:0.9) {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--live-timeout") { continue }
                    #endif
                    consume(data,guided:true)
                }
            }
        }
        .onChange(of:camera.frameID) { _,_ in if let data=camera.lastFrame,scenePhase == .active { consume(data,guided:false) } }
        .onChange(of:photoItem) { _,item in
            cancel();paused=true
            frameTask=Task { @MainActor in
                do { if let data=try await item?.loadTransferable(type:Data.self),!Task.isCancelled { reviewData=data;reviewImage=UIImage(data:data);selection = .init(x:0.5,y:0.5) } }
                catch { explorer.error="This photo could not be opened. Try another image." }
                frameTask=nil
            }
        }
        .onDisappear { cancel();camera.stop() }
        .sheet(isPresented:$showExamples,onDismiss:{ paused=false;startClock() }) { examplesSheet }
        .sheet(isPresented:$showInfo,onDismiss:{ paused=false;startClock() }) {
            VStack(alignment:.leading,spacing:20) {
                Text("A lens, not a shutter.").font(.title.bold())
                Text("The camera streams frames to on-device Vision analysis. A stable structure across several frames opens its reveal automatically.")
                Text("If nothing clear emerges after 12 seconds, the lens opens a labelled illustrated example. It never assigns a made-up result to your camera view.").foregroundStyle(LensStyle.secondary)
                Text("Frames stay on this device. Only the final frame is saved when you collect a discovery; no movie or microphone recording is stored.").font(.subheadline).foregroundStyle(LensStyle.secondary)
                QuietButton(title:"Keep looking",primary:true) { showInfo=false }
            }.padding(28).presentationDetents([.medium,.large])
        }
    }
    private var stage:some View {
        GeometryReader { proxy in
            let image=frozenImage ?? reviewImage ?? (camera.available ? frame.flatMap { UIImage(data:$0.data) }:guidedImage)
            let imageSize=image?.size ?? CGSize(width:720,height:1280)
            let fit=min(proxy.size.width/imageSize.width,proxy.size.height/imageSize.height)
            let size=CGSize(width:imageSize.width*fit,height:imageSize.height*fit)
            ZStack {
                if camera.available,live,frozenImage==nil { CameraPreview(session:camera.session).frame(width:proxy.size.width,height:proxy.size.height) }
                else if let image { Image(uiImage:image).resizable().scaledToFit().frame(width:proxy.size.width,height:proxy.size.height) }
                if live,let frame {
                    StructureCanvas(graph:frame.graph,color:(camera.available ? Color.white:guide.family.color).opacity(completing ? 0.65:0.22),lineWidth:0.8)
                        .frame(width:size.width,height:size.height)
                    Canvas { context,_ in
                        for (n,p) in frame.keyPoints.enumerated() {
                            let r=explorer.reduceMotion ? 2.0:2.0+sin(elapsed*1.2+Double(n))*0.4
                            let point=CGPoint(x:p.x*size.width,y:p.y*size.height)
                            context.fill(Path(ellipseIn:CGRect(x:point.x-r,y:point.y-r,width:r*2,height:r*2)),with:.color(camera.available ? .white:guide.family.color))
                        }
                    }.frame(width:size.width,height:size.height).allowsHitTesting(false).accessibilityHidden(true)
                }
                if reviewImage != nil {
                    ZStack {
                        Circle().stroke(LensStyle.green,lineWidth:1.5).frame(width:32,height:32)
                        Circle().fill(LensStyle.green).frame(width:4,height:4)
                    }.position(x:(proxy.size.width-size.width)/2+selection.x*size.width,y:(proxy.size.height-size.height)/2+selection.y*size.height)
                }
                VStack {
                    HStack {
                        Label(camera.available && !guideFallback ? "Live · On device":"Guided camera preview",systemImage:camera.available && !guideFallback ? "circle.fill":"sparkle")
                            .font(.caption.weight(.medium)).padding(.horizontal,13).padding(.vertical,9).lensGlass()
                        Spacer()
                    }
                    Spacer()
                    if completing { Label(fallbackTimedOut ? "An example to begin.":"A structure, noticed.",systemImage:fallbackTimedOut ? "sparkle":"checkmark").font(.headline).padding(16).lensGlass() }
                }.padding(16)
                if analyzing { Color.white.opacity(0.4);ProgressView("Following the structure…").tint(LensStyle.green) }
            }.frame(width:proxy.size.width,height:proxy.size.height).clipShape(RoundedRectangle(cornerRadius:30))
                .contentShape(Rectangle()).gesture(SpatialTapGesture().onEnded { value in
                    if reviewImage != nil { selection = .init(x:min(1,max(0,(value.location.x-(proxy.size.width-size.width)/2)/size.width)),y:min(1,max(0,(value.location.y-(proxy.size.height-size.height)/2)/size.height))) }
                })
        }
    }
    private var liveControls:some View {
        VStack(spacing:12) {
            HStack(spacing:14) {
                ZStack {
                    Circle().stroke(LensStyle.green.opacity(0.15),lineWidth:2)
                    Circle().trim(from:0,to:gate.progress).stroke(LensStyle.green,style:StrokeStyle(lineWidth:2,lineCap:.round)).rotationEffect(.degrees(-90))
                    Image(systemName:completing ? "checkmark":paused ? "pause":"sparkle").font(.caption).foregroundStyle(LensStyle.green)
                }.frame(width:36,height:36).animation(.easeInOut(duration:0.5),value:gate.progress)
                VStack(alignment:.leading,spacing:4) {
                    Text(paused ? "Take your time.":message).font(.headline).accessibilityIdentifier("liveStatus")
                    Text(frame?.repetition != nil ? "Repetition · \(frame?.keyPoints.count ?? 0) key points":frame==nil ? "Looking for contours and small echoes":"Structure · \(frame?.keyPoints.count ?? 0) key points").font(.caption).foregroundStyle(LensStyle.secondary)
                }
                Spacer()
                Button { paused.toggle();if !paused { startClock() } } label: { Image(systemName:paused ? "play.fill":"pause.fill").frame(width:44,height:44).lensGlass(interactive:true) }.buttonStyle(.plain).accessibilityLabel(paused ? "Resume live observation":"Pause live observation").accessibilityIdentifier("pauseLive")
            }
            if !camera.available { Text(camera.message).font(.caption).foregroundStyle(LensStyle.secondary).multilineTextAlignment(.center)
                if camera.permissionDenied { Button("Camera settings") { if let url=URL(string:UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }.font(.caption).frame(minHeight:44) } }
        }
    }
    private var photoControls:some View {
        GlassGroup {
            VStack(spacing:12) {
                QuietButton(title:"Reveal this structure",icon:"arrow.right",primary:true) { analyzePhoto() }.disabled(analyzing)
                QuietButton(title:analyzing ? "Cancel analysis":"Return to the live lens",icon:"arrow.counterclockwise") {
                    cancel();analyzing=false;reviewData=nil;reviewImage=nil;paused=false;startClock()
                }
            }
        }
    }
    private func startClock() { guard !completing else { return };guideFallback=false;fallbackTimedOut=false;frozenImage=nil;gate=LiveObservationGate();liveBegan=ProcessInfo.processInfo.systemUptime;elapsed=0;message="Let your eye wander.";completing=false }
    private func cancel() { frameTask?.cancel();frameTask=nil;requestID=UUID() }
    private func consume(_ data:Data,guided:Bool) {
        guard live,!paused,!completing,frameTask==nil,!showExamples,!showInfo else { return }
        let token=requestID
        frameTask=Task { @MainActor in
            do {
                let evidence=try await SceneAnalyzer.inspect(data:data,classify:gate.frames%3==0)
                guard !Task.isCancelled,requestID==token,live,!paused else { frameTask=nil;return }
                frame=evidence
                let decision=gate.consider(evidence,elapsed:elapsed)
                frameTask=nil
                switch decision {
                case .reveal:if guided { finishGuided(timedOut:false) } else { finishLive(evidence) }
                case .settling:message="A shape is settling."
                case .looking:message=evidence.canReveal ? "Following its edges.":"Try a clearer edge."
                case .guidedExample:finishGuided(timedOut:true)
                }
            } catch { if requestID==token { frameTask=nil;message="Keep looking. A clearer shape will help." } }
        }
    }
    private func finishGuided(timedOut:Bool) {
        cancel();completing=true;guideFallback=true;fallbackTimedOut=timedOut
        if timedOut { frame=nil }
        camera.pauseSampling();message=timedOut ? "Let’s begin with an example.":"A structure, noticed."
        let image=guide.image();frozenImage=image
        var specimen=guide.specimen()
        specimen.analysis.evidence?.isLive=false
        specimen.plantID=explorer.linkedPlant ?? specimen.plantID
        let data=image.jpegData(compressionQuality:0.92)
        let token=requestID
        frameTask=Task { @MainActor in
            do { try await Task.sleep(for:.seconds(timedOut ? 1.2:0.85)) } catch { return }
            guard requestID==token,!Task.isCancelled else { return }
            explorer.select(specimen,image:image,data:data);explorer.reveal()
        }
    }
    private func finishLive(_ evidence:LiveFrameEvidence) {
        cancel();completing=true;camera.pauseSampling();frozenImage=UIImage(data:evidence.data);message="A structure, noticed."
        let count=gate.frames,token=requestID
        frameTask=Task { @MainActor in
            do {
                let output=try await SceneAnalyzer.analyze(data:evidence.data,liveFrames:count)
                try await Task.sleep(for:.seconds(0.8))
                guard requestID==token,!Task.isCancelled else { return }
                var specimen=Specimen(id:UUID(),plantID:explorer.linkedPlant ?? UUID(),title:output.result.evidence?.kind == .repeated ? "An everyday rhythm":"A noticed structure",subtitle:output.result.evidence?.family.rawValue ?? "A live observation",source:.init(imageName:"",origin:.camera,date:Date()),analysis:output.result)
                if let hint=output.result.evidence?.objectHint { specimen.subtitle="Near \(hint) · Live observation" }
                explorer.select(specimen,image:UIImage(data:output.data),data:output.data);explorer.reveal()
            } catch {
                guard requestID==token,!Task.isCancelled else { return }
                completing=false;frozenImage=nil;frameTask=nil;camera.resumeSampling();startClock();message="That shape shifted. Let’s look again."
            }
        }
    }
    private func analyzePhoto() {
        guard let data=reviewData,!analyzing else { return }
        cancel();analyzing=true;let token=requestID
        frameTask=Task { @MainActor in
            do {
                let output=try await SceneAnalyzer.analyze(data:data,selection:selection)
                guard !Task.isCancelled,requestID==token else { return }
                let specimen=Specimen(id:UUID(),plantID:explorer.linkedPlant ?? UUID(),title:"A noticed structure",subtitle:output.result.evidence?.family.rawValue ?? "Photo observation",source:.init(imageName:"",origin:.imported,date:Date()),analysis:output.result)
                analyzing=false;explorer.select(specimen,image:UIImage(data:output.data),data:output.data);explorer.reveal()
            } catch { guard !Task.isCancelled,requestID==token else { return };analyzing=false;frameTask=nil;explorer.error=error.localizedDescription }
        }
    }
    private var examplesSheet:some View {
        NavigationStack {
            List {
                Section("Botanical photographs · Traced examples") {
                    ForEach(store.examples) { item in
                        Button { showExamples=false;explorer.select(item,image:store.image(for:item));explorer.reveal() } label: {
                            HStack(spacing:16) { GlyphView(graph:item.analysis.graph,active:false).frame(width:60,height:60);VStack(alignment:.leading,spacing:4) { Text(item.title);Text(item.subtitle).font(.caption).foregroundStyle(LensStyle.secondary) } }
                        }.accessibilityIdentifier("choose-\(item.exampleKey ?? "sample")")
                    }
                }
                Section("Life around you · Illustrated studies") {
                    ForEach(WorldLibrary.all) { study in
                        Button { showExamples=false;let image=study.image();explorer.select(study.specimen(),image:image,data:image.jpegData(compressionQuality:0.92));explorer.reveal() } label: {
                            HStack(spacing:16) { WorldArtwork(study:study).frame(width:60,height:60);VStack(alignment:.leading,spacing:4) { Text(study.name);Text(study.family.rawValue).font(.caption).foregroundStyle(LensStyle.secondary) } }
                        }.accessibilityIdentifier("choose-world-\(study.id)")
                    }
                }
            }.navigationTitle("Ways to see").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { showExamples=false } } }
        }.tint(LensStyle.green).presentationDetents([.large])
    }
}
