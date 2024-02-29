//
//  VideoFiltersManager.swift
//  LeapVideoEditor
//
//  Created by bigstep on 20/10/22.
//

import Foundation
import AVFoundation

class VideoFiltersManager: NSObject {
    
    static let shared = VideoFiltersManager()
    private override init() {}
    
    //
    //MARK: Add filter to video
    func addfiltertoVideo(strfiltername : String, strUrl : URL, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        //FilterName
        let filter = CIFilter(name:strfiltername)
        
        //Asset
        let asset = AVAsset(url: strUrl)
        
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("EffectVideo")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).mp4")
        }catch let error {
            failure(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        //AVVideoComposition
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            
            // Clamp to avoid blurring transparent pixels at the image edges
            let source = request.sourceImage.clampedToExtent()
            filter?.setValue(source, forKey: kCIInputImageKey)
            
            // Crop the blurred output to the bounds of the original image
            let output = filter?.outputImage!.cropped(to: request.sourceImage.extent)
            
            // Provide the filter output to the composition
            request.finish(with: output!, context: nil)
            
        })
        
        //export the video to as per your requirement conversion
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputFileType = AVFileType.mp4
        exportSession.outputURL = outputURL
        exportSession.videoComposition = composition
        
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status {
            case .completed:
                success(outputURL)
                
            case .failed:
                failure(exportSession.error?.localizedDescription)
                
            case .cancelled:
                failure(exportSession.error?.localizedDescription)
                
            default:
                failure(exportSession.error?.localizedDescription)
            }
        })
    }
    
     func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
}
