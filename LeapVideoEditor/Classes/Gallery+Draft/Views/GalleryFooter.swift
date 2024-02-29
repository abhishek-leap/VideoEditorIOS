//
//  GalleryFooter.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/09/22.
//

import Foundation

class GalleryFooter : UIView {
    
    // MARK: UI Elements
    
    let nextButton: LoadingButton = {
        let button = LoadingButton()
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Next", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14.5)
        button.backgroundColor =  UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!
        return button
    }()
    
    private let borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: adding views
    
    private func setupView() {
        addSubview(nextButton)
        nextButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        nextButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        nextButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6).isActive = true
        nextButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.35).isActive = true
        
        addSubview(borderView)
        borderView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        borderView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        borderView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}
