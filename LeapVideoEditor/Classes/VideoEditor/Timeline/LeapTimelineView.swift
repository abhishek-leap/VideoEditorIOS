//
//  LeapTimelineView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 07/09/22.
//

import UIKit
import CoreMedia

protocol LeapTimelineDelegate: AnyObject {
    
    func timelineDragged(seconds: TimeInterval)
    func timelineBeginDragging()
    func timelineEndDragging()
    func reloadVideo()
    func rearrangeVideo(initialIndex: Int, finalIndex: Int)
    func updateDeleteButton()
    func openGallery()
}

class LeapTimelineView: UIView {
    
    let mainVideoScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    let videoStackView: UIView = {
        let stackView = UIView()
        return stackView
    }()
    let effectsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    let centerLine: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    let effectsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "add-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.addTarget(self, action: #selector(addTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let leftAnchorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    let rightAnchorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    lazy var leftAnchorDragView: UIView = {
        let view = UIView()
        addAnchors(view: view)
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(leftAnchorDragged(_:))))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var rightAnchorDragView: UIView = {
        let view = UIView()
        addAnchors(view: view)
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rightAnchorDragged(_:))))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var leftanchorConstraint = leftAnchorDragView.trailingAnchor.constraint(equalTo: videoStackView.leadingAnchor, constant: 10)
    lazy var rightAnchorConstraint = rightAnchorDragView.leadingAnchor.constraint(equalTo: videoStackView.trailingAnchor, constant: -10)
    
    func addAnchors(view: UIView) {
        let lineView = UIView()
        lineView.backgroundColor = .white
        lineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineView)
        let anchorIcon = UIImageView(image: UIImage(named: "anchor-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil))
        anchorIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(anchorIcon)
        NSLayoutConstraint.activate([
            lineView.topAnchor.constraint(equalTo: view.topAnchor),
            lineView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            lineView.widthAnchor.constraint(equalToConstant: 1),
            lineView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            anchorIcon.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            anchorIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.widthAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    weak var selectedItem: LeapTimelineWrapperView?
    weak var delegate: LeapTimelineDelegate?
    private var isScrollUpdating = false
    var leapTimelineVideoItems = [LeapTimelineVideoItem]()
    private var snapshotView: UIImageView?
    var selectedVideoIndex = -1
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    var tempVideoItems = [[UIImage]]()
    private var initialIndex = -1
    var videoViews = [LeapTimelineVideoView]()
    var firstInitialized = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(mainVideoScrollView)
        addSubview(effectsScrollView)
        addSubview(centerLine)
        effectsScrollView.addSubview(effectsStackView)
        effectsScrollView.delegate = self
        mainVideoScrollView.addSubview(videoStackView)
        mainVideoScrollView.delegate = self
        let bottomLineView = UIView()
        bottomLineView.backgroundColor = .white
        bottomLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLineView)
        addSubview(leftAnchorView)
        addSubview(rightAnchorView)
        addSubview(leftAnchorDragView)
        addSubview(rightAnchorDragView)
        addSubview(addButton)
        
        NSLayoutConstraint.activate([
            mainVideoScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainVideoScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainVideoScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            mainVideoScrollView.heightAnchor.constraint(equalToConstant: 34),
            effectsScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectsScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectsScrollView.topAnchor.constraint(equalTo: topAnchor),
            effectsScrollView.bottomAnchor.constraint(equalTo: mainVideoScrollView.topAnchor),
            centerLine.topAnchor.constraint(equalTo: topAnchor),
            centerLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            centerLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLine.widthAnchor.constraint(equalToConstant: 1),
//            effectsStackView.leadingAnchor.constraint(equalTo: effectsScrollView.leadingAnchor),
//            effectsStackView.trailingAnchor.constraint(equalTo: effectsScrollView.trailingAnchor),
//            effectsStackView.topAnchor.constraint(equalTo: effectsScrollView.topAnchor),
//            effectsStackView.bottomAnchor.constraint(equalTo: effectsScrollView.bottomAnchor),
            effectsStackView.widthAnchor.constraint(equalTo: videoStackView.widthAnchor),
            leftAnchorView.trailingAnchor.constraint(equalTo: leftAnchorDragView.leadingAnchor, constant: 10),
            leftAnchorView.topAnchor.constraint(equalTo: topAnchor),
            leftAnchorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightAnchorView.leadingAnchor.constraint(equalTo: rightAnchorDragView.trailingAnchor, constant: -10),
            rightAnchorView.topAnchor.constraint(equalTo: topAnchor),
            rightAnchorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftAnchorDragView.topAnchor.constraint(equalTo: topAnchor),
            leftAnchorDragView.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftanchorConstraint,
            rightAnchorDragView.topAnchor.constraint(equalTo: topAnchor),
            rightAnchorDragView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightAnchorConstraint,
            bottomLineView.leadingAnchor.constraint(equalTo: leftAnchorView.trailingAnchor),
            bottomLineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLineView.heightAnchor.constraint(equalToConstant: 2),
            bottomLineView.trailingAnchor.constraint(equalTo: rightAnchorView.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        let inset = UIScreen.main.bounds.width/2
        mainVideoScrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        effectsScrollView.contentInset = UIEdgeInsets(top: 5, left: inset, bottom: 5, right: inset)
        effectsScrollView.isDirectionalLockEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if firstInitialized {
            mainVideoScrollView.contentOffset = CGPoint(x: -(UIScreen.main.bounds.width/2), y: 0)
            effectsScrollView.contentOffset = CGPoint(x: -(UIScreen.main.bounds.width/2), y: 0)
            firstInitialized = false
        }
    }
    
    func setup(leapTimelineVideoItems: [LeapTimelineVideoItem]) {
        var width: CGFloat = 0
        self.leapTimelineVideoItems = leapTimelineVideoItems
        for leapTimelineVideoItem in leapTimelineVideoItems {
            let videoView = LeapTimelineVideoView(target: self, leapTimelineVideoItem: leapTimelineVideoItem)
            videoView.setupVideo()
            videoView.frame.origin.x = width
            width += videoView.frame.size.width+1
            videoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:))))
            videoViews.append(videoView)
            videoStackView.addSubview(videoView)
        }
        self.tempVideoItems = leapTimelineVideoItems.map { $0.thumbnails.map { $0.image! } }
        let finalWidth = width*2 > UIScreen.main.bounds.width*2 ? width*2 : UIScreen.main.bounds.width*2
        leftAnchorView.widthAnchor.constraint(equalToConstant: finalWidth).isActive = true
        rightAnchorView.widthAnchor.constraint(equalToConstant: finalWidth).isActive = true
        videoStackView.frame.size = CGSize(width: width, height: 34)
        if width > 360 {
            let newWidth = width-360
            mainVideoScrollView.contentSize = CGSize(width: 360, height: 34)
            effectsScrollView.contentSize = CGSize(width: 360, height: 0)
            rightAnchorConstraint.constant -= newWidth
        } else {
            mainVideoScrollView.contentSize = videoStackView.frame.size
            effectsScrollView.contentSize = CGSize(width: width, height: 0)
        }
    }
    
    @discardableResult
    func insertItem(timelineItem: LeapTimelineItem) -> LeapTimelineWrapperView {
        let wrapperView = LeapTimelineWrapperView(timelineItem: timelineItem)
        wrapperView.delegate = self
        wrapperView.heightAnchor.constraint(equalToConstant: 34).isActive = true
        if wrapperView.timelineItemView.frame.origin.x + wrapperView.timelineItemView.frame.size.width > videoStackView.frame.size.width {
            wrapperView.timelineItemView.frame.origin.x = videoStackView.frame.size.width - wrapperView.timelineItemView.frame.size.width
            timelineItem.startPosition = wrapperView.timelineItemView.frame.origin.x/24
        }
        effectsStackView.insertArrangedSubview(wrapperView, at: 0)
        effectsScrollView.contentSize.height += 39
        return wrapperView
    }
    
    func updateScroll(time: CMTime) {
        isScrollUpdating = true
        let xOffset = CMTimeGetSeconds(time)*24 - UIScreen.main.bounds.width/2
        mainVideoScrollView.contentOffset.x = xOffset
        effectsScrollView.contentOffset.x = xOffset
        isScrollUpdating = false
    }
    
    // MARK: Apply filters in timeline
    /// Parameters:
    /// filter: filter to be applied
    
    func applyTimelineFilters(_ filter: VideoFilterModel) {
        for (itemIndex, leapTimelineVideoItem) in leapTimelineVideoItems.enumerated() {
            for imageIndex in 0..<leapTimelineVideoItem.thumbnails.count {
                let image = tempVideoItems[itemIndex][imageIndex]
                leapTimelineVideoItem.thumbnails[imageIndex].image = image.addFilter(filter: filter)
            }
        }
    }
    
    // MARK: Remove the applied filter from timeline
    
    func removeTimelineFilter() {
        for (itemIndex, leapTimelineVideoItem) in leapTimelineVideoItems.enumerated() {
            for imageIndex in 0..<leapTimelineVideoItems[itemIndex].thumbnails.count {
                leapTimelineVideoItem.thumbnails[imageIndex].image = tempVideoItems[itemIndex][imageIndex]
            }
        }
    }
    
    @objc func handleTapGesture(_ gesture : UITapGestureRecognizer) {
        defer {
            delegate?.updateDeleteButton()
        }
        if let selectedItem = selectedItem {
            selectedItem.hideSelectionView(true)
            self.selectedItem = nil
        }
        if selectedVideoIndex >= 0 {
            videoViews[selectedVideoIndex].setSelected(false)
        }
        guard let view = gesture.view as? LeapTimelineVideoView, let index = videoViews.firstIndex(of: view), index != selectedVideoIndex else {
            selectedVideoIndex = -1
            return
        }
        selectedVideoIndex = index
        view.setSelected(true)
        videoStackView.bringSubviewToFront(view)
    }
    
    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let view = gesture.view as? LeapTimelineVideoView else { return }
        switch gesture.state {
        case .began:
            initialIndex = selectedVideoIndex
            var boundsToUse = view.selectionView.bounds
            boundsToUse.size.width += 24
            let snapshotView = UIImageView(frame: boundsToUse)
            snapshotView.image = view.createSnapshot(boundsToUse: boundsToUse)
            snapshotView.center = CGPoint(x: gesture.location(in: mainVideoScrollView).x, y: 17)
            mainVideoScrollView.addSubview(snapshotView)
            self.snapshotView = snapshotView
            view.alpha = 0
            generator.impactOccurred()
        case .changed:
            guard let snapshotView = snapshotView else { return }
            let location = gesture.location(in: mainVideoScrollView)
            let locationInView = gesture.location(in: self)
            snapshotView.center = CGPoint(x: location.x, y: 17)
            func updateUI() {
                guard let currentIndex = videoViews.firstIndex(of: view) else { return }
                videoViews.insert(videoViews.remove(at: currentIndex), at: selectedVideoIndex)
                if currentIndex < selectedVideoIndex {
                    var widthToAdd: CGFloat = 0
                    for index in currentIndex..<selectedVideoIndex {
                        let videoView = videoViews[index]
                        videoView.frame.origin.x -= view.frame.size.width
                        widthToAdd += videoView.frame.size.width
                    }
                    view.frame.origin.x += widthToAdd
                } else {
                    var widthToSubtract: CGFloat = 0
                    for index in (selectedVideoIndex+1)...currentIndex {
                        let videoView = videoViews[index]
                        videoView.frame.origin.x += view.frame.size.width
                        widthToSubtract += videoView.frame.size.width
                    }
                    view.frame.origin.x -= widthToSubtract
                }
            }
            if locationInView.x-snapshotView.frame.size.width/2 < 0 && selectedVideoIndex > 0 {
                mainVideoScrollView.contentOffset.x -= 5
            } else if locationInView.x+snapshotView.frame.size.width/2 > UIScreen.main.bounds.width && selectedVideoIndex < videoViews.count-1 {
                mainVideoScrollView.contentOffset.x += 5
            }
            if selectedVideoIndex-1 >= 0 && videoViews[selectedVideoIndex-1].center.x > location.x {
                selectedVideoIndex -= 1
                updateUI()
            } else if selectedVideoIndex+1 < videoViews.count && videoViews[selectedVideoIndex+1].center.x < location.x {
                selectedVideoIndex += 1
                updateUI()
            }
        default:
            snapshotView?.removeFromSuperview()
            snapshotView = nil
            view.alpha = 1
            guard initialIndex != selectedVideoIndex else { return }
            delegate?.rearrangeVideo(initialIndex: initialIndex, finalIndex: selectedVideoIndex)
        }
    }
    
    @objc func leftAnchorDragged(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let position = gesture.location(in: videoStackView).x
            if position < 0 {
                leftanchorConstraint.constant = 10
            } else if videoStackView.frame.size.width+rightAnchorConstraint.constant-position+10 > 360 {
                leftanchorConstraint.constant = videoStackView.frame.size.width+rightAnchorConstraint.constant-340
            } else if position+50 < (videoStackView.frame.size.width+rightAnchorConstraint.constant) {
                leftanchorConstraint.constant = position+10
            } else {
                leftanchorConstraint.constant = videoStackView.frame.size.width+rightAnchorConstraint.constant-40
            }
        case .ended:
            let newWidth = videoStackView.frame.size.width - leftanchorConstraint.constant + rightAnchorConstraint.constant + 20
            mainVideoScrollView.contentOffset.x -= mainVideoScrollView.contentSize.width - newWidth
            mainVideoScrollView.contentSize.width = newWidth
            effectsScrollView.contentSize.width = newWidth
            effectsScrollView.contentOffset.x = mainVideoScrollView.contentOffset.x
            videoStackView.frame.origin.x = -(leftanchorConstraint.constant-10)
            effectsStackView.frame.origin.x = videoStackView.frame.origin.x
            reloadVideo()
        default:
            break
        }
    }
    
    @objc func rightAnchorDragged(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let position = videoStackView.frame.size.width - gesture.location(in: videoStackView).x
            if position < 0 {
                rightAnchorConstraint.constant = -10
            } else if videoStackView.frame.size.width-leftanchorConstraint.constant-position+10 > 360 {
                rightAnchorConstraint.constant = -(videoStackView.frame.size.width-leftanchorConstraint.constant-340)
            } else if position+50 < (videoStackView.frame.size.width-leftanchorConstraint.constant) {
                rightAnchorConstraint.constant = -position - 10
            } else {
                rightAnchorConstraint.constant = -(videoStackView.frame.size.width-leftanchorConstraint.constant-40)
            }
        case .ended:
            mainVideoScrollView.contentSize.width = videoStackView.frame.size.width - leftanchorConstraint.constant + rightAnchorConstraint.constant + 20
            effectsScrollView.contentSize.width = mainVideoScrollView.contentSize.width
            reloadVideo()
        default:
            break
        }
    }
    
    @objc func addTapped(_ sender: UIButton) {
        delegate?.openGallery()
    }
}

extension LeapTimelineView: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.timelineBeginDragging()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.timelineEndDragging()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { delegate?.timelineEndDragging() }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isScrollUpdating else { return }
        if scrollView == mainVideoScrollView {
            effectsScrollView.contentOffset.x = scrollView.contentOffset.x
        } else if scrollView == effectsScrollView {
            mainVideoScrollView.contentOffset.x = scrollView.contentOffset.x
        }
        delegate?.timelineDragged(seconds: (scrollView.contentOffset.x + UIScreen.main.bounds.width/2)/24)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if selectedVideoIndex >= 0 {
            for videoView in videoViews {
                for subView in videoView.selectionView.subviews {
                    let subviewPoint = subView.convert(point, from: self)
                    if subView.point(inside: subviewPoint, with: event) { return subView }
                }
            }
        }
        for wrapperView in effectsStackView.arrangedSubviews {
            guard let wrapperView = wrapperView as? LeapTimelineWrapperView else { continue }
            if wrapperView.timelineItemView.leftDragView.isHidden {
                return super.hitTest(point, with: event)
            }
            for subView in wrapperView.timelineItemView.subviews {
                let subviewPoint = subView.convert(point, from: self)
                if subView.point(inside: subviewPoint, with: event) { return subView }
            }
        }
        return super.hitTest(point, with: event)
    }
}

extension LeapTimelineView: LeapTimelineWrapperDelegate {
    
    func timelineSelected(timelineItem: LeapTimelineWrapperView) {
        defer {
            delegate?.updateDeleteButton()
        }
        if selectedVideoIndex >= 0 {
            videoViews[selectedVideoIndex].setSelected(false)
            selectedVideoIndex = -1
        }
        if let selectedItem = selectedItem {
            selectedItem.hideSelectionView(true)
            if selectedItem == timelineItem {
                self.selectedItem = nil
                return
            }
        }
        selectedItem = timelineItem
        timelineItem.hideSelectionView(false)
    }
}

extension LeapTimelineView: LeapTimelineVideoDelegate {
    
    func resetVideoViews() {
        var totalWitdth: CGFloat = 0
        for videoView in videoViews {
//            if index == 0 && videoView.frame.origin.x != 0 {
//                if videoView.frame.origin.x+10 > leftanchorConstraint.constant {
//                    leftanchorConstraint.constant = 10
//                } else {
//                    leftanchorConstraint.constant -= videoView.frame.origin.x
//                }
//            }
            videoView.frame.origin.x = totalWitdth
            totalWitdth += videoView.frame.size.width+1
        }
        videoStackView.frame.size.width = totalWitdth
        let newWidth = videoStackView.frame.size.width - leftanchorConstraint.constant + rightAnchorConstraint.constant + 20
        mainVideoScrollView.contentOffset.x -= mainVideoScrollView.contentSize.width - newWidth
        mainVideoScrollView.contentSize.width = newWidth
        effectsScrollView.contentSize.width = newWidth
        effectsScrollView.contentOffset.x = mainVideoScrollView.contentOffset.x
        videoStackView.frame.origin.x = -(leftanchorConstraint.constant-10)
        effectsStackView.frame.origin.x = videoStackView.frame.origin.x
    }
    
    func updateTrim(isTrimming: Bool) {
        isScrollUpdating = isTrimming
        isTrimming ? delegate?.timelineBeginDragging() : delegate?.timelineEndDragging()
    }
    
    func reloadVideo() {
        delegate?.reloadVideo()
    }
}
