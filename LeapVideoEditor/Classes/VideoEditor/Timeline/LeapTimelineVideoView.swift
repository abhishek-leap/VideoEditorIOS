//
//  LeapTimelineCell.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 19/09/22.
//

import UIKit
import AVFoundation

protocol LeapTimelineVideoDelegate: AnyObject {
    
    func resetVideoViews()
    func updateTrim(isTrimming: Bool)
    func reloadVideo()
}

class LeapTimelineVideoView: UIView {
    
    let stackView = UIStackView()
    let selectionView = LeapTimelineBaseView()
    let longGesture: UILongPressGestureRecognizer
    let leapTimelineVideoItem: LeapTimelineVideoItem
    
    let muteView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "mute", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    weak var delegate: LeapTimelineVideoDelegate?
    
    init(target: LeapTimelineView, leapTimelineVideoItem: LeapTimelineVideoItem) {
        longGesture = UILongPressGestureRecognizer(target: target, action: #selector(LeapTimelineView.handleLongGesture(_:)))
        self.leapTimelineVideoItem = leapTimelineVideoItem
        super.init(frame: .zero)
        
        delegate = target
        longGesture.isEnabled = false
        addGestureRecognizer(longGesture)
        
        layer.cornerRadius = 6
        
        let stackWrapperView = UIView()
        stackWrapperView.clipsToBounds = true
        stackWrapperView.translatesAutoresizingMaskIntoConstraints = false
        stackWrapperView.addSubview(stackView)
        addSubview(stackWrapperView)
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionView)
        
        selectionView.leftDragView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(leftViewDragged(_:))))
        selectionView.rightDragView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rightViewDragged(_:))))
        addSubview(muteView)
        muteView.isHidden = !leapTimelineVideoItem.isMuted
        
        NSLayoutConstraint.activate([
            selectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionView.topAnchor.constraint(equalTo: topAnchor),
            selectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackWrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackWrapperView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackWrapperView.topAnchor.constraint(equalTo: topAnchor),
            stackWrapperView.bottomAnchor.constraint(equalTo: bottomAnchor),
            muteView.centerYAnchor.constraint(equalTo: centerYAnchor),
            muteView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func leftViewDragged(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.updateTrim(isTrimming: true)
        case .changed:
            var xPosition = gesture.location(in: self).x
            if stackView.frame.origin.x - xPosition > 0 {
                xPosition += stackView.frame.origin.x - xPosition
            }
            frame.size.width -= xPosition
            frame.origin.x += xPosition
            stackView.frame.origin.x -= xPosition
        default:
            delegate?.resetVideoViews()
            delegate?.updateTrim(isTrimming: false)
            leapTimelineVideoItem.startPosition = abs(stackView.frame.origin.x)/24
            leapTimelineVideoItem.size = frame.size.width/24
            delegate?.reloadVideo()
        }
    }
    
    @objc func rightViewDragged(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.updateTrim(isTrimming: true)
        case .changed:
            var xPosition = gesture.location(in: self).x
            xPosition -= frame.size.width
            frame.size.width += xPosition
            if frame.size.width > (stackView.frame.size.width + stackView.frame.origin.x) {
                frame.size.width = (stackView.frame.size.width + stackView.frame.origin.x)
            }
        default:
            delegate?.resetVideoViews()
            delegate?.updateTrim(isTrimming: false)
            leapTimelineVideoItem.size = frame.size.width/24
            delegate?.reloadVideo()
        }
    }
    
    func setupVideo() {
        for thumbnail in leapTimelineVideoItem.thumbnails {
            stackView.addArrangedSubview(thumbnail)
        }
        frame.size = CGSize(width: leapTimelineVideoItem.duration*24, height: 34)
        stackView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 34)
        selectionView.isHidden = true
    }
    
    func setSelected(_ selected: Bool) {
        longGesture.isEnabled = selected
        selectionView.isHidden = !selected
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !selectionView.isHidden else {
            return super.point(inside: point, with: event)
        }
        if super.point(inside: point, with: event) { return true }
        for subview in [selectionView.leftDragView, selectionView.rightDragView] {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) { return true }
        }
        return false
    }
}
