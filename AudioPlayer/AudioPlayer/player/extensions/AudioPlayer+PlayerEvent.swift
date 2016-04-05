//
//  AudioPlayer+PlayerEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 03/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

extension AudioPlayer {
    func handlePlayerEvent(event: PlayerEventProducer.PlayerEvent) {
        switch event {
        case .EndedPlaying(let error):
            if let error = error {
                state = .Failed(error)
                nextOrStop()
            } else {
                nextOrStop()
            }

        case .InterruptionBegan:
            if state == .Playing || state == .Buffering {
                //We pause the player when an interruption is detected
                backgroundHandler.beginBackgroundTask()
                pausedForInterruption = true
                pause()
            }

        case .InterruptionEnded:
            if pausedForInterruption {
                if resumeAfterInterruption {
                    resume()
                }
                pausedForInterruption = false
                backgroundHandler.endBackgroundTask()
            }

        case .LoadedDuration(let time):
            if let currentItem = currentItem, time = time.ap_timeIntervalValue {
                updateNowPlayingInfoCenter()
                delegate?.audioPlayer(self,
                                      didFindDuration: time,
                                      forItem: currentItem)
            }

        case .LoadedMetadata(let metadata):
            if let currentItem = currentItem where metadata.count > 0 {
                currentItem.parseMetadata(metadata)
                delegate?.audioPlayer(self, didUpdateEmptyMetadataOnItem: currentItem, withData: metadata)
            }

        case .LoadedMoreRange:
            if let currentItem = currentItem, currentItemLoadedRange = currentItemLoadedRange {
                delegate?.audioPlayer(self,
                                      didLoadRange: currentItemLoadedRange,
                                      forItem: currentItem)
            }

        case .Progressed(let time):
            if let currentItemProgression = time.ap_timeIntervalValue,
                currentItemDuration = currentItemDuration where currentItemDuration > 0 {
                //This fixes the behavior where sometimes the `playbackLikelyToKeepUp` isn't
                //changed even though it's playing (happens mostly at the first play though).
                if state == .Buffering || state == .Paused {
                    if shouldResumePlaying {
                        stateBeforeBuffering = nil
                        state = .Playing
                        player?.rate = rate
                    } else {
                        state = .Paused
                    }
                    backgroundHandler.endBackgroundTask()
                }

                //Then we can call the didUpdateProgressionToTime: delegate method
                let percentage = Float(currentItemProgression / currentItemDuration) * 100
                delegate?.audioPlayer(self, didUpdateProgressionToTime: currentItemProgression,
                                      percentageRead: percentage)
            }

        case .ReadyToPlay:
            //There is enough data in the buffer
            if shouldResumePlaying {
                stateBeforeBuffering = nil
                state = .Playing
                player?.rate = rate
            } else {
                state = .Paused
            }

            retryCount = 0

            //We cancel the retry we might have asked for
            retryTimer?.invalidate()
            retryTimer = nil

            backgroundHandler.endBackgroundTask()

        case .RouteChanged:
            //In some route changes, the player pause automatically
            //TODO: there should be a check if state == playing
            if let player = player where player.rate == 0 {
                state = .Paused
            }

        case .SessionMessedUp:
            #if os(iOS) || os(tvOS)
                //We reenable the audio session directly in case we're in background
                startAudioSession()

                //Aaaaand we: restart playing/go to next
                state = .Stopped
                qualityAdjustmentEventProducer.interruptionCount += 1
                retryOrPlayNext()
            #endif

        case .StartedBuffering:
            //The buffer is empty and player is loading
            if state == .Playing && !qualityIsBeingChanged {
                qualityAdjustmentEventProducer.interruptionCount += 1
            }

            stateBeforeBuffering = state
            if reachability.isReachable() || (currentItem?.soundURLs[currentQuality ?? defaultQuality]?.ap_isOfflineURL ?? false) {
                state = .Buffering
            } else {
                state = .WaitingForConnection
            }
            backgroundHandler.beginBackgroundTask()
        }
    }
}
