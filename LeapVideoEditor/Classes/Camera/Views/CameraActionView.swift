//
//  CameraActionView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 23/08/22.
//

import UIKit

public protocol CameraActionDelegate: AnyObject {
    func didSelect(action: CameraAction)
}

public class CameraActionView: UITableView {
    
    private var cameraActions = [CameraAction]()
    public weak var actionDelegate: CameraActionDelegate?
    var showAll = false {
        didSet {
            reloadData()
        }
    }
    
    let moreActionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 21
        button.setImage(UIImage(named: "arrow-down", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
        button.setImage(UIImage(named: "arrow-up", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .selected)
        button.backgroundColor = UIColor(named: "buttonBackground", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func setup(cameraActions: [CameraAction]) {
        backgroundColor = .clear
        separatorStyle = .none
        register(CameraActionCell.self, forCellReuseIdentifier: CameraActionCell.identifierString)
        self.cameraActions = cameraActions
        dataSource = self
        delegate = self
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 42, height: 48))
        footerView.addSubview(moreActionButton)
        NSLayoutConstraint.activate([
            moreActionButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 6),
            moreActionButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor),
            moreActionButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            moreActionButton.heightAnchor.constraint(equalToConstant: 42),
            moreActionButton.widthAnchor.constraint(equalToConstant: 42)
        ])
        tableFooterView = footerView
        moreActionButton.addTarget(self, action: #selector(moreActionTapped(_:)), for: .touchUpInside)
    }
    
    @objc func moreActionTapped(_ sender: UIButton) {
        showAll.toggle()
        sender.isSelected = showAll
    }
}

extension CameraActionView: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showAll {
            return cameraActions.count
        }
        return cameraActions.count > 5 ? 5 : cameraActions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CameraActionCell.identifierString, for: indexPath) as! CameraActionCell
        let cameraAction = cameraActions[indexPath.row]
        let imageName: String
        let title: String
        switch cameraAction {
        case .flip:
            imageName = "flip-camera-icon"
            title = "Flip"
        case .sound:
            imageName = "sound-icon"
            title = "Sound"
        case .effects:
            imageName = "effects-icon"
            title = "Lenses"
        case .filters:
            imageName = "filter-icon"
            title = "Filters"
        case .timer:
            imageName = "timer-icon"
            title = "Timer"
        case .speed:
            imageName = "speed-icon"
            title = "Speed"
        case .flash:
            imageName = "flash-icon"
            title = "Flash"
        case .grid:
            imageName = "grid-icon"
            title = "Grid"
        case .stickers:
            imageName = "sticker-icon"
            title = "Stickers"
        case .text:
            imageName = "textIcon"
            title = "Text"
        case .voice:
            imageName = "micIcon"
            title = "Voice"
        }
        cell.actionImageView.image = UIImage(named: imageName, in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        cell.actionLabel.text = title
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionDelegate?.didSelect(action: cameraActions[indexPath.row])
    }
}

public enum CameraAction: CaseIterable {
    case flip
    case sound
    case effects
    case filters
    case timer
    case speed
    case flash
    case grid
    case stickers
    case text
    case voice
}
