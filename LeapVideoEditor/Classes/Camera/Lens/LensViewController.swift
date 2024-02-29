//
//  LensViewController.swift
//  DKImagePickerController
//
//  Created by Jovanpreet Randhawa on 31/08/22.
//

import UIKit
import SCSDKCameraKitReferenceUI
import Kingfisher

protocol LensSelectionDelegate: AnyObject {
    
    func didSelect(lens: LensItem)
    
    func didClearLens()
}

class LensViewController: BaseViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let width = floor(UIScreen.main.bounds.width/3)
        layout.itemSize = CGSize(width: width, height: width*1.4)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "remove-lens-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.addTarget(self, action: #selector(removeLensTapped(_:)), for: .touchUpInside)
        return button
    }()
    private let lensItems: [LensItem]
    weak var lensSelectionDelegate: LensSelectionDelegate?
    
    init(cameraController: LeapCameraController, lensSelectionDelegate: LensSelectionDelegate) {
        self.lensSelectionDelegate = lensSelectionDelegate
        lensItems = cameraController.groupIDs.flatMap {
            cameraController.cameraKit.lenses.repository.lenses(groupID: $0).map {
                LensItem(lensId: $0.id, groupId: $0.groupId, iconURL: $0.iconUrl, name: $0.name ?? "")
            }
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(collectionView)
        view.addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            removeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            removeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Lenses"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), style: .plain, target: self, action: #selector(closeTapped(_:)))
        collectionView.register(LensCollectionViewCell.self, forCellWithReuseIdentifier: LensCollectionViewCell.identifier)
        collectionView.contentInset.bottom = 50
    }
    
    func presentController(from controller: UIViewController) {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.setupDefaultStyle()
        controller.present(navigationController, animated: true)
    }
    
    @objc func closeTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc func removeLensTapped(_ sender: UIButton) {
        lensSelectionDelegate?.didClearLens()
        dismiss(animated: true)
    }
}

extension LensViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        lensItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LensCollectionViewCell.identifier, for: indexPath) as! LensCollectionViewCell
        let lensItem = lensItems[indexPath.row]
        cell.lensNameLabel.text = lensItem.name
        cell.lensIcon.kf.setImage(with: lensItem.iconURL)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lensSelectionDelegate?.didSelect(lens: lensItems[indexPath.row])
        dismiss(animated: true)
    }
}
