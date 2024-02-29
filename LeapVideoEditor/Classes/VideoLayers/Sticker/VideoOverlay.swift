//
//  StickersOverlay.swift
//  LeapVideoEditor
//
//  Created by bigstep on 12/09/22.
//

import AVFoundation
import GiphyUISDK
import Kingfisher

class VideoOverlay: BaseOverlay {
    let image: GiphyYYImage
    
    override var layer: CALayer {
        let imageLayer = CALayer()
        imageLayer.contents = image.cgImage
        imageLayer.backgroundColor = backgroundColor.cgColor
        imageLayer.frame = frame
        imageLayer.opacity = 0.0
        return imageLayer
    }
    
    
    init(image: GiphyYYImage,
         frame: CGRect,
         delay: TimeInterval,
         duration: TimeInterval,
         backgroundColor: UIColor = UIColor.clear) {
        
        self.image = image
        super.init(frame: frame, delay: delay, duration: duration, backgroundColor: backgroundColor)
    }
}
