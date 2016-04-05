//
//  AudioPlayer+NetworkEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 03/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

extension AudioPlayer {
    func handleNetworkEvent(event: NetworkEventProducer.NetworkEvent) {
        switch event {
        case .ConnectionLost:
            //Early exit if state prevents us to handle connection loss
            guard let currentItem = currentItem where state != .WaitingForConnection else {
                return
            }

            //In case we're not playing offline file
            if !(currentItem.soundURLs[currentQuality]?.ap_isOfflineURL ?? false) {
                stateWhenConnectionLost = state

                if let currentItem = player?.currentItem where currentItem.playbackBufferEmpty {
                    if state == .Playing {
                        qualityAdjustmentEventProducer.interruptionCount += 1
                    }

                    state = .WaitingForConnection
                    backgroundHandler.beginBackgroundTask()
                }
            }

        case .ConnectionRetrieved:
            //Early exit if connection wasn't lost during playing or `resumeAfterConnectionLoss`
            //isn't enabled.
            guard let lossDate = networkEventProducer.connectionLossDate,
                stateWhenLost = stateWhenConnectionLost where resumeAfterConnectionLoss else {
                    return
            }

            let isAllowedToRestart = lossDate.timeIntervalSinceNow < maximumConnectionLossTime
            let wasPlayingBeforeLoss = stateWhenLost != .Stopped

            if isAllowedToRestart && wasPlayingBeforeLoss {
                retryOrPlayNext()
            }

            stateWhenConnectionLost = nil

        case .NetworkChanged:
            break
        }
    }
}
