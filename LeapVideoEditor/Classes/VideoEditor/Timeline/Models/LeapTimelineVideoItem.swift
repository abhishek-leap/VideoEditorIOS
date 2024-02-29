//
//  LeapTimelineVideoItem.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 19/09/22.
//

import UIKit
import AVFoundation

class LeapTimelineVideoItem: Identifiable, Equatable {
    
    var thumbnails = [UIImageView]()
    let maxThumbnails: Int
    let videoURL: URL
    let duration: TimeInterval
    var startPosition: TimeInterval
    var size: TimeInterval
    var isMuted = false
    var hasAudio = true
    
    init(videoURL: URL, startPosition: TimeInterval = 0, size: TimeInterval = 0) {
        self.videoURL = videoURL
        self.startPosition = startPosition
        let asset = AVAsset(url: videoURL)
        duration = CMTimeGetSeconds(asset.duration)
        self.size = size == 0 ? duration : size
        maxThumbnails = Int(ceil(duration))
        let imageWidth: CGFloat = 24
        var offset: Int64 = 0
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.maximumSize = CGSize(width: 100, height: 100)
        imgGenerator.appliesPreferredTrackTransform = true
        do {
            for i in 0..<maxThumbnails {
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: offset, timescale: 1), actualTime: nil)
                let imageView = UIImageView(image: UIImage(cgImage: cgImage))
                imageView.contentMode = .scaleAspectFill
                imageView.widthAnchor.constraint(equalToConstant: i == maxThumbnails-1 ? imageWidth*modf(duration).1 : imageWidth).isActive = true
                thumbnails.append(imageView)
                offset += 1
            }
        } catch _ { }
    }
    
    static func == (lhs: LeapTimelineVideoItem, rhs: LeapTimelineVideoItem) -> Bool {
        lhs.videoURL == rhs.videoURL
    }
}
