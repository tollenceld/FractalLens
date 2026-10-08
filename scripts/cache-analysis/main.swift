import Foundation
struct Seed:Decodable { var key:String;var branches:[Branch];var aspectRatio:Double }
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let resources=root.appendingPathComponent("FractalLens/Resources")
let seeds=try JSONDecoder().decode([Seed].self,from:Data(contentsOf:resources.appendingPathComponent("examples.json")))
var cache=[String:AnalysisResult]()
for seed in seeds { cache[seed.key]=StructuralAnalysis.evaluate(StructureGraph(branches:seed.branches,aspectRatio:seed.aspectRatio)) }
let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
try encoder.encode(cache).write(to:resources.appendingPathComponent("example-analyses.json"))
for key in cache.keys.sorted() { let a=cache[key]!;print("\(key): similarity=\(a.metrics.similarity ?? 0), branches=\(a.graph.branches.count), depth=\(a.metrics.depth)") }
