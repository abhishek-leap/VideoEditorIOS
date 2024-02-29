//
//  Extensions.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 01/09/22.
//

import UIKit
import AVFoundation
import MBProgressHUD

extension UINavigationController {
    
    func setupDefaultStyle() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "navigationBackground", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
            appearance.titleTextAttributes[.foregroundColor] = UIColor.white
            appearance.largeTitleTextAttributes[.foregroundColor] = UIColor.white
            navigationBar.standardAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.backgroundColor = UIColor(named: "navigationBackground", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
        }
        navigationBar.tintColor = .white
    }
}

extension UIImage {
    static func gradientImage(with bounds: CGRect,
                              colors: [CGColor],
                              locations: [NSNumber]?) -> UIImage? {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        // This makes it horizontal
        gradientLayer.startPoint = CGPoint(x: 0.0,
                                           y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0,
                                         y: 0.5)
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return image
    }
    
    class func imageWithLabel(view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func addFilter(filter : VideoFilterModel) -> UIImage {
        let filter = CIFilter(name: filter.filterName)
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        //Return the image
        return UIImage(cgImage: cgImage!)
    }
    
    func setImageColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        let rect = CGRect(origin: CGPoint.zero, size: size)
        color.setFill()
        self.draw(in: rect)
        context.setBlendMode(.sourceIn)
        context.fill(rect)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }
    
    /// Method to scale an image to the given size while keeping the aspect ratio
    ///
    /// - Parameter newSize: the new size for the image
    /// - Returns: the resized image
    func scaleImageToSize(newSize: CGSize) -> UIImage? {
        
        var scaledImageRect: CGRect = CGRect.zero
        
        let aspectWidth: CGFloat = newSize.width / size.width
        let aspectHeight: CGFloat = newSize.height / size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if UIGraphicsGetCurrentContext() != nil {
            draw(in: scaledImageRect)
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return scaledImage
        }
        
        return nil
    }
    
    /// Method to get a size for the image appropriate for video (dividing by 16 without overlapping 1200)
    ///
    /// - Returns: a size fit for video
    func getSizeForVideo() -> CGSize {
        let scale = UIScreen.main.scale
        var imageWidth = 16 * ((size.width / scale) / 16).rounded(.awayFromZero)
        var imageHeight = 16 * ((size.height / scale) / 16).rounded(.awayFromZero)
        var ratio: CGFloat!
        
        if imageWidth > 1400 {
            ratio = 1400 / imageWidth
            imageWidth = 16 * (imageWidth / 16).rounded(.towardZero) * ratio
            imageHeight = 16 * (imageHeight / 16).rounded(.towardZero) * ratio
        }
        
        if imageWidth < 800 {
            ratio = 800 / imageWidth
            imageWidth = 16 * (imageWidth / 16).rounded(.awayFromZero) * ratio
            imageHeight = 16 * (imageHeight / 16).rounded(.awayFromZero) * ratio
        }
        
        if imageHeight > 1200 {
            ratio = 1200 / imageHeight
            imageWidth = 16 * (imageWidth / 16).rounded(.towardZero) * ratio
            imageHeight = 16 * (imageHeight / 16).rounded(.towardZero) * ratio
        }
        
        return CGSize(width: imageWidth, height: imageHeight)
    }
    
    
    /// Method to resize an image to an appropriate video size
    ///
    /// - Returns: the resized image
    func resizeImageToVideoSize() -> UIImage? {
        let scale = UIScreen.main.scale
        let videoImageSize = getSizeForVideo()
        let imageRect = CGRect(x: 0, y: 0, width: videoImageSize.width * scale, height: videoImageSize.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageRect.width, height: imageRect.height), false, scale)
        if let _ = UIGraphicsGetCurrentContext() {
            draw(in: imageRect, blendMode: .normal, alpha: 1)
            
            if let resultImage = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                return resultImage
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

extension UIViewController {
    
    func showHud() { MBProgressHUD.showAdded(to: view, animated: true) }
    
    func removeHud() { MBProgressHUD.hide(for: view, animated: true) }
    
    func showAlert(title: String = "", msg: String, buttonTitle: String = "Okay", _ completion : (() -> Void)? = nil) {
        let alertViewController = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) { _ in
            completion?()
        }
        alertViewController.addAction(okAction)
        present(alertViewController, animated: true, completion: nil)
    }
    
    func showActionsheet(title: String, message: String, actions: [(String, UIAlertAction.Style)], completion: @escaping (_ index: Int) -> Void) {
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for (index, (title, style)) in actions.enumerated() {
            let alertAction = UIAlertAction(title: title, style: style) { (_) in
                completion(index)
            }
            alertAction.setValue(UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!, forKey: "titleTextColor")
            alertViewController.addAction(alertAction)
        }
        // iPad Support
        alertViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    /// Display message in prompt view
    ///
    /// — Parameters:
    /// — title: Title to display Alert
    /// — message: Pass string of content message
    /// — options: Pass multiple UIAlertAction title like “OK”,”Cancel” etc
    /// — completion: The block to execute after the presentation finishes.
    func presentAlertWithTitleAndMessage(title: String, message: String, actions: [(String, UIAlertAction.Style)], completion: @escaping (Int) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for (index, (title, style)) in actions.enumerated() {
            let alertAction = UIAlertAction.init(title: title, style: style) { _ in
                completion(index)
            }
            alertAction.setValue(UIColor(named: "gradient-2", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)!, forKey: "titleTextColor")
            alertController.addAction(alertAction)
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    func transparentNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        extendedLayoutIncludesOpaqueBars = true
    }
}

extension CGPoint {
    static func +(lhs: Self, rhs: Self?) -> CGPoint {
        guard let right = rhs else {
            return lhs
        }
        return .init(x: lhs.x + right.x, y: lhs.y + right.y)
    }
}

extension UIView {
    
    var originalFrame: CGRect {
        let currentTransform = transform
        transform = .identity
        let originalFrame = frame
        transform = currentTransform
        return originalFrame
    }
    
    func createSnapshot(boundsToUse: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: boundsToUse.size)
        let image = renderer.image { ctx in
            ctx.cgContext.translateBy(x: 12, y: 0)
            layer.render(in: ctx.cgContext)
        }
        return image
    }
}

extension String {
    
    // MARK: to convert hex color code to UIColor
    
    func hexStringToUIColor () -> UIColor {
        var cString:String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UITextView {
    
    // MARK: to vertically center the textview cursor
    
    func centerVertically() {
        let fittingSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
    // MARK: Apply neon text effect to the text of textview
    /// - Parameters:
    ///   - startColor: start color of the gradient
    ///   - endColor: End color of the gradient.
    func applyGradientWith(startColor: UIColor, endColor: UIColor) {
        
        var startColorRed:CGFloat = 0
        var startColorGreen:CGFloat = 0
        var startColorBlue:CGFloat = 0
        var startAlpha:CGFloat = 0
        
        if !startColor.getRed(&startColorRed, green: &startColorGreen, blue: &startColorBlue, alpha: &startAlpha) {
            return
        }
        
        let endColorRed:CGFloat = 0
        let endColorGreen:CGFloat = 0
        let endColorBlue:CGFloat = 0
        let endAlpha:CGFloat = 0
        
        let gradientText = self.text ?? ""
        
        let textSize: CGSize = gradientText.size(withAttributes: [NSAttributedString.Key.font : self.font ?? .systemFont(ofSize: 50)])
        let width:CGFloat = textSize.width
        let height:CGFloat = textSize.height
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }
        
        UIGraphicsPushContext(context)
        
        let glossGradient:CGGradient?
        let rgbColorspace:CGColorSpace?
        let num_locations:size_t = 2
        let locations:[CGFloat] = [ 0.0, 1.0 ]
        let components:[CGFloat] = [startColorRed, startColorGreen, startColorBlue, startAlpha, endColorRed, endColorGreen, endColorBlue, endAlpha]
        rgbColorspace = CGColorSpaceCreateDeviceRGB()
        glossGradient = CGGradient(colorSpace: rgbColorspace!, colorComponents: components, locations: locations, count: num_locations)
        let topCenter = CGPoint.zero
        let bottomCenter = CGPoint(x: 0, y: textSize.height)
        context.drawLinearGradient(glossGradient!, start: topCenter, end: bottomCenter, options: CGGradientDrawingOptions.drawsBeforeStartLocation)
        
        UIGraphicsPopContext()
        guard let gradientImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()
        self.textColor = UIColor(patternImage: gradientImage)
    }
}


extension UIView {
    enum GlowEffect: Float {
        case small = 0.4, normal = 2, big = 15
    }
    
    func doGlowAnimation(withColor color: UIColor, withEffect effect: GlowEffect = .normal) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowRadius = .zero
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        
        let glowAnimation = CABasicAnimation(keyPath: "shadowRadius")
        glowAnimation.fromValue = Int.zero
        glowAnimation.toValue = effect.rawValue
        glowAnimation.beginTime = CACurrentMediaTime()+0.3
        glowAnimation.duration = CFTimeInterval(0.3)
        glowAnimation.fillMode = .forwards
        glowAnimation.autoreverses = false
        glowAnimation.isRemovedOnCompletion = false
        layer.add(glowAnimation, forKey: "shadowGlowingAnimation")
    }
    
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
}

extension AVAsset {
    
    func videoOrientation() -> (orientation: UIInterfaceOrientation, device: AVCaptureDevice.Position) {
        var orientation: UIInterfaceOrientation = .unknown
        var device: AVCaptureDevice.Position = .unspecified
        
        let tracks: [AVAssetTrack] = self.tracks(withMediaType: .video)
        if let videoTrack = tracks.first {
            
            let t = videoTrack.preferredTransform
            
            if (t.a == 0 && t.b == 1.0 && t.d == 0) {
                orientation = .portrait
                
                if t.c == 1.0 {
                    device = .front
                } else if t.c == -1.0 {
                    device = .back
                }
            }
            else if (t.a == 0 && t.b == -1.0 && t.d == 0) {
                orientation = .portraitUpsideDown
                
                if t.c == -1.0 {
                    device = .front
                } else if t.c == 1.0 {
                    device = .back
                }
            }
            else if (t.a == 1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeRight
                
                if t.d == -1.0 {
                    device = .front
                } else if t.d == 1.0 {
                    device = .back
                }
            }
            else if (t.a == -1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeLeft
                
                if t.d == 1.0 {
                    device = .front
                } else if t.d == -1.0 {
                    device = .back
                }
            }
        }
        
        return (orientation, device)
    }
    
    func writeAudioTrackToURL(URL: URL, completion: @escaping (Bool, Error?) -> ()) {
        do {
            let audioAsset = try self.audioAsset()
            audioAsset.writeToURL(URL: URL, completion: completion)
            
        } catch {
            completion(false, error)
        }
    }
    
    func writeToURL(URL: URL, completion: @escaping (Bool, Error?) -> ()) {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, nil)
            return
        }
        
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL      = URL as URL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                completion(false, nil)
            @unknown default:
                completion(false, nil)
            }
        }
    }
    
    func audioAsset() throws -> AVAsset {
        let composition = AVMutableComposition()
        let audioTracks = tracks(withMediaType: AVMediaType.audio)
        for track in audioTracks {
            
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        return composition
    }
}

extension Double {
    
    func getTimeString() -> String {
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
}

extension Data {
    
    static func getTotalVideoSize(_ dataArray: [Data]) -> String {
        var totalData: Int64 = 0
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
        bcf.countStyle = .file
        for data in dataArray {
            totalData += Int64(data.count)
        }
        let string = bcf.string(fromByteCount: totalData)
        return string
    }
    
    func saveTempData(filePath: URL, completion: @escaping ((_ filePath: URL)->Void)){
        DispatchQueue.global(qos: .background).async {
            do {
                try self.write(to: filePath, options: .atomic)
                DispatchQueue.main.async {
                    completion(filePath)
                }
            } catch {
                print("an error happened while downloading or saving the file")
            }
        }
    }
}

extension URL {
    
    func getThumbnailImage() -> UIImage? {
        let asset: AVAsset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }
        
        return nil
    }
    
    static func checkPath(_ path: String) -> Bool {
        let isFileExist = FileManager.default.fileExists(atPath: path)
        return isFileExist
    }
}
