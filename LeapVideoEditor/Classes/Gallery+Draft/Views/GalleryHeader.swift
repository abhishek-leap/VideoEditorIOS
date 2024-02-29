//
//  GalleryHeader.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/09/22.
//

import Foundation

class GalleryHeader: UIView {
    
    // MARK: UI Elements
    
    let crossButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "close-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)?.setImageColor(color: .black), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let attributedIcon = NSMutableAttributedString()
        let icon = String.fontAwesomeIcon(name: .chevronDown)
        let iconString = NSAttributedString(string: icon, attributes: [NSAttributedString.Key.font:UIFont.fontAwesome(ofSize: 16, style: .solid), NSAttributedString.Key.foregroundColor: UIColor.black ])
        attributedIcon.append(NSAttributedString(string: "All ", attributes: [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.black ]))
        attributedIcon.append(iconString)
        label.attributedText = attributedIcon
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFooter()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupFooter() {
        addSubview(crossButton)
        crossButton.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
        crossButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
        
        addSubview(headerLabel)
        headerLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
    }
    
    func updateHeaderLabel(_ headerTitle: String) {
        let attributedIcon = NSMutableAttributedString()
        let icon = String.fontAwesomeIcon(name: .chevronDown)
        let iconString = NSAttributedString(string: icon, attributes: [NSAttributedString.Key.font:UIFont.fontAwesome(ofSize: 16, style: .solid), NSAttributedString.Key.foregroundColor: UIColor.black ])
        attributedIcon.append(NSAttributedString(string: headerTitle, attributes: [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.black ]))
        attributedIcon.append(iconString)
        headerLabel.attributedText = attributedIcon
    }
}
