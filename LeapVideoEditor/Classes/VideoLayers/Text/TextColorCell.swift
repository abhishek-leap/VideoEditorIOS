//
//  TextColorCell.swift
//  LeapVideoEditor
//
//  Created by bigstep on 13/09/22.
//

import Foundation

class TextColorCell: UICollectionViewCell {
    static let reuseIdentifier = "textColorCell"
    var color: VideoOverlayTextColor? {
        didSet {
            let colorCode = color?.colorCode ?? ""
            let color = colorCode.hexStringToUIColor()
            backgroundColor = color
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.white.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = layer.bounds.height/2
    }
}


