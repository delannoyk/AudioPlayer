//
//  AudioPlayer+Control.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 29/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import CoreMedia
#if os(iOS) || os(tvOS)
    import UIKit
#endif

extension AudioPlayer {
    /**
     Resume the player.
     */
    public func resume() {
        player?.rate = rate

        //We don't wan't to change the state to Playing in case it's Buffering. That
        //would be a lie.
        if !state.isPlaying && !state.isBuffering {
            state = .playing
        }

        retryEventProducer.startProducingEvents()
    }

    /**
     Pauses the player.
     */
    public func pause() {
        //We ensure the player actually pauses
        player?.rate = 0
        state = .paused

        retryEventProducer.stopProducingEvents()

        //Let's begin a background task for the player to keep buffering if the app is in
        //background. This will mimic the default behavior of `AVPlayer` when pausing while the
        //app is in foreground.
        backgroundHandler.beginBackgroundTask()
    }

    /**
     Plays previous item in the queue or rewind current item.
     */
    public func previous() {
        if hasPrevious {
            currentItem = queue?.previousItem()
        } else {
            seek(to: 0)
        }
    }

    /**
     Plays next item in the queue.
     */
    public func next() {
        if hasNext {
            currentItem = queue?.nextItem()
        }
    }

    /**
     Plays the next item in the queue and if there isn't, the player will stop.
     */
    public func nextOrStop() {
        if hasNext {
            next()
        } else {
            stop()
        }
    }

    /**
     Stops the player and clear the queue.
     */
    public func stop() {
        retryEventProducer.stopProducingEvents()

        if let _ = player {
            player?.rate = 0
            player = nil
        }
        if let _ = currentItem {
            currentItem = nil
        }
        if let _ = queue {
            queue = nil
        }

        setAudioSession(active: false)
        state = .stopped
    }

    /**
     Seeks to a specific time.

     - parameter time:                              The time to seek to.
     - parameter byAdaptingTimeToFitSeekableRanges: A boolean value indicating whether the time
        should be adapted to current seekable ranges in order to be bufferless.
     - parameter toleranceBefore:                   The tolerance allowed before time.
     - parameter toleranceAfter:                    The tolerance allowed after time.
     */
    public func seek(to time: TimeInterval,
                     byAdaptingTimeToFitSeekableRanges: Bool = false,
                     toleranceBefore: CMTime = kCMTimePositiveInfinity,
                     toleranceAfter: CMTime = kCMTimePositiveInfinity) {
        guard let earliest = currentItemSeekableRange?.earliest,
            let latest = currentItemSeekableRange?.latest else {
                //In case we don't have a valid `seekableRange`, although this *shouldn't* happen
                //let's just call `AVPlayer.seek(to:)` with given values.
                player?.seek(
                    to: CMTime(timeInterval: time),
                    toleranceBefore: toleranceBefore,
                    toleranceAfter: toleranceAfter)
                updateNowPlayingInfoCenter()
                return
        }

        if !byAdaptingTimeToFitSeekableRanges || (time >= earliest && time <= latest) {
            //Time is in seekable range, there's no problem here.
            player?.seek(
                to: CMTime(timeInterval: time),
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter)
            updateNowPlayingInfoCenter()
        } else if time < earliest {
            //Time is before seekable start, so just move to the most early position as possible.
            seekToSeekableRangeStart(padding: 1)
        } else if time > latest {
            //Time is larger than possibly, so just move forward as far as possible.
            seekToSeekableRangeEnd(padding: 1)
        }
    }

    /**
     Seeks backwards as far as possible.

     - parameter padding: The padding to apply if any.
     */
    public func seekToSeekableRangeStart(padding: TimeInterval) {
        if let range = currentItemSeekableRange {
            let position = min(range.latest, range.earliest + padding)
            player?.seek(to: CMTime(timeInterval: position))
            updateNowPlayingInfoCenter()
        }
    }

    /**
     Seeks forward as far as possible.

     - parameter padding: The padding to apply if any.
     */
    public func seekToSeekableRangeEnd(padding: TimeInterval) {
        if let range = currentItemSeekableRange {
            let position = max(range.earliest, range.latest - padding)
            player?.seek(to: CMTime(timeInterval: position))
            updateNowPlayingInfoCenter()
        }
    }

    #if os(iOS) || os(tvOS)
    /**
     Handle events received from Control Center/Lock screen/Other in UIApplicationDelegate.

     - parameter event: The event received.
     */
    public func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == .remoteControl {
            switch event.subtype {
            case .remoteControlBeginSeekingBackward:
                rate = -(rate * rateMultiplerOnSeeking)
            case .remoteControlBeginSeekingForward:
                rate = rate * rateMultiplerOnSeeking
            case .remoteControlEndSeekingBackward:
                rate = -(rate / rateMultiplerOnSeeking)
            case .remoteControlEndSeekingForward:
                rate = rate / rateMultiplerOnSeeking
            case .remoteControlNextTrack:
                next()
            case .remoteControlPause:
                pause()
            case .remoteControlPlay:
                resume()
            case .remoteControlPreviousTrack:
                previous()
            case .remoteControlStop:
                stop()
            case .remoteControlTogglePlayPause:
                if case .playing = state {
                    pause()
                } else {
                    resume()
                }
            default:
                break
            }
        }
    }
    #endif
}
