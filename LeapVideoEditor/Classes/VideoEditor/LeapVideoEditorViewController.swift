//
//  VideoEditorViewController.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 25/08/22.
//

import UIKit
import AVFoundation
import GiphyUISDK
import Kingfisher
import DKImagePickerController
import ffmpegkit

class LeapVideoEditorViewController: BaseViewController {
    let recorderService = VoiceRecordService()
    var isVoiceRecording = false
    var timelineItems = [LeapTimelineItem]()
    var totalVideoDuration: Double
    var player = AVPlayer()
    public let playerLayer: AVPlayerLayer
    var backTapped: (() -> Void)?
    public var isVideoDragging = false
    private var isFromDraft = false
    private var draftVideoIndex = -1
    public var selectedFilter: VideoFilterModel?
    public let filtersManager = VideoFiltersManager.shared
    private var audioTimelineItems = [LeapTimelineItem]()
    var leapTimelineVideoItems = [LeapTimelineVideoItem]()
    private var token: String
    var videoCommands = [String]()
    
    // to set the position of selected sticker/text on the video
    private let dragGestureSetup = VideoOverlayDragView()
    
    public weak var videoEditorDelegate: VideoEditorDelegate?
    
    // manages stickers functionality
    private let stickersManager = GiphyStickersManager.shared
    
    // MARK: UI Elements:-
    
    let cameraActionView: CameraActionView = {
        let cameraActionView = CameraActionView()
        cameraActionView.translatesAutoresizingMaskIntoConstraints = false
        return cameraActionView
    }()
    lazy var doneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "checkmark-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneTapped(_:)), for: .touchUpInside)
        return button
    }()
    let previewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var timeLineView: LeapTimelineView = {
        let view = LeapTimelineView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        return label
    }()
    lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(playTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var micView: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(named: "micIcon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 24
        view.isHidden = true
        view.layer.borderColor = UIColor.white.cgColor
        view.addTarget(self, action: #selector(voiceRecordingAction), for: .touchUpInside)
        return view
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setImage(UIImage(named: "bin-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)
        return button
    }()
    lazy var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setImage(UIImage(named: "mute", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(muteTapped(_:)), for: .touchUpInside)
        return button
    }()
    lazy var infoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "infoBackground", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        return view
    }()
    lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "back-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    init(videoURLs: [(videoURL: URL, isMuted: Bool)], audioTimelineItems: [LeapTimelineItem], videoDuration: Double, token: String) {
        self.totalVideoDuration = videoDuration
        self.playerLayer = AVPlayerLayer(player: player)
        self.token = token
        super.init(nibName: nil, bundle: nil)
        videoURLs.forEach {
            let item = LeapTimelineVideoItem(videoURL: $0.videoURL)
            item.isMuted = $0.isMuted
            leapTimelineVideoItems.append(item)
        }
        self.audioTimelineItems = audioTimelineItems
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor(named: "backgroundColor", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        previewView.layer.addSublayer(playerLayer)
        setupTimeLineView()
        setupPreviewView()
        setupDoneButton()
        setupCameraActionView()
        setupInfoView()
        setupBackButton()
        setupActions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraActionView.setup(cameraActions: [.sound, .text, .stickers, .filters, .voice])
        player.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(1), timescale: 10), queue: .main) {[weak self] time in
            guard let self = self, !self.isVideoDragging else { return }
            self.timeLineView.updateScroll(time: time)
            self.updateTimeline(currentTime: CMTimeGetSeconds(time))
        }
        setupInteraction()
        setupVideo()
    }
    
    func setupVideo() {
        videoCommands = []
        let videoItem = AVMutableComposition()
        let videoTrack = videoItem.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = videoItem.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var currentTime = CMTime.zero
        let startTimeSeconds = (timeLineView.leftanchorConstraint.constant-10)/24
        let startTime = CMTime(seconds: startTimeSeconds, preferredTimescale: 1000)
        let maxDurationSeconds = (timeLineView.videoStackView.frame.size.width/24) - startTimeSeconds - ((abs(timeLineView.rightAnchorConstraint.constant)-10)/24)
        let maxDuration = CMTime(seconds: maxDurationSeconds, preferredTimescale: 1000)
        var originalTime = CMTime(seconds: 0, preferredTimescale: 1000)
        var instructions = [AVMutableVideoCompositionInstruction]()
        var finalSize = CGSize.zero
        var videoTransform = [(transform: CGAffineTransform, timeRange: CMTimeRange)]()
        for leapTimelineVideoItem in leapTimelineVideoItems {
            let asset = AVURLAsset(url: leapTimelineVideoItem.videoURL)
            let assetVideoTrack = asset.tracks(withMediaType: .video)[0]
            let signedSize = assetVideoTrack.naturalSize.applying(assetVideoTrack.preferredTransform)
            let videoSize = CGSize(width: abs(signedSize.width), height: abs(signedSize.height))
            if videoSize.width >= finalSize.width && videoSize.height >= finalSize.height {
                finalSize = videoSize
            }
        }
        for leapTimelineVideoItem in leapTimelineVideoItems {
            let asset = AVURLAsset(url: leapTimelineVideoItem.videoURL) //1
            var startPosition = CMTime(seconds: leapTimelineVideoItem.startPosition, preferredTimescale: 1000)
            var size = CMTime(seconds: leapTimelineVideoItem.size, preferredTimescale: 1000)
            if currentTime < startTime {
                if startTime > size+currentTime {
                    currentTime = currentTime + size
                    continue
                } else {
                    let timeToSubtract = startTime - currentTime
                    startPosition = startPosition + timeToSubtract
                    currentTime = currentTime + timeToSubtract
                    size = size - timeToSubtract
                }
            }
            var maxDurationReached = false
            if originalTime + size > maxDuration {
                size = maxDuration - originalTime
                maxDurationReached = true
            }
            let assetRange = CMTimeRangeMake(start: startPosition, duration: size)
            if !leapTimelineVideoItem.isMuted, let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
                leapTimelineVideoItem.hasAudio = true
                do {
                    try audioTrack?.insertTimeRange(assetRange, of: assetAudioTrack, at: originalTime)
                } catch { }
            } else {
                leapTimelineVideoItem.hasAudio = false
            }
            do {
                let assetVideoTrack = asset.tracks(withMediaType: .video)[0]
                let rotation = atan2(Double(assetVideoTrack.preferredTransform.b), Double(assetVideoTrack.preferredTransform.a)) * (180 / .pi)
                let signedSize = assetVideoTrack.naturalSize.applying(assetVideoTrack.preferredTransform)
                let videoSize = CGSize(width: abs(signedSize.width), height: abs(signedSize.height))
                let isDeviceLandscapeLeft = rotation == -90 || rotation == 270
                let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
                var transform = CGAffineTransform.identity
                var invertedTransform = CGAffineTransform.identity
                let widthRatio = finalSize.width/videoSize.width
                let heightRatio = finalSize.height/videoSize.height
                var vf = "-vf \""
                if widthRatio > heightRatio {
                    vf += "crop=\(videoSize.width):trunc(\((finalSize.height/finalSize.width)*videoSize.width)):0:0,"
                } else if heightRatio > widthRatio {
                    vf += "crop=trunc(\((finalSize.width/finalSize.height)*videoSize.height)):\(videoSize.height):0:0,"
                }
                if finalSize.width > finalSize.height {
                    let ratio = finalSize.width/640
                    let height = ceil((finalSize.height/ratio)/2)*2
                    vf += "scale=640:\(height)\""
                } else {
                    let ratio = finalSize.height/640
                    let width = ceil((finalSize.width/ratio)/2)*2
                    vf += "scale=\(width):640\""
                }
                videoCommands.append(" -ss \(getReadableTime(time: startPosition)) -t \(getReadableTime(time: size)) -i \"\(leapTimelineVideoItem.videoURL.path)\"\(leapTimelineVideoItem.isMuted ? " -an" : "") \(vf)")
                if widthRatio > heightRatio {
//                    if heightRatio > 1 {
//                        transform = transform.translatedBy(x: abs(finalSize.width - videoSize.width*heightRatio)/2, y: 0)
//                    }
                    transform = CGAffineTransform(scaleX: widthRatio, y: widthRatio)
                    invertedTransform = transform
                } else if heightRatio > widthRatio {
//                    if widthRatio > 1 {
//                        transform = transform.translatedBy(x: 0, y: abs(finalSize.height - videoSize.height*widthRatio)/2)
//                    }
                    transform = CGAffineTransform(scaleX: heightRatio, y: heightRatio)
                    invertedTransform = transform
                }
                if abs(rotation) == 180 {
                    transform = transform.translatedBy(x: videoSize.width, y: videoSize.height).rotated(by: CGFloat.pi)
                    invertedTransform = transform
                } else if rotation != 0 {
                    transform = transform.translatedBy(x: isDeviceLandscapeLeft ? 0 : videoSize.width, y: isDeviceLandscapeLeft ? videoSize.height : 0).rotated(by: isDeviceLandscapeLeft ? -(CGFloat.pi/2) : CGFloat.pi/2)
                    let ratio = widthRatio > heightRatio ? widthRatio : heightRatio
                    invertedTransform = invertedTransform.translatedBy(x: isDeviceLandscapeLeft ? finalSize.width/ratio : 0, y: isDeviceLandscapeLeft ? 0 : finalSize.height/ratio).rotated(by: isDeviceLandscapeLeft ? CGFloat.pi/2 : -(CGFloat.pi/2))
                }
                if !transform.isIdentity { instruction.setTransform(transform, at: .zero) }
                let videoTrackInstruction = AVMutableVideoCompositionInstruction()
                videoTrackInstruction.timeRange = CMTimeRange(start: originalTime, duration: size)
                videoTransform.append((invertedTransform, videoTrackInstruction.timeRange))
                videoTrackInstruction.layerInstructions = [instruction]
                instructions.append(videoTrackInstruction)
                try videoTrack?.insertTimeRange(assetRange, of: assetVideoTrack, at: originalTime) //4
                currentTime = currentTime + size
                originalTime = originalTime + size
            } catch { }
            if maxDurationReached { break }
        }
        var audioItems = audioTimelineItems
        audioItems.append(contentsOf: timelineItems.filter({ $0.type == .audio }))
        for audioItem in audioItems {
            guard let audioURL = audioItem.itemData as? URL else { continue }
            let asset = AVURLAsset(url: audioURL)
            guard let assetAudioTrack = asset.tracks(withMediaType: .audio).first else { continue }
            let audioTrack = videoItem.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: audioItem.size, preferredTimescale: 1000)), of: assetAudioTrack, at: CMTime(seconds: audioItem.startPosition, preferredTimescale: 1000))
        }
        let item = AVPlayerItem(asset: videoItem)
        let composition: AVMutableVideoComposition
        if let selectedFilter = selectedFilter {
            composition = AVMutableVideoComposition(asset: videoItem, applyingCIFiltersWithHandler: { request in
                var source = request.sourceImage.applyingFilter(selectedFilter.filterName)
                if let transform = videoTransform.first(where: { $0.timeRange.containsTime(request.compositionTime) })?.transform, !transform.isIdentity {
                    source = source.transformed(by: transform)
                }
                request.finish(with: source, context: nil)
            })
            composition.renderSize = finalSize
            timeLineView.applyTimelineFilters(selectedFilter)
        } else {
            composition = AVMutableVideoComposition()
            composition.instructions = instructions
            composition.frameDuration = CMTimeMake(value: 1, timescale: 1000)
            composition.renderSize = finalSize
            timeLineView.removeTimelineFilter()
        }
        item.videoComposition = composition
        NotificationCenter.default.removeObserver(self)
        player.replaceCurrentItem(with: item)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer.frame = previewView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !audioTimelineItems.isEmpty else { return }
        timelineItems.append(contentsOf: audioTimelineItems)
        for audioTimelineItem in audioTimelineItems {
            timeLineView.insertItem(timelineItem: audioTimelineItem)
        }
        audioTimelineItems = []
    }
    
    func getReadableTime(time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
        let minutes = Int((totalSeconds / 60).truncatingRemainder(dividingBy: 60))
        let hours = Int(totalSeconds / 3600)
        
        return String(format: "%02d:%02d:%02f",hours, minutes, seconds)
    }
    
    @objc func deleteTapped(_ sender: UIButton) {
        guard !isVoiceRecording else { return }
        defer {
            updateDeleteButton()
        }
        if let selectedItem = timeLineView.selectedItem {
            if let index = timelineItems.firstIndex(of: selectedItem.timelineItem) {
                dragGestureSetup.removeDragView(id: selectedItem.timelineItem.id)
                let item = timelineItems.remove(at: index)
                if item.type == .audio { setupVideo() }
                selectedItem.removeFromSuperview()
                timeLineView.effectsScrollView.contentSize.height -= 39
            }
            timeLineView.selectedItem = nil
        } else if timeLineView.selectedVideoIndex >= 0 {
            
        }
    }
    
    @objc func muteTapped(_ sender: UIButton) {
        if timeLineView.selectedVideoIndex >= 0 {
            leapTimelineVideoItems[timeLineView.selectedVideoIndex].isMuted.toggle()
            timeLineView.videoViews[timeLineView.selectedVideoIndex].muteView.isHidden = !leapTimelineVideoItems[timeLineView.selectedVideoIndex].isMuted
            muteButton.setImage(UIImage(named: leapTimelineVideoItems[timeLineView.selectedVideoIndex].isMuted ? "mute" : "unmute", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
            setupVideo()
        }
    }
    
    @objc func playTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.isSelected ? player.play() : player.pause()
    }
    
    @objc func doneTapped(_ sender: UIButton) {
        stopRecording()
        self.showHud()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {[weak self] in
            guard let self = self else { return }
            if self.saveAsDraftAction() {
                self.prepareFinalVideo()
            } else {
                self.removeHud()
                self.showAlert(title: "Error", msg: "Unable to save video in draft. Please try again.")
            }
        }
//        self.presentAlertWithTitleAndMessage(title: "Save as Draft", message: "Do you want to save this video as Draft?", actions: [("Save", .default), ("Don't Save", .cancel)]) {[weak self] index in
//            guard let self = self else { return }
//            self.showHud()
//            Task {
//                if index == 0 {
//                    if self.saveAsDraftAction() {
//                        await self.prepareFinalVideo()
//                    } else {
//                        self.removeHud()
//                        self.showAlert(title: "Error", msg: "Unable to save video in draft. Please try again.")
//                    }
//                } else if index == 1 {
//                    await self.prepareFinalVideo()
//                }
//            }
//        }
    }
    
    @objc func backTapped(_ sender: UIButton) {
        stopRecording()
        self.presentAlertWithTitleAndMessage(title: "Save as Draft", message: "Do you want to save this video as Draft?", actions: [("Save", .default), ("Don't Save", .cancel)]) {[weak self] index in
            guard let self = self else { return }
            func closeView() {
                self.navigationController?.popViewController(animated: true)
                self.backTapped?()
            }
            guard index == 0 else {
                closeView()
                return
            }
            if self.saveAsDraftAction() {
                closeView()
            } else {
                self.showAlert(title: "Error", msg: "Unable to save video in draft. Please try again.")
            }
        }
    }
    
    @objc func playerDidFinishPlaying(_ notification: Notification) {
        playButton.isSelected = false
        player.seek(to: .zero)
    }
    
    func updateTimeline(currentTime: TimeInterval) {
        for timelineItem in timelineItems {
            timelineItem.view.isHidden = timelineItem.startPosition > currentTime || timelineItem.startPosition + timelineItem.size < currentTime
        }
        guard let totalTime = player.currentItem?.duration else { return }
        if totalTime.value > 0 {
            timeLabel.text = "\(currentTime.getTimeString()) / \(CMTimeGetSeconds(totalTime).getTimeString())"
        }
        else {
            timeLabel.text = "\(currentTime.getTimeString()) / \(self.totalVideoDuration.getTimeString())"
        }
        
    }
}

// MARK: Camera Action View

extension LeapVideoEditorViewController {
    
    private func setupCameraActionView() {
        view.addSubview(cameraActionView)
        NSLayoutConstraint.activate([
            cameraActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            cameraActionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cameraActionView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16),
            cameraActionView.widthAnchor.constraint(equalToConstant: 62)
        ])
    }
}


// MARK: Done Button

extension LeapVideoEditorViewController {
    
    private func setupDoneButton() {
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: timeLineView.topAnchor, constant: -55)
        ])
    }
}

// MARK: Preview View

extension LeapVideoEditorViewController {
    
    private func setupPreviewView() {
        view.addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: timeLineView.topAnchor)
        ])
    }
}

// MARK: Timeline View

extension LeapVideoEditorViewController {
    
    private func setupTimeLineView() {
        view.addSubview(timeLineView)
        NSLayoutConstraint.activate([
            timeLineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timeLineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timeLineView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            timeLineView.heightAnchor.constraint(equalToConstant: 135)
        ])
        timeLineView.setup(leapTimelineVideoItems: leapTimelineVideoItems)
    }
}

// MARK: Info View

extension LeapVideoEditorViewController {
    
    private func setupInfoView() {
        previewView.addSubview(infoView)
        infoView.addSubview(timeLabel)
        infoView.addSubview(playButton)
        infoView.addSubview(micView)
        infoView.addSubview(deleteButton)
        infoView.addSubview(muteButton)
        NSLayoutConstraint.activate([
            infoView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 48),
            timeLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            timeLabel.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: infoView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 48),
            playButton.heightAnchor.constraint(equalToConstant: 48),
            
            micView.centerXAnchor.constraint(equalTo: infoView.centerXAnchor),
            micView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            micView.widthAnchor.constraint(equalToConstant: 48),
            micView.heightAnchor.constraint(equalToConstant: 48),
            
            deleteButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -6),
            deleteButton.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 48),
            deleteButton.heightAnchor.constraint(equalToConstant: 48),
            
            muteButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -6),
            muteButton.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),
            muteButton.widthAnchor.constraint(equalToConstant: 48),
            muteButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

// MARK: Close button

extension LeapVideoEditorViewController {
    
    public func setupBackButton() {
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
}

// MARK: actions setup

extension LeapVideoEditorViewController {
    
    public func setupActions() {
        cameraActionView.actionDelegate = self
    }
}

// MARK: menu actions delegate

extension LeapVideoEditorViewController: CameraActionDelegate {
    
    public func didSelect(action: CameraAction) {
        stopRecording()
        switch action {
        case .stickers:
            stickersManager.stickerDelegate = self
            stickersManager.launchStickers(self)
        case .text:
            self.presentTextEditor()
        case .filters:
            presentFilters()
        case .sound:
            let controller = SoundCollectionViewController(token: token)
            controller.delegate = self
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.setupDefaultStyle()
            present(navigationController, animated: true)
        case .voice:
            self.micView.isHidden = !self.micView.isHidden
            self.playButton.isHidden = !self.micView.isHidden
            if isVoiceRecording {
                do {
                    try self.recorderService.stopRecording()
                    isVoiceRecording = !isVoiceRecording
                } catch {
                    print(error.localizedDescription)
                }
            }
        default:
            print("not applicable")
        }
    }
}

// MARK: sticker selection delegate

extension LeapVideoEditorViewController : StickersDelegate {
    
    // MARK: when tap on the sticker to add on the video
    
    func didSelectSticker(_ gifData: Data) {
        guard let sticker = GiphyYYImage(data: gifData) else { return }
        let timelineItem = LeapTimelineItem(itemData: gifData, thumbnail: sticker, type: .sticker, startPosition: (timeLineView.mainVideoScrollView.contentOffset.x+UIScreen.main.bounds.width/2)/24)
        timelineItems.append(timelineItem)
        timeLineView.insertItem(timelineItem: timelineItem)
        dragGestureSetup.parentView = previewView
        dragGestureSetup.videoBounds = playerLayer.videoRect
        dragGestureSetup.configureDragView(for: .sticker, sticker: sticker, timeLineItem: timelineItem, overlayCenter: timelineItem.itemPosition)
    }
    
    // MARK: to get the current position of sticker
    
    private func setupInteraction() {
        self.dragGestureSetup.userDragged = { [unowned self] (currentPosition, ended) in
            self.hideUnhideElements(!ended)
        }
    }
    
    // MARK:  when adjust position of sticker, hide the video actions views
    
    private func hideUnhideElements(_ hide: Bool) {
        self.cameraActionView.isHidden = hide
        self.doneButton.isHidden = hide
        self.infoView.isHidden = hide
    }
    
    
    // MARK: after selecting the sticker position, add sticker to the video layer
    
    private func prepareFinalVideo() {
        func showError(error: Error) {
            removeHud()
            showAlert(title: "Error", msg: error.localizedDescription)
        }
        func dismiss(with videoURL: URL) {
            removeHud()
            self.dismiss(animated: true) {
                self.videoEditorDelegate?.videoEditorDidCapture(videoURL: videoURL)
            }
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        var inputFiles = [String]()
        for videoCommand in videoCommands {
            let inputFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4").path
            let session = FFmpegKit.execute("\(videoCommand) -preset veryfast \(inputFile)")
            guard session?.getReturnCode().isValueSuccess() ?? true else {
                showError(error: NSError(domain: "GenericError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Something went wrong please try again later. Code: 1"]))
                return
            }
            inputFiles.append(inputFile)
        }
        var inputCommand = ""
        var filterCommand = " -filter_complex \""
        for (index, inputFile) in inputFiles.enumerated() {
            inputCommand.append(" -i \"\(inputFile)\"")
            filterCommand.append("[\(index):v] [\(!leapTimelineVideoItems[index].hasAudio ? inputFiles.count : index):a] ")
        }
        inputCommand.append(" -f lavfi -t 0.1 -i anullsrc")
        inputCommand.append(filterCommand)
        inputCommand.append("concat=n=\(inputFiles.count):v=1:a=1 [outv] [outa]\" -map \"[outv]\" -map \"[outa]\" -r 25 ")
        if timelineItems.isEmpty {
            inputCommand.append("-brand mp42 -vcodec libx264 -preset veryfast ")
        }
        inputCommand.append(outputURL.path)
        let session = FFmpegKit.execute(inputCommand)
        guard session?.getReturnCode().isValueSuccess() ?? true else {
            showError(error: NSError(domain: "GenericError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Something went wrong please try again later. Code: 2"]))
            return
        }
        func handleOtherExport(outputURL: URL) {
            switch addSounds(inputFile: outputURL) {
            case .success(let soundOutput):
                switch addVideoLayers(inputFile: soundOutput) {
                case .success(let finalOutput):
                    dismiss(with: finalOutput)
                case .failure(let error):
                    showError(error: error)
                }
            case .failure(let error):
                showError(error: error)
            }
        }
        if let selectedFilter = selectedFilter, let filter = selectedFilter.filter {
            let asset = AVAsset(url: outputURL)
            let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                
                let source = request.sourceImage.clampedToExtent()
                filter.setValue(source, forKey: kCIInputImageKey)
                
                // Crop the blurred output to the bounds of the original image
                let output = filter.outputImage!.cropped(to: request.sourceImage.extent)
                
                // Provide the filter output to the composition
                request.finish(with: output, context: nil)
            })
            let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            export?.outputFileType = .mp4
            let filterOutputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
            export?.outputURL = filterOutputURL
            export?.videoComposition = composition
            export?.exportAsynchronously {
                DispatchQueue.main.async {
                    if export?.status == .completed {
                        handleOtherExport(outputURL: filterOutputURL)
                    } else {
                        showError(error: export?.error ?? NSError(domain: "GenericError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Something went wrong please try again later. Code: 3"]))
                    }
                }
            }
        } else {
            handleOtherExport(outputURL: outputURL)
        }
    }
    
    func addSounds(inputFile: URL) -> Result<URL, Error> {
        let outfile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        var inputVideo = "-y -i \(inputFile.path)"
        var complexFilter = " -filter_complex "
        var complexFilterOut = "[0]"
        let audioItems = timelineItems.filter({ $0.type == .audio })
        if audioItems.isEmpty {
            return .success(inputFile)
        }
        for (index, audioItem) in audioItems.enumerated() {
            guard let audioURL = audioItem.itemData as? URL else { continue }
            inputVideo.append(" -i \(audioURL.path)")
            complexFilter.append("[\(index + 1)]adelay=\(audioItem.startPosition)|\(audioItem.startPosition)[aud\(index + 1)];")
            complexFilterOut.append("[aud\(index + 1)]")
        }
        complexFilterOut.append("amix=\(audioItems.count + 1)")
        complexFilter.append(complexFilterOut)
        inputVideo.append(complexFilter)
        if timelineItems.count-audioItems.count == 0 {
            inputVideo.append(" -brand mp42 -c:v libx264 -preset veryfast")
        } else {
            inputVideo.append(" -c:v copy")
        }
        inputVideo.append(" -c:a aac -shortest \(outfile.path)")
        let session = FFmpegKit.execute(inputVideo)
        guard session?.getReturnCode().isValueSuccess() ?? true else {
            return .failure(NSError(domain: "GenericError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Something went wrong please try again later. Code: 4"]))
        }
        return .success(outfile)
    }
    
    func addVideoLayers(inputFile: URL) -> Result<URL, Error> {
        let track = AVURLAsset(url: inputFile).tracks(withMediaType: .video)[0]
        let widthRatio = track.naturalSize.width/previewView.frame.size.width
        let heightRatio = track.naturalSize.height/previewView.frame.size.height
        let finalRatio = widthRatio > heightRatio ? widthRatio : heightRatio
        let heightToSubtract = (previewView.frame.size.height-(track.naturalSize.height/finalRatio))/2
        let widthToSubtract = (previewView.frame.size.width-(track.naturalSize.width/finalRatio))/2
        var filePaths = "-y -i \(inputFile.path) "
        var fileScaleConst = ""
        var fileOverlyConst = ""
        let items = timelineItems.filter { $0.type == .sticker || $0.type == .text }
        if items.isEmpty { return .success(inputFile) }
        for (index, sticker) in items.enumerated() {
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(sticker.type == .text ? "png" : "gif")
            FileManager.default.createFile(atPath: outputURL.path, contents: sticker.itemData as? Data)
            if sticker.type == .sticker { filePaths.append("-stream_loop -1") }
            filePaths.append(" -i \(outputURL.path) ")
            if (index == 0) {
                fileScaleConst.append("[0]scale=\(track.naturalSize.width):\(track.naturalSize.height)[vid];")//scale input video // for aspect ratio ,setsar=1:1
                fileScaleConst.append("[\(index + 1):v]scale=\(sticker.view.frame.size.width*finalRatio):\(sticker.view.frame.size.height*finalRatio)[out\(index)]")
                fileOverlyConst.append(";[vid][out\(index)]overlay=x=\((sticker.view.frame.origin.x-widthToSubtract)*finalRatio):y=\((sticker.view.frame.origin.y-heightToSubtract)*finalRatio):enable=between(t\\,\(sticker.startPosition)\\,\(sticker.startPosition+sticker.size))")
                if sticker.type == .sticker {//To stop of the stream loop
                    fileOverlyConst.append(":shortest=1")
                }
                if index < items.count-1 {
                    fileOverlyConst.append("[temp\(index)]")
                }
            } else {
                fileScaleConst.append(";[\(index+1):v]scale=\(sticker.view.frame.size.width*finalRatio):\(sticker.view.frame.size.height*finalRatio)[out\(index)]")
                fileOverlyConst.append(";[temp\(index-1)][out\(index)]overlay=x=\((sticker.view.frame.origin.x-widthToSubtract)*finalRatio):y=\((sticker.view.frame.origin.y-heightToSubtract)*finalRatio):enable=between(t\\,\(sticker.startPosition)\\,\(sticker.startPosition+sticker.size))")
                if sticker.type == .sticker {//To stop of the stream loop
                    fileOverlyConst.append(":shortest=1")
                }
                if index < items.count-1 {
                    fileOverlyConst.append("[temp\(index)]")
                }
            }
        }
        fileScaleConst.append(fileOverlyConst)
        filePaths.append("-filter_complex ")
        filePaths.append(fileScaleConst)
        let outfile = FileManager.default.temporaryDirectory.appendingPathComponent("output-\(Int(Date().timeIntervalSince1970)).mp4")
        filePaths.append(" -brand mp42 -vcodec libx264 -preset veryfast \(outfile.path)")
        let session = FFmpegKit.execute(filePaths)
        guard session?.getReturnCode().isValueSuccess() ?? true else {
            return .failure(NSError(domain: "GenericError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Something went wrong please try again later. Code: 5"]))
        }
        return .success(outfile)
    }
    
    func resizeImage(image: GiphyYYImage, newWidth: CGFloat) -> GiphyYYImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext( CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() as? GiphyYYImage else { return nil}
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func addVideoOverlay(composition: AVMutableComposition, outputURL: URL, videoSize: CGSize) async -> AVAssetExportSession? {
        let processor = VideoOverlayManager(outputURL: outputURL, videoSize: videoSize, outputPresetName: timelineItems.isEmpty ? AVAssetExportPresetPassthrough : AVAssetExportPresetMediumQuality)
        for sticker in timelineItems where sticker.type == .text || sticker.type == .sticker {
            let imageOverlay = VideoOverlay(image: sticker.view.image! as! GiphyYYImage, frame: CGRect(
                x: (sticker.view.frame.origin.x * UIScreen.main.scale),
                y: (sticker.view.frame.origin.y) * UIScreen.main.scale,
                width: sticker.view.frame.size.width * UIScreen.main.scale,
                height: sticker.view.frame.size.height * UIScreen.main.scale), delay: sticker.startPosition, duration: sticker.size)
            processor.addOverlay(imageOverlay)
        }
        self.dragGestureSetup.removeAllStickers()
        return await processor.process(composition: composition)
    }
}

// MARK: extension to add text on the video

extension LeapVideoEditorViewController {
    
    private func presentTextEditor() {
        let controller = VideoTextOverlayController()
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        navController.modalPresentationStyle = .overFullScreen
        self.present(navController, animated: true, completion: nil)
    }
}


// MARK: Video Text Delegates

extension LeapVideoEditorViewController: VideoTextDelegate {
    
    func didEndEditing(_ editedImageLabel: UIImage) {
        guard let data = editedImageLabel.pngData(), let sticker = GiphyYYImage(data: data) else { return }
        let timelineItem = LeapTimelineItem(itemData: data, thumbnail: sticker, type: .text, startPosition: (timeLineView.mainVideoScrollView.contentOffset.x+UIScreen.main.bounds.width/2)/24)
        timelineItems.append(timelineItem)
        timeLineView.insertItem(timelineItem: timelineItem)
        self.dragGestureSetup.parentView = self.previewView
        self.dragGestureSetup.videoBounds = self.playerLayer.videoRect
        self.dragGestureSetup.configureDragView(for: .text, sticker: sticker, timeLineItem: timelineItem, overlayCenter: timelineItem.itemPosition)
    }
}

// MARK: Timeline Delegate

extension LeapVideoEditorViewController: LeapTimelineDelegate {
    
    func reloadVideo() {
        setupVideo()
    }
    
    func rearrangeVideo(initialIndex: Int, finalIndex: Int) {
        leapTimelineVideoItems.insert(leapTimelineVideoItems.remove(at: initialIndex), at: finalIndex)
        setupVideo()
    }
    
    func timelineDragged(seconds: TimeInterval) {
        var seconds = seconds
        if seconds < 0 { seconds = 0 }
        if let time = player.currentItem?.duration, seconds > CMTimeGetSeconds(time) { seconds = CMTimeGetSeconds(time) }
        player.currentItem?.seek(to: CMTime(seconds: seconds, preferredTimescale: 100), completionHandler: nil)
        updateTimeline(currentTime: seconds)
    }
    
    func timelineBeginDragging() {
        isVideoDragging = true
    }
    
    func timelineEndDragging() {
        isVideoDragging = false
    }
    
    func updateDeleteButton() {
        deleteButton.isHidden = timeLineView.selectedItem == nil
        if timeLineView.selectedVideoIndex < 0 {
            muteButton.isHidden = true
        } else {
            muteButton.isHidden = false
            muteButton.setImage(UIImage(named: leapTimelineVideoItems[timeLineView.selectedVideoIndex].isMuted ? "mute" : "unmute", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        }
    }
    
    func openGallery() {
        let galleryController = MediaGalleryViewController()
        galleryController.assetsDelegate = self
        self.present(galleryController, animated: true, completion: nil)
    }
}

extension LeapVideoEditorViewController: GalleryAssetsDelegate {
    
    // MARK: get all the selected photos/videos here
    // Parameters:
    // assets : Array of selected assets
    
    func didSelectedAssets(_ assets: [(recordURL: URL, duration: Double, isPhoto: Bool)]) {
        var timelineItems = [LeapTimelineVideoItem]()
        for asset in assets {
            timelineItems.append(LeapTimelineVideoItem(videoURL: asset.recordURL))
            totalVideoDuration += asset.duration
        }
        self.leapTimelineVideoItems.append(contentsOf: timelineItems)
        timeLineView.leapTimelineVideoItems.append(contentsOf: timelineItems)
        var width: CGFloat = timeLineView.videoViews.reduce(0) { $0+$1.frame.size.width+1 }
        for timelineItem in timelineItems {
            let videoView = LeapTimelineVideoView(target: timeLineView, leapTimelineVideoItem: timelineItem)
            videoView.setupVideo()
            videoView.frame.origin.x = width
            width += videoView.frame.size.width+1
            videoView.addGestureRecognizer(UITapGestureRecognizer(target: timeLineView, action: #selector(LeapTimelineView.handleTapGesture(_:))))
            timeLineView.videoViews.append(videoView)
            timeLineView.videoStackView.addSubview(videoView)
        }
        timeLineView.tempVideoItems.append(contentsOf: timelineItems.map { $0.thumbnails.map { $0.image! } })
//        let finalWidth = width*2 > UIScreen.main.bounds.width*2 ? width*2 : UIScreen.main.bounds.width*2
        //todo change flow
//        timeLineView.leftAnchorView.widthAnchor.constraint(equalToConstant: finalWidth).isActive = true
//        timeLineView.rightAnchorView.widthAnchor.constraint(equalToConstant: finalWidth).isActive = true
        timeLineView.videoStackView.frame.size = CGSize(width: width, height: 34)
        if width > 360 {
            let newWidth = width-360
            timeLineView.mainVideoScrollView.contentSize = CGSize(width: 360, height: 34)
            timeLineView.effectsScrollView.contentSize = CGSize(width: 360, height: 0)
            timeLineView.rightAnchorConstraint.constant -= newWidth
        } else {
            timeLineView.mainVideoScrollView.contentSize = timeLineView.videoStackView.frame.size
            timeLineView.effectsScrollView.contentSize = CGSize(width: width, height: 0)
        }
        setupVideo()
    }
}

// MARK: Draft Work

extension LeapVideoEditorViewController {
    
    // MARK: Set draft items in timeline
    /// Parameters:
    /// timeLineItems: items saved in draft
    /// index: video sequence
    
    func setDraftItems(_ timeLineItems: [LeapTimelineItem], leftAnchor: Double, rightAnchor: Double, index: Int) {
        self.draftVideoIndex = index
        self.isFromDraft = true
        for item in timeLineItems {
            timelineItems.append(item)
            timeLineView.insertItem(timelineItem: item)
            self.dragGestureSetup.parentView = self.previewView
            self.dragGestureSetup.videoBounds = self.playerLayer.videoRect
            self.dragGestureSetup.configureDragView(for: item.type, sticker: item.thumbnail, timeLineItem: item, overlayCenter: item.offset, itemSize: item.itemSize)
            
        }
        timeLineView.leftanchorConstraint.constant = leftAnchor
        timeLineView.rightAnchorConstraint.constant = rightAnchor
        let newWidth = timeLineView.videoStackView.frame.size.width - leftAnchor + rightAnchor + 20
        timeLineView.mainVideoScrollView.contentOffset.x -= timeLineView.mainVideoScrollView.contentSize.width - newWidth
        timeLineView.mainVideoScrollView.contentSize.width = newWidth
        timeLineView.effectsScrollView.contentSize.width = newWidth
        timeLineView.effectsScrollView.contentOffset.x = timeLineView.mainVideoScrollView.contentOffset.x
        timeLineView.videoStackView.frame.origin.x = -(leftAnchor-10)
        timeLineView.effectsStackView.frame.origin.x = timeLineView.videoStackView.frame.origin.x
        setupVideo()
    }
    
    // MARK: save video in draft
    
    func saveAsDraftAction() -> Bool {
        var items = [VideoOverlayItemsModel]()
        for item in self.timelineItems {
            if item.type == .audio {
                do {
                    let data = try Data(contentsOf: item.itemData as! URL)
                    let item = VideoOverlayItemsModel(overlayData: data, overlayOriginX: item.view.frame.origin.x, overlayOriginY: item.view.frame.origin.y, overlayWidth: item.view.frame.size.width, overlayHeight: item.view.frame.size.height, startPosition: item.startPosition, overlayDuration: item.size, overlayType: item.type.rawValue)
                    items.append(item)
                } catch { }
            } else if item.type == .record {
                continue
            } else {
                let item = VideoOverlayItemsModel(overlayData: item.itemData as! Data, overlayOriginX: item.view.frame.origin.x, overlayOriginY: item.view.frame.origin.y, overlayWidth: item.view.frame.size.width, overlayHeight: item.view.frame.size.height, startPosition: item.startPosition, overlayDuration: item.size, overlayType: item.type.rawValue)
                items.append(item)
            }
        }
        let videosData = self.leapTimelineVideoItems.compactMap { timelineVideoItem -> DraftVideoItemModel? in
            do {
                let data = try Data(contentsOf: timelineVideoItem.videoURL)
                return DraftVideoItemModel(videoData: data, isMuted: timelineVideoItem.isMuted)
            } catch { }
            return nil
        }
        let videoToSave = DraftVideoModel(videoItems: videosData, overlayItems: items, videoDate: Date(), videoDuration: self.totalVideoDuration, leftAnchor: timeLineView.leftanchorConstraint.constant, rightAnchor: timeLineView.rightAnchorConstraint.constant)
        videoToSave.videoFilter = self.selectedFilter?.filterName
        return isFromDraft ? DraftVideoModel.updateDraftVideo(videoToSave, index: draftVideoIndex) : DraftVideoModel.saveDraftVideo(videoToSave)
    }
}

// MARK: Music Work

extension LeapVideoEditorViewController: SoundControllerDelegate {
    
    func audioSelected(audioURL: URL, track: Track) {
        for item in timelineItems {
            if let _ = item.itemData as? AudioVisualizationView {
                do {
                    try self.recorderService.stopRecording()
                    isVoiceRecording = false
                    micView.isHidden = true
                    playButton.isHidden = false
                } catch {
                    print(error.localizedDescription)
                }
                break
            }
        }
        let timelineItem = LeapTimelineItem(itemData: audioURL, thumbnail: GiphyYYImage(), type: .audio, startPosition: (timeLineView.mainVideoScrollView.contentOffset.x+UIScreen.main.bounds.width/2)/24)
        timelineItems.append(timelineItem)
        timeLineView.insertItem(timelineItem: timelineItem)
    }
    
    func removeTrack() { /*todo nothing*/ }
}
