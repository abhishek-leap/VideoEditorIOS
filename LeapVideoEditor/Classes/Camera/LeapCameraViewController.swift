//
//  LeapCameraController.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 01/08/22.
//

import UIKit
import SCSDKCameraKit
import SCSDKCameraKitReferenceUI
import DKImagePickerController
import GiphyUISDK
import Photos

public protocol VideoEditorDelegate: AnyObject {
    
    func videoEditorDidCancel()
    
    func videoEditorDidCapture(videoURL: URL)
}

/// Describes an interface to control app orientation
public protocol LeapAppOrientationDelegate: AnyObject {
    
    /// Lock app orientation
    /// - Parameter orientation: interface orientation mask to lock orientations to
    func lockOrientation(_ orientation: UIInterfaceOrientationMask)
    
    /// Unlock orientation
    func unlockOrientation()
    
}

/// This is the default view controller which handles setting up the camera, lenses, carousel, etc.
open class LeapCameraViewController: BaseViewController, LeapCameraControllerUIDelegate {
    
    // MARK: CameraKit properties
    
    /// A controller which manages the camera and lenses stack on behalf of the view controller
    public let cameraController: LeapCameraController
    private let captureSessionQueue = DispatchQueue(label: "FilteringCameraController_capture_session_queue",
                                                    attributes: [])
    /// App orientation delegate to control app orientation
    public weak var appOrientationDelegate: LeapAppOrientationDelegate?
    
    public weak var videoEditorDelegate: VideoEditorDelegate?
    
    let token: String
    var shouldResume: Bool
    
    var recordings = [(recordURL: URL, duration: Double, isPhoto: Bool)]()
    var timer: Timer?
    var maxDuration: Double = 15
    var currentDuration: Double = 0
    var audioTimelineItems = [LeapTimelineItem]()
    var selectedTrack: Track?
    
    /// convenience prop to get current interface orientation of application/scene
    fileprivate var applicationInterfaceOrientation: UIInterfaceOrientation {
        var interfaceOrientation = UIApplication.shared.statusBarOrientation
        if #available(iOS 13, *),
           let sceneOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        {
            interfaceOrientation = sceneOrientation
        }
        return interfaceOrientation
    }
    
    /// convenience prop to get current interface orientation mask to lock device from rotation
    fileprivate var currentInterfaceOrientationMask: UIInterfaceOrientationMask {
        switch applicationInterfaceOrientation {
        case .portrait, .unknown: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        @unknown default:
            return .portrait
        }
    }
    
    // The backing view
    public lazy var cameraView = LeapCameraView()
    var selectedLens: LensItem?
    
    override open func loadView() {
        view = cameraView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        cameraView.cameraActionView.backgroundColor = .clear
        CameraPermissionHelper.checkPermission(for: .camera, controller: self) {[weak self] granted in
            guard let self = self else { return}
            if granted {
                CameraPermissionHelper.checkPermission(for: .microphone, controller: self) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.setup()
                        }
                        if let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                            let mediaURL = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("media")
                            if !FileManager.default.fileExists(atPath: mediaURL.path) {
                                do {
                                    try FileManager.default.createDirectory(atPath: mediaURL.path, withIntermediateDirectories: true, attributes: nil)
                                } catch { }
                            }
                            let soundURL = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("sounds")
                            if !FileManager.default.fileExists(atPath: soundURL.path) {
                                do {
                                    try FileManager.default.createDirectory(atPath: soundURL.path, withIntermediateDirectories: true, attributes: nil)
                                } catch { }
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self?.dismiss(animated: true) {[weak self] in
                                self?.videoEditorDelegate?.videoEditorDidCancel()
                            }
                        }
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {[weak self] in
                        self?.videoEditorDelegate?.videoEditorDidCancel()
                    }
                }
            }
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraController.increaseBrightnessIfNecessary()
        cameraView.previewView.safeArea = CGRect(x: 0, y: 0, width: cameraView.frame.size.width-cameraView.cameraActionView.frame.size.width, height: cameraView.previewView.frame.size.height)
        if shouldResume {
            shouldResume = false
            draftAction()
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraController.restoreBrightnessIfNecessary()
    }
    
    // MARK: Init
    
    /// Returns a camera view controller initialized with a camera controller that is configured with a newly created AVCaptureSession stack
    /// and CameraKit session with the specified configuration and list of group IDs.
    /// - Parameters:
    ///   - repoGroups: List of group IDs to observe.
    ///   - sessionConfig: Config to configure session with application id and api token.
    ///   Pass this in if you wish to dynamically update or overwrite the application id and api token in the application's `Info.plist`.
    convenience public init(repoGroups: [String], videoEditorDelegate: VideoEditorDelegate, sessionConfig: SessionConfig? = nil, token: String, shouldResume: Bool, environment: String) {
        // Max size of lens content cache = 150 * 1024 * 1024 = 150MB
        // 150MB to make sure that some lenses that use large assets such as the ones required for
        // 3D body tracking (https://lensstudio.snapchat.com/templates/object/3d-body-tracking) have
        // enough cache space to fit alongside other lenses.
        let lensesConfig = LensesConfig(cacheConfig: CacheConfig(lensContentMaxSize: 150 * 1024 * 1024))
        let cameraKit = Session(sessionConfig: sessionConfig, lensesConfig: lensesConfig, errorHandler: nil)
        let captureSession = AVCaptureSession()
        self.init(cameraKit: cameraKit, captureSession: captureSession, repoGroups: repoGroups, videoEditorDelegate: videoEditorDelegate, token: token, shouldResume: shouldResume, environment: environment)
    }
    
    /// Convenience init to configure a camera controller with a specified AVCaptureSession stack, CameraKit, and list of group IDs.
    /// - Parameters:
    ///   - cameraKit: camera kit session
    ///   - captureSession: a backing AVCaptureSession to use
    ///   - repoGroups: the group IDs to observe
    convenience public init(cameraKit: CameraKitProtocol, captureSession: AVCaptureSession, repoGroups: [String], videoEditorDelegate: VideoEditorDelegate, token: String, shouldResume: Bool, environment: String) {
        let cameraController = LeapCameraController(cameraKit: cameraKit, captureSession: captureSession)
        cameraController.groupIDs = repoGroups
        self.init(cameraController: cameraController, videoEditorDelegate: videoEditorDelegate, token: token, shouldResume: shouldResume, environment: environment)
    }
    
    /// Initialize the view controller with a preconfigured camera controller
    /// - Parameter cameraController: the camera controller to use.
    public init(cameraController: LeapCameraController, videoEditorDelegate: VideoEditorDelegate, token: String, shouldResume: Bool, environment: String) {
        Path.environment = environment
        self.cameraController = cameraController
        self.videoEditorDelegate = videoEditorDelegate
        self.token = token
        self.shouldResume = shouldResume
        super.init(nibName: nil, bundle: nil)
        checkSDKVersion()
    }
    
    func checkSDKVersion() {
        guard let version = LeapBundleHelper.resourcesBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, UserDefaults.standard.string(forKey: "appVersion") != version else { return }
        let currentVersion = UserDefaults.standard.string(forKey: "appVersion") ?? "0.1.1"
        if let appVersionInt = Int(currentVersion.replacingOccurrences(of: ".", with: "")), appVersionInt < 036 {
            UserDefaults.standard.removeObject(forKey: DraftVideoModel.Key.video.rawValue)
        }
        UserDefaults.standard.set(version, forKey: "appVersion")
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overridable Helper
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cameraController.cameraKit.videoOrientation = videoOrientation(
            from: orientation(from: applicationInterfaceOrientation, transform: coordinator.targetTransform))
    }
    
    // MARK: Lenses Setup
    
    /// Apply a specific lens
    /// - Parameters:
    ///   - lens: selected lens
    open func applyLens(_ lens: Lens) {
        cameraView.activityIndicator.stopAnimating()  // stop any loading indicator that may still be going on from previous lens
        cameraController.applyLens(lens) { [weak self] success in
            guard let strongSelf = self else { return }
            if success {
                print("\(lens.name ?? "Unnamed") (\(lens.id)) Applied")
                
                DispatchQueue.main.async {
                    strongSelf.hideAllHints()
                }
            }
        }
        cameraView.watermarkView.isHidden = false
    }
    
    /// Helper function to clear currently selected lens
    open func clearLens() {
        cameraView.activityIndicator.stopAnimating()  // stop any loading indicator that may still be going on from current lens
        cameraController.clearLens(completion: nil)
        cameraView.watermarkView.isHidden = true
    }
    
    // MARK: CameraControllerUIDelegate
    
    open func cameraController(_ controller: LeapCameraController, updatedLenses lenses: [Lens]) {
        //todo update lens view controller
    }
    
    open func cameraControllerRequestedActivityIndicatorShow(_ controller: LeapCameraController) {
        cameraView.activityIndicator.startAnimating()
    }
    
    open func cameraControllerRequestedActivityIndicatorHide(_ controller: LeapCameraController) {
        cameraView.activityIndicator.stopAnimating()
    }
    
    open func cameraControllerRequestedRingLightShow(_ controller: LeapCameraController) {
        cameraView.ringLightView.isHidden = false
    }
    
    open func cameraControllerRequestedRingLightHide(_ controller: LeapCameraController) {
        cameraView.ringLightView.isHidden = true
    }
    
    open func cameraControllerRequestedFlashControlHide(_ controller: LeapCameraController) {
        //todo handle stuff
    }
    
    open func cameraControllerRequestedCameraFlip(_ controller: LeapCameraController) {
        flip(sender: controller)
    }
    
    open func cameraController(
        _ controller: LeapCameraController, requestedHintDisplay hint: String, for lens: Lens, autohide: Bool
    ) {
        guard lens.id == cameraController.currentLens?.id else { return }
        
        cameraView.hintLabel.text = hint
        cameraView.hintLabel.layer.removeAllAnimations()
        cameraView.hintLabel.alpha = 0.0
        
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.cameraView.hintLabel.alpha = 1.0
            }
        ) { completed in
            guard autohide, completed else { return }
            UIView.animate(
                withDuration: 0.5, delay: 2.0,
                animations: {
                    self.cameraView.hintLabel.alpha = 0.0
                }, completion: nil)
        }
    }
    
    open func cameraController(_ controller: LeapCameraController, requestedHintHideFor lens: Lens) {
        hideAllHints()
    }
    
    private func hideAllHints() {
        cameraView.hintLabel.layer.removeAllAnimations()
        cameraView.hintLabel.alpha = 0.0
    }
    
    public func presentController(from controller: UIViewController) {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.isNavigationBarHidden = true
        controller.present(navigationController, animated: true)
    }
}

// MARK: General Camera Setup

extension LeapCameraViewController {
    
    /// Calls the relevant setup methods on the camera controller
    fileprivate func setup() {
        configureCameraKit()
        setupActions()
        cameraController.cameraKit.add(output: cameraView.previewView)
        cameraController.uiDelegate = self
        setupSystemNotificationObservers()
    }
    
    fileprivate func configureCameraKit() {
        cameraController.configure(
            orientation: videoOrientation(from: applicationInterfaceOrientation),
            textInputContextProvider: TextInputProvider(cameraViewController: self),
            agreementsPresentationContextProvider: AgreementsPresentationProvider(
                cameraViewController: self),
            completion: { [weak self] in
                // Re-check adjustment availability and add observer only after completion, because during first setup
                // permissions may not have been granted yet/the session may not start immediately until permissions
                // are granted.
                //                guard let self = self else { return }
                //                self.updateAdjustmentButtonStatus()
                //                self.cameraController.cameraKit.adjustments.processor?.addObserver(self)
            })
    }
    
    /// Configures the target actions and delegates needed for the view controller to function
    fileprivate func setupActions() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(sender:)))
        cameraView.previewView.addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(flip(sender:)))
        doubleTap.numberOfTapsRequired = 2
        cameraView.previewView.addGestureRecognizer(doubleTap)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoom(sender:)))
        cameraView.previewView.addGestureRecognizer(pinchGestureRecognizer)
        cameraView.previewView.automaticallyConfiguresTouchHandler = true
        
        // todo        cameraView.cameraActionsView.flipCameraButton.addTarget(
        //            self, action: #selector(self.flip(sender:)), for: .touchUpInside)
        cameraView.closeButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
        cameraView.cameraActionView.setup(cameraActions: [.flip, .sound, .effects, .flash, .grid])
        cameraView.cameraActionView.actionDelegate = self
        
        setupFlashButtons()
        
        //        cameraView.cameraButton.delegate = self todo update
        //        cameraView.cameraButton.allowWhileRecording = [doubleTap, pinchGestureRecognizer]
        
        cameraView.doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        cameraView.recordButton.addTarget(self, action: #selector(recordTapped(_:)), for: .touchUpInside)
        cameraView.latestImage.addTarget(self, action: #selector(galleryAction), for: .touchUpInside)
        cameraView.draftButton.addTarget(self, action: #selector(draftAction), for: .touchUpInside)
        cameraView.mediaPickerView.provider = cameraController.lensMediaProvider
        cameraView.mediaPickerView.delegate = cameraController
        cameraController.lensMediaProvider.uiDelegate = cameraView.mediaPickerView
    }
    
}

// MARK: Camera Action Delegate

extension LeapCameraViewController: CameraActionDelegate {
    
    public func didSelect(action: CameraAction) {
        switch action {
        case .flip:
            cameraController.flipCamera()
        case .sound:
            let controller = SoundCollectionViewController(token: token)
            controller.delegate = self
            controller.selectedTrack = selectedTrack
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.setupDefaultStyle()
            present(navigationController, animated: true)
        case .effects:
            let lensController = LensViewController(cameraController: cameraController, lensSelectionDelegate: self)
            lensController.presentController(from: self)
        case .flash:
            guard cameraController.cameraPosition == .back else { return }
            if let inputDevice = cameraController.cameraInputDevice, inputDevice.hasTorch && inputDevice.isTorchAvailable {
                do {
                    try inputDevice.lockForConfiguration()
                    inputDevice.torchMode = inputDevice.torchMode == .on ? .off : .on
                    inputDevice.unlockForConfiguration()
                } catch { }
            }
        case .grid:
            cameraView.gridView.isHidden.toggle()
        default:
            print("not applicable")
        }
    }
}

// MARK: Close view

extension LeapCameraViewController {
    
    @objc private func closeButtonTapped(_ sender: UIButton) {
        //        cameraController.cameraKit.activeInput.stopRunning()
        //        cameraController.cameraKit.stop()
        dismiss(animated: true) {[weak self] in
            self?.videoEditorDelegate?.videoEditorDidCancel()
        }
    }
}

// MARK: Done button

extension LeapCameraViewController {
    
    @objc func doneTapped() {
        guard !recordings.isEmpty else { return }
        let videoUrls = recordings.map { ($0.recordURL, false) }
        let totalVideoDuration = recordings.reduce(0) {$0 + $1.duration}
        let videoEditor = LeapVideoEditorViewController(videoURLs: videoUrls, audioTimelineItems: audioTimelineItems, videoDuration: totalVideoDuration, token: token)
        self.redirectToPlayleapEditor(videoEditor: videoEditor)
    }
    
    // MARK: redirect to playleap video editor
    /// Parameters-
    ///  videoUrls: List of videos
    
    private func redirectToPlayleapEditor(videoEditor: LeapVideoEditorViewController) {
        cameraController.clearLens(willReapply: true)
        cameraController.restoreBrightnessIfNecessary()
        cameraController.captureSession.stopRunning()
        videoEditor.videoEditorDelegate = self.videoEditorDelegate
        videoEditor.backTapped = {[weak self] in
            guard let self = self else { return }
            DispatchQueue.global().async {
                self.cameraController.captureSession.startRunning()
            }
            self.cameraController.reapplyCurrentLens()
            self.cameraController.increaseBrightnessIfNecessary()
            self.recordings = []
            self.audioTimelineItems = []
            self.cameraView.recordButton.setImage(UIImage(named: "start-recording", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
            self.maxDuration = 15
            self.cameraView.progressView.progressBar.progress = 0
            self.cameraView.progressView.maxTimeLabel.text = ""
            self.cameraView.progressView.timeLabel.text = ""
            let draftVideosCount = DraftVideoModel.getVideos()?.count ?? 0
            self.cameraView.draftsView.isHidden = draftVideosCount == 0
        }
        self.navigationController?.pushViewController(videoEditor, animated: true)
        //        let movie = AVMutableComposition()
        //        let videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        //        let audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        //        var currentTime = CMTime.zero
        //        for recording in recordings {
        //            do {
        //                let asset = AVURLAsset(url: recording.recordURL) //1
        //                let assetAudioTrack = asset.tracks(withMediaType: .audio).first! //2
        //                let assetVideoTrack = asset.tracks(withMediaType: .video).first!
        //                let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration) //3
        //                try videoTrack?.insertTimeRange(assetRange, of: assetVideoTrack, at: currentTime) //4
        //                try audioTrack?.insertTimeRange(assetRange, of: assetAudioTrack, at: currentTime)
        //                currentTime = CMTimeAdd(currentTime, asset.duration)
        //            } catch { }
        //        }
        //        let exporter = AVAssetExportSession(asset: movie, presetName: AVAssetExportPresetHighestQuality) //1
        //        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        //        //configure exporter
        //        exporter?.outputURL = exportURL //2
        //        exporter?.outputFileType = .mov
        //        exporter?.exportAsynchronously {[weak self] in
        //            guard let self = self else { return }
        //            DispatchQueue.main.async {
        //                if let error = exporter?.error {
        //                    self.showAlert(title: "Error", msg: error.localizedDescription)
        //                } else {
        //
        //                }
        //            }
        //        }
    }
}

// MARK: Gallery action

extension LeapCameraViewController {
    
    @objc private func galleryAction() {
        let galleryController = MediaGalleryViewController()
        galleryController.assetsDelegate = self
        self.present(galleryController, animated: true, completion: nil)
    }
}

// MARK: Draft videos action

extension LeapCameraViewController {
    
    @objc func draftAction() {
        let controller = DraftVideosController()
        controller.delegate = self
        let videos = DraftVideoModel.getVideos() ?? []
        controller.draftVideos = videos
        self.present(controller, animated: true, completion: nil)
    }
}

// MARK: Record Button

extension LeapCameraViewController {
    
    @objc func recordTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            self.cameraView.progressView.setupProgressSections(recordings: self.recordings, maxDuration: self.maxDuration)
            cameraController.startRecording()
            appOrientationDelegate?.lockOrientation(currentInterfaceOrientationMask)
            cameraView.mediaPickerView.dismiss()
            cameraView.cameraActionView.isHidden = true
            cameraView.galleryView.isHidden = true
            cameraView.doneButton.isHidden = true
            currentDuration = 0
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        } else { stopRecording() }
    }
    
    func stopRecording() {
        timer?.invalidate()
        cameraController.finishRecording { url, error in
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                guard let url = url else {
                    if let error = error { self.showAlert(title: "Error", msg: error.localizedDescription) }
                    return
                }
                let asset = AVURLAsset(url: url)
                let duration = CMTimeGetSeconds(asset.duration)
                if self.selectedTrack != nil, let audioItem = self.audioTimelineItems.last {
                    audioItem.size += duration
                }
                self.recordings.append((url, duration, false))
                self.appOrientationDelegate?.unlockOrientation()
                self.cameraView.cameraActionView.isHidden = false
                self.cameraView.galleryView.isHidden = false
                self.cameraView.doneButton.isHidden = false
            }
        }
    }
    
    @objc func updateProgress() {
        currentDuration += 0.1
        let currentTotalDuration = recordings.reduce(currentDuration, { $0 + $1.duration })
        
        if currentTotalDuration > maxDuration {
            if maxDuration == 60 {
                stopRecording()
                cameraView.recordButton.isSelected = false
            } else if maxDuration == 30 {
                maxDuration = 60
                cameraView.progressView.setupProgressSections(recordings: recordings, maxDuration: maxDuration)
            } else {
                maxDuration = 30
                cameraView.progressView.setupProgressSections(recordings: recordings, maxDuration: maxDuration)
            }
        }
        cameraView.progressView.timeLabel.text = currentTotalDuration.getTimeString()
        cameraView.progressView.maxTimeLabel.text = maxDuration.getTimeString()
        cameraView.progressView.progressBar.setProgress(Float(currentTotalDuration/maxDuration), animated: false)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear], animations: {[unowned self] in
            self.cameraView.progressView.progressBar.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: Single Tap

extension LeapCameraViewController {
    
    /// Handles a single tap gesture by dismissing the tone map control if it is visible and setting the point
    /// of interest otherwise.
    /// - Parameter sender: The single tap gesture recognizer.
    @objc private func handleSingleTap(sender: UITapGestureRecognizer) {
        setPointOfInterest(sender: sender)
    }
    
}

// MARK: Camera Point of Interest

extension LeapCameraViewController {
    
    /// Sets the camera's point of interest for focus and exposure based on where the user tapped
    /// - Parameter sender: the caller
    @objc fileprivate func setPointOfInterest(sender: UITapGestureRecognizer) {
        cameraView.drawTapAnimationView(at: sender.location(in: sender.view))
        
        guard let focusPoint = sender.captureDevicePoint else { return }
        
        cameraController.setPointOfInterest(at: focusPoint)
    }
    
}

// MARK: Camera Flip

extension LeapCameraViewController {
    
    /// Flips the camera
    /// - Parameter sender: the caller
    @objc fileprivate func flip(sender: Any) {
        //        switch cameraController.cameraPosition {
        //        case .front:
        //            cameraView.cameraActionsView.setupFlashToggleButtonForFront()
        //            cameraView.cameraActionsView.flipCameraButton.accessibilityValue = CameraElements.CameraFlip.front
        //        case .back:
        //            cameraView.cameraActionsView.setupFlashToggleButtonForBack()
        //            cameraView.cameraActionsView.flipCameraButton.accessibilityValue = CameraElements.CameraFlip.back
        //        default:
        //            break
        //        }
    }
}

// MARK: System Notification Observers

extension LeapCameraViewController {
    
    @objc private func increaseBrightnessIfNecessary() {
        cameraController.increaseBrightnessIfNecessary()
    }
    
    @objc private func restoreBrightnessIfNecessary() {
        cameraController.restoreBrightnessIfNecessary()
    }
    
    private func setupSystemNotificationObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(restoreBrightnessIfNecessary), name: UIApplication.willResignActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(increaseBrightnessIfNecessary), name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(restoreBrightnessIfNecessary), name: UIApplication.willTerminateNotification,
            object: nil)
    }
    
}

// MARK: Camera Zoom

extension LeapCameraViewController {
    
    /// Zooms the camera based on a pinch gesture
    /// - Parameter sender: the caller
    @objc fileprivate func zoom(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .changed:
            cameraController.zoomExistingLevel(by: sender.scale)
        case .ended:
            cameraController.finalizeZoom()
        default:
            break
        }
    }
}

// MARK: selected gallery assets delegate

extension LeapCameraViewController: GalleryAssetsDelegate {
    
    // MARK: get all the selected photos/videos here
    // Parameters:
    // assets : Array of selected assets
    
    func didSelectedAssets(_ assets: [(recordURL: URL, duration: Double, isPhoto: Bool)]) {
        recordings.append(contentsOf: assets)
        self.doneTapped()
    }
}

// MARK: Ring Light Control Delegate

extension LeapCameraViewController: LeapFlashControlViewDelegate {
    
    public func flashControlView(_ view: LeapFlashControlView, updatedRingLightValue value: Float) {
        cameraView.ringLightView.ringLightGradient.updateIntensity(to: CGFloat(value), animated: true)
    }
    
    public func flashControlView(_ view: LeapFlashControlView, selectedRingLightColor color: UIColor) {
        cameraView.ringLightView.changeColor(to: color)
    }
    
    public func flashControlView(_ view: LeapFlashControlView, updatedFlashMode flashMode: LeapCameraController.FlashMode) {
        cameraController.flashState = .on(flashMode)
    }
    
}

// MARK: Flash Buttons

extension LeapCameraViewController {
    
    private func setupFlashButtons() {
        //        cameraView.cameraActionsView.flashActionView.enableAction = { [weak self] in
        //            self?.cameraController.enableFlash()
        //        }
        
        //        cameraView.cameraActionsView.flashActionView.disableAction = { [weak self] in
        //            self?.cameraController.disableFlash()
        //        }
    }
    
}

private extension LeapMediaPickerView {
    func dismiss() {
        if let provider = provider {
            mediaPickerProviderRequestedUIDismissal(provider)
        }
    }
}

// MARK: Presentation Delegate

extension LeapCameraViewController: UIAdaptivePresentationControllerDelegate {
    
    open func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        guard presentationController.presentedViewController is PreviewViewController else { return }
        cameraController.reapplyCurrentLens()
        cameraController.increaseBrightnessIfNecessary()
    }
}

// MARK: Agreements presentation context

extension LeapCameraViewController {
    
    class AgreementsPresentationProvider: NSObject, AgreementsPresentationContextProvider {
        
        weak var cameraViewController: LeapCameraViewController?
        
        init(cameraViewController: LeapCameraViewController) {
            self.cameraViewController = cameraViewController
        }
        
        public var viewControllerForPresentingAgreements: UIViewController {
            return cameraViewController ?? UIApplication.shared.keyWindow!.rootViewController!
        }
        
        public func dismissAgreementsViewController(_ viewController: UIViewController, accepted: Bool) {
            viewController.dismiss(animated: true, completion: nil)
            if !accepted { cameraViewController?.selectedLens = nil }
        }
        
    }
    
}

// MARK: Text input context

extension LeapCameraViewController {
    
    class TextInputProvider: NSObject, TextInputContextProvider {
        
        public let keyboardAccessoryProvider: TextInputKeyboardAccessoryProvider? = KeyboardAccessoryViewProvider()
        weak var cameraViewController: LeapCameraViewController?
        
        init(cameraViewController: LeapCameraViewController) {
            self.cameraViewController = cameraViewController
        }
        
        public var parentView: UIView? {
            cameraViewController?.view
        }
        
    }
    
}

// MARK: Orientation Helper

extension LeapCameraViewController {
    
    /// Calculates a user interface orientation based on an input orientation and provided affine transform
    /// - Parameters:
    ///   - orientation: the base orientation
    ///   - transform: the transform specified
    /// - Returns: the resulting orientation
    fileprivate func orientation(from orientation: UIInterfaceOrientation, transform: CGAffineTransform)
    -> UIInterfaceOrientation
    {
        let conversionMatrix: [UIInterfaceOrientation] = [
            .portrait, .landscapeLeft, .portraitUpsideDown, .landscapeRight,
        ]
        guard let oldIndex = conversionMatrix.firstIndex(of: orientation), oldIndex != NSNotFound else {
            return .unknown
        }
        let rotationAngle = atan2(transform.b, transform.a)
        var newIndex = Int(oldIndex) - Int(round(rotationAngle / (.pi / 2)))
        while newIndex >= 4 {
            newIndex -= 4
        }
        while newIndex < 0 {
            newIndex += 4
        }
        return conversionMatrix[newIndex]
    }
    
    /// Determines the applicable AVCaptureVideoOrientation from a given UIInterfaceOrientation
    /// - Parameter interfaceOrientation: the interface orientation
    /// - Returns: the relevant AVCaptureVideoOrientation
    fileprivate func videoOrientation(from interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .portrait, .unknown: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portraitUpsideDown: return .portraitUpsideDown
        @unknown default: return .portrait
        }
    }
}

// MARK: Lens selection delegate

extension LeapCameraViewController: LensSelectionDelegate {
    
    func didSelect(lens: LensItem) {
        guard let snapLens = cameraController.cameraKit.lenses.repository.lens(id: lens.lensId, groupID: lens.groupId) else { return }
        applyLens(snapLens)
        selectedLens = lens
    }
    
    func didClearLens() {
        clearLens()
    }
}

// MARK: Draft Video Delegates

extension LeapCameraViewController: DraftVideoProtocol {
    
    func emptyDraft() {
        self.cameraView.draftsView.isHidden = true
    }
    
    func didSelectDraftVideo(_ video: DraftVideoModel, index: Int) {
        var videoUrls: [(videoURL: URL, isMuted: Bool)] = []
        let videoItems = video.videoItems
        for item in videoItems {
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let videoURL = documentURL.appendingPathComponent("\(UUID().uuidString).mp4")
            do {
                try item.videoData.write(to: videoURL, options: .atomic)
                videoUrls.append((videoURL, item.isMuted))
            }
            catch {
                print(error.localizedDescription)
            }
        }
        let overlayItems = video.overlayItems
        var leapTimeLineItems: [LeapTimelineItem] = []
        for item in overlayItems {
            guard let type = VideoOverlayType(rawValue: item.overlayType) else { continue }
            switch type {
            case .sticker, .text:
                guard let image = GiphyYYImage(data: item.overlayData) else { continue }
                let timeLineItem = LeapTimelineItem(itemData: item.overlayData, thumbnail: image, type: type, startPosition: 0, position: CGPoint(x: item.overlayOriginX, y: item.overlayOriginY), itemSize: CGSize(width: item.overlayWidth, height: item.overlayHeight))
                timeLineItem.startPosition = TimeInterval(item.startPosition)
                timeLineItem.size = TimeInterval(item.overlayDuration)
                leapTimeLineItems.append(timeLineItem)
            case .audio:
                let data = item.overlayData
                let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp3")
                data.saveTempData(filePath: exportURL) { filePath in
                    let timeLineItem = LeapTimelineItem(itemData: filePath, thumbnail: GiphyYYImage(), type: type, startPosition: 0, position: CGPoint(x: Int(item.overlayOriginX), y: Int(item.overlayOriginY)), itemSize: CGSize(width: Int(item.overlayWidth), height: Int(item.overlayHeight)))
                    timeLineItem.startPosition = TimeInterval(item.startPosition)
                    timeLineItem.size = TimeInterval(item.overlayDuration)
                    leapTimeLineItems.append(timeLineItem)
                }
            case .record:
                break
            }
        }
        //todo update from draft
        let videoEditor = LeapVideoEditorViewController(videoURLs: videoUrls, audioTimelineItems: audioTimelineItems, videoDuration: video.totalVideoDuration, token: token)
        self.redirectToPlayleapEditor(videoEditor: videoEditor)
        if let filter = video.videoFilter {
            videoEditor.selectedFilter = VideoFilterModel(filter: CIFilter(name: filter), filterName: filter, thumbnail: UIImage(), filterLabel: filter)
        }
        // delay of 0.5 sec to load the video in avplayer then add overlay items saved in draft
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            videoEditor.setDraftItems(leapTimeLineItems, leftAnchor: video.leftAnchor, rightAnchor: video.rightAnchor, index: index)
        }
    }
}

// MARK: Sound delegate

extension LeapCameraViewController: SoundControllerDelegate {
    
    func audioSelected(audioURL: URL, track: Track) {
        let item = LeapTimelineItem(itemData: audioURL, thumbnail: GiphyYYImage(), type: .audio, startPosition: recordings.reduce(0, { $0+$1.duration }), size: 0)
        if let lastItem = audioTimelineItems.last, lastItem.size == 0 { audioTimelineItems.removeLast() }
        audioTimelineItems.append(item)
        cameraView.recordButton.kf.setImage(with: URL(string: track.images.imagesDefault), for: .normal)
        selectedTrack = track
    }
    
    func removeTrack() {
        selectedTrack = nil
        if let lastItem = audioTimelineItems.last, lastItem.size == 0 { audioTimelineItems.removeLast() }
        cameraView.recordButton.setImage(UIImage(named: "start-recording", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
    }
}
