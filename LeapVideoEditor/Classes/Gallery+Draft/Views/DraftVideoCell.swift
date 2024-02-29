//
//  DraftVideoCell.swift
//  LeapVideoEditor
//
//  Created by bigstep on 10/10/22.
//

import Foundation

// MARK: Draft Video Cell

class DraftVideoCell: UITableViewCell {
    var video: DraftVideoModel? {
        didSet {
            guard let videoData = video?.videoItems.first else { return}
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let videoURL = documentURL.appendingPathComponent("video.mp4")
            do {
                try videoData.videoData.write(to: videoURL, options: .atomic)
            }
            catch {
                print(error.localizedDescription)
            }
            videoThumbnail.image = videoURL.getThumbnailImage()
            videoSize.text = Data.getTotalVideoSize(video?.videoItems.map({ $0.videoData }) ?? [])
            videoIdLabel.text = UUID().uuidString
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyy.MM.dd HH:mm"
            timeStampLabel.text = "Last Update: " + dateFormatterGet.string(from: video?.videoDate ?? Date())
            self.videoDurationLabel.text = video?.totalVideoDuration.getTimeString() ?? ""
        }
    }
 
    static let reuseIdentifier = "draftCell"
    
    // MARK: UI Elements:
    
    private lazy var videoThumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .gray
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var videoIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = .black
        label.text = "ID: 227000-002"
        return label
    }()
    
    private lazy var timeStampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.text = "Last Update: 2022 09:22 15:34"
        return label
    }()
    
    private lazy var videoSize: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.text = "9 MB"
        return label
    }()
    
    private lazy var videoDurationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.text = "00:43"
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    private func setupView() {
        addSubview(videoThumbnail)
        videoThumbnail.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        videoThumbnail.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        videoThumbnail.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.97).isActive = true
        videoThumbnail.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.97).isActive = true
        
        addSubview(videoIdLabel)
        videoIdLabel.leftAnchor.constraint(equalTo: videoThumbnail.rightAnchor, constant: 10).isActive = true
        videoIdLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        videoIdLabel.topAnchor.constraint(equalTo: videoThumbnail.topAnchor, constant: 20).isActive = true
        
        addSubview(timeStampLabel)
        timeStampLabel.leftAnchor.constraint(equalTo: videoThumbnail.rightAnchor, constant: 10).isActive = true
        timeStampLabel.topAnchor.constraint(equalTo: videoIdLabel.bottomAnchor, constant: 10).isActive = true
        
        addSubview(videoSize)
        videoSize.leftAnchor.constraint(equalTo: videoThumbnail.rightAnchor, constant: 10).isActive = true
        videoSize.topAnchor.constraint(equalTo: timeStampLabel.bottomAnchor, constant: 7).isActive = true
        
        addSubview(videoDurationLabel)
        videoDurationLabel.leftAnchor.constraint(equalTo: videoThumbnail.rightAnchor, constant: 10).isActive = true
        videoDurationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
    }
 
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
