//
//  SoundCollectionCell.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 10/10/22.
//

import UIKit

class SoundCollectionCell: UICollectionViewCell {
    
    static let identifier = "socundCell"
    
    let collectionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let collectionNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(collectionImageView)
        contentView.addSubview(collectionNameLabel)
        
        NSLayoutConstraint.activate([
            collectionImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionImageView.heightAnchor.constraint(equalTo: collectionImageView.widthAnchor),
            collectionNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionNameLabel.topAnchor.constraint(equalTo: collectionImageView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
