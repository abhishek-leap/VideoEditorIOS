//
//  CameraActionCell.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 24/08/22.
//

import UIKit

class CameraActionCell: UITableViewCell {
    
    static let identifierString = "cameraActionCell"
    
    let actionImageView = UIImageView()
    let actionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        actionImageView.backgroundColor = UIColor(named: "buttonBackground", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        actionImageView.layer.cornerRadius = 21
        actionImageView.contentMode = .center
        
        actionLabel.font = .systemFont(ofSize: 12)
        actionLabel.textColor = .white
        let stackView = UIStackView(arrangedSubviews: [actionImageView, actionLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        backgroundColor = .clear
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            actionImageView.heightAnchor.constraint(equalToConstant: 42),
            actionImageView.widthAnchor.constraint(equalToConstant: 42),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
