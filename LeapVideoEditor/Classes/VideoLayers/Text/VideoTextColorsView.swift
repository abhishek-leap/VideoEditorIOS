//
//  VideoTextColorsView.swift
//  LeapVideoEditor
//
//  Created by bigstep on 06/09/22.
//

import Foundation
import UIKit

protocol OverlayTextColorDelegate: AnyObject {
    func didSelectColor(_ color: VideoOverlayTextColor)
}

struct VideoOverlayTextColor {
    let colorCode: String
}

class VideoTextColorsView: UICollectionView {
    private let colors = [
        VideoOverlayTextColor(colorCode: "#FFFFFF"),
        VideoOverlayTextColor(colorCode: "#000000"),
        VideoOverlayTextColor(colorCode: "#FF0000"),
        VideoOverlayTextColor(colorCode: "#FFA500"),
        VideoOverlayTextColor(colorCode: "#FFFF00"),
        VideoOverlayTextColor(colorCode: "#FFFFFF"),
        VideoOverlayTextColor(colorCode: "#90ee90"),
        VideoOverlayTextColor(colorCode: "#006400"),
        VideoOverlayTextColor(colorCode: "#87CEEB"),
    ]
    
    weak var colorActionDelegate: OverlayTextColorDelegate?
    
    // space between each color
    private let cellSpacing: CGFloat = 12
    
    // total number of visible colors at a time
    private let visibleColorsCount: CGFloat = 9
    
    // to check the selected index to resize the item
    private var selectedIndex = 0
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        configureCollectionView()
    }
    
    private func configureCollectionView() {
        register(TextColorCell.self, forCellWithReuseIdentifier: TextColorCell.reuseIdentifier)
        dataSource = self
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: collection view delegates

extension VideoTextColorsView: UICollectionViewDelegate , UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextColorCell.reuseIdentifier, for: indexPath) as? TextColorCell else { fatalError("could not find the cell")}
        cell.color = colors[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - ((visibleColorsCount + 1) * cellSpacing))/visibleColorsCount, height: (collectionView.bounds.width - ((visibleColorsCount + 1) * cellSpacing))/visibleColorsCount)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = colors[indexPath.row]
        colorActionDelegate?.didSelectColor(color)
        let selectedCell = collectionView.cellForItem(at: indexPath)  as? TextColorCell
        selectedCell?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let unselectedCell = collectionView.cellForItem(at: indexPath)  as? TextColorCell
        unselectedCell?.transform = .identity
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: cellSpacing, bottom: 0, right: cellSpacing)
    }
}

