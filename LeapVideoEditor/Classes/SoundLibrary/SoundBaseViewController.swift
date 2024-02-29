//
//  SoundBaseViewController.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 12/10/22.
//

import UIKit
import MBProgressHUD
import Alamofire
import AVFoundation

class SoundBaseViewController: BaseViewController {
    
    var accessToken = ""
    weak var delegate: SoundControllerDelegate?
    var trackSelection: ((Track) -> Void)?
    var tracks = [Track]()
    private var selectedTrack: Track?
    var audioPlayer: AVAudioPlayer?
    let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        return formatter
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SoundTableViewCell.self, forCellReuseIdentifier: SoundTableViewCell.identifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func doneTapped(_ sender: UIBarButtonItem) {
        guard let selectedTrack = selectedTrack else { return }
        Task {
            stopPlayer()
            if let url = selectedTrack.soundURL {
                self.dismiss(animated: true) {
                    self.delegate?.audioSelected(audioURL: url, track: selectedTrack)
                }
            } else {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.label.text = "Downloading"
                let result = await getSoundURL(track: selectedTrack)
                hud.hide(animated: true)
                switch result {
                case .success(let url):
                    self.dismiss(animated: true) {
                        self.delegate?.audioSelected(audioURL: url, track: selectedTrack)
                    }
                case .failure(let error):
                    hud.hide(animated: true)
                    self.showAlert(title: "Error", msg: error.isResponseSerializationError ? "Something went wrong. Please try again later." : error.localizedDescription)
                }
            }
        }
    }
    
    func getSoundURL(track: Track) async -> Result<URL, AFError> {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("sounds/\(track.id).mp3")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            track.soundURL = fileURL
            track.state = 3
            return .success(fileURL)
        }
        track.state = 1
        let response = await NetworkHelper.request(url: "\(SoundPath.tracks)\(track.id)/download", method: .get, headers: ["Authorization": "Bearer \(accessToken)"], TrackURLModel.self)
        switch response.result {
        case .success(let value):
            let destination: DownloadRequest.Destination = { _, _ in
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            let downloadTask = AF.download(value.url, to: destination).serializingDownloadedFileURL()
            switch await downloadTask.result {
            case .success(let url):
                track.state = 3
                track.soundURL = url
                return .success(url)
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            track.state = 2
            return .failure(error)
        }
    }
    
    func play(url: URL) {
        if let selectedTrack = selectedTrack {
            selectedTrack.state = 4
        }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
    
    func stopPlayer() {
        if let selectedTrack = selectedTrack {
            selectedTrack.state = 3
        }
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.stop()
        self.audioPlayer = nil
    }
}

extension SoundBaseViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SoundTableViewCell.identifier, for: indexPath) as! SoundTableViewCell
        let track = tracks[indexPath.row]
        cell.soundImageView.kf.setImage(with: URL(string: track.images.imagesDefault))
        cell.soundNameLabel.text = track.title
        cell.artistNameLabel.text = track.mainArtists.reduce("", { $0.isEmpty ? $1 : "\($0) & \($1)" })
        cell.timeLabel.text = formatter.string(from: track.length)
        cell.playButton.setTitle(nil, for: .normal)
        cell.playButton.setImage(nil, for: .normal)
        if let selectedTrack = selectedTrack, selectedTrack.id == track.id {
            cell.selectionImageView.isHidden = false
            switch track.state {
            case 1:
                cell.playButton.setTitle("Loading", for: .normal)
            case 2:
                cell.playButton.setTitle("Error", for: .normal)
            case 4:
                cell.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            default:
                cell.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        } else {
            cell.selectionImageView.isHidden = true
            cell.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let track = tracks[indexPath.row]
        stopPlayer()
        if let selectedTrack = selectedTrack, let index = tracks.firstIndex(where: { $0.id == selectedTrack.id }), let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SoundTableViewCell {
            cell.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            cell.playButton.setTitle(nil, for: .normal)
            cell.selectionImageView.isHidden = true
        }
        if let selectedTrack = selectedTrack, selectedTrack.id == track.id {
            self.selectedTrack = nil
        } else {
            self.selectedTrack = track
            if let url = track.soundURL {
                play(url: url)
                if let cell = tableView.cellForRow(at: indexPath) as? SoundTableViewCell {
                    cell.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    cell.playButton.setTitle(nil, for: .normal)
                    cell.selectionImageView.isHidden = false
                }
            } else {
                if let cell = tableView.cellForRow(at: indexPath) as? SoundTableViewCell {
                    cell.playButton.setImage(nil, for: .normal)
                    cell.playButton.setTitle("Loading", for: .normal)
                    cell.selectionImageView.isHidden = false
                }
                if track.state != 1 {
                    Task {
                        let result = await getSoundURL(track: track)
                        if track.id == selectedTrack?.id, let cell = tableView.cellForRow(at: indexPath) as? SoundTableViewCell {
                            switch result {
                            case .success(let url):
                                play(url: url)
                                cell.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                                cell.playButton.setTitle(nil, for: .normal)
                            case .failure:
                                cell.playButton.setTitle("Error", for: .normal)
                                showAlert(title: "Error", msg: "Unable to play sound.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        92
    }
}
