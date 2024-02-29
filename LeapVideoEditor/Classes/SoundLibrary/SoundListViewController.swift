//
//  SoundTableViewController.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 10/10/22.
//

import UIKit

class SoundListViewController: SoundBaseViewController {
    
    private let collectionId: String
    
    init(accessToken: String, collectionId: String) {
        self.collectionId = collectionId
        
        super.init(nibName: nil, bundle: nil)
        self.accessToken = accessToken
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        callCollectionAPI()
    }
    
    func callCollectionAPI() {
        Task {
            showHud()
            let response = await NetworkHelper.request(url: "\(SoundPath.getCollections)/\(collectionId)", method: .get, headers: ["Authorization": "Bearer \(accessToken)"], Collection.self)
            self.removeHud()
            switch response.result {
            case .success(let value):
                self.tracks = value.tracks
                self.tableView.reloadData()
                self.navigationItem.title = value.name
            case .failure(let error):
                self.showAlert(title: "Error", msg: error.isResponseSerializationError ? "Something went wrong. Please try again later." : error.localizedDescription)
            }
        }
    }

    
}
