//
//  MediaGalleryViewController.swift
//  DKImagePickerController
//
//  Created by bigstep on 26/09/22.
//

import Foundation
import DKImagePickerController
import Photos

enum ConstructionError: Error {
  case invalidImage, invalidURL
}

class MediaGalleryViewController: BaseViewController {
    
    weak var assetsDelegate: GalleryAssetsDelegate?
    private var currentTabIndex = 0
    private lazy var galleryUIDelegate =  CustomGalleryUIDelegate()
    private lazy var selectedAssets = [DKAsset]()
    private var selectedAssetHeightConstraint: NSLayoutConstraint?
    private var pickerController: DKImagePickerController?
    private var initiallyLoading = true
    
    
    // MARK: UI Elements-
    
    private let tabsView: GalleryTabsView = {
        let view = GalleryTabsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let galleryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = .zero
        collectionView.scrollIndicatorInsets = .zero
        return collectionView
    }()
    
    private let selectedAssetView: SelectedAssetsCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = SelectedAssetsCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    private let galleryFooter: GalleryFooter = {
        let view = GalleryFooter()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let galleryHeader: GalleryHeader = {
        let view = GalleryHeader()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: load all the views of view controller
    
    override func loadView() {
        super.loadView()
        setupHeaderView()
        tabsSetup()
        setupFooterView()
        setupSelectedAssetView()
        setupCollectionView()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initiallyLoading = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initiallyLoading {
            tabsView.setSelectedTab(indexPath: IndexPath(item: 1, section: 0), animated: false)
        }
    }
}

// MARK: gallery tabs view setup

extension MediaGalleryViewController {
    
    private func tabsSetup() {
        view.addSubview(tabsView)
        tabsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tabsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tabsView.topAnchor.constraint(equalTo: galleryHeader.bottomAnchor).isActive = true
        tabsView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        tabsView.galleryTabDelegate = self
    }
}

// MARK: collection view setup

extension MediaGalleryViewController {
    
    private func setupCollectionView() {
        view.addSubview(galleryCollectionView)
        galleryCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        galleryCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        galleryCollectionView.topAnchor.constraint(equalTo: tabsView.bottomAnchor).isActive = true
        galleryCollectionView.bottomAnchor.constraint(equalTo: selectedAssetView.topAnchor, constant: -5).isActive = true
        galleryCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        galleryCollectionView.delegate = self
        galleryCollectionView.dataSource = self
        galleryCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "galleryCell")
    }
}

// MARK: selected asset view setup

extension MediaGalleryViewController {
    
    private func setupSelectedAssetView() {
        view.addSubview(selectedAssetView)
        selectedAssetView.bottomAnchor.constraint(equalTo: galleryFooter.topAnchor, constant: -10).isActive = true
        selectedAssetView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        selectedAssetView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        selectedAssetHeightConstraint = selectedAssetView.heightAnchor.constraint(equalToConstant: 0)
        selectedAssetHeightConstraint?.isActive = true
        selectedAssetView.selectedAssetDelegate = self
    }
}

// MARK: gallery footer view setup

extension MediaGalleryViewController {
    
    func setupFooterView() {
        view.addSubview(galleryFooter)
        galleryFooter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        galleryFooter.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        galleryFooter.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        galleryFooter.heightAnchor.constraint(equalToConstant: 60).isActive = true
        galleryFooter.nextButton.addTarget(self, action: #selector(nextAction(_:)), for: .touchUpInside)
    }
    
    // MARK: action to move next with the selected assets
    
    @objc private func nextAction(_ sender: LoadingButton) {
        sender.startAnimation()
        var videos: [(recordURL: URL, duration: Double, isPhoto: Bool)] = Array(repeating: (URL(fileURLWithPath: ""), 0, false), count: selectedAssets.count)
        var remainingAssets = selectedAssets.count
        func handleDismiss() {
            remainingAssets -= 1
            if remainingAssets == .zero {
                DispatchQueue.main.async {
                    self.dismiss(animated: false) {
                        if videos.count > 0 {
                            self.assetsDelegate?.didSelectedAssets(videos)
                        }
                    }
                }
            }
        }
        for index in 0..<selectedAssets.count {
            let asset = selectedAssets[index]
            if asset.type == .video {
                asset.fetchAVAsset { (avAsset, info) in
                    if let avAsset = avAsset as? AVURLAsset {
                        videos[index] = (avAsset.url, avAsset.duration.seconds, false)
                    }
                    handleDismiss()
                    //                        FFmpegKit.execute("-i \(avAsset.url.absoluteString) -preset veryfast -vf \"fps=30,scale='min(720,iw)':-1\" \(outputURL.absoluteString)")
                }
            } else {
                asset.fetchImage(with: CGSize(width: 1920, height: 1920)) {[weak self] image, info in
                    guard let self = self, let image = image else {
                        handleDismiss()
                        return
                    }
                    do {
                        try self.createFilmstrip(image, duration: 3) { videoURL in
                            let asset = AVURLAsset(url: videoURL)
                            videos[index] = (videoURL, CMTimeGetSeconds(asset.duration), true)
                            handleDismiss()
                        }
                    } catch {
                        handleDismiss()
                    }
                }
            }
        }
    }
    
    func createFilmstrip(_ image: UIImage, duration: Int, completion: @escaping (URL)->Void) throws {
        guard let staticImage = CIImage(image: image) else {
            throw ConstructionError.invalidImage
        }
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let width:Int = Int(staticImage.extent.size.width)
        let height:Int = Int(staticImage.extent.size.height)
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)
        
        let context = CIContext()
        context.render(staticImage, to: pixelBuffer!)
        let outputMovieURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        
        //delete any old file
        do {
            try FileManager.default.removeItem(at: outputMovieURL)
        } catch {
            print("Could not remove file \(error.localizedDescription)")
        }
        
        //create an assetwrite instance
        guard let videoWriter = try? AVAssetWriter(outputURL: outputMovieURL, fileType: .mp4) else {
            abort()
        }
        let videoSettings: [String : Any] = [AVVideoCodecKey : AVVideoCodecType.h264, AVVideoWidthKey : image.size.width, AVVideoHeightKey : image.size.height,]
        
        /// create a video writter input
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        
        /// create setting for the pixel buffer
        let sourceBufferAttributes: [String : Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
            (kCVPixelBufferWidthKey as String): Float(image.size.width),
            (kCVPixelBufferHeightKey as String):  Float(image.size.height),
            (kCVPixelBufferCGImageCompatibilityKey as String): NSNumber(value: true),
            (kCVPixelBufferCGBitmapContextCompatibilityKey as String): NSNumber(value: true)
        ]
        
        /// create pixel buffer for the input writter and the pixel buffer settings
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        
        /// check if an input can be added to the asset
        
        /// add the input writter to the video asset
        videoWriter.add(videoWriterInput)
        
        /// check if a write session can be executed
        if videoWriter.startWriting() {
            
            /// if it is possible set the start time of the session (current at the begining)
            videoWriter.startSession(atSourceTime: CMTime.zero)
            
            /// check that the pixel buffer pool has been created
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            /// create/access separate queue for the generation process
            let media_queue = DispatchQueue(label: "mediaInputQueue", attributes: [])
            
            /// start video generation on a separate queue
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                
                let framesPerSecond = 30
                let totalFrames = duration * framesPerSecond
                var frameCount = 0
                
                while frameCount < totalFrames {
                    if videoWriterInput.isReadyForMoreMediaData {
                        let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(framesPerSecond))
                        //append the contents of the pixelBuffer at the correct ime
                        pixelBufferAdaptor.append(pixelBuffer!, withPresentationTime: frameTime)
                        frameCount+=1
                    }
                }
                
                // after all images are appended the writting shoul be marked as finished
                videoWriterInput.markAsFinished()
                
                videoWriter.finishWriting {
                    pixelBuffer = nil
                    //outputMovieURL now has the video
                    completion(outputMovieURL)
                    //            Logger().info("Finished video location: \(outputMovieURL)")
                }
            })
        }
    }
}

// MARK: gellery header setup

extension MediaGalleryViewController {
    
    func setupHeaderView() {
        view.addSubview(galleryHeader)
        galleryHeader.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        galleryHeader.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        galleryHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        galleryHeader.heightAnchor.constraint(equalToConstant: 60).isActive = true
        galleryHeader.crossButton.addTarget(self, action: #selector(dismissGallery), for: .touchUpInside)
    }
    
    // MARK: cross button action to dismiss controller
    
    @objc private func dismissGallery() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: collection view delegates implementation

extension MediaGalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        tabsView.horizontalBarLeftAnchorConstraint?.constant = scrollView.contentOffset.x / CGFloat(tabsView.tabs.count)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let index = Int(targetContentOffset.pointee.x / view.frame.width)
        let indexPath = IndexPath(item: index, section: 0)
        self.currentTabIndex = indexPath.row
        tabsView.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.configureImagePicker(index: indexPath.row, cell: cell)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let childControllers = self.children
        for controller in childControllers {
            controller.removeFromParent()
        }
    }
    
    fileprivate func imageOnlyAssetFetchOptions(_ index: Int) -> PHFetchOptions {
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return assetFetchOptions
    }
    
    // MARK: configuring picker every time when switching between tabs
    // Parameters:
    // index: current tab index
    // cell: current tab cell
    
    func configureImagePicker(index: Int, cell: UICollectionViewCell) {
        pickerController = DKImagePickerController()
        pickerController?.UIDelegate = galleryUIDelegate
        galleryUIDelegate.delegate = self
        pickerController?.inline = true
        switch index {
        case 0:
            pickerController?.sourceType = .photo
            pickerController?.assetType = .allAssets
            if selectedAssets.count > 0 {
                pickerController?.select(assets: selectedAssets)
            }
            self.galleryHeader.updateHeaderLabel("All ")
            
        case 1:
            pickerController?.sourceType = .photo
            pickerController?.assetType = .allVideos
            if selectedAssets.count > 0 {
                let  videoAssets = selectedAssets.filter {
                    $0.type == .video
                }
                pickerController?.select(assets: videoAssets)
            }
            self.galleryHeader.updateHeaderLabel("Videos ")
            
        case 2:
            pickerController?.sourceType = .photo
            pickerController?.assetType = .allPhotos
            if selectedAssets.count > 0 {
                let  videoAssets = selectedAssets.filter {
                    $0.type == .photo
                }
                pickerController?.select(assets: videoAssets)
            }
            self.galleryHeader.updateHeaderLabel("Photos ")
        default:
            print("not applicable")
        }
        self.display(contentController: pickerController!, on: cell.contentView)
    }
    
    // MARK: adding gallery view inside cell based on tab index
    // Parameters:
    // contentController: Gallery Controller
    // view: Current Cell
    func display(contentController content: UIViewController, on view: UIView) {
        self.addChild(content)
        content.view.frame = view.bounds
        view.addSubview(content.view)
        content.didMove(toParent: self)
    }
    
}

// MARK: Gallery Tabs Delegate

extension MediaGalleryViewController: GalleryTabsProtocol {
    
    func scrollToTabIndex(tabIndex: IndexPath, animated: Bool) {
        self.currentTabIndex = tabIndex.row
        let rect = self.galleryCollectionView.layoutAttributesForItem(at: tabIndex)?.frame
        self.galleryCollectionView.scrollRectToVisible(rect ?? CGRect.zero, animated: animated)
    }
}

// MARK: Gallery Action Delegates

extension MediaGalleryViewController: GalleryActionDelegate {
    func didAddAsset(_ assets: [DKAsset]) {
        guard let asset = assets.first else { return}
        if !selectedAssets.contains(asset) {
            self.selectedAssets.append(asset)
        }
        selectedAssetView.assets = selectedAssets
        if selectedAssetHeightConstraint?.constant == 0 {
            selectedAssetHeightConstraint?.constant = 100
            UIView.animate(withDuration: 0.25, animations: self.view.layoutIfNeeded)
        }
        galleryFooter.nextButton.setTitle("Next(\(selectedAssets.count))", for: .normal)
        galleryFooter.nextButton.alpha = 1.0
        galleryFooter.nextButton.isEnabled = true
    }
    
    // MARK: remove particular asset
    // Parameters:
    // assets: asset to be removed
    
    func didRemoveAsset(_ assets: [DKAsset]) {
        guard let asset = assets.first else { return}
        removeSelectedAsset(asset)
    }
    
    // MARK: remove selected asset
    // Parameters:
    // asset: asset which needs to be removed
    
    private func removeSelectedAsset(_ asset: DKAsset) {
        let index = self.selectedAssets.firstIndex(of: asset) ?? 0
        selectedAssets.remove(at: index)
        selectedAssetView.assets = selectedAssets
        selectedAssetHeightConstraint?.constant = selectedAssets.count == 0 ? 0 : 100
        if selectedAssets.count == 0 {
            galleryFooter.nextButton.setTitle("Next", for: .normal)
            galleryFooter.nextButton.alpha = 0.5
            galleryFooter.nextButton.isEnabled = false
            selectedAssetHeightConstraint?.constant = 0
            UIView.animate(withDuration: 0.25, animations: self.view.layoutIfNeeded)
        }
        else {
            galleryFooter.nextButton.setTitle("Next(\(selectedAssets.count))", for: .normal)
            galleryFooter.nextButton.alpha = 1.0
            galleryFooter.nextButton.isEnabled = true
        }
    }
}

//MARK: Selected asset remove action delegate

extension MediaGalleryViewController: SelectedAssetProtocol {
    func removeAsset(_ asset: DKAsset) {
        pickerController?.deselect(asset: asset)
    }
}
