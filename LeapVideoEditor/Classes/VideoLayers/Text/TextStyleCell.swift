//
//  File.swift
//  LeapVideoEditor
//
//  Created by bigstep on 12/09/22.
//

import Foundation

class TextStyleCell : UICollectionViewCell {
    var style: TextStyle? {
        didSet {
            guard let style = style else {return}
            styleLabel.font = UIFont(name: style.fontName, size: 15) ?? .systemFont(ofSize: 15)
            styleLabel.text = style.name
        }
    }
    static let reuseIdentifier = "textStyleCell"
    
    // MARK: UI Elements:-
    
    private lazy var styleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.masksToBounds = true
        layer.borderWidth = 0.75
        layer.cornerRadius = 5
        
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderColor = UIColor.white.withAlphaComponent(1).cgColor
            }
            else {
                layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
            }
        }
    }
    
    // MARK: cell setup
    
    private func setupCell() {
        addSubview(styleLabel)
        styleLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        styleLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        styleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        styleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
