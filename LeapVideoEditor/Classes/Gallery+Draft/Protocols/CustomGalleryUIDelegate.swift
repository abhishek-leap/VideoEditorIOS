//
//  CustomGalleryUIDelegate.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/09/22.
//

import Foundation
import DKImagePickerController

open class CustomGalleryUIDelegate: DKImagePickerControllerBaseUIDelegate {
    weak var delegate: GalleryActionDelegate?
    
    override open func layoutForImagePickerController(_ imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type {
        return CustomGalleryFlowLayout.self
    }
    
    open override func imagePickerController(_ imagePickerController: DKImagePickerController, didSelectAssets: [DKAsset]) {
        delegate?.didAddAsset(didSelectAssets)
    }
    
    open override func imagePickerController(_ imagePickerController: DKImagePickerController, didDeselectAssets: [DKAsset]) {
        delegate?.didRemoveAsset(didDeselectAssets)
    }
}
