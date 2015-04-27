//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 26/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

// MARK: - AudioPlayerState

/**
`AudioPlayerState` defines 4 state an `AudioPlayer` instance can be in.

- `Buffering`: Represents that the player is buffering data before playing them.
- `Playing`:   Represents that the player is playing.
- `Paused`:    Represents that the player is paused.
- `Stopped`:   Represents that the player is stopped.
*/
public enum AudioPlayerState {
    case Buffering
    case Playing
    case Paused
    case Stopped
}


// MARK: - AudioPlayerMode

public struct AudioPlayerModeMask: RawOptionSetType {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public init(nilLiteral: ()) {
        self.rawValue = 0
    }

    public static var Normal: AudioPlayerModeMask {
        return self(rawValue: 0b000)
    }

    public static var Shuffle: AudioPlayerModeMask {
        return self(rawValue: 0b001)
    }

    public static var Repeat: AudioPlayerModeMask {
        return self(rawValue: 0b010)
    }

    public static var RepeatAll: AudioPlayerModeMask {
        return self(rawValue: 0b100)
    }

    public static var allZeros: AudioPlayerModeMask {
        return self.Normal
    }
}

public func &(lhs: AudioPlayerModeMask, rhs: AudioPlayerModeMask) -> AudioPlayerModeMask {
    return AudioPlayerModeMask(rawValue: lhs.rawValue & rhs.rawValue)
}

public func |(lhs: AudioPlayerModeMask, rhs: AudioPlayerModeMask) -> AudioPlayerModeMask {
    return AudioPlayerModeMask(rawValue: lhs.rawValue | rhs.rawValue)
}

public func ^(lhs: AudioPlayerModeMask, rhs: AudioPlayerModeMask) -> AudioPlayerModeMask {
    return AudioPlayerModeMask(rawValue: lhs.rawValue ^ rhs.rawValue)
}

prefix public func ~(x: AudioPlayerModeMask) -> AudioPlayerModeMask {
    return AudioPlayerModeMask(rawValue: ~x.rawValue)
}


// MARK: - AudioPlayer

/**
An `AudioPlayer` instance is used to play `AudioPlayerItem`. It's an easy to use
AVPlayer with simple methods to handle the whole playing audio process.

You can get events (such as state change or time observation) by registering a delegate.
*/
public class AudioPlayer: NSObject {
    // MARK: Initialization

    public override init() {
        state = .Buffering
        super.init()
    }

    // MARK: Private properties

    private var player: AVPlayer?

    private var enqueueItems: [AudioItem]?


    // MARK: Readonly properties

    /// The current state of the player.
    public private(set) var state: AudioPlayerState

    /// The current item being played.
    public private(set) var currentItem: AudioItem? //TODO: didSet = _playItem

    /// The current item duration or nil if no item or unknown duration.
    public var currentItemDuration: NSTimeInterval? {
        if let currentItem = player?.currentItem {
            let seconds = CMTimeGetSeconds(currentItem.duration)
            if !isnan(seconds) {
                return NSTimeInterval(seconds)
            }
        }
        return nil
    }

    /// The current item progression or nil if no item.
    public var currentItemProgression: NSTimeInterval? {
        if let currentItem = player?.currentItem {
            let seconds = CMTimeGetSeconds(currentItem.currentTime())
            if !isnan(seconds) {
                return NSTimeInterval(seconds)
            }
        }
        return nil
    }

    /// The current quality being played.
    public private(set) var currentQuality: AudioQuality?


    /// MARK: Public properties

    /// The maximum number of interruption before putting the player to Stopped mode. Default value is 10.
    public var maximumRetryCount = 10

    /// The delay to wait before cancelling last retry and retrying. Default value is 10seconds.
    public var retryTimeout = NSTimeInterval(10)

    /// Defines whether the player should resume after a system interruption or not. Default value is `true`.
    public var resumeAfterInterruption = true

    /// Defines whether the player should resume after a connection loss or not. Default value is `true`.
    public var resumeAfterConnectionLoss = true

    /// Defines the maximum to wait after a connection loss before putting the player to Stopped mode and cancelling the resume. Default value is 60seconds.
    public var maximumConnectionLossTime = NSTimeInterval(60)

    /// Defines whether the player should automatically adjust sound quality based on the number of interruption before a delay and the maximum number of interruption whithin this delay. Default value is `true`.
    public var adjustQualityAutomatically = true

    /// Defines the default quality used to play. Default value is `.Medium`
    public var defaultQuality = AudioQuality.Medium

    /// Defines the delay within which the player wait for an interruption before upgrading the quality. Default value is 10minutes.
    public var adjustQualityTimeInternal = NSTimeInterval(10 * 60)

    /// Defines the maximum number of interruption to have within the `adjustQualityTimeInterval` delay before downgrading the quality. Default value is 3.
    public var adjustQualityAfterInterruptionCount = 3

    /// Defines the mode of the player. Default is `.Normal`.
    public var mode = AudioPlayerModeMask.Normal

    /// Defines the rate of the player. Default value is 1.
    public var rate = Float(1) {
        didSet {
            player?.rate = rate
        }
    }

    /// Defines the rate multiplier of the player when the backward/forward buttons are pressed. Default value is 2.
    public var rateMultiplerOnSeeking = Float(1.5)

    //public var delegate: ?


    /// MARK: Public handy functions

    /**
    Play an item.

    :param: item The item to play.
    */
    public func playItem(item: AudioItem) {
        playItems([item])
    }

    /**
    Plays the first item in `items` and enqueud the rest.

    :param: items The items to play.
    */
    public func playItems(items: [AudioItem]) {
        if items.count > 0 {
            currentItem = items.first
            enqueueItems = items
        }
        else {
            stop()
            enqueueItems = nil
        }
    }


    /**
    Resume the player.
    */
    public func resume() {
        player?.play()
        state = .Playing
    }

    /**
    Pauses the player.
    */
    public func pause() {
        player?.pause()
        state = .Paused
    }

    /**
    Stops the player and clear the queue.
    */
    public func stop() {
        //Stopping player immediately
        player?.pause()

        state = .Stopped

        enqueueItems = nil
        currentItem = nil
        player = nil
    }

    /**
    Plays next item in the queue.
    */
    public func next() {

    }

    /**
    Plays previous item in the queue.
    */
    public func previous() {

    }

    /**
    Seeks to a specific time.

    :param: time The time to seek to.
    */
    public func seekToTime(time: NSTimeInterval) {
        player?.seekToTime(CMTimeMake(Int64(time), 1))
        updateNowPlayingInfoCenter()
    }

    /**
    Handle events received from Control Center/Lock screen/Other in UIApplicationDelegate.

    :param: event The event received.
    */
    public func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == .RemoteControl {
            //ControlCenter Or Lock screen
            switch event.subtype {
            case .RemoteControlBeginSeekingBackward:
                rate = -(rate * rateMultiplerOnSeeking)
                break

            case .RemoteControlBeginSeekingBackward:
                rate = rate * rateMultiplerOnSeeking
                break

            case .RemoteControlEndSeekingBackward:
                rate = -(rate / rateMultiplerOnSeeking)
                break

            case .RemoteControlEndSeekingForward:
                rate = rate / rateMultiplerOnSeeking
                break

            case .RemoteControlNextTrack:
                next()
                break

            case .RemoteControlPause:
                pause()
                break

            case .RemoteControlPlay:
                resume()
                break

            case .RemoteControlPreviousTrack:
                previous()
                break

            case .RemoteControlStop:
                stop()
                break

            case .RemoteControlTogglePlayPause:
                if state == .Playing {
                    pause()
                }
                else {
                    resume()
                }
                break

            default:
                break
            }
        }
    }


    // MARK: MPNowPlayingInfoCenter

    /**
    Updates the MPNowPlayingInfoCenter with current item's info.
    */
    private func updateNowPlayingInfoCenter() {
        if let currentItem = currentItem {
            var info = [NSObject: AnyObject]()
            if let title = currentItem.title {
                info[MPMediaItemPropertyTitle] = title
            }
            if let artist = currentItem.artist {
                info[MPMediaItemPropertyArtist] = artist
            }
            if let album = currentItem.album {
                info[MPMediaItemPropertyAlbumTitle] = album
            }
            if let trackCount = currentItem.trackCount {
                info[MPMediaItemPropertyAlbumTrackCount] = trackCount
            }
            if let trackNumber = currentItem.trackNumber {
                info[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
            }
            if let artwork = currentItem.artworkImage {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: artwork)
            }

            if let duration = currentItemDuration {
                info[MPMediaItemPropertyPlaybackDuration] = duration
            }
            if let progression = currentItemProgression {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression
            }
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
        }
        else {
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
        }
    }


    // MARK: Events


}
