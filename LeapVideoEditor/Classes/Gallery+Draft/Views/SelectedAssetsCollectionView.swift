//
//  SelectedAssetsCollectionView.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/09/22.
//

import Foundation
import DKImagePickerController

class SelectedAssetsCollectionView: UICollectionView {
    weak var selectedAssetDelegate: SelectedAssetProtocol?
    var assets: [DKAsset] = [] {
        didSet {
            reloadData()
        }
    }
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.register(SelectedAssetCell.self, forCellWithReuseIdentifier: SelectedAssetCell.cellIdentifier)
        showsHorizontalScrollIndicator = false
        delegate = self
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: collection view delegates

extension SelectedAssetsCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectedAssetCell.cellIdentifier, for: indexPath) as? SelectedAssetCell else { fatalError("could not find the cell")}
        cell.asset = assets[indexPath.row]
        cell.delegate = self
        cell.index = indexPath.row
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width/5, height: collectionView.bounds.width/5)
    }
}

// MARK: delegate implementation to remove the selected asset

extension SelectedAssetsCollectionView: SelectedAssetProtocol {
    func removeAsset(_ asset: DKAsset) {
        selectedAssetDelegate?.removeAsset(asset)
    }
}
