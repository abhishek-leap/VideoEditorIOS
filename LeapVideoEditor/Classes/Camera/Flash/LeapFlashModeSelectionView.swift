//
//  LeapFlashModeSelectionView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 19/08/22.
//

import SCSDKCameraKitReferenceUI
import Foundation
import UIKit

public protocol LeapFlashModeSelectionViewDelegate: AnyObject {

    /// Notifies the delegate that there is an update to the selected flash mode.
    /// - Parameters:
    ///    - view: The flash mode selection view.
    ///    - updatedFlashMode: The updated flash mode selection.
    func flashModeSelectionView(_ view: LeapFlashModeSelectionView, updatedMode mode: LeapCameraController.FlashMode)

}

public class LeapFlashModeSelectionView: UIView {

    /// Delegate for handling update's to the selected flash mode in the view.
    public weak var delegate: LeapFlashModeSelectionViewDelegate?

    /// The current FlashMode that is selected in the view.
    public var flashMode: LeapCameraController.FlashMode {
        set {
            segmentedControl.selectedSegmentIndex = newValue.rawValue
        }
        get {
            return LeapCameraController.FlashMode(rawValue: segmentedControl.selectedSegmentIndex) ?? .standard
        }
    }

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            NSLocalizedString("Standard", comment: ""),
            NSLocalizedString("Ring", comment: ""),
        ])

        control.accessibilityIdentifier = FlashControlElements.flashModeSelector.id
        control.addTarget(self, action: #selector(flashModeChanged), for: .valueChanged)

        control.tintColor = .clear
        control.backgroundColor = .clear
        control.apportionsSegmentWidthsByContent = true
        let rect = CGRect(x: 0.0, y: 0.0, width: 1, height: 27)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        control.setDividerImage(image, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        control.setBackgroundImage(image, for: .normal, barMetrics: .default)

        let imageSize = CGSize(width: 3, height: 27)
        let underlineSize = CGSize(width: 3, height: 3)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let selImage = renderer.image(actions: { context in
            UIColor(hex: 0xFFFC00).setFill()
            UIRectFill(
                CGRect(
                    x: 0, y: imageSize.height - underlineSize.height, width: underlineSize.width,
                    height: underlineSize.height))
        })
        control.setBackgroundImage(selImage, for: .selected, barMetrics: .default)

        let defaultAttributes = [
            NSAttributedString.Key.font: UIFont.sc_demiBoldFont(size: 16)!,
            NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5),
        ]
        control.setTitleTextAttributes(defaultAttributes, for: .normal)
        let selectedAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(hex: 0xFFFC00)
        ]
        control.setTitleTextAttributes(selectedAttributes, for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        if #available(iOS 13.0, *) {
            control.layer.maskedCorners = .init()
        } else {
            control.layer.cornerRadius = 0
        }

        return control
    }()

    @objc private func flashModeChanged(_ sender: UISegmentedControl) {
        if let flashMode = LeapCameraController.FlashMode(rawValue: sender.selectedSegmentIndex) {
            delegate?.flashModeSelectionView(self, updatedMode: flashMode)
        }
    }

    // MARK: Init

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

}

// MARK: View Setup

extension LeapFlashModeSelectionView {

    private func commonInit() {
        addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

}
