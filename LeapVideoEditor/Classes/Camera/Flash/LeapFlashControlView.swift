//
//  LeapFlashControlView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 18/08/22.
//

import UIKit
import SCSDKCameraKitReferenceUI

public protocol LeapFlashControlViewDelegate: AnyObject {

    /// Notifies the delegate that a ring light color was selected.
    /// - Parameters:
    ///    - view: The flash control view.
    ///    - selectedRingLightColor: The ring light color that was just selected.
    func flashControlView(_ view: LeapFlashControlView, selectedRingLightColor color: UIColor)

    /// Notifies the delegate that the control's ring light intensity slider has an updated value.
    /// - Parameters:
    ///    - view: The flash control view.
    ///    - updatedRingLightValue: The updated intensity value received from the slider.
    func flashControlView(_ view: LeapFlashControlView, updatedRingLightValue value: Float)

    /// Notifies the delegate that there is an update to the selected flash mode.
    /// - Parameters:
    ///    - view: The flash control view.
    ///    - updatedFlashMode: The updated flash mode selection.
    func flashControlView(_ view: LeapFlashControlView, updatedFlashMode flashMode: LeapCameraController.FlashMode)

}

public class LeapFlashControlView: UIView {

    /// Delegate for handling changes to the view's controls.
    public weak var delegate: LeapFlashControlViewDelegate?

    /// The intensity of the ring light according to the control's slider's value.
    public var ringLightIntensityValue: Float {
        get {
            ringLightIntensitySlider.value
        }
        set {
            ringLightIntensitySlider.setValue(newValue, animated: false)
        }
    }

    /// Used to restore ring light intensity to the last user setting if the flash mode is changed via the flash mode selector.
    private var lastRingLightIntensityValue: Float?

    /// Whether or not the initial ring light color has been selected.
    private var initialColorSelected = false

    // MARK: Views

    /// View that provides the control with its blurred background.
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect: UIBlurEffect
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        } else {
            blurEffect = UIBlurEffect(style: .dark)
        }

        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Primary label for the control.
    public let primaryLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Flash", comment: "")
        label.textColor = .white
        label.font = UIFont.sc_boldFont(size: 18)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    /// View that enables the user to swtich between flash modes.
    public lazy var flashModeSelectionView: LeapFlashModeSelectionView = {
        let view = LeapFlashModeSelectionView()
        view.accessibilityLabel = NSLocalizedString("Flash Mode Selector", comment: "")
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    /// View with ring light color options to select between.
    public lazy var ringLightColorSelectionView: RingLightColorSelectionView = {
        let view = RingLightColorSelectionView()
        view.accessibilityLabel = NSLocalizedString("Ring Light Color Selector", comment: "")
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0

        return view
    }()

    /// Slider to choose intensity of the ring light.
    private lazy var ringLightIntensitySlider: ControlSlider = {
        let slider = ControlSlider()
        slider.accessibilityIdentifier = FlashControlElements.ringLightIntensitySlider.id
        slider.accessibilityLabel = NSLocalizedString("Ring Light Intensity Slider", comment: "")
        slider.delegate = self
        slider.translatesAutoresizingMaskIntoConstraints = false

        return slider
    }()

    /// Stack view that contains the ring light color selection view and intensity slider.
    private lazy var ringLightSettingsView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [ringLightColorSelectionView, ringLightIntensitySlider])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    // MARK: Flash Mode Change Handling

    private func flashModeChanged(to flashMode: LeapCameraController.FlashMode) {
        delegate?.flashControlView(self, updatedFlashMode: flashMode)
        switch flashMode {
        case .standard: collapseRingLightSettings()
        case .ring: expandRingLightSettings()
        }
    }

    private func collapseRingLightSettings() {
        ringLightIntensitySlider.setValue(0, animated: false)
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.ringLightColorSelectionView.alpha = 0
            self?.ringLightColorSelectionView.isHidden = true
        }
    }

    private func expandRingLightSettings() {
        UIView.animate(
            withDuration: 0.4, delay: 0, options: .curveEaseInOut,
            animations: { [weak self] in
                self?.ringLightColorSelectionView.isHidden = false
                self?.ringLightColorSelectionView.alpha = 1

            },
            completion: { [weak self] complete in
                if complete && !(self?.initialColorSelected ?? false) {
                    self?.ringLightColorSelectionView.performInitialSelection()
                    self?.initialColorSelected = true
                }
            })
    }

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.cornerRadius = 20
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
        layer.masksToBounds = true
        setupBlurEffectView()
        setupPrimaryLabel()
        setupFlashSelectionView()
        setupRingLightSettingsView()
        NSLayoutConstraint.activate([
            ringLightIntensitySlider.widthAnchor.constraint(equalToConstant: 161.0)
        ])
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: 189.0, height: UIView.noIntrinsicMetric)
    }

}

// MARK: Blur Effect

extension LeapFlashControlView {

    private func setupBlurEffectView() {
        addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

}

// MARK: Primary Label

extension LeapFlashControlView {

    private func setupPrimaryLabel() {
        addSubview(primaryLabel)
        NSLayoutConstraint.activate([
            primaryLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14.0),
            primaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14.0),
            primaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12.0),
            primaryLabel.heightAnchor.constraint(equalToConstant: 25.0),
        ])
    }

}

// MARK: Flash Mode Selector

extension LeapFlashControlView {

    private func setupFlashSelectionView() {
        addSubview(flashModeSelectionView)
        NSLayoutConstraint.activate([
            flashModeSelectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14.0),
            flashModeSelectionView.topAnchor.constraint(equalTo: primaryLabel.bottomAnchor, constant: 4.0),
            flashModeSelectionView.heightAnchor.constraint(equalToConstant: 27),
        ])
    }

}

// MARK: Ring Light Settings View

extension LeapFlashControlView {

    private func setupRingLightSettingsView() {
        addSubview(ringLightSettingsView)
        NSLayoutConstraint.activate([
            ringLightSettingsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            ringLightSettingsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            ringLightSettingsView.topAnchor.constraint(equalTo: flashModeSelectionView.bottomAnchor, constant: 11.0),
            bottomAnchor.constraint(equalTo: ringLightSettingsView.bottomAnchor, constant: 16.0),
        ])
    }
}

// MARK: Color Selection View

extension LeapFlashControlView {

    private func setupColorSelectionView() {
        addSubview(ringLightColorSelectionView)
        addConstraints([
            ringLightColorSelectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            ringLightColorSelectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            ringLightColorSelectionView.topAnchor.constraint(
                equalTo: flashModeSelectionView.bottomAnchor, constant: 11.0),
        ])
    }

}

// MARK: Intensity Slider

extension LeapFlashControlView {

    private func setupIntensitySlider() {
        addSubview(ringLightIntensitySlider)
        NSLayoutConstraint.activate([
            ringLightIntensitySlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14.0),
            ringLightIntensitySlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14.0),
            ringLightIntensitySlider.topAnchor.constraint(
                equalTo: ringLightColorSelectionView.bottomAnchor, constant: 8.0),
            bottomAnchor.constraint(equalTo: ringLightIntensitySlider.bottomAnchor, constant: 16.0),
        ])
    }

}

// MARK: Flash Mode Selection View Delegate

extension LeapFlashControlView: LeapFlashModeSelectionViewDelegate {

    public func flashModeSelectionView(_ view: LeapFlashModeSelectionView, updatedMode mode: LeapCameraController.FlashMode) {
        switch mode {
        case .ring:
            ringLightIntensityValue = lastRingLightIntensityValue ?? Constants.defaultRingLightIntensity
        case .standard:
            lastRingLightIntensityValue = ringLightIntensityValue
        }
        flashModeChanged(to: mode)
    }

}

// MARK: Control Slider Delegate

extension LeapFlashControlView: ControlSliderDelegate {

    public func controlSlider(_ slider: ControlSlider, updatedValue value: Float, done: Bool) {
        if value == 0 {
            flashModeSelectionView.flashMode = .standard
        } else {
            flashModeSelectionView.flashMode = .ring
        }

        if done {
            flashModeChanged(to: flashModeSelectionView.flashMode)
        }

        delegate?.flashControlView(self, updatedRingLightValue: value)
    }

}

// MARK: Ring Light Color Selection View Delegate

extension LeapFlashControlView: RingLightColorSelectionViewDelegate {

    public func ringLightColorSelectionView(_ view: RingLightColorSelectionView, selectedColor color: UIColor) {
        delegate?.flashControlView(self, selectedRingLightColor: color)
    }

}

// MARK: Constants

extension LeapFlashControlView {

    private enum Constants {
        static let defaultRingLightIntensity: Float = 0.2
    }

}
