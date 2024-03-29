//
//  AudioVisualizationView.swift
//  LeapVideoEditor
//
//  Created by bigstep on 29/10/22.
//

import Foundation

public class AudioVisualizationView: BaseNibView {
    public enum AudioVisualizationMode {
        case read
        case write
    }
    
    private enum LevelBarType {
        case upper
        case lower
        case single
    }
    
    @IBInspectable public var meteringLevelBarWidth: CGFloat = 3.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable public var meteringLevelBarInterItem: CGFloat = 2.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable public var meteringLevelBarCornerRadius: CGFloat = 2.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable public var meteringLevelBarSingleStick: Bool = true {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    public var audioVisualizationMode: AudioVisualizationMode = .read
    
    public var audioVisualizationTimeInterval: TimeInterval = 0.05 // Time interval between each metering bar representation
    // Specify a `gradientPercentage` to have the width of gradient be that percentage of the view width (starting from left)
    // The rest of the screen will be filled by `self.gradientStartColor` to display nicely.
    // Do not specify any `gradientPercentage` for gradient calculating fitting size automatically.
    public var currentGradientPercentage: Float?
    
    private var meteringLevelsArray: [Float] = []    // Mutating recording array (values are percentage: 0.0 to 1.0)
    private var meteringLevelsClusteredArray: [Float] = [] // Generated read mode array (values are percentage: 0.0 to 1.0)
    private var currentMeteringLevelsArray: [Float] {
        if !self.meteringLevelsClusteredArray.isEmpty {
            return meteringLevelsClusteredArray
        }
        return meteringLevelsArray
    }
    
    private var playChronometer: Chronometer?
    
    public var meteringLevels: [Float]? {
        didSet {
            if let meteringLevels = self.meteringLevels {
                self.meteringLevelsClusteredArray = meteringLevels
                self.currentGradientPercentage = 0.0
                _ = self.scaleSoundDataToFitScreen()
            }
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let context = UIGraphicsGetCurrentContext() {
            self.drawLevelBarsMaskAndGradient(inContext: context)
        }
    }
    
    public func reset() {
        self.meteringLevels = nil
        self.currentGradientPercentage = nil
        self.meteringLevelsClusteredArray.removeAll()
        self.meteringLevelsArray.removeAll()
        self.setNeedsDisplay()
    }
    
    // MARK: - Record Mode Handling
    public func add(meteringLevel: Float) {
        guard self.audioVisualizationMode == .write else {
            fatalError("trying to populate audio visualization view in read mode")
        }
        
        self.meteringLevelsArray.append(meteringLevel)
        self.setNeedsDisplay()
    }
    
    public func scaleSoundDataToFitScreen() -> [Float] {
        if self.meteringLevelsArray.isEmpty {
            return []
        }
        
        self.meteringLevelsClusteredArray.removeAll()
        var lastPosition: Int = 0
        
        for index in 0..<self.maximumNumberBars {
            let position: Float = Float(index) / Float(self.maximumNumberBars) * Float(self.meteringLevelsArray.count)
            var h: Float = 0.0
            
            if self.maximumNumberBars > self.meteringLevelsArray.count && floor(position) != position {
                let low: Int = Int(floor(position))
                let high: Int = Int(ceil(position))
                
                if high < self.meteringLevelsArray.count {
                    h = self.meteringLevelsArray[low] + ((position - Float(low)) * (self.meteringLevelsArray[high] - self.meteringLevelsArray[low]))
                } else {
                    h = self.meteringLevelsArray[low]
                }
            } else {
                for nestedIndex in lastPosition...Int(position) {
                    h += self.meteringLevelsArray[nestedIndex]
                }
                let stepsNumber = Int(1 + position - Float(lastPosition))
                h = h / Float(stepsNumber)
            }
            
            lastPosition = Int(position)
            self.meteringLevelsClusteredArray.append(h)
        }
        self.setNeedsDisplay()
        return self.meteringLevelsClusteredArray
    }
    
    // PRAGMA: - Play Mode Handling
    public func play(from url: URL) {
        guard self.audioVisualizationMode == .read else {
            fatalError("trying to read audio visualization in write mode")
        }
        
        AudioContext.load(fromAudioURL: url) { audioContext in
            guard let audioContext = audioContext else {
                fatalError("Couldn't create the audioContext")
            }
            self.meteringLevels = audioContext.render(targetSamples: 100)
            self.play(for: 2)
        }
    }
    
    public func play(for duration: TimeInterval) {
        guard self.audioVisualizationMode == .read else {
            fatalError("trying to read audio visualization in write mode")
        }
        
        guard self.meteringLevels != nil else {
            fatalError("trying to read audio visualization of non initialized sound record")
        }
        
        if let currentChronometer = self.playChronometer {
            currentChronometer.start() // resume current
            return
        }
        
        self.playChronometer = Chronometer(withTimeInterval: self.audioVisualizationTimeInterval)
        self.playChronometer?.start(shouldFire: false)
        
        self.playChronometer?.timerDidUpdate = { [weak self] timerDuration in
            guard let this = self else {
                return
            }
            
            if timerDuration >= duration {
                this.stopWave()
                return
            }
            
            this.currentGradientPercentage = Float(timerDuration) / Float(duration)
            this.setNeedsDisplay()
        }
    }
    
    public func pause() {
        guard let chronometer = self.playChronometer, chronometer.isPlaying else {
            fatalError("trying to pause audio visualization view when not playing")
        }
        self.playChronometer?.pause()
    }
    
    public func stopWave() {
        self.playChronometer?.stop()
        self.playChronometer = nil
        
        self.currentGradientPercentage = 1.0
        self.setNeedsDisplay()
        self.currentGradientPercentage = nil
    }
    
    // MARK: - Mask + Gradient
    private func drawLevelBarsMaskAndGradient(inContext context: CGContext) {
        if self.currentMeteringLevelsArray.isEmpty {
            return
        }
        
        context.saveGState()
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        let maskContext = UIGraphicsGetCurrentContext()
        UIColor.black.set()
        
        self.drawMeteringLevelBars(inContext: maskContext!)
        
        let mask = UIGraphicsGetCurrentContext()?.makeImage()
        UIGraphicsEndImageContext()
        context.clip(to: self.bounds, mask: mask!)
        context.draw(mask!, in: self.bounds)
        
        context.restoreGState()
    }
    
    // MARK: - Bars
    private func drawMeteringLevelBars(inContext context: CGContext) {
        let offset = max(self.currentMeteringLevelsArray.count - self.maximumNumberBars, 0)
        
        for index in offset..<self.currentMeteringLevelsArray.count {
            if self.meteringLevelBarSingleStick {
                self.drawBar(index - offset, meteringLevelIndex: index, levelBarType: .single, context: context)
            } else {
                self.drawBar(index - offset, meteringLevelIndex: index, levelBarType: .upper, context: context)
                self.drawBar(index - offset, meteringLevelIndex: index, levelBarType: .lower, context: context)
            }
        }
    }
    
    private func drawBar(_ barIndex: Int, meteringLevelIndex: Int, levelBarType: LevelBarType, context: CGContext) {
        context.saveGState()
        
        var barRect: CGRect
        
        let xPointForMeteringLevel = self.xPointForMeteringLevel(barIndex)
        let heightForMeteringLevel = self.heightForMeteringLevel(self.currentMeteringLevelsArray[meteringLevelIndex])
        
        switch levelBarType {
        case .upper:
            barRect = CGRect(x: xPointForMeteringLevel,
                             y: self.centerY - heightForMeteringLevel,
                             width: self.meteringLevelBarWidth,
                             height: heightForMeteringLevel)
        case .lower:
            barRect = CGRect(x: xPointForMeteringLevel,
                             y: self.centerY,
                             width: self.meteringLevelBarWidth,
                             height: heightForMeteringLevel)
        case .single:
            let height = max(heightForMeteringLevel * 2, 3)
            barRect = CGRect(x: xPointForMeteringLevel,
                             y: 0,
                             width: self.meteringLevelBarWidth,
                             height: height)
        }
        let barPath = UIBezierPath(roundedRect: barRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: meteringLevelBarCornerRadius, height: meteringLevelBarCornerRadius))
        
        UIColor.black.set()
        barPath.fill()
        
        context.restoreGState()
    }
    
    // MARK: - Points Helpers
    private var centerY: CGFloat {
        return self.frame.size.height / 2.0
    }
    
    private var maximumBarHeight: CGFloat {
        return self.frame.size.height / 2.0
    }
    
    private var maximumNumberBars: Int {
        return Int(self.frame.size.width / (self.meteringLevelBarWidth + self.meteringLevelBarInterItem))
    }
    
    private func xLeftMostBar() -> CGFloat {
        return self.xPointForMeteringLevel(min(self.maximumNumberBars - 1, self.currentMeteringLevelsArray.count - 1))
    }
    
    private func heightForMeteringLevel(_ meteringLevel: Float) -> CGFloat {
        return CGFloat(meteringLevel) * self.maximumBarHeight
    }
    
    private func xPointForMeteringLevel(_ atIndex: Int) -> CGFloat {
        return CGFloat(atIndex) * (self.meteringLevelBarWidth + self.meteringLevelBarInterItem)
    }
}
