//
//  TimelineItem.swift
//  DKImagePickerController
//
//  Created by Jovanpreet Randhawa on 12/09/22.
//

import Foundation
import GiphyUISDK

class LeapTimelineItem: Identifiable, Equatable {
    
    let itemData: Any
    var startPosition: TimeInterval
    var size: TimeInterval
    var recordedAudioSize: TimeInterval = 0
    let thumbnail: GiphyYYImage
    let id = UUID()
    let type: VideoOverlayType
    var view: GiphyYYAnimatedImageView
    var offset : CGPoint
    var itemSize: CGSize
    var itemPosition: CGPoint
    
    init(itemData: Any, thumbnail: GiphyYYImage, type: VideoOverlayType, startPosition: TimeInterval, position: CGPoint = .zero, itemSize: CGSize = .zero, size: TimeInterval = 3) {
        self.itemData = itemData
        self.startPosition = startPosition
        self.size = size
        self.thumbnail = thumbnail
        self.type = type
        view = GiphyYYAnimatedImageView()
        self.offset = .zero
        self.itemSize = itemSize
        self.itemPosition = position
    }
    
    static func == (lhs: LeapTimelineItem, rhs: LeapTimelineItem) -> Bool {
        lhs.id == rhs.id
    }
}

