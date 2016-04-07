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
        state = .Playing
    }

    /**
     Pauses the player.
     */
    public func pause() {
        player?.rate = 0
        state = .Paused
    }

    /**
     Plays previous item in the queue or rewind current item.
     */
    public func previous() {
        if hasPrevious {
            currentItem = queue?.previousItem()
        } else {
            seekToTime(0)
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

        setAudioSessionActive(false)
        state = .Stopped
    }

    /**
     Seeks to a specific time.

     - parameter time:            The time to seek to.
     - parameter toleranceBefore: The tolerance allowed before time.
     - parameter toleranceAfter:  The tolerance allowed after time.
     */
    public func seekToTime(time: NSTimeInterval,
                           toleranceBefore: CMTime = kCMTimePositiveInfinity,
                           toleranceAfter: CMTime = kCMTimePositiveInfinity) {
        guard let earliest = currentItemSeekableRange?.earliest,
            latest = currentItemSeekableRange?.latest else {
                //In case we don't have a valid `seekableRange`, although this *shouldn't* happen
                //let's just call `AVPlayer.seekToTime` with given values.
                player?.seekToTime(CMTime(timeInterval: time),
                                   toleranceBefore: toleranceBefore,
                                   toleranceAfter: toleranceAfter)
                updateNowPlayingInfoCenter()
                return
        }

        if time >= earliest && time <= latest {
            //Time is in seekable range, there's no problem here.
            player?.seekToTime(CMTime(timeInterval: time),
                               toleranceBefore: toleranceBefore,
                               toleranceAfter: toleranceAfter)
            updateNowPlayingInfoCenter()
        } else if time < earliest {
            //Time is before seekable start, so just move to the most early position as possible.
            seekToSeekableRangeStart(1)
        } else if time > latest {
            //Time is larger than possibly, so just move forward as far as possible.
            seekToSeekableRangeEnd(1)
        }
    }

    /**
     Seeks backwards as far as possible.

     - parameter padding: The padding to apply if any.
     */
    public func seekToSeekableRangeStart(padding: NSTimeInterval) {
        if let range = currentItemSeekableRange {
            let position = min(range.latest, range.earliest + padding)
            player?.seekToTime(CMTime(timeInterval: position))
            updateNowPlayingInfoCenter()
        }
    }

    /**
     Seeks forward as far as possible.

     - parameter padding: The padding to apply if any.
     */
    public func seekToSeekableRangeEnd(padding: NSTimeInterval) {
        if let range = currentItemSeekableRange {
            let position = max(range.earliest, range.latest - padding)
            player?.seekToTime(CMTime(timeInterval: position))
            updateNowPlayingInfoCenter()
        }
    }

    #if os(iOS) || os(tvOS)
    /**
     Handle events received from Control Center/Lock screen/Other in UIApplicationDelegate.

     - parameter event: The event received.
     */
    public func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == .RemoteControl {
            switch event.subtype {
            case .RemoteControlBeginSeekingBackward:
                rate = -(rate * rateMultiplerOnSeeking)
            case .RemoteControlBeginSeekingForward:
                rate = rate * rateMultiplerOnSeeking
            case .RemoteControlEndSeekingBackward:
                rate = -(rate / rateMultiplerOnSeeking)
            case .RemoteControlEndSeekingForward:
                rate = rate / rateMultiplerOnSeeking
            case .RemoteControlNextTrack:
                next()
            case .RemoteControlPause:
                pause()
            case .RemoteControlPlay:
                resume()
            case .RemoteControlPreviousTrack:
                previous()
            case .RemoteControlStop:
                stop()
            case .RemoteControlTogglePlayPause:
                if state == .Playing {
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
