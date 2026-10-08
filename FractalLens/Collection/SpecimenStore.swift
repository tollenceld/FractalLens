import Foundation
import Observation
import UIKit

@MainActor @Observable final class SpecimenStore {
    private(set) var specimens=[Specimen]()
    private(set) var examples=[Specimen]()
    var loadError:String?
    private var writeBlocked=false
    let directory:URL
    init(directory:URL? = nil, loadExamples:Bool = true) {
        self.directory=directory ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("FractalLens",isDirectory:true)
        do {
            try FileManager.default.createDirectory(at:self.directory,withIntermediateDirectories:true)
            let index=self.directory.appendingPathComponent("specimens.json")
            if FileManager.default.fileExists(atPath:index.path) { specimens=try JSONDecoder().decode(Archive.self,from:Data(contentsOf:index)).specimens }
        } catch { writeBlocked=true;loadError="Your collection could not be opened. Your files have been kept safe." }
        if loadExamples { examples=ExampleLibrary.load() }
    }
    private struct Archive:Codable { var version=1; var specimens:[Specimen] }
    func save(_ specimen:Specimen, imageData:Data? = nil) throws -> Specimen {
        if writeBlocked { throw CocoaError(.fileWriteUnknown) }
        if let existing=specimens.first(where:{$0.id==specimen.id}) { return existing }
        var saved=specimen; saved.savedAt=Date()
        var createdImage:URL?
        if let data=imageData {
            let name="\(saved.id.uuidString).jpg", url=directory.appendingPathComponent(name)
            try data.write(to:url,options:.atomic); saved.source.imageName=name; createdImage=url
        }
        let next=specimens+[saved]
        do { try JSONEncoder().encode(Archive(specimens:next)).write(to:directory.appendingPathComponent("specimens.json"),options:.atomic) }
        catch { if let createdImage { try? FileManager.default.removeItem(at:createdImage) }; throw error }
        specimens=next
        return saved
    }
    func image(for specimen:Specimen) -> UIImage? {
        if let image=UIImage(contentsOfFile:directory.appendingPathComponent(specimen.source.imageName).path) { return image }
        guard let url=Bundle.main.url(forResource:specimen.source.imageName,withExtension:nil) else { return nil }
        return UIImage(contentsOfFile:url.path)
    }
    func observations(of specimen:Specimen) -> [Specimen] {
        specimens.filter { $0.plantID==specimen.plantID }.sorted { $0.source.date < $1.source.date }
    }
}

struct ExampleAsset:Codable {
    var key:String
    var title:String
    var subtitle:String
    var image:String
    var attribution:String
    var branches:[Branch]
    var aspectRatio:Double
}
enum ExampleLibrary {
    static func load() -> [Specimen] {
        guard let url=Bundle.main.url(forResource:"examples",withExtension:"json"),let data=try? Data(contentsOf:url),let assets=try? JSONDecoder().decode([ExampleAsset].self,from:data) else { return [] }
        let cached: [String:AnalysisResult]
        if let cacheURL=Bundle.main.url(forResource:"example-analyses",withExtension:"json"),let cacheData=try? Data(contentsOf:cacheURL),let decoded=try? JSONDecoder().decode([String:AnalysisResult].self,from:cacheData) { cached=decoded } else { cached=[:] }
        return assets.enumerated().map { index,asset in
            let id=UUID(uuidString:String(format:"A1000000-0000-4000-8000-%012d",index+1))!
            let graph=StructureGraph(branches:asset.branches,aspectRatio:asset.aspectRatio)
            return Specimen(id:id,plantID:id,title:asset.title,subtitle:asset.subtitle,source:.init(imageName:asset.image,origin:.example,date:Date(),attribution:asset.attribution),analysis:cached[asset.key] ?? StructuralAnalysis.evaluate(graph),exampleKey:asset.key)
        }
    }
}
