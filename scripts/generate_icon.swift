import AppKit
import Foundation
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let data=try Data(contentsOf:root.appendingPathComponent("FractalLens/Resources/examples.json"))
let examples=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
let branches=examples[0]["branches"] as! [[String:Any]]
let size=1024
let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
NSColor(calibratedRed:0.91,green:0.96,blue:0.88,alpha:1).setFill()
NSBezierPath(rect:NSRect(x:0,y:0,width:size,height:size)).fill()
let context=NSGraphicsContext.current!.cgContext
context.setLineCap(.round)
for branch in branches {
 let depth=branch["depth"] as! Int
 if depth>2 {continue}
 let points=branch["points"] as! [[String:Double]]
 context.beginPath()
 for (i,p) in points.enumerated() {
  let x=p["x"]!,y=p["y"]!
  let angle = -0.45
  let dx=(x-0.5)*900,dy=(0.5-y)*700
  let point=CGPoint(x:512+dx*cos(angle)-dy*sin(angle),y:512+dx*sin(angle)+dy*cos(angle))
  if i==0 {context.move(to:point)} else {context.addLine(to:point)}
 }
 context.setStrokeColor(NSColor(calibratedRed:0.13,green:0.48,blue:0.36,alpha:1).cgColor)
 context.setLineWidth(depth==0 ? 4.0:depth==1 ? 2.8:1.8)
 context.strokePath()
}
NSGraphicsContext.restoreGraphicsState()
let out=root.appendingPathComponent("FractalLens/Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
try bitmap.representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent("AppIcon.png"))
let catalog="""
{"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
"""
try catalog.write(to:out.appendingPathComponent("Contents.json"),atomically:true,encoding:.utf8)
