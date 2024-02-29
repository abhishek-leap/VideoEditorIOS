//
//  GiphyStickersManager.swift
//  LeapVideoEditor
//
//  Created by bigstep on 31/08/22.
//

import Foundation
import GiphyUISDK

public protocol StickersDelegate {
    
    /// Notifies the delegate that the selected sticker has been cached and ready to use
    /// - Parameters:
    ///   - image: image of selected sticker
    func didSelectSticker(_ gifData: Data)
}

final class GiphyStickersManager {
    private let giphyKey = "Jcvyks88J7LATW5T24fv40lAgcWBlAAZ"
    static let shared = GiphyStickersManager()
    public var stickerDelegate: StickersDelegate?
    
    private init() {
        Giphy.configure(apiKey: giphyKey)
    }
    
    // MARK: launch giphy stickers
    
    func launchStickers(_ controller: UIViewController) {
        let stickersController = GiphyViewController()
        stickersController.stickerColumnCount = .four
        stickersController.delegate = self
        stickersController.mediaTypeConfig = [.stickers, .emoji, .recents]
        controller.present(stickersController, animated: true, completion: nil)
    }
}

// MARK: giphy delegates

extension GiphyStickersManager: GiphyDelegate {
    func didDismiss(controller: GiphyViewController?) {}
    
    func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
        giphyViewController.dismiss(animated: true) {
            let url = media.url(rendition: giphyViewController.renditionType, fileType: .gif) ?? ""
            GPHCache.shared.downloadAssetData(url) {[weak self] (giphyData, error) in
                DispatchQueue.main.async {
                    guard let giphyData = giphyData else { return }
                    guard let self = self else { return }
                    self.stickerDelegate?.didSelectSticker(giphyData)
                }
            }
        }
    }
}

