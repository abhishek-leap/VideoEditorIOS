//
//  LeapTimelineWrapperView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 14/09/22.
//

import UIKit

protocol LeapTimelineWrapperDelegate: AnyObject {
    
    func timelineSelected(timelineItem: LeapTimelineWrapperView)
}

class LeapTimelineWrapperView: UIView {
    
    let timelineItemView: LeapTimelineItemView
    let timelineItem: LeapTimelineItem
    weak var delegate: LeapTimelineWrapperDelegate?
    private var initialPoint = CGFloat.zero
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        UILongPressGestureRecognizer(target: self, action: #selector(timelineViewDragged(_:)))
    }()
    
    init(timelineItem: LeapTimelineItem) {
        self.timelineItem = timelineItem
        timelineItemView = LeapTimelineItemView(timelineItem: timelineItem)
        super.init(frame: .zero)
        timelineItemView.frame = CGRect(x: timelineItem.startPosition*24, y: 0, width: timelineItem.size*24, height: 34)
        addSubview(timelineItemView)
        
        timelineItemView.leftDragView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(leftViewDragged(_:))))
        timelineItemView.rightDragView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rightViewDragged(_:))))
        timelineItemView.addGestureRecognizer(longPressGesture)
        timelineItemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(timelineTapped(_:))))
        hideSelectionView(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func updateAudioSize(waveformView: AudioVisualizationView, overrite: Bool = false) {
        if !overrite { timelineItem.recordedAudioSize += 0.16666667 }
        if timelineItem.recordedAudioSize > timelineItem.size || overrite {
            timelineItem.size = timelineItem.recordedAudioSize
            timelineItemView.frame.size.width = timelineItem.recordedAudioSize*24
            waveformView.frame.size.width = timelineItemView.frame.size.width
        }
    }
    
    @objc func leftViewDragged(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            var xPosition = gesture.location(in: self).x
            if xPosition < 0 { xPosition = 0 }
            let width = timelineItemView.frame.size.width - (xPosition - timelineItemView.frame.origin.x)
            guard width >= 30 else { return }
            timelineItemView.frame.size.width = width
            timelineItemView.frame.origin.x = xPosition
        case .ended:
            timelineItem.size = timelineItemView.frame.size.width/24
            timelineItem.startPosition = timelineItemView.frame.origin.x/24
        default:
            break
        }
    }
    
    @objc func rightViewDragged(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            var width = gesture.location(in: self).x
            if width > frame.size.width { width = frame.size.width }
            width -= timelineItemView.frame.origin.x
            guard width >= 30 else { return }
            timelineItemView.frame.size.width = width
        case .ended:
            timelineItem.size = timelineItemView.frame.size.width/24
            timelineItem.startPosition = timelineItemView.frame.origin.x/24
        default:
            break
        }
    }
    
    @objc func timelineViewDragged(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            generator.impactOccurred()
            initialPoint = gesture.location(in: self).x
        case .changed:
            let newPoint = gesture.location(in: self).x
            var position = (newPoint - initialPoint) + timelineItemView.frame.origin.x
            if position < 0 { position = 0 }
            if position + timelineItemView.frame.size.width > frame.size.width { position = frame.size.width - timelineItemView.frame.size.width }
            timelineItemView.frame.origin.x = position
            initialPoint = newPoint
        case .ended:
            timelineItem.startPosition = timelineItemView.frame.origin.x/24
        default:
            break
        }
    }
    
    @objc func timelineTapped(_ gesture: UITapGestureRecognizer) {
        delegate?.timelineSelected(timelineItem: self)
    }
    
    func hideSelectionView(_ visible: Bool) {
        timelineItemView.hideSelectionView(visible)
        longPressGesture.isEnabled = !visible
    }
}
