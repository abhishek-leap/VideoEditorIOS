//
//  LeapMediaPickerView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 18/08/22.
//

import SCSDKCameraKit
import UIKit

/// Describes an interface to be notified of MediaPickerView events
public protocol LeapMediaPickerViewDelegate: NSObjectProtocol {

    /// User selected asset in MediaPickerView
    /// - Parameters:
    ///   - mediaPickerView: MediaPickerView instance
    ///   - selectedAsset: user selected asset
    func mediaPickerView(_ mediaPickerView: LeapMediaPickerView, selectedAsset: LensMediaPickerProviderAsset)
}

/// Selection view for Media Picker
public class LeapMediaPickerView: UIView {

    // MARK: Properties

    /// Delegate to be notified of MediaPickerView events
    public weak var delegate: LeapMediaPickerViewDelegate?

    public var provider: LensMediaPickerProvider? {
        didSet {
            reconfigureDataSource()
        }
    }

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let noMediaLabel = UILabel()
    private var dataSource: MediaPickerViewDataSource?
    private let shapeView = ShapeView()
    private let containerView = UIView()

    private let shapeViewCompactConstraint: NSLayoutConstraint

    // MARK: Init

    /// Designated init to provide in required deps
    /// - Parameter provider: LensMediaPickerProvider instance to provide media to the picker view
    public init() {
        // Actual size assigned later
        shapeViewCompactConstraint = shapeView.widthAnchor.constraint(equalToConstant: 100)
        super.init(frame: .zero)
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topAnchor.constraint(equalTo: containerView.topAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        addConstraint(widthAnchor.constraint(greaterThanOrEqualToConstant: 100))
        containerView.addSubview(shapeView)
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        shapeView.addConstraint(shapeViewCompactConstraint)
        containerView.addConstraints([
            containerView.leadingAnchor.constraint(lessThanOrEqualTo: shapeView.leadingAnchor),
            containerView.trailingAnchor.constraint(greaterThanOrEqualTo: shapeView.trailingAnchor),
            containerView.centerXAnchor.constraint(equalTo: shapeView.centerXAnchor),
            containerView.bottomAnchor.constraint(equalTo: shapeView.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: shapeView.topAnchor),
        ])
        shapeView.shapeLayer.fillColor = UIColor.white.cgColor
        containerView.addSubview(collectionView)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints([
            collectionView.leadingAnchor.constraint(equalTo: shapeView.leadingAnchor, constant: 5),
            collectionView.trailingAnchor.constraint(equalTo: shapeView.trailingAnchor, constant: -5),
            collectionView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -25),
        ])
        collectionView.register(
            LeapMediaPickerViewAssetCell.self,
            forCellWithReuseIdentifier: MediaPickerViewDataSource.Constants.assetCellIdentifier)
        collectionView.register(
            LeapMediaPickerViewLoadingFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: MediaPickerViewDataSource.Constants.loadingFooterIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        addSubview(noMediaLabel)
        noMediaLabel.translatesAutoresizingMaskIntoConstraints = false
        noMediaLabel.isHidden = true
        noMediaLabel.textColor = .gray
        noMediaLabel.text = NSLocalizedString("No Media Found", comment: "")
        addConstraints([
            noMediaLabel.centerXAnchor.constraint(equalTo: shapeView.centerXAnchor),
            noMediaLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 120)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        var insetBounds = shapeView.bounds
        insetBounds.size.height -= 20
        let path = UIBezierPath(roundedRect: insetBounds, cornerRadius: 10)
        path.move(to: CGPoint(x: insetBounds.midX - 10, y: insetBounds.maxY))
        path.addLine(to: CGPoint(x: insetBounds.midX, y: bounds.maxY - 10))
        path.addLine(to: CGPoint(x: insetBounds.midX + 10, y: insetBounds.maxY))
        path.close()
        shapeView.shapeLayer.path = path.cgPath
    }

    func showLoadingIndicator(for asset: LensMediaPickerProviderAsset) {
        dataSource?.loadingAsset = asset
        collectionView.reloadData()
    }

    func hideLoadingIndicator(for asset: LensMediaPickerProviderAsset) {
        guard dataSource?.loadingAsset?.identifier == asset.identifier else { return }
        dataSource?.loadingAsset = nil
        collectionView.reloadData()
    }

    fileprivate func reconfigureDataSource() {
        if let provider = provider {
            dataSource = MediaPickerViewDataSource(provider: provider)
            dataSource?.delegate = self
        }
        collectionView.dataSource = dataSource
        collectionView.delegate = dataSource
        collectionView.reloadData()
    }

}

extension LeapMediaPickerView: MediaPickerViewDataSourceDelegate {

    fileprivate func mediaPickerViewDataSource(
        _ mediaPickerViewDataSource: MediaPickerViewDataSource, loadedAssets: [LensMediaPickerProviderAsset]
    ) {
        // Trigger layout pass so collectionView.contentSize will be properly assigned.
        collectionView.reloadData()
        shapeViewCompactConstraint.isActive = false
        layoutIfNeeded()
        setNeedsLayout()
        if mediaPickerViewDataSource.collectionView(collectionView, numberOfItemsInSection: 0) == 0 {
            noMediaLabel.isHidden = false
        } else {
            noMediaLabel.isHidden = true
        }
    }

    fileprivate func mediaPickerViewDataSource(
        _ mediaPickerViewDataSource: MediaPickerViewDataSource, selectedAsset: LensMediaPickerProviderAsset
    ) {
        collectionView.reloadData()
        delegate?.mediaPickerView(self, selectedAsset: selectedAsset)
    }

    fileprivate func mediaPickerViewDataSource(
        _ mediaPickerViewDataSource: MediaPickerViewDataSource, requestsNoAssetsLabelHidden hidden: Bool
    ) {
        noMediaLabel.isHidden = hidden
    }

}

extension LeapMediaPickerView: LensMediaPickerProviderUIDelegate {

    public func mediaPickerProviderRequestedUIPresentation(_ provider: LensMediaPickerProvider) {
        collectionView.reloadData()
        if provider.hasMoreAssetsToFetch && provider.fetchedAssetCount == 0 {
            shapeViewCompactConstraint.isActive = true
            dataSource?.loadMore()
        }
        guard isHidden else { return }
        setNeedsLayout()
        isHidden = false
        containerView.transform = CGAffineTransform(translationX: 0, y: intrinsicContentSize.height / 2).scaledBy(
            x: 0.001, y: 0.001)
        UIView.animate(
            withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [],
            animations: {
                self.containerView.transform = .identity
            }, completion: nil)
    }

    public func mediaPickerProviderRequestedUIDismissal(_ provider: LensMediaPickerProvider) {
        UIView.animate(
            withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [],
            animations: {
                self.containerView.transform = CGAffineTransform(
                    translationX: 0, y: self.intrinsicContentSize.height / 2
                ).scaledBy(x: 0.001, y: 0.001)
            }
        ) { finished in
            guard finished else { return }
            self.isHidden = true
        }
    }

}

extension LeapMediaPickerView {

    private class ShapeView: UIView {

        override class var layerClass: AnyClass {
            CAShapeLayer.self
        }

        var shapeLayer: CAShapeLayer {
            layer as! CAShapeLayer
        }

    }

}

// MARK: Collection View Data Source

private protocol MediaPickerViewDataSourceDelegate: NSObjectProtocol {
    func mediaPickerViewDataSource(
        _ mediaPickerViewDataSource: MediaPickerViewDataSource, loadedAssets: [LensMediaPickerProviderAsset])
    func mediaPickerViewDataSource(
        _ mediaPickerViewDataSource: MediaPickerViewDataSource, selectedAsset: LensMediaPickerProviderAsset)
}

private class MediaPickerViewDataSource: NSObject {

    weak var delegate: MediaPickerViewDataSourceDelegate?

    var loadingAsset: LensMediaPickerProviderAsset? = nil

    private let provider: LensMediaPickerProvider
    private let durationFormatter = DateComponentsFormatter()
    private var loadingMore = false
    private var selection: LensMediaPickerProviderAsset? = nil

    init(provider: LensMediaPickerProvider) {
        self.provider = provider
        durationFormatter.unitsStyle = .positional
        durationFormatter.allowedUnits = [.minute, .second]
        durationFormatter.zeroFormattingBehavior = .pad
        super.init()
    }

}

extension MediaPickerViewDataSource: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        provider.fetchedAssetCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: Constants.assetCellIdentifier, for: indexPath)
            as! LeapMediaPickerViewAssetCell
        let asset = provider.fetchedAsset(at: indexPath.item)
        cell.imageView.image = asset.previewImage
        if asset.type == .video {
            cell.durationLabel.isHidden = false
            cell.durationLabel.text = durationFormatter.string(from: asset.duration)
        } else {
            cell.durationLabel.isHidden = true
        }
        cell.selectionMask.isHidden = selection?.identifier != asset.identifier
        if loadingAsset?.identifier == asset.identifier {
            cell.loadingIndiciator.startAnimating()
        } else {
            cell.loadingIndiciator.stopAnimating()
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Constants.loadingFooterIdentifier,
            for: indexPath)
        return view
    }

}

extension MediaPickerViewDataSource: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !loadingMore else { return }
        if scrollView.bounds.maxX >= scrollView.contentSize.width {
            loadMore()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selection = provider.fetchedAsset(at: indexPath.item)
        self.selection = selection
        delegate?.mediaPickerViewDataSource(self, selectedAsset: selection)
    }

    func loadMore() {
        guard !loadingMore else { return }
        loadingMore = true
        provider.fetchNextAssetBatch(size: Constants.batchSize, queue: .main) { [weak self] assets in
            guard let self = self else { return }
            self.delegate?.mediaPickerViewDataSource(self, loadedAssets: assets)
            self.loadingMore = false
        }
    }

}

extension MediaPickerViewDataSource: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let thumb = provider.fetchedAsset(at: indexPath.item).previewImage
        let aspect = thumb.size.width / thumb.size.height
        let height = collectionView.frame.height
        return CGSize(width: height * aspect, height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard provider.hasMoreAssetsToFetch else { return .zero }
        let height = collectionView.frame.height
        return CGSize(width: height, height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        5
    }

}

extension MediaPickerViewDataSource {

    enum Constants {
        static let batchSize = 10
        static let assetCellIdentifier = "MediaPickerViewAssetCell"
        static let loadingFooterIdentifier = "MediaPickerViewLoadingFooter"
    }

}
