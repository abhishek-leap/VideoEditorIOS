//
//  LeapVideoEditor + Voice Over.swift
//  LeapVideoEditor
//
//  Created by bigstep on 28/10/22.
//

import Foundation
import AVFoundation
import UIKit

import GiphyUISDK

// MARK: Voice Over Implementation

extension LeapVideoEditorViewController {
    
    // MARK: voice recording button action
    
    @objc func voiceRecordingAction() {
        isVoiceRecording = !isVoiceRecording
        recordAudio()
        let image = isVoiceRecording ? "VoiceWave" : "micIcon"
        micView.setImage(UIImage(named: image, in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
    }
    
    // MARK: start recording audio
    
    func recordAudio() {
        if !isVoiceRecording {
            do {
                try self.recorderService.stopRecording()
                micView.isHidden = true
                playButton.isHidden = false
            } catch {
                print(error.localizedDescription)
            }
        } else {
            self.recorderService.startRecording {[weak self] soundRecord, error in
                guard let self = self else { return }
                guard let url = soundRecord?.audioFilePathLocal else { return }
                DispatchQueue.main.async {
                    let timelineItem = LeapTimelineItem(itemData: url, thumbnail: GiphyYYImage(), type: .record, startPosition: 0)
                    self.timelineItems.append(timelineItem)
                    let wrapperView = self.timeLineView.insertItem(timelineItem: timelineItem)
                    if let liveWaveformView = wrapperView.timelineItemView.subviews.first(where: { $0 is AudioVisualizationView }) as? AudioVisualizationView {
                        self.setupAudioVisuals(liveWaveformView, wrapperView: wrapperView)
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        guard isVoiceRecording else { return }
        do {
            try self.recorderService.stopRecording()
            micView.isHidden = true
            playButton.isHidden = false
        } catch {
            print(error.localizedDescription)
        }
        isVoiceRecording = false
        micView.setImage(UIImage(named: "micIcon", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil), for: .normal)
    }
    
    func setupAudioVisuals(_ waveformView: AudioVisualizationView, wrapperView: LeapTimelineWrapperView) {
        self.recorderService.askAudioRecordingPermission()
        self.recorderService.audioMeteringLevelUpdate = { meteringLevel in
            wrapperView.updateAudioSize(waveformView: waveformView)
            if wrapperView.timelineItem.size > CMTimeGetSeconds(self.player.currentItem?.duration ?? .zero) {
                self.stopRecording()
            }
            waveformView.add(meteringLevel: meteringLevel)
        }
        self.recorderService.audioDidFinish = {[weak self] in
            guard let self = self else { return }
            waveformView.stopWave()
            let item = self.timelineItems.removeLast()
            let newItem = LeapTimelineItem(itemData: item.itemData, thumbnail: GiphyYYImage(), type: .audio, startPosition: item.startPosition, size: item.size)
            wrapperView.removeFromSuperview()
            self.timeLineView.effectsScrollView.contentSize.height -= 39
            self.timelineItems.append(newItem)
            self.timeLineView.insertItem(timelineItem: newItem)
            self.setupVideo()
        }
    }
}









