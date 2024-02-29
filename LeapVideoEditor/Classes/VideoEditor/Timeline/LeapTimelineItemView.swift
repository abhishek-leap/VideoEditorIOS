//
//  LeapTimelineItemView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 14/09/22.
//

import UIKit
import AVFoundation

class LeapTimelineItemView: LeapTimelineBaseView {
    
    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    init(timelineItem: LeapTimelineItem) {
        super.init(frame: .zero)
        thumbnailImageView.image = timelineItem.thumbnail
        addSubview(thumbnailImageView)
        sendSubviewToBack(thumbnailImageView)
        let colorString: String
        switch timelineItem.type {
        case .sticker:
            colorString = "stickerTimelineBackground"
        case .text:
            colorString = "textTimelineBackground"
        case .audio:
            colorString = "imageTimelineBackground"
            if let url = timelineItem.itemData as? URL {
                let asset = AVURLAsset(url: url)
                let waveFormView = WaveformImageView(frame: CGRect(x: 0, y: 0, width: CMTimeGetSeconds(asset.duration)*24, height: 34))
                waveFormView.configuration = Waveform.Configuration(style: .striped(.init(color: .black, width: 2, spacing: 2)), position: .bottom)
                waveFormView.waveformAudioURL = url
                let waveFormWrapperView = UIView()
                waveFormWrapperView.clipsToBounds = true
                waveFormWrapperView.translatesAutoresizingMaskIntoConstraints = false
                addSubview(waveFormWrapperView)
                sendSubviewToBack(waveFormWrapperView)
                NSLayoutConstraint.activate([
                    waveFormWrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    waveFormWrapperView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    waveFormWrapperView.topAnchor.constraint(equalTo: topAnchor),
                    waveFormWrapperView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
                waveFormWrapperView.addSubview(waveFormView)
            }
        case .record:
            colorString = "imageTimelineBackground"
            let liveWaveformView: AudioVisualizationView = {
                let view = AudioVisualizationView()
                view.audioVisualizationMode = .write
                view.meteringLevelBarWidth = 2
                view.meteringLevelBarInterItem = 2
                view.backgroundColor = UIColor(named: "imageTimelineBackground", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
                view.meteringLevelBarCornerRadius = 1
                return view
            }()
            liveWaveformView.frame = CGRect(x: 0, y: 0, width: timelineItem.size*24, height: 34)
            addSubview(liveWaveformView)
            sendSubviewToBack(liveWaveformView)
        }
        backgroundColor = UIColor(named: colorString, in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        for subview in [leftDragView, rightDragView] {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) { return true }
        }
        return false
    }
}
