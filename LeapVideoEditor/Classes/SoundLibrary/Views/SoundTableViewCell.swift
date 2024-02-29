//
//  SoundTableViewCell.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 10/10/22.
//

import UIKit

class SoundTableViewCell: UITableViewCell {
    
    static let identifier = "soundCell"
    
    let soundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    let soundNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    let artistNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    let selectionImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "checkmark-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil))
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    let playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let titleStackView = UIStackView(arrangedSubviews: [soundNameLabel, artistNameLabel])
        titleStackView.axis = .vertical
        
        let descStackView = UIStackView(arrangedSubviews: [titleStackView, timeLabel])
        descStackView.axis = .vertical
        descStackView.distribution = .equalSpacing
        
        let imageContainerView = UIView()
        imageContainerView.addSubview(soundImageView)
        imageContainerView.addSubview(playButton)
        
        let stackView = UIStackView(arrangedSubviews: [imageContainerView, descStackView, selectionImageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            soundImageView.widthAnchor.constraint(equalToConstant: 60),
            soundImageView.heightAnchor.constraint(equalToConstant: 60),
            soundImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            soundImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            soundImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            soundImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            playButton.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            playButton.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            playButton.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            playButton.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
