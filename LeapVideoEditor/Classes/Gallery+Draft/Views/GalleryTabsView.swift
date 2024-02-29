//
//  GalleryTabsView.swift
//  LeapVideoEditor
//
//  Created by bigstep on 26/09/22.
//

import Foundation

// MARK: Protocol to move tab bottom bar

protocol GalleryTabsProtocol {
    func scrollToTabIndex(tabIndex: IndexPath, animated: Bool)
}

class GalleryTabsView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var galleryTabDelegate: GalleryTabsProtocol?
    var horizontalBarLeftAnchorConstraint: NSLayoutConstraint?
    lazy var tabs = ["All", "Videos", "Photos"]
    
    // MARK: UI Elements
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.clear
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView.register(GalleryTabCell.self, forCellWithReuseIdentifier: GalleryTabCell.cellIdentifier)
        addSubview(collectionView)
        addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        addConstraintsWithFormat("V:|[v0]|", views: collectionView)
        setupHorizontalBar()
        collectionView.reloadData()
    }
    
    // MARK: setting horizonatal bottom bar
    
    func setupHorizontalBar() {
        let horizontalBarView = UIView()
        horizontalBarView.backgroundColor = .black
        horizontalBarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalBarView)
        
        horizontalBarLeftAnchorConstraint = horizontalBarView.leftAnchor.constraint(equalTo: self.leftAnchor)
        horizontalBarLeftAnchorConstraint?.isActive = true
        
        horizontalBarView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        horizontalBarView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1/3).isActive = true
        horizontalBarView.heightAnchor.constraint(equalToConstant: 4).isActive = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setSelectedTab(indexPath: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryTabCell.cellIdentifier, for: indexPath) as! GalleryTabCell
        cell.menuTitle = self.tabs[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.width / CGFloat(tabs.count), height: frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setSelectedTab(indexPath: IndexPath, animated: Bool) {
        let x = CGFloat(indexPath.item) * frame.width / CGFloat(tabs.count)
        horizontalBarLeftAnchorConstraint?.constant = x
        if animated {
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.layoutIfNeeded()
            }, completion: nil)
        }
        galleryTabDelegate?.scrollToTabIndex(tabIndex: indexPath, animated: animated)
    }
}

