//
//  VideoTextStyleView.swift
//  LeapVideoEditor
//
//  Created by bigstep on 07/09/22.
//

import Foundation
import UIKit
import FontAwesome_swift

// MARK: text style options

enum TextStyleType {
    case font
    case textGlow
}

// MARK: Text Alignment options

enum VideoTextAlignment {
    case center
    case left
    case right
}


// MARK: struct to pass the data to the cells

struct TextStyle {
    let type: TextStyleType
    var name: String
    let fontName: String
}

// MARK: Delegates for style actions

protocol VideoTextStyleDelegate: AnyObject {
    func didSelectFont(_ font: String)
    func didTappedTextBackgroundButton(_ background: UIColor)
    func didTappedAlignmentButton(_ alignment: NSTextAlignment)
    func didTappedNeonStyle()
}

class VideoTextStyleView: UIView {
    
    weak var styleDelegate: VideoTextStyleDelegate?
    private let cellSpacing: CGFloat = 12  // spacing between two font options in collection view
    private var textStyles = [
        TextStyle(type: .font, name: "ewriter", fontName: "AmericanTypewriter-Bold"),
        TextStyle(type: .font, name: "Handwriting", fontName: "SnellRoundhand-Black"),
        TextStyle(type: .textGlow, name: "NEON", fontName: ""),
        TextStyle(type: .font, name: "Menlo", fontName: "Menlo-Regular"),
        TextStyle(type: .font, name: "Charter", fontName: "Charter-BlackItalic"),
        TextStyle(type: .font, name: "SavoyeLet", fontName: "SavoyeLetPlain"),
        TextStyle(type: .font, name: "Didot", fontName: "Didot"),
        TextStyle(type: .font, name: "Baskerville", fontName: "Baskerville")
    ]
    
    
    // collection view to display fonts
    private let collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cw = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cw.translatesAutoresizingMaskIntoConstraints = false
        cw.backgroundColor = .clear
        cw.showsHorizontalScrollIndicator = false
        return cw
    }()
    
    // text background button to change text background
    private let textBackgroundButton: UIButton = {
        let button = UIButton()
        button.tag = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.setTitle("A", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = .boldSystemFont(ofSize: 25)
        button.setTitleColor(.white, for: .normal)
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    
    // text alignment button to change the alignment of text
    private let textAlignmentButtton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(String.fontAwesomeIcon(name: .alignCenter), for: .normal)
        button.titleLabel?.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        button.setTitleColor(.white, for: .normal)
        button.tag = 0
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupButtonViews()
        setupCollectionView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: collection view setup:-

extension VideoTextStyleView {
    private func setupCollectionView() {
        addSubview(collectionView)
        collectionView.leftAnchor.constraint(equalTo: textAlignmentButtton.rightAnchor, constant: 10).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        collectionView.register(TextStyleCell.self, forCellWithReuseIdentifier: TextStyleCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

// MARK: setup text background and alignment view and its actions

extension VideoTextStyleView {
    private func setupButtonViews() {
        addSubview(textBackgroundButton)
        textBackgroundButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        textBackgroundButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        textBackgroundButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textBackgroundButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        textBackgroundButton.addTarget(self, action: #selector(textBackgroundAction(_:)), for: .touchUpInside)
        
        addSubview(textAlignmentButtton)
        textAlignmentButtton.leftAnchor.constraint(equalTo: textBackgroundButton.rightAnchor, constant: 10).isActive = true
        textAlignmentButtton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        textAlignmentButtton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textAlignmentButtton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        textAlignmentButtton.addTarget(self, action: #selector(textAlignmentAction(_:)), for: .touchUpInside)
    }
    
    // MARK: text alignment button action
    
    @objc func textAlignmentAction(_ sender: UIButton) {
        sender.tag = sender.tag > 1 ? 0 : sender.tag + 1
        switch sender.tag {
        case 0:
            sender.setTitle(String.fontAwesomeIcon(name: .alignCenter), for: .normal)
            styleDelegate?.didTappedAlignmentButton(.center)
        case 1:
            sender.setTitle(String.fontAwesomeIcon(name: .alignLeft), for: .normal)
            styleDelegate?.didTappedAlignmentButton(.left)
        case 2:
            sender.setTitle(String.fontAwesomeIcon(name: .alignRight), for: .normal)
            styleDelegate?.didTappedAlignmentButton(.right)
        default:
            print("not applicable")
        }
    }
    
    // MARK: text background button action
    
    @objc func textBackgroundAction(_ sender: UIButton) {
        sender.tag = sender.tag > 2 ? 0 : sender.tag + 1
        sender.setTitleColor(.white, for: .normal)
        switch sender.tag {
        case 0:
            sender.backgroundColor = .clear
        case 1:
            sender.backgroundColor = .black
        case 2:
            sender.backgroundColor = .white
            sender.setTitleColor(.black, for: .normal)
        case 3:
            sender.backgroundColor = .gray
        default:
            print("not applicable")
        }
        let color = sender.backgroundColor ?? .clear
        styleDelegate?.didTappedTextBackgroundButton(color)
    }
}


// MARK: collection view delegates and datasources implementation

extension VideoTextStyleView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return textStyles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextStyleCell.reuseIdentifier, for: indexPath) as? TextStyleCell else { fatalError("could not find cell")}
        cell.style = textStyles[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = textStyles[indexPath.row]
        let itemSize = item.name.size(withAttributes: [
            NSAttributedString.Key.font : UIFont(name: item.fontName, size: 15) ?? .systemFont(ofSize: 15)
        ])
        return CGSize(width: itemSize.width + 25, height: 35)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let style = self.textStyles[indexPath.row]
        switch style.type {
        case .textGlow:
            styleDelegate?.didTappedNeonStyle()
        case .font:
            styleDelegate?.didSelectFont(style.fontName)
        }
        let selectedCell = collectionView.cellForItem(at: indexPath)  as? TextStyleCell
        selectedCell?.layer.borderColor = UIColor.white.withAlphaComponent(1.0).cgColor
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let unselectedCell = collectionView.cellForItem(at: indexPath)  as? TextStyleCell
        unselectedCell?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
    }
}



