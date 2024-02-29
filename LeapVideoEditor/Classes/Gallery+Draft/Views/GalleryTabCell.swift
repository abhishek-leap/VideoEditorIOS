//
//  GalleryTabCell.swift
//  LeapVideoEditor
//
//  Created by bigstep on 02/10/22.
//

import Foundation

class GalleryTabCell: UICollectionViewCell {
    static let cellIdentifier = "galleryTabCell"
    var menuTitle: String = "" {
        didSet {
            menuLabel.text = menuTitle
        }
    }
    let menuLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override var isHighlighted: Bool {
        didSet {
            menuLabel.textColor = isHighlighted ? .black : .gray
        }
    }
    override var isSelected: Bool {
        didSet {
            menuLabel.textColor = isSelected ? .black : .gray
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(menuLabel)
        addConstraintsWithFormat("V:[v0(28)]", views: menuLabel)
        addConstraint(NSLayoutConstraint(item: menuLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: menuLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        menuLabel.sizeToFit()
    }
    
}
