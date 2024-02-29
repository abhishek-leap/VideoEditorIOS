//
//  VideoOverlayDragView.swift
//  LeapVideoEditor
//
//  Created by bigstep on 01/09/22.
//

import Foundation
import GiphyUISDK
import UIKit

// MARK: this class is used to drag sticker or text to set the position on the video

class VideoOverlayDragView: NSObject {
    var parentView: UIView?
    var videoBounds: CGRect?
   
    // The interaction we use to notify the VC
    var userDragged: ((CGPoint, Bool) -> ())?
    
    private lazy var draggableViews = [LeapTimelineItem]()

    
    private var currentViewIndex = -1  // store current view index
        
    private func setup(_ view: GiphyYYAnimatedImageView) {
        
        // Creation of the gesture recognizer
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognized))
        view.addGestureRecognizer(gestureRecognizer)
        
        let rotationGesture = UIRotationGestureRecognizer.init(target: self, action: #selector(rotate(gesture:)))
        view.addGestureRecognizer(rotationGesture)
        
        let pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(scale(gesture:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    
    /// to configure the selected sticker/text for dragging/rotating/resizing
    /// - Parameters:
    ///   - type: sticker or text
    ///   - stickerData: data of selected sticker
    ///   - text: text to add on the video if any
    
    func configureDragView(for type: VideoOverlayType, sticker: GiphyYYImage, text: String = "", timeLineItem: LeapTimelineItem, overlayCenter: CGPoint, itemSize: CGSize = .zero) {
        let draggableView = GiphyYYAnimatedImageView()
        draggableView.backgroundColor = .clear
        draggableView.isUserInteractionEnabled = true
        draggableView.layer.masksToBounds = true
        draggableView.contentMode = .scaleAspectFit
        timeLineItem.view = draggableView
        parentView?.addSubview(draggableView)
        draggableView.image = sticker
        draggableView.sizeToFit()
        let finalSize: CGSize
        if type == .text {
            finalSize = CGSize(width: draggableView.intrinsicContentSize.width*0.4, height: draggableView.intrinsicContentSize.height*0.4)
        } else {
            finalSize = draggableView.intrinsicContentSize
        }
        draggableView.frame.size = itemSize == .zero ? finalSize : itemSize
        draggableViews.append(timeLineItem)
        if timeLineItem.itemPosition == .zero {
            timeLineItem.view.center = parentView?.center ?? .zero
        }
        else {
            timeLineItem.view.frame.origin = timeLineItem.itemPosition
        }
        timeLineItem.view.tag = draggableViews.count - 1
        self.setup(timeLineItem.view)
    }
    
    func removeDragView(id: UUID) {
        draggableViews.first(where: { $0.id == id })?.view.removeFromSuperview()
    }
    
    private func update(old: CGPoint?) {
        self.draggableViews[currentViewIndex].offset = old ?? CGPoint.zero
        self.draggableViews[currentViewIndex].view.center = parentView!.center + old
    }
    
    func removeAllStickers() {
        for draggableView in draggableViews {
            draggableView.view.removeFromSuperview()
        }
        self.draggableViews.removeAll()
    }
}

// MARK: Gesture Actions:-

extension VideoOverlayDragView {
    
    // MARK: to resize the sticker/text
    
    @objc func scale(gesture : UIPinchGestureRecognizer){
        guard let view = gesture.view else { return}
        self.currentViewIndex = view.tag
        if gesture.state == UIGestureRecognizer.State.began || gesture.state == UIGestureRecognizer.State.changed{
            view.transform = (gesture.view?.transform)!.scaledBy(x: gesture.scale, y: gesture.scale)
            view.layer.contentsScale = UIScreen.main.scale + (4 * gesture.scale)
            view.layer.allowsEdgeAntialiasing = true
            for subview in (view.subviews) {
                subview.contentScaleFactor = gesture.scale
                subview.layer.contentsScale = UIScreen.main.scale + (4 * gesture.scale)
                subview.layer.allowsEdgeAntialiasing = true
            }
            gesture.scale = 1.0
            
        }
        if gesture.state == .ended {
            print(self.draggableViews[currentViewIndex].view.frame)
        }
    }
    
    // MARK: to rotate the sticker/text
    
    @objc func rotate(gesture : UIRotationGestureRecognizer){
        if gesture.state == UIGestureRecognizer.State.began || gesture.state == UIGestureRecognizer.State.changed{
            gesture.view?.transform = (gesture.view?.transform)!.rotated(by: gesture.rotation)
            gesture.rotation = 0
        }
    }
    
    // MARK: to relocate the sticker/text
    
    @objc private func panGestureRecognized(_ gestureRecognizer: UIPanGestureRecognizer) {
        // switch over the different states to perform the right operation
        guard let view = gestureRecognizer.view else { return}
        self.currentViewIndex = view.tag
        switch gestureRecognizer.state {
        case .began:
            // The interaction started.
            
            // Retrieve the current offset of the the view
            let currentOffset = self.draggableViews[currentViewIndex].offset
            
            // Retrieve from the gesture recognizer of how much the user dragged the element
            let translation = gestureRecognizer.translation(in: self.parentView)
            
            // Create the initial translation by summing up the current offset and the first translation
            let initialTranslation = currentOffset + translation
            
            // !!! SET THE INITIAL TRANSLATION INTO THE GESTURE RECOGNIZER !!!
            gestureRecognizer.setTranslation(initialTranslation, in: self.parentView)
            self.update(old: initialTranslation)//
            
            // Notify the VC
            self.userDragged?(initialTranslation, false)
            
            break
        case .changed:
            // Retrieve the change from the previous iteration
            let translation = gestureRecognizer.translation(in: self.parentView)
            self.update(old: translation)
            
            // Notify the VC
            self.userDragged?(translation, false)
            
        case .ended:
            // Retrieve the change from the previous iteration
          
            var translation = gestureRecognizer.translation(in: self.parentView)
            let videoBounds = self.videoBounds ?? CGRect.zero
            
            // checking if draggable view is outside the bounds of video
            if view.frame.maxX >= videoBounds.maxX {
                translation = CGPoint(x: translation.x - ( view.frame.maxX - videoBounds.maxX), y: translation.y)
            }
            else if view.frame.minX <= videoBounds.minX {
                translation = CGPoint(x: translation.x - ( view.frame.minX - videoBounds.minX ), y: translation.y)
            }
            if view.frame.maxY >= videoBounds.maxY {
                translation = CGPoint(x: translation.x, y: translation.y - ( view.frame.maxY - videoBounds.maxY))
            }
            else if view.frame.minY <= videoBounds.minY {
                translation = CGPoint(x: translation.x, y: translation.y - ( view.frame.minY - videoBounds.minY))
            }
            self.update(old: translation)
            
            // Notify the VC
            self.userDragged?(translation, true)
        default:
            break
        }
    }
}



