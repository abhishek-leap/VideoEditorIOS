//
//  VideoEditor + VideoFilter.swift
//  LeapVideoEditor
//
//  Created by bigstep on 20/10/22.
//

import Foundation
import AVFoundation

// MARK: Filters Implementation

extension LeapVideoEditorViewController: VideoFilterProtocol {
    
    // MARK: present to filters screen to select the filter
    
    public func presentFilters() {
        guard let videoURL =  self.leapTimelineVideoItems.first?.videoURL else { return }
        let asset = AVAsset(url: videoURL)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.maximumSize = CGSize(width: 400, height: 400)
        imgGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) else { return }
        let controller = VideoFiltersController(videoThumbnail: UIImage(cgImage: cgImage))
        controller.delegate = self
        if #available(iOS 15.0, *) {
            if let sheet = controller.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        self.present(controller, animated: true, completion: nil)
    }
    
    // MARK: delegate function which provides the selected filter
    /// Parameters:
    /// filter: selected filter
    
    func didSelectFilter(_ filter: VideoFilterModel) {
        selectedFilter = filter.filter == nil ? nil : filter
        setupVideo()
    }
}
