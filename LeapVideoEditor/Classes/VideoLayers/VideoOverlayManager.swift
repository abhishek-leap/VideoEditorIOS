//
//  VideoOverlayManager.swift
//  LeapVideoEditor
//
//  Created by bigstep on 12/09/22.
//

import AVFoundation

public enum VideoOverlayType: Int {
    case sticker = 1
    case text = 2
    case audio = 3
    case record = 4
}

class VideoOverlayManager {
    let outputURL: URL
    
    let outputPresetName: String
    
    private var overlays: [VideoOverlay] = []
    
    let videoSize: CGSize
    
    // MARK: Initializers
    
    init(outputURL: URL, videoSize: CGSize, outputPresetName: String) {
        self.outputURL = outputURL
        self.videoSize = videoSize
        self.outputPresetName = outputPresetName
    }
    
    // MARK: Processing
    
    func process(composition: AVMutableComposition) async -> AVAssetExportSession? {
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        if !overlays.isEmpty {
            let overlayLayer = CALayer()
            let videoLayer = CALayer()
            overlayLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            overlayLayer.addSublayer(videoLayer)
            overlayLayer.transform = CATransform3DMakeScale(1.0, -1.0, 1.0)
            videoLayer.transform = CATransform3DMakeScale(1.0, -1.0, 1.0)
            
            overlays.forEach { (overlay) in
                let layer = overlay.layer
                layer.add(overlay.startAnimation, forKey: "startAnimation") // animation with start time of particular sticker
                layer.add(overlay.endAnimation, forKey: "endAnimation") //animation with end time of particular sticker
                layer.transform = CATransform3DMakeScale(1.0, -1.0, 1.0)
                if let animation = fetchStickerFrames(to: overlay) {
                    layer.add(animation, forKey: "contents") // animation for adding frames of gif
                    overlayLayer.addSublayer(layer)
                }
                else {
                    overlayLayer.addSublayer(layer)
                }
            }
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: overlayLayer)
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        _ = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: composition.tracks(withMediaType: .video)[0])
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: outputPresetName) else {
            return nil
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        await exportSession.export()
        return exportSession
    }
    
    // MARK: this appends all the stickers, texts in an array
    // Parameters:
    // overLay: Particular sticker to append
    
    func addOverlay(_ overlay: VideoOverlay) {
        overlays.append(overlay)
    }
    
    
    // MARK: this will fetch all the frames of animated sticker and return the animation
    // Parameters:
    // overLay: Particular sticker properties
    
    private func fetchStickerFrames(to overLay: VideoOverlay) -> CAAnimation? {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.contents))
        
        var frames: [CGImage] = []
        var delayTimes: [CGFloat] = []
        var totalTime: CGFloat = 0.0
        
        guard let data = overLay.image.animatedImageData else { return nil}
        guard let gifSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image source not found")
            return nil
        }
        
        // get frame
        let frameCount = CGImageSourceGetCount(gifSource)
        
        for i in 0..<frameCount {
            guard let frame = CGImageSourceCreateImageAtIndex(gifSource, i, nil) else {
                continue
            }
            
            guard let dic = CGImageSourceCopyPropertiesAtIndex(gifSource, i, nil) as? [AnyHashable: Any] else { continue }
            var delayTime: CGFloat = 0
            if #available(iOS 14.0, *) {
                guard let gifDic = dic[kCGImagePropertyWebPDictionary] as? [AnyHashable: Any] else { continue }
                delayTime = gifDic[kCGImagePropertyGIFDelayTime] as? CGFloat ?? 0
            } else {
                guard let gifDic  = dic[kCGImagePropertyGIFDictionary] as? [AnyHashable: Any] else { continue }
                delayTime = gifDic[kCGImagePropertyGIFDelayTime] as? CGFloat ?? 0
            }
            frames.append(frame)
            delayTimes.append(delayTime)
            totalTime += delayTime
        }
        
        if frames.count == 0 {
            return nil
        }
        
        assert(frames.count == delayTimes.count)
        
        var times: [NSNumber] = []
        var currentTime: CGFloat = 0
        
        for i in 0..<delayTimes.count {
            times.append(NSNumber(value: Double(currentTime / totalTime)))
            currentTime += delayTimes[i]
        }
        animation.keyTimes = times
        animation.values = frames
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = Double(totalTime)
        animation.repeatCount = .greatestFiniteMagnitude
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        return animation
    }
}
