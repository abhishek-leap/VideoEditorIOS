//
//  VideoFiltersCell.swift
//  LeapVideoEditor
//
//  Created by bigstep on 20/10/22.
//

import Foundation

class VideoFiltersCell: UICollectionViewCell {
    static let cellIdentifier = "videoFiltersCell"
    var filter: VideoFilterModel? {
        didSet {
            filterNameLabel.text = filter?.filterLabel ?? ""
            let context = CIContext()
            guard let image = filter?.thumbnail else { return}
            guard let ciImage = CIImage(image: image) else { return}
            guard let filterEffect = filter?.filter else {
                self.filterImageView.image = image
                return
            }
            let cgImage = context.createCGImage(filterEffect.outputImage!, from: ciImage.extent)!
            DispatchQueue.main.async {
                let filteredImage = UIImage(cgImage: cgImage)
                self.filterImageView.image = filteredImage
            }
        }
    }
    // MARK: UI Elements
    
    let filterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .green
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.borderWidth = 1.0
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let filterNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: .none)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellView() {
        addSubview(filterImageView)
        addSubview(filterNameLabel)
        
        filterImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        filterImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
        filterImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
        
        filterNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        filterNameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        filterNameLabel.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.2).isActive = true
    }
}
