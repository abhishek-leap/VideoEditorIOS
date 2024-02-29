//
//  SoundViewController.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 09/10/22.
//

import UIKit
import Combine

protocol SoundControllerDelegate: AnyObject {
    func audioSelected(audioURL: URL, track: Track)
    func removeTrack()
}

class SoundCollectionViewController: SoundBaseViewController {
    
    let token: String
    private var collections = [Collection]()
    var textChangeToken: AnyCancellable?
    var selectedTrack: Track?
    var page = 0
    var pageSize = 20
    var canLoad = true
    
    init(token: String) {
        self.token = token
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search"
        searchController.delegate = self
//        searchController.searchBar.tintColor = .white
//        searchController.searchBar.barStyle = .black
        searchController.searchBar.searchTextField.backgroundColor = .white
        return searchController
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        return searchBar
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let width = (UIScreen.main.bounds.width-64)/3
        layout.itemSize = CGSize(width: width, height: width+17)
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SoundCollectionCell.self, forCellWithReuseIdentifier: SoundCollectionCell.identifier)
        return collectionView
    }()
    
    let selectedTrackImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    let selectedTrackNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        button.addTarget(self, action: #selector(removeSelectedTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.tintColor = .black
        button.setImage(UIImage(named: "close-icon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    lazy var selectedTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.gray.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 6
        view.addSubview(selectedTrackImageView)
        let currentLabel = UILabel()
        currentLabel.font = .systemFont(ofSize: 10)
        currentLabel.textColor = .gray
        currentLabel.text = "Current sound"
        let stackView = UIStackView(arrangedSubviews: [currentLabel, selectedTrackNameLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        view.addSubview(stackView)
        view.addSubview(removeButton)
        NSLayoutConstraint.activate([
            selectedTrackImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            selectedTrackImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            selectedTrackImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            selectedTrackImageView.heightAnchor.constraint(equalToConstant: 40),
            selectedTrackImageView.widthAnchor.constraint(equalToConstant: 40),
            stackView.leadingAnchor.constraint(equalTo: selectedTrackImageView.trailingAnchor, constant: 8),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            removeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            removeButton.topAnchor.constraint(equalTo: view.topAnchor),
            removeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            removeButton.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8)
        ])
        view.isHidden = true
        return view
    }()
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .white
        tableView.isHidden = true
        navigationItem.searchController = searchController
        let stackView = UIStackView(arrangedSubviews: [ collectionView, tableView, selectedTrackView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTrack()
        definesPresentationContext = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped(_:)))
        navigationItem.title = "Sounds"
        Task {
            showHud()
            let response = await NetworkHelper.request(url: Path.getAccessToken, method: .get, headers: ["Authorization" : "Bearer \(token)"], AccessTokenModel.self)
            switch response.result {
            case .success(let value):
                accessToken = value.accessToken
                await callCollectionAPI()
            case .failure(let error):
                removeHud()
                showAlert(title: "Error", msg: error.isResponseSerializationError ? "Something went wrong. Please try again later." : error.localizedDescription) {[weak self] in
                    guard let self = self else { return }
                    self.dismiss(animated: true)
                }
            }
        }
        
        textChangeToken = NotificationCenter.default.publisher(for: UISearchTextField.textDidChangeNotification, object: searchController.searchBar.searchTextField)
            .map({ ($0.object as! UISearchTextField).text ?? "" })
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink {[weak self] searchText in
                guard let self = self else { return }
                if searchText.isEmpty {
                    self.tracks = []
                    self.tableView.reloadData()
                } else {
                    Task {
                        let response = await NetworkHelper.request(url: SoundPath.searchTrack, method: .get, param: ["term": searchText], headers: ["Authorization": "Bearer \(self.accessToken)"], SoundSearchModel.self)
                        switch response.result {
                        case .success(let value):
                            self.tracks = value.tracks
                            self.tableView.reloadData()
                        case .failure(let error):
                            self.showAlert(title: "Error", msg: error.isResponseSerializationError ? "Something went wrong. Please try again later." : error.localizedDescription)
                        }
                    }
                }
            }
    }
    
    func setupTrack() {
        guard let selectedTrack = selectedTrack else { return }
        selectedTrackView.isHidden = false
        selectedTrackImageView.kf.setImage(with: URL(string: selectedTrack.images.imagesDefault))
        selectedTrackNameLabel.text = selectedTrack.title
    }
    
    func callCollectionAPI() async {
        guard canLoad else { return }
        canLoad = false
        let response = await NetworkHelper.request(url: SoundPath.getCollections, method: .get, param: ["offset": page*pageSize, "limit": pageSize], headers: ["Authorization": "Bearer \(accessToken)"], CollectionModel.self)
        self.removeHud()
        switch response.result {
        case .success(let value):
            self.collections.append(contentsOf: value.collections)
            canLoad = !value.collections.isEmpty
            self.collectionView.reloadData()
        case .failure(let error):
            canLoad = true
            self.showAlert(title: "Error", msg: error.isResponseSerializationError ? "Something went wrong. Please try again later." : error.localizedDescription)
        }
    }
    
    @objc func removeSelectedTapped(_ sender: UIButton) {
        delegate?.removeTrack()
        selectedTrackView.isHidden = true
        selectedTrack = nil
    }
}

extension SoundCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SoundCollectionCell.identifier, for: indexPath) as! SoundCollectionCell
        let collection = collections[indexPath.item]
        cell.collectionImageView.kf.setImage(with: URL(string: collection.images.imagesDefault))
        cell.collectionNameLabel.text = collection.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == collections.count-1 && canLoad {
            page += 1
            Task { await callCollectionAPI() }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = SoundListViewController(accessToken: accessToken, collectionId: collections[indexPath.item].id)
        controller.delegate = delegate
        controller.trackSelection = {[weak self] track in
            guard let self = self else { return }
            self.selectedTrack = track
            self.setupTrack()
        }
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func showSearch() {
        tableView.isHidden = false
        collectionView.isHidden = true
    }
    
    func hideSearch() {
        tableView.isHidden = true
        collectionView.isHidden = false
        tracks = []
        tableView.reloadData()
    }
}

extension SoundCollectionViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showSearch()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.endEditing(true)
//        searchBar.resignFirstResponder()
        hideSearch()
    }
}

extension SoundCollectionViewController: UISearchControllerDelegate {
    
    func didPresentSearchController(_ searchController: UISearchController) {
        showSearch()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        hideSearch()
    }
}
