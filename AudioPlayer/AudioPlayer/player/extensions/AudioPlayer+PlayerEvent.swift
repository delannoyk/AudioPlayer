//
//  AudioPlayer+PlayerEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 03/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

extension AudioPlayer {
    /// Handles player events.
    ///
    /// - Parameters:
    ///   - producer: The event producer that generated the player event.
    ///   - event: The player event.
    func handlePlayerEvent(from producer: EventProducer, with event: PlayerEventProducer.PlayerEvent) {
        switch event {
        case .endedPlaying(let error):
            if !currentItemIsOffline,
                isInternetConnectionError(error) || (!isOnline && isEndedEarlyError(error)) {
                // While playing online content we got an internet error or
                // ended playing the item before it was finished while offline (likely also due to connection loss).
                stateWhenConnectionLost = .playing
                state = .waitingForConnection
            } else if let error = error {
                // Some unrecoverable error occured while playing, set failed state and
                // let the retry handler try again if it's enabled.
                state = .failed(.foundationError(error))
            } else {
                nextOrStop()
            }

        case .interruptionBegan where state.isPlaying || state.isBuffering:
            //We pause the player when an interruption is detected
            backgroundHandler.beginBackgroundTask()
            pausedForInterruption = true
            pause()

        case .interruptionEnded where pausedForInterruption:
            if resumeAfterInterruption {
                resume()
            }
            pausedForInterruption = false
            backgroundHandler.endBackgroundTask()

        case .loadedDuration(let time):
            if let currentItem = currentItem, let time = time.ap_timeIntervalValue {
                updateNowPlayingInfoCenter()
                delegate?.audioPlayer(self, didFindDuration: time, for: currentItem)
            }

        case .loadedMetadata(let metadata):
            if let currentItem = currentItem, !metadata.isEmpty {
                currentItem.parseMetadata(metadata)
                delegate?.audioPlayer(self, didUpdateEmptyMetadataOn: currentItem, withData: metadata)
            }

        case .loadedMoreRange:
            if let currentItem = currentItem, let currentItemLoadedRange = currentItemLoadedRange {
                delegate?.audioPlayer(self, didLoad: currentItemLoadedRange, for: currentItem)
            }

        case .progressed(let time):
            if let currentItemProgression = time.ap_timeIntervalValue, let item = player?.currentItem,
                item.status == .readyToPlay {
                //This fixes the behavior where sometimes the `playbackLikelyToKeepUp` isn't
                //changed even though it's playing (happens mostly at the first play though).
                if state.isBuffering || state.isPaused {
                    if shouldResumePlaying {
                        stateBeforeBuffering = nil
                        state = .playing
                        player?.rate = rate
                    } else {
                        player?.rate = 0
                        state = .paused
                    }
                    backgroundHandler.endBackgroundTask()
                }

                //Then we can call the didUpdateProgressionTo: delegate method
                let itemDuration = currentItemDuration ?? 0
                let percentage = (itemDuration > 0 ? Float(currentItemProgression / itemDuration) * 100 : 0)
                delegate?.audioPlayer(self, didUpdateProgressionTo: currentItemProgression, percentageRead: percentage)
            }

        case .readyToPlay:
            //There is enough data in the buffer
            if shouldResumePlaying {
                stateBeforeBuffering = nil
                state = .playing
                player?.rate = rate
            } else {
                player?.rate = 0
                state = .paused
            }

            //TODO: where to start?
            retryEventProducer.stopProducingEvents()
            backgroundHandler.endBackgroundTask()

        case .routeChanged:
            //In some route changes, the player pause automatically
            //TODO: there should be a check if state == playing
            if let player = player, player.rate == 0 {
                state = .paused
            }

        case .sessionMessedUp:
            #if os(iOS) || os(tvOS)
                //We reenable the audio session directly in case we're in background
                setAudioSession(active: true)

                //Aaaaand we: restart playing/go to next
                state = .stopped
                qualityAdjustmentEventProducer.interruptionCount += 1
                retryOrPlayNext()
            #endif

        case .startedBuffering:
            //The buffer is empty and player is loading
            if case .playing = state, !qualityIsBeingChanged {
                qualityAdjustmentEventProducer.interruptionCount += 1
            }

            stateBeforeBuffering = state
            if isOnline || currentItemIsOffline {
                state = .buffering
            } else {
                state = .waitingForConnection
            }
            backgroundHandler.beginBackgroundTask()

        default:
            break
        }
    }
}

//TODO: Refactor to better location
func isInternetConnectionError(_ error: Error?) -> Bool {
    guard let urlErr = error as? URLError else {
        return false
    }
    return urlErr.code == URLError.Code.notConnectedToInternet
        || urlErr.code == URLError.Code.networkConnectionLost
}

func isEndedEarlyError(_ error: Error?) -> Bool {
    return error as? EndedError == EndedError.ItemEndedEarly
}
