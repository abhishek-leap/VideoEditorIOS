//
//  LensCollectionViewCell.swift
//  DKImagePickerController
//
//  Created by Jovanpreet Randhawa on 31/08/22.
//

import UIKit

class LensCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "lensCollectionCell"
    
    let lensIcon = UIImageView()
    let lensNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView(arrangedSubviews: [lensIcon, lensNameLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        let imageSize = floor(UIScreen.main.bounds.width/3)*0.7
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            lensIcon.heightAnchor.constraint(equalToConstant: imageSize),
            lensIcon.widthAnchor.constraint(equalToConstant: imageSize)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
