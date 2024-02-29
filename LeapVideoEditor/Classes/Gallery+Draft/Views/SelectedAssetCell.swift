//
//  SelectedAssetCell.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/09/22.
//

import Foundation
import DKImagePickerController
import Photos

protocol SelectedAssetProtocol: AnyObject {
    func removeAsset(_ asset: DKAsset)
}

class SelectedAssetCell : UICollectionViewCell {
    weak var delegate: SelectedAssetProtocol?
    var index = 0
    var asset: DKAsset? {
        didSet {
            guard let originalAsset = asset?.originalAsset else { return}
            guard let image = getUIImage(asset: originalAsset) else { return}
            selectedAssetImage.image = image
        }
    }
    static let cellIdentifier = "assetCell"
    
    // MARK: UI elements:
    
    private let selectedAssetImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let crossButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.fontAwesome(ofSize: 12, style: .solid)
        button.setTitle(String.fontAwesomeIcon(name: .times), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: setup cell
    
    private func setupCell() {
        addSubview(selectedAssetImage)
        selectedAssetImage.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        selectedAssetImage.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        selectedAssetImage.topAnchor.constraint(equalTo: topAnchor).isActive = true
        selectedAssetImage.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(crossButton)
        crossButton.topAnchor.constraint(equalTo: selectedAssetImage.topAnchor).isActive = true
        crossButton.rightAnchor.constraint(equalTo: selectedAssetImage.rightAnchor).isActive = true
        crossButton.widthAnchor.constraint(equalTo: selectedAssetImage.widthAnchor, multiplier: 1/4).isActive = true
        crossButton.heightAnchor.constraint(equalTo: selectedAssetImage.widthAnchor, multiplier: 1/4).isActive = true
        crossButton.addTarget(self, action: #selector(removeAssetAction), for: .touchUpInside)
    }
    
    // MARK: action to remove particular photo/video from selected assets
    
    @objc private func removeAssetAction() {
        guard let asset = asset else {return }
        delegate?.removeAsset(asset)
    }
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        var img: UIImage?
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true // Set it to false for async callback
        
        let imageManager = PHCachingImageManager()
        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: options) { image, info in
            img = image
        }
        return img
    }
}
