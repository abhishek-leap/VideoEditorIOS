//
//  LeapTimelineBaseView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 14/09/22.
//

import UIKit

class LeapTimelineBaseView: UIView {
    
    let leftDragView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 12, height: 34), byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: 6, height: 6))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
        return view
    }()
    let rightDragView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 12, height: 34), byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 6, height: 6))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
        return view
    }()
    let topLine: UIView = {
        let line = UIView()
        line.backgroundColor = .white
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()
    let bottomLine: UIView = {
        let line = UIView()
        line.backgroundColor = .white
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 6
        
        addSubview(leftDragView)
        addSubview(rightDragView)
        addSubview(topLine)
        addSubview(bottomLine)
        
        NSLayoutConstraint.activate([
            leftDragView.topAnchor.constraint(equalTo: topAnchor),
            leftDragView.trailingAnchor.constraint(equalTo: leadingAnchor),
            leftDragView.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftDragView.widthAnchor.constraint(equalToConstant: 12),
            rightDragView.topAnchor.constraint(equalTo: topAnchor),
            rightDragView.leadingAnchor.constraint(equalTo: trailingAnchor),
            rightDragView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightDragView.widthAnchor.constraint(equalToConstant: 12),
            topLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 2),
            bottomLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideSelectionView(_ hidden: Bool) {
        leftDragView.isHidden = hidden
        rightDragView.isHidden = hidden
        topLine.isHidden = hidden
        bottomLine.isHidden = hidden
    }
}
