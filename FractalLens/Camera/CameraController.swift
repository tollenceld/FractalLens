@preconcurrency import AVFoundation
import SwiftUI
import Observation
import CoreImage
import ImageIO

/// Video frames are sampled on a dedicated queue. No photo shutter or movie file is used.
/// Only the final observed frame is retained when the user collects a discovery.
@MainActor @Observable final class CameraController {
    private let engine=CaptureEngine()
    var session:AVCaptureSession { engine.session }
    var available=false
    var message="Opening your lens…"
    var lastFrame:Data?
    var frameID=0
    var permissionDenied=false
    private var starting=false
    private var generation=0
    func start() async {
        #if targetEnvironment(simulator)
        message="Guided camera preview · Camera available on iPhone"
        return
        #else
        if starting {
            while starting { do { try await Task.sleep(for:.milliseconds(50)) } catch { return } }
            guard !Task.isCancelled else { return }
        }
        guard !Task.isCancelled else { return }
        starting=true;generation += 1;let token=generation
        defer { starting=false }
        let permission=AVCaptureDevice.authorizationStatus(for:.video)
        let granted=permission == .authorized ? true : (permission == .notDetermined ? await AVCaptureDevice.requestAccess(for:.video):false)
        guard token==generation else { return }
        guard granted else { available=false;permissionDenied=true;message="Camera access is off. Explore a guided view or open a photo.";return }
        engine.receiver.setHandler { [weak self] data in Task { @MainActor in guard let self,self.available else { return };self.lastFrame=data;self.frameID += 1 } }
        let success=await engine.start()
        guard token==generation else { engine.stop();return }
        available=success;message=success ? "Observing on this device":"Camera unavailable. A guided view is still here."
        #endif
    }
    func pauseSampling() { engine.receiver.setEnabled(false) }
    func resumeSampling() { engine.receiver.setEnabled(true) }
    func stop() { generation += 1;available=false;engine.stop() }
}
private final class CaptureEngine:@unchecked Sendable {
    let session=AVCaptureSession()
    let receiver=VideoFrameReceiver()
    private let queue=DispatchQueue(label:"studio.fractal.camera.session",qos:.userInitiated)
    private let output=AVCaptureVideoDataOutput()
    private var configured=false
    func start() async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                if !configured {
                    guard let device=AVCaptureDevice.default(.builtInWideAngleCamera,for:.video,position:.back),let input=try? AVCaptureDeviceInput(device:device) else { continuation.resume(returning:false);return }
                    session.beginConfiguration();session.sessionPreset = .hd1280x720
                    output.alwaysDiscardsLateVideoFrames=true
                    output.videoSettings=[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
                    guard session.canAddInput(input),session.canAddOutput(output) else { session.commitConfiguration();continuation.resume(returning:false);return }
                    session.addInput(input);session.addOutput(output)
                    output.setSampleBufferDelegate(receiver,queue:receiver.queue)
                    if let connection=output.connection(with:.video),connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle=90 }
                    session.commitConfiguration();configured=true
                }
                receiver.setEnabled(true)
                if !session.isRunning { session.startRunning() }
                continuation.resume(returning:true)
            }
        }
    }
    func stop() { receiver.setEnabled(false);queue.async { [session] in if session.isRunning { session.stopRunning() } } }
}
private final class VideoFrameReceiver:NSObject,AVCaptureVideoDataOutputSampleBufferDelegate,@unchecked Sendable {
    let queue=DispatchQueue(label:"studio.fractal.camera.frames",qos:.userInitiated)
    private var onFrame: (@Sendable(Data)->Void)?
    func setHandler(_ handler:@escaping @Sendable(Data)->Void) { queue.async { self.onFrame=handler } }
    private let context=CIContext(options:[.cacheIntermediates:false])
    private var enabled=true
    private var lastSample=0.0
    func setEnabled(_ value:Bool) { queue.async { self.enabled=value } }
    func captureOutput(_ output:AVCaptureOutput,didOutput sampleBuffer:CMSampleBuffer,from connection:AVCaptureConnection) {
        let now=ProcessInfo.processInfo.systemUptime
        guard enabled,now-lastSample>=0.7,let buffer=CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastSample=now
        autoreleasepool {
            let image=CIImage(cvPixelBuffer:buffer)
            let scale=min(1,720/max(image.extent.width,image.extent.height))
            let small=image.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
            guard let cg=context.createCGImage(small,from:small.extent) else { return }
            let data=NSMutableData()
            guard let destination=CGImageDestinationCreateWithData(data,"public.jpeg" as CFString,1,nil) else { return }
            CGImageDestinationAddImage(destination,cg,[kCGImageDestinationLossyCompressionQuality:0.86] as CFDictionary)
            if CGImageDestinationFinalize(destination) { onFrame?(data as Data) }
        }
    }
}
struct CameraPreview:UIViewRepresentable {
    let session:AVCaptureSession
    class Preview:UIView {
        override class var layerClass:AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer:AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
    func makeUIView(context:Context)->Preview {
        let view=Preview();view.backgroundColor = .black;view.previewLayer.session=session
        // Aspect fit matches the frame and its normalized evidence coordinates exactly.
        view.previewLayer.videoGravity = .resizeAspect
        if let connection=view.previewLayer.connection,connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle=90 }
        return view
    }
    func updateUIView(_ uiView:Preview,context:Context) {}
}
