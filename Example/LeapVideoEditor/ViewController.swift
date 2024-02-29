//
//  ViewController.swift
//  LeapVideoEditor
//
//  Created by jovan-bigstep on 07/29/2022.
//  Copyright (c) 2022 jovan-bigstep. All rights reserved.
//

import AVKit
import UIKit
import LeapVideoEditor
import SCSDKCameraKit

class ViewController: UIViewController {
    
    fileprivate var supportedOrientations: UIInterfaceOrientationMask = .portrait
    
    private enum Constants {
        static let partnerGroupId = "7163f91d-e557-401f-b10d-d3fe035af60d"
    }
    
    private var cameraController: LeapCameraViewController?

    @IBAction func openCamera(_ sender: UIButton) {
        let cameraController = LeapCameraViewController(repoGroups: [SCCameraKitLensRepositoryBundledGroup, Constants.partnerGroupId], videoEditorDelegate: self, sessionConfig: SessionConfig(applicationID: "43fd3b78-a45a-4919-ab50-5293df030e86", apiToken: "eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNjUyMTkzNjYxLCJzdWIiOiI0M2ZkM2I3OC1hNDVhLTQ5MTktYWI1MC01MjkzZGYwMzBlODZ-U1RBR0lOR344MmExYjkxMi1hMGE0LTRmODctODA4ZS02NTQ3NDZlZjI4YWYifQ.A9OH7VGRUyopCGiyxb-cV4qncxDvKtf7jTzVdgfN8Ps"), token: "CyctZacevceB6FBFa9tZpirUg9MGRodQA5CJIu6gmxqngErYfWFlmI40Bm55GDe0", shouldResume: false, environment: "leapStaging")
        cameraController.appOrientationDelegate = self
        cameraController.presentController(from: self)
        self.cameraController = cameraController
    }
}

extension ViewController: LeapAppOrientationDelegate {

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        supportedOrientations = orientation
    }

    func unlockOrientation() {
        supportedOrientations = .allButUpsideDown
    }
}

extension ViewController: VideoEditorDelegate {
    
    func videoEditorDidCancel() {
        cameraController = nil
    }
    
    func videoEditorDidCapture(videoURL: URL) {
        cameraController = nil
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: videoURL)
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
        print(videoURL)
    }
}
