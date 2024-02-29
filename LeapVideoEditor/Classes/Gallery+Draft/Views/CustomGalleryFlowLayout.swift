//
//  CustomGalleryFlowLayout.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/09/22.
//

import Foundation

open class CustomGalleryFlowLayout: UICollectionViewFlowLayout {
    private let spacing: CGFloat = 3
    open override func prepare() {
        super.prepare()
        
        self.scrollDirection = .vertical
        let contentWidth = (self.collectionView!.bounds.width - (2 * spacing))/3
        let contentHeight = (self.collectionView!.bounds.width - (2 * spacing))/3
        self.itemSize = CGSize(width: contentWidth, height: contentHeight)
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
    }
}
