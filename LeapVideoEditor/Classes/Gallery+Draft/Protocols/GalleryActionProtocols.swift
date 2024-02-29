//
//  GalleryActionProtocols.swift
//  LeapVideoEditor
//
//  Created by bigstep on 10/10/22.
//

import Foundation
import DKImagePickerController

// MARK: to select/delete particular gallery video

protocol GalleryActionDelegate: AnyObject {
    func didAddAsset(_ assets: [DKAsset])
    func didRemoveAsset(_ assets: [DKAsset])
}

protocol GalleryAssetsDelegate: AnyObject {
    func didSelectedAssets(_ assets: [(recordURL: URL, duration: Double, isPhoto: Bool)])
}
