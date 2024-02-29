//
//  VideoFiltersController.swift
//  LeapVideoEditor
//
//  Created by bigstep on 20/10/22.
//

import Foundation

// MARK: VideoFilter Protocols

protocol VideoFilterProtocol: AnyObject {
    func didSelectFilter(_ filter: VideoFilterModel)
}

class VideoFiltersController: BaseViewController {
    
    private lazy var filters = [VideoFilterModel]()
    weak var delegate: VideoFilterProtocol?
    var videoThumbnail: UIImage
    
    // MARK: UI Elements:
    
    private let filtersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    private let topBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray
        view.layer.cornerRadius = 5
        return view
    }()
    
    // MARK: Initializer
    
    init(videoThumbnail: UIImage) {
        self.videoThumbnail = videoThumbnail
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        setTopBar()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        setupCollectionView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let ciImage = CIImage(image: videoThumbnail) else { return}
        self.filters = [
            VideoFilterModel(filter: nil, filterName: "", thumbnail: videoThumbnail, filterLabel: "Original"),
            VideoFilterModel(filter: CIFilter.comicEffect(inputImage: ciImage), filterName: "CIComicEffect", thumbnail: videoThumbnail, filterLabel: "Comic"),
            VideoFilterModel(filter: CIFilter.photoEffectFade(inputImage: ciImage), filterName: "CIPhotoEffectFade", thumbnail: videoThumbnail, filterLabel: "Fade"),
            VideoFilterModel(filter: CIFilter.photoEffectMono(inputImage: ciImage), filterName: "CIPhotoEffectMono", thumbnail: videoThumbnail, filterLabel: "Mono"),
            VideoFilterModel(filter: CIFilter.photoEffectNoir(inputImage: ciImage), filterName: "CIPhotoEffectNoir", thumbnail: videoThumbnail, filterLabel: "Noir"),
            VideoFilterModel(filter: CIFilter.sepiaTone(inputImage: ciImage), filterName: "CISepiaTone", thumbnail: videoThumbnail, filterLabel: "Sepia"),
            VideoFilterModel(filter: CIFilter.affineClamp(inputImage: ciImage), filterName: "CIAffineClamp", thumbnail: videoThumbnail, filterLabel: "Clamp"),
            VideoFilterModel(filter: CIFilter.bloom(inputImage: ciImage), filterName: "CIBloom", thumbnail: videoThumbnail, filterLabel: "Bloom"),
            VideoFilterModel(filter: CIFilter.bokehBlur(inputImage: ciImage), filterName: "CIBokehBlur", thumbnail: videoThumbnail, filterLabel: "Blur"),
            VideoFilterModel(filter: CIFilter.clamp(inputImage: ciImage), filterName: "CIClamp", thumbnail: videoThumbnail, filterLabel: "Clamp"),
            VideoFilterModel(filter: CIFilter.discBlur(inputImage: ciImage), filterName: "CIDiscBlur", thumbnail: videoThumbnail, filterLabel: "Disc Blur"),
            VideoFilterModel(filter: CIFilter.gaussianBlur(inputImage: ciImage), filterName: "CIGaussianBlur", thumbnail: videoThumbnail, filterLabel: "Gaussian Blur"),
            VideoFilterModel(filter: CIFilter.gloom(inputImage: ciImage), filterName: "CIGloom", thumbnail: videoThumbnail, filterLabel: "Gloom"),
            VideoFilterModel(filter: CIFilter.photoEffectTransfer(inputImage: ciImage), filterName: "CIPhotoEffectTransfer", thumbnail: videoThumbnail, filterLabel: "Transfer")
        ]
    }
}

// MARK: setup collection view

extension VideoFiltersController {
    
    // MARK: adding collection view in view controller
    
    private func setupCollectionView() {
        view.addSubview(filtersCollectionView)
        filtersCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        filtersCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        filtersCollectionView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 5).isActive = true
        filtersCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        filtersCollectionView.register(VideoFiltersCell.self, forCellWithReuseIdentifier: VideoFiltersCell.cellIdentifier)
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
    }
}

// MARK: setup topBar View

extension VideoFiltersController {
    
    // MARK: setup topBar view
    
    private func setTopBar() {
        view.addSubview(topBar)
        topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        topBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
        topBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        topBar.heightAnchor.constraint(equalToConstant: 10).isActive = true
    }
}

// MARK: collection view delegates

extension VideoFiltersController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoFiltersCell.cellIdentifier, for: indexPath) as? VideoFiltersCell else { fatalError("could not find cell")}
        cell.filter = filters[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - 30)/3, height: (collectionView.bounds.width - 30)/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.dismiss(animated: true) { [unowned self] in
            let filter = self.filters[indexPath.row]
            self.delegate?.didSelectFilter(filter)
        }
        
    }
}
