//
//  VideoTextOverlayController.swift
//  LeapVideoEditor
//
//  Created by bigstep on 06/09/22.
//

import Foundation
import UIKit

// MARK: VideoTextDelegate

protocol VideoTextDelegate: AnyObject {
    
    // MARK: this provide the final image returned from UILabel and we can add this image in video
    /// - Parameters:
    ///   - editedImageLabel: image after converting uilabel to image
    
    func didEndEditing(_ editedImageLabel: UIImage)
}


class VideoTextOverlayController: BaseViewController {
    
    weak var delegate: VideoTextDelegate?
    private var colorsViewBottomConstraint: NSLayoutConstraint?
    
    // MARK: UI Elements
    
    // color list view
    private let colorsView: VideoTextColorsView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let view = VideoTextColorsView(frame: CGRect.zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    // textView to edit the text to be displayed on the video overlay
    private let editorTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 50)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        textView.textColor = .white
        return textView
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor.gray, for: .normal)
        return button
    }()
    
    // text style view
    private let textStyleView: VideoTextStyleView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let view = VideoTextStyleView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func loadView() {
        super.loadView()
        self.setupColorsView()
        self.setupTextStyleView()
        self.setupTextView()
        self.transparentNavBar()
        self.doneButtonSetup()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setuKeyboardNotification()
        editorTextView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        editorTextView.centerVertically()
    }
    
    deinit {
        removeKeyboardNotification()
    }
}

// MARK: Color list view

extension VideoTextOverlayController: OverlayTextColorDelegate {
    
    // MARK: set colors view constraints
    
    private func setupColorsView() {
        view.addSubview(colorsView)
        colorsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        colorsViewBottomConstraint = colorsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        colorsViewBottomConstraint?.isActive = true
        colorsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        colorsView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        colorsView.colorActionDelegate = self
    }
    
    // MARK: color selection action
    
    func didSelectColor(_ color: VideoOverlayTextColor) {
        editorTextView.textColor = color.colorCode.hexStringToUIColor()
    }
}

// MARK: text view to edit the text

extension VideoTextOverlayController: UITextViewDelegate {
    
    // MARK: set textfield constraints
    
    private func setupTextView() {
        view.addSubview(editorTextView)
        NSLayoutConstraint.activate([
            editorTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            editorTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editorTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            editorTextView.bottomAnchor.constraint(equalTo: textStyleView.topAnchor, constant: -10)
        ])
    }
}


// MARK: Keyboard handling

extension VideoTextOverlayController {
    
    // MARK: Notify when the keyboard is launched
    
    private func setuKeyboardNotification() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    // MARK: to remove the keyboard notification
    
    private func removeKeyboardNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: this function will get called when keyboard will launch and will re-adjust the UI
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardFrameInView = self.view.convert(keyboardFrame.cgRectValue, from: nil)
            let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
            let intersection = safeAreaFrame.intersection(keyboardFrameInView)
            colorsViewBottomConstraint?.constant = -intersection.height - 5
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: Text Style View Setup

extension VideoTextOverlayController {
    
    private func setupTextStyleView() {
        view.addSubview(textStyleView)
        textStyleView.bottomAnchor.constraint(equalTo: colorsView.topAnchor, constant: -5).isActive = true
        textStyleView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textStyleView.widthAnchor.constraint(equalToConstant: view.bounds.width - 40).isActive = true
        textStyleView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        textStyleView.styleDelegate = self
    }
}

// MARK: Done Button setup

extension VideoTextOverlayController {
    
    // MARK: adding done button in nav bar
    
    private func doneButtonSetup() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEditing))
        doneButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    // MARK: called when add texting is done
    
    @objc func doneEditing() {
        self.dismiss(animated: true) {[weak self] in
            guard let self = self else { return}
            let text = self.editorTextView.text ?? ""
            if text != "" {
                
                // creating a label and setting all the selected properties and then converting it to image
                // to add it to video layer
                let label = UILabel()
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.backgroundColor = self.editorTextView.textInputView.backgroundColor
                label.text = self.editorTextView.text ?? ""
                label.font = self.editorTextView.font ?? .systemFont(ofSize: 50)
                label.textAlignment = self.editorTextView.textAlignment
                label.setSizeForText(label.text ?? "", maxWidth: self.view.frame.size.width)
                label.textColor = self.editorTextView.textColor
                guard let image = UIImage.imageWithLabel(view: label) else { return}
                self.delegate?.didEndEditing(image)
            }
            
            
        }
        
    }
}

// MARK: Text Style Delegate

extension VideoTextOverlayController: VideoTextStyleDelegate {
    
    // MARK: current font selected
    // Parameters:
    // font: current font selected
    
    func didSelectFont(_ font: String) {
        editorTextView.font = UIFont(name: font, size: 50) ?? .systemFont(ofSize: 50)
        editorTextView.centerVertically()
        
    }
    
    // MARK: text background button
    // Parameters:
    // background: current background selected
    
    func didTappedTextBackgroundButton(_ background: UIColor) {
        editorTextView.textInputView.backgroundColor = background
    }
    
    // MARK: when tap on alignment button
    // Parameters:
    // alignment: current alignment selected
    
    func didTappedAlignmentButton(_ alignment: NSTextAlignment) {
        editorTextView.textAlignment = alignment
    }
    
    // MARK: when tap on neon text style
    
    func didTappedNeonStyle() {
        let gradientColor1 = UIColor(named: "gradient-1", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil) ?? .red
        let gradientColor2 = UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil) ?? .green
        editorTextView.applyGradientWith(startColor: gradientColor1, endColor: gradientColor2)
    }
}

extension UILabel {
    
    var textSize: CGSize { text?.size(withAttributes: [.font: font!]) ?? .zero }
    
    func setSizeForText(_ str: String, maxWidth: CGFloat) {
        text = str
        let dividedByMaxWidth = Int(textSize.width / maxWidth)
        if dividedByMaxWidth == 0 {
            frame.size = textSize
        } else {
            numberOfLines = dividedByMaxWidth + 1
            frame.size = CGSize(width: maxWidth, height: frame.size.height * CGFloat(numberOfLines))
            sizeToFit()
        }
    }
}



