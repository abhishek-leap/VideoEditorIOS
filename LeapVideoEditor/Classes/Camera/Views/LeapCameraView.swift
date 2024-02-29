//
//  LeapCameraView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 01/08/22.
//

import AVFoundation
import AVKit
import SCSDKCameraKit
import UIKit
import SCSDKCameraKitReferenceUI
import DKImagePickerController
import Photos

/// This is the default view that backs the CameraViewController.
open class LeapCameraView: UIView {

    /// default camerakit view to draw outputted textures
    public let previewView = PreviewView()

    // MARK: View properties

    ///close camera controller
    public let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "close-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
        
    }()
    
    public let gridView: GridView = {
        let gridView = GridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.isHidden = true
        return gridView
    }()
    
    public let latestImage: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "gallery-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.contentMode = .scaleAspectFill
        let imageFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let gradient = CAGradientLayer()
        gradient.frame = imageFrame
        gradient.colors = [UIColor(named: "gradient-1", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!.cgColor, UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        let shape = CAShapeLayer()
        shape.lineWidth = 2
        shape.path = UIBezierPath(roundedRect: imageFrame, cornerRadius: 6).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        button.layer.addSublayer(gradient)
        return button
    }()
    
    public lazy var galleryView: UIStackView = {
        let uploadLabel = UILabel()
        uploadLabel.text = "Upload"
        uploadLabel.font = .systemFont(ofSize: 12)
        uploadLabel.textColor = .white
        let stackView = UIStackView(arrangedSubviews: [latestImage, uploadLabel])
        stackView.spacing = 2
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    public lazy var draftsView: UIStackView = {
        let uploadLabel = UILabel()
        uploadLabel.text = "Drafts"
        uploadLabel.font = .systemFont(ofSize: 12)
        uploadLabel.textColor = .white
        let stackView = UIStackView(arrangedSubviews: [draftButton, uploadLabel])
        stackView.spacing = 2
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    public lazy var draftButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "gallery-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.contentMode = .scaleAspectFill
        let imageFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let gradient = CAGradientLayer()
        gradient.frame = imageFrame
        gradient.colors = [UIColor(named: "gradient-1", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!.cgColor, UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        let shape = CAShapeLayer()
        shape.lineWidth = 2
        shape.path = UIBezierPath(roundedRect: imageFrame, cornerRadius: 6).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        button.layer.addSublayer(gradient)
        return button
    }()
    
    public let cameraActionView: CameraActionView = {
        let cameraActionView = CameraActionView()
        cameraActionView.translatesAutoresizingMaskIntoConstraints = false
        return cameraActionView
    }()
    
    public let doneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "checkmark-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    public let progressView: LeapProgressView = {
        let progressView = LeapProgressView()
        let gradientColors = [UIColor(named: "gradient-1", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!.cgColor, UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!.cgColor]
        progressView.progressBar.progressImage = UIImage.gradientImage(with: CGRect(x: 16, y: 8, width: UIScreen.main.bounds.width-32, height: 6), colors: gradientColors, locations: nil)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    public let recordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "start-recording", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.setImage(UIImage(named: "pause-recording", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .selected)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.layer.cornerRadius = 30
        return button
    }()

    public let hintLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0.0
        label.font = .boldSystemFont(ofSize: 20.0)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// View used for ring light effect.
    public let ringLightView: RingLightView = {
        let view = RingLightView()
        view.accessibilityIdentifier = CameraElements.ringLightView.id
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    /// media picker to allow using photos from camera roll in lenses
    public lazy var mediaPickerView: LeapMediaPickerView = {
        let view = LeapMediaPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        if #available(iOS 13, *) {
            view.style = .large
            view.color = .white
        } else {
            view.style = .whiteLarge
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public let watermarkView = UIImageView(image: UIImage(named: "powered-by", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil))

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = UIColor(named: "backgroundColor", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("Unimplemented")
    }

//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        previewView.configureSafeArea(with: [recordButton, cameraActionView])
//        previewView.configureSafeArea(with: [carouselView])
//        ringLightView.ringLightGradient.updateIntensity(
//            to: CGFloat(flashControlView.ringLightIntensityValue), animated: false)
//    }
}

// MARK: General View Setup

extension LeapCameraView {

    private func setup() {
        setupProgressView()
        setupPreview()
        setupGridView()
        setupRingLight()
        setupCloseButton()
        setupHintLabel()
        setupRecordButton()
        setupMediaPicker()
        setupActivityIndicator()
        setupGalleryView()
        setupDraftView()
        setupDoneButton()
        setupCameraActionView()
        setupWaterMark()
    }

    private func setupPreview() {
        addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        let height = UIScreen.main.bounds.width*1.6
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            previewView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            previewView.heightAnchor.constraint(equalToConstant: height)
        ])
        
        previewView.explicitViewportProvider = ExplicitViewportProvider(viewportSize: CGSize(width: UIScreen.main.bounds.width, height: height), outputResolution: CGSize(width: 1200, height: 1920), safeArea: .zero)
    }

}

// MARK: Ring Light

extension LeapCameraView {

    private func setupRingLight() {
        addSubview(ringLightView)
        NSLayoutConstraint.activate([
            ringLightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            ringLightView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ringLightView.topAnchor.constraint(equalTo: topAnchor),
            ringLightView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

}

// MARK: Gallery View

extension LeapCameraView {
    
    private func setupGalleryView() {
        let groupDataManagerConfiguration = DKImageGroupDataManagerConfiguration()
        groupDataManagerConfiguration.fetchLimit = 10
        groupDataManagerConfiguration.assetGroupTypes = [.smartAlbumUserLibrary]

        let groupDataManager = DKImageGroupDataManager(configuration: groupDataManagerConfiguration)
        groupDataManager.fetchGroups {[weak self] groups, error in
            guard let groupID = groups?.first else { return }
            groupDataManager.fetchGroupThumbnail(with: groupID, size: CGSize(width: 30, height: 30), options: PHImageRequestOptions()) { image, info in
                guard let self = self else { return }
                if let image = image { self.latestImage.setImage(image, for: .normal) }
            }
        }
        addSubview(galleryView)
        NSLayoutConstraint.activate([
            latestImage.heightAnchor.constraint(equalToConstant: 40),
            latestImage.widthAnchor.constraint(equalToConstant: 40),
            galleryView.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -28),
            galleryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}

// MARK: Draft View

extension LeapCameraView {
    
    private func setupDraftView() {
        let groupDataManagerConfiguration = DKImageGroupDataManagerConfiguration()
        groupDataManagerConfiguration.fetchLimit = 10
        groupDataManagerConfiguration.assetGroupTypes = [.smartAlbumUserLibrary]

        let groupDataManager = DKImageGroupDataManager(configuration: groupDataManagerConfiguration)
        groupDataManager.fetchGroups {[weak self] groups, error in
            guard let groupID = groups?.first else { return }
            groupDataManager.fetchGroupThumbnail(with: groupID, size: CGSize(width: 30, height: 30), options: PHImageRequestOptions()) { image, info in
                guard let self = self else { return }
                if let image = image { self.draftButton.setImage(image, for: .normal) }
            }
        }
        addSubview(draftsView)
        NSLayoutConstraint.activate([
            draftButton.heightAnchor.constraint(equalToConstant: 40),
            draftButton.widthAnchor.constraint(equalToConstant: 40),
            draftsView.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -28),
            draftsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
        
        let draftVideos = DraftVideoModel.getVideos()
        let videosCount = draftVideos?.count ?? 0
        draftsView.isHidden = videosCount == 0
    }
}

// MARK: Done Button

extension LeapCameraView {
    
    private func setupDoneButton() {
        addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: galleryView.topAnchor, constant: -55)
        ])
    }
}

// MARK: Camera Action View

extension LeapCameraView {
    
    private func setupCameraActionView() {
        addSubview(cameraActionView)
        NSLayoutConstraint.activate([
            cameraActionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            cameraActionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            cameraActionView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16),
            cameraActionView.widthAnchor.constraint(equalToConstant: 62)
        ])
    }
}

// MARK: Watermark View

extension LeapCameraView {
    
    private func setupWaterMark() {
        watermarkView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(watermarkView)
        NSLayoutConstraint.activate([
            watermarkView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            watermarkView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        watermarkView.isHidden = true
    }
}

// MARK: Grid View

extension LeapCameraView {
    
    private func setupGridView() {
        previewView.addSubview(gridView)
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            gridView.topAnchor.constraint(equalTo: previewView.topAnchor),
            gridView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor)
        ])
    }
}

// MARK: Camera Bottom Bar

extension LeapCameraView {

    private func setupProgressView() {
        addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}

// MARK: Camera Ring

extension LeapCameraView {

    private func setupRecordButton() {
        addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -24),
            recordButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 60),
            recordButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

}

// MARK: Media Picker

extension LeapCameraView {

    private func setupMediaPicker() {
        addSubview(mediaPickerView)
        NSLayoutConstraint.activate([
            mediaPickerView.bottomAnchor.constraint(equalTo: recordButton.topAnchor),
            mediaPickerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            mediaPickerView.widthAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.widthAnchor),
        ])
    }

}

// MARK: Hint

extension LeapCameraView {

    private func setupHintLabel() {
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

// MARK: Activity Indicator

extension LeapCameraView {

    public func setupActivityIndicator() {
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}

// MARK: Close button

extension LeapCameraView {
    
    public func setupCloseButton() {
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
}

// MARK: Tap to Focus

extension LeapCameraView {

    public func drawTapAnimationView(at point: CGPoint) {
        let view = TapAnimationView(center: point)
        addSubview(view)

        view.show()
    }

}

