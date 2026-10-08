import SwiftUI

@main struct FractalLensApp:App {
    var body:some Scene { WindowGroup { RootView().preferredColorScheme(.light) } }
}
struct RootView:View {
    @Namespace private var specimenSpace
    @State private var store=SpecimenStore()
    @State private var explorer=Explorer()
    @State private var selectedTab=0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    var body:some View {
        ZStack {
            InstrumentBackdrop()
            if explorer.stage == .home {
                TabView(selection:$selectedTab) {
                    NavigationStack {
                        HomeView(store:store,explorer:explorer,namespace:specimenSpace,onSave:save,onPatterns:{ selectedTab=1 })
                    }.tabItem { Label("Discover",systemImage:"sparkle.magnifyingglass") }.tag(0)
                    NavigationStack { PatternAtlasView(onWorldReveal:explorer.openStudy) }
                        .tabItem { Label("Patterns",systemImage:"circle.hexagongrid") }.tag(1)
                    NavigationStack { CollectionView(store:store,explorer:explorer,namespace:specimenSpace) }
                        .tabItem { Label("Collection",systemImage:"square.grid.2x2") }.tag(2)
                }.tint(LensStyle.green).transition(.opacity)
            } else if explorer.stage == .observe {
                NavigationStack { ObserveView(store:store,explorer:explorer) }
                    .transition(.opacity)
            } else {
                NavigationStack { ExperienceView(store:store,explorer:explorer,namespace:specimenSpace,onSave:save) }
                    .transition(.opacity)
            }
        }
        .foregroundStyle(LensStyle.foreground)
        .tint(LensStyle.green)
        .animation(.easeInOut(duration:reduceMotion ? 0.15:0.45),value:explorer.stage)
        .onChange(of:explorer.stage) { _,stage in
            if stage == .home && explorer.showArchive { selectedTab=2;explorer.showArchive=false }
        }
        .alert("A moment to look closer",isPresented:Binding(get:{ explorer.error != nil || store.loadError != nil },set:{ if !$0 { explorer.error=nil;store.loadError=nil } })) {
            Button("Continue",role:.cancel) { explorer.error=nil;store.loadError=nil }
        } message: { Text(explorer.error ?? store.loadError ?? "") }
        .onChange(of:phase) { _,new in explorer.setActive(new == .active) }
        .onChange(of:reduceMotion,initial:true) { _,new in explorer.reduceMotion=new }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains(where:{$0.hasPrefix("--pattern=")}) {
                selectedTab=1
            }
            if ProcessInfo.processInfo.arguments.contains("--live") || ProcessInfo.processInfo.arguments.contains(where:{$0.hasPrefix("--live-preview=")}) { explorer.observe();return }
            if let argument=ProcessInfo.processInfo.arguments.first(where:{$0.hasPrefix("--world=")}) { explorer.openStudy(WorldLibrary.study(String(argument.dropFirst(8))));return }
            if ProcessInfo.processInfo.arguments.contains("--collection") { selectedTab=2 }
            if let argument=ProcessInfo.processInfo.arguments.first(where:{$0.hasPrefix("--preview=")}),let sample=store.examples.first,let stage=LensStage(rawValue:String(argument.dropFirst(10))) {
                explorer.select(sample,image:store.image(for:sample),detail:true)
                explorer.transition(to:stage)
                if stage == .dive { explorer.selectedScale=1 }
                if stage == .alter { explorer.rules.angle += 20;explorer.regenerate() }
                return
            }
            #endif
            if ProcessInfo.processInfo.arguments.contains("--demo"),let item=store.examples.first {
                try? await Task.sleep(for:.seconds(1));explorer.demo(item,image:store.image(for:item),save:save)
            }
        }
    }
    private func save() {
        guard let item=explorer.specimen,!explorer.saving else { return }
        explorer.saving=true
        do {
            let saved=try store.save(item,imageData:explorer.imageData)
            explorer.specimen=saved;explorer.saved=true
            UIImpactFeedbackGenerator(style:.soft).impactOccurred()
            explorer.pauseSequence()
            explorer.detailMode=2;explorer.transition(to:.detail)
            let savedID=saved.id
            Task { @MainActor in
                try? await Task.sleep(for:.seconds(0.8))
                guard explorer.specimen?.id==savedID,explorer.stage == .detail else { return }
                explorer.showArchive=true
                withAnimation(.easeInOut(duration:explorer.reduceMotion ? 0.2:1.1)) { explorer.goHome() }
            }
        } catch { explorer.error="Your specimen could not be saved. Please try again. The current observation is still here." }
        explorer.saving=false
    }
}
