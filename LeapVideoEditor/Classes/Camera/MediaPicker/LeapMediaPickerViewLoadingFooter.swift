//
//  LeapMediaPickerViewLoadingFooter.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 18/08/22.
//

import UIKit

/// Loading view footer for media picker view
class LeapMediaPickerViewLoadingFooter: UICollectionReusableView {

    let loadingIndicator = UIActivityIndicatorView(style: .gray)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            centerXAnchor.constraint(equalTo: loadingIndicator.centerXAnchor),
            centerYAnchor.constraint(equalTo: loadingIndicator.centerYAnchor),
        ])
        loadingIndicator.startAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
