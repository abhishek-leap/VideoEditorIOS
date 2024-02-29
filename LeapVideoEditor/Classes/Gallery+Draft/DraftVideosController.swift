//
//  DraftVideosController.swift
//  LeapVideoEditor
//
//  Created by bigstep on 03/10/22.
//

import Foundation
import UIKit
import AVFoundation


class DraftVideosController: BaseViewController {
    weak var delegate: DraftVideoProtocol?
    var draftVideos: [DraftVideoModel] = [] {
        didSet {
            draftVideoTable.reloadData()
        }
    }
    
    // MARK: UI Elements:
    
    private lazy var draftVideoTable: UITableView = {
        let tableView = UITableView()
        tableView.separatorColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let headerView: GalleryHeader = {
        let header = GalleryHeader()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.headerLabel.text = "Drafts"
        return header
    }()
    
    override func loadView() {
        super.loadView()
        setupHeaderView()
        setupTableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

// MARK: Draft Video Table Setup

extension DraftVideosController {
    
    private func setupTableView() {
        view.addSubview(draftVideoTable)
        draftVideoTable.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        draftVideoTable.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        draftVideoTable.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10).isActive = true
        draftVideoTable.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        draftVideoTable.register(DraftVideoCell.self, forCellReuseIdentifier: DraftVideoCell.reuseIdentifier)
        draftVideoTable.delegate = self
        draftVideoTable.dataSource = self
    }
}

// MARK: draft header setup

extension DraftVideosController {
    
    func setupHeaderView() {
        view.addSubview(headerView)
        headerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        headerView.crossButton.addTarget(self, action: #selector(dismissGallery), for: .touchUpInside)
    }
    
    // MARK: cross button action to dismiss controller
    
    @objc private func dismissGallery() {
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: UITableView Delegates

extension DraftVideosController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return draftVideos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DraftVideoCell.reuseIdentifier, for: indexPath) as? DraftVideoCell else { fatalError("could not find cell")}
        cell.video = draftVideos[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.height/5
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) { [unowned self] in
            self.delegate?.didSelectDraftVideo(self.draftVideos[indexPath.row], index: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            draftVideos.remove(at: indexPath.row)
            if draftVideos.count == 0 {
                delegate?.emptyDraft()
            }
            DraftVideoModel.removeDraftVideo(draftVideos)
            tableView.endUpdates()
        }
    }
}



