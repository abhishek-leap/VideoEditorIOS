//
//  CameraPermissionHelper.swift
//  LeapVideoEditor
//
//  Created by bigstep on 31/05/23.
//

import AVFoundation
import UIKit
class CameraPermissionHelper {
    enum MediaType {
        case camera
        case microphone
    }
    
    static func checkPermission(for mediaType: MediaType, controller: UIViewController, completion: @escaping (Bool) -> Void) {
        var mediaTypeString: AVMediaType
        
        switch mediaType {
        case .camera:
            mediaTypeString = .video
        case .microphone:
            mediaTypeString = .audio
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: mediaTypeString)
        
        switch status {
        case .authorized:
            // Permission already granted
            completion(true)
        case .denied, .restricted:
            // Permission denied or restricted
            completion(false)
            showPermissionAlert(mediaType: mediaType, controller: controller)
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: mediaTypeString) {granted in
                completion(granted)
                if !granted {
                    CameraPermissionHelper.showPermissionAlert(mediaType: mediaType, controller: controller)
                }
            }
        @unknown default:
            // Handle any future authorization statuses
            completion(false)
            showPermissionAlert(mediaType: mediaType, controller: controller)
        }
    }
    
    static func showPermissionAlert(mediaType: MediaType, controller: UIViewController) {
        var permissionName: String
        
        switch mediaType {
        case .camera:
            permissionName = "Camera"
        case .microphone:
            permissionName = "Microphone"
        }
        
        let alert = UIAlertController(title: "\(permissionName) Access Required",
                                      message: "Please grant \(permissionName) access in Settings to use this feature.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) {  _ in
            CameraPermissionHelper.showAppSettings()
        })
        
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    static func showAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, completionHandler: nil)
        }
    }
}




