//
//  CoreDataManager.swift
//  LeapVideoEditor
//
//  Created by bigstep on 04/10/22.
//

import Foundation

class DraftVideoModel: Codable {
    var videoItems: [DraftVideoItemModel]
    var overlayItems: [VideoOverlayItemsModel]
    var videoDate: Date
    var videoFilter: String?
    var totalVideoDuration: Double
    var leftAnchor: Double
    var rightAnchor: Double
    enum Key: String, CodingKey {
        case video = "DraftVideo"
    }
    
    
    init(videoItems : [DraftVideoItemModel], overlayItems: [VideoOverlayItemsModel], videoDate: Date, videoDuration: Double, leftAnchor: Double, rightAnchor: Double) {
        self.videoItems = videoItems
        self.overlayItems = overlayItems
        self.videoDate = videoDate
        self.totalVideoDuration = videoDuration
        self.leftAnchor = leftAnchor
        self.rightAnchor = rightAnchor
    }
    
    public static func saveDraftVideo(_ video: DraftVideoModel) -> Bool {
        var videoArray = [DraftVideoModel]()
        if let videoData = UserDefaults.standard.data(forKey: Key.video.rawValue), let storedArray = try? JSONDecoder().decode([DraftVideoModel].self, from: videoData) {
            videoArray = storedArray
        }
        videoArray.append(video)
        do {
            let encodedVideoData = try JSONEncoder().encode(videoArray)
            UserDefaults.standard.set(encodedVideoData, forKey: Key.video.rawValue)
            return true
        } catch {
            return false
        }
    }
    
    public static func removeDraftVideo(_ updatedDraftVideos: [DraftVideoModel]) {
        let encodedVideoData = try! JSONEncoder().encode(updatedDraftVideos)
        UserDefaults.standard.set(encodedVideoData, forKey: Key.video.rawValue)
    }
    
    public static func getVideos() -> [DraftVideoModel]?{
        if let videoData = UserDefaults.standard.data(forKey: Key.video.rawValue) {
            let videoArray = try! JSONDecoder().decode([DraftVideoModel].self, from: videoData)
            return videoArray
        }
        return []
    }
    
    public static func updateDraftVideo(_ video: DraftVideoModel, index: Int) -> Bool {
        var videoArray = [DraftVideoModel]()
        if let videoData = UserDefaults.standard.data(forKey: Key.video.rawValue), let storedArray = try? JSONDecoder().decode([DraftVideoModel].self, from: videoData) {
            videoArray = storedArray
        }
        videoArray[index] = video
        do {
            let encodedVideoData = try JSONEncoder().encode(videoArray)
            UserDefaults.standard.set(encodedVideoData, forKey: Key.video.rawValue)
            return true
        } catch {
            return false
        }
    }
}

class DraftVideoItemModel: Codable {
    let videoData: Data
    let isMuted: Bool
    
    init(videoData: Data, isMuted: Bool) {
        self.videoData = videoData
        self.isMuted = isMuted
    }
}

class VideoOverlayItemsModel: Codable {
    var overlayData: Data
    var overlayOriginX : Double
    var overlayOriginY: Double
    var overlayWidth: Double
    var overlayHeight: Double
    var startPosition: Double
    var overlayDuration: Double
    let overlayType: Int // 1 for sticker/text, 2 for audio/voice
   
    init(overlayData : Data, overlayOriginX: Double, overlayOriginY: Double, overlayWidth: Double, overlayHeight: Double, startPosition: Double, overlayDuration: Double, overlayType: Int) {
        self.overlayData = overlayData
        self.overlayOriginX = overlayOriginX
        self.overlayOriginY = overlayOriginY
        self.overlayWidth = overlayWidth
        self.overlayHeight = overlayHeight
        self.startPosition = startPosition
        self.overlayDuration = overlayDuration
        self.overlayType = overlayType
    }
}



