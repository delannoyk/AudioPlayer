//
//  AudioPlayer+QualityAdjustmentEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 03/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import AVFoundation

extension AudioPlayer {
    func handleQualityEvent(event: QualityAdjustmentEventProducer.QualityAdjustmentEvent) {
        //Early exit if user doesn't want to adjust quality
        guard adjustQualityAutomatically else {
            return
        }

        switch event {
        case .GoDown:
            guard let quality = AudioQuality(rawValue: currentQuality.rawValue - 1) else {
                return
            }
            handleQualityChange(quality)

        case .GoUp:
            guard let quality = AudioQuality(rawValue: currentQuality.rawValue + 1) else {
                return
            }
            handleQualityChange(quality)
        }
    }

    private func handleQualityChange(newQuality: AudioQuality) {
        guard let URL = currentItem?.soundURLs[newQuality] else {
            return
        }

        let cip = currentItemProgression
        let item = AVPlayerItem(URL: URL)

        qualityIsBeingChanged = true
        player?.replaceCurrentItemWithPlayerItem(item)
        if let cip = cip {
            seekToTime(cip)
        }
        qualityIsBeingChanged = false

        currentQuality = newQuality
    }
}
