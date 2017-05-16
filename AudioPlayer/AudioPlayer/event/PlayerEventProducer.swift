//
//  PlayerEventProducer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 08/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import AVFoundation

// MARK: - AVPlayer+KVO

private extension AVPlayer {
    //swiftlint:disable variable_name
    /// The list of properties that is observed through KVO.
    static var ap_KVOProperties: [String] {
        return [
            "currentItem.playbackBufferEmpty",
            "currentItem.playbackLikelyToKeepUp",
            "currentItem.duration",
            "currentItem.status",
            "currentItem.loadedTimeRanges",
            "currentItem.timedMetadata"]
    }
}

// MARK: - Selector+PlayerEventProducer

private extension Selector {
    #if os(iOS) || os(tvOS)
    /// The selector to call when the audio session is interrupted.
    static let audioSessionInterrupted =
        #selector(PlayerEventProducer.audioSessionGotInterrupted(note:))
    #endif

    /// The selector to call when the audio session route changes.
    static let audioRouteChanged = #selector(PlayerEventProducer.audioSessionRouteChanged(note:))

    /// The selector to call when the audio session get messed up.
    static let audioSessionMessedUp = #selector(PlayerEventProducer.audioSessionMessedUp(note:))

    /// The selector to call when an audio item ends playing.
    static let itemDidEnd = #selector(PlayerEventProducer.playerItemDidEnd(note:))
}


/// Custom errors which may be passed with PlayerEvent.endedPlaying event
enum EndedError: Error {
    case ItemEndedEarly
}

// MARK: - PlayerEventProducer

/// A `PlayerEventProducer` listens to notifications and observes events generated by an AVPlayer.
class PlayerEventProducer: NSObject, EventProducer {
    /// A `PlayerEvent` is an event a player generates over time.
    ///
    /// - startedBuffering: The player started buffering the audio file.
    /// - readyToPlay: The player is ready to play. It buffered enough data.
    /// - loadedMoreRange: The player loaded more range of time.
    /// - loadedMetadata: The player loaded metadata.
    /// - loadedDuration: The player has found audio item duration.
    /// - progressed: The player progressed in its playing.
    /// - endedPlaying: The player ended playing the current item because it went through the
    ///     file or because of an error.
    /// - interruptionBegan: The player got interrupted (phone call, Siri, ...).
    /// - interruptionEnded: The interruption ended.
    /// - routeChanged: The player's route changed.
    /// - sessionMessedUp: The audio session is messed up.
    enum PlayerEvent: Event {
        case startedBuffering
        case readyToPlay
        case loadedMoreRange(CMTime, CMTime)
        case loadedMetadata([AVMetadataItem])
        case loadedDuration(CMTime)
        case progressed(CMTime)
        case endedPlaying(Error?)
        case interruptionBegan
        case interruptionEnded
        case routeChanged
        case sessionMessedUp
    }

    /// The player to produce events with.
    ///
    /// Note that setting it has the same result as calling `stopProducingEvents`.
    var player: AVPlayer? {
        willSet {
            stopProducingEvents()
        }
    }

    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener?

    /// The time observer for the player.
    private var timeObserver: Any?

    /// A boolean value indicating whether we're currently listening to events on the player.
    private var listening = false

    /// Stops producing events on deinitialization.
    deinit {
        stopProducingEvents()
    }

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard let player = player, !listening else {
            return
        }

        //Observing notifications sent through `NSNotificationCenter`
        let center = NotificationCenter.default
        #if os(iOS) || os(tvOS)
            center.addObserver(self,
                selector: .audioSessionInterrupted,
                name: .AVAudioSessionInterruption,
                object: nil)
            center.addObserver(
                self,
                selector: .audioRouteChanged,
                name: .AVAudioSessionRouteChange,
                object: nil)
            center.addObserver(
                self,
                selector: .audioSessionMessedUp,
                name: .AVAudioSessionMediaServicesWereLost,
                object: nil)
            center.addObserver(
                self,
                selector: .audioSessionMessedUp,
                name: .AVAudioSessionMediaServicesWereReset,
                object: nil)
        #endif
        center.addObserver(self, selector: .itemDidEnd, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        //Observing AVPlayer's property
        for keyPath in AVPlayer.ap_KVOProperties {
            player.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }

        //Observing timing event
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 2), queue: .main) { [weak self] time in
            if let `self` = self {
                self.eventListener?.onEvent(PlayerEvent.progressed(time), generetedBy: self)
            }
        }

        listening = true
    }

    /// Stops listening to the player events.
    func stopProducingEvents() {
        guard let player = player, listening else {
            return
        }

        //Unobserving notifications sent through `NSNotificationCenter`
        let center = NotificationCenter.default
        #if os(iOS) || os(tvOS)
            center.removeObserver(self, name: .AVAudioSessionInterruption, object: nil)
            center.removeObserver(self, name: .AVAudioSessionRouteChange, object: nil)
            center.removeObserver(self, name: .AVAudioSessionMediaServicesWereLost, object: nil)
            center.removeObserver(self, name: .AVAudioSessionMediaServicesWereReset, object: nil)
        #endif
        center.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        //Unobserving AVPlayer's property
        for keyPath in AVPlayer.ap_KVOProperties {
            player.removeObserver(self, forKeyPath: keyPath)
        }

        //Unobserving timing event
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil

        listening = false
    }

    /// This message is sent to the receiver when the value at the specified key path relative to the given object has
    /// changed. The receiver must be registered as an observer for the specified `keyPath` and `object`.
    ///
    /// - Parameters:
    ///   - keyPath: The key path, relative to `object`, to the value that has changed.
    ///   - object: The source object of the key path `keyPath`.
    ///   - change: A dictionary that describes the changes that have been made to the value of the property at the key
    ///         path `keyPath` relative to `object`. Entries are described in Change Dictionary Keys.
    ///   - context: The value that was provided when the receiver was registered to receive key-value observation
    ///         notifications.
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, let p = object as? AVPlayer, let currentItem = p.currentItem {
            switch keyPath {
            case "currentItem.duration":
                let duration = currentItem.duration
                eventListener?.onEvent(PlayerEvent.loadedDuration(duration), generetedBy: self)

                let metadata = currentItem.asset.commonMetadata
                eventListener?.onEvent(PlayerEvent.loadedMetadata(metadata), generetedBy: self)

            case "currentItem.playbackBufferEmpty" where currentItem.isPlaybackBufferEmpty:
                eventListener?.onEvent(PlayerEvent.startedBuffering, generetedBy: self)

            case "currentItem.playbackLikelyToKeepUp" where currentItem.isPlaybackLikelyToKeepUp:
                eventListener?.onEvent(PlayerEvent.readyToPlay, generetedBy: self)

            case "currentItem.status" where currentItem.status == .failed:
                eventListener?.onEvent(
                    PlayerEvent.endedPlaying(currentItem.error), generetedBy: self)

            case "currentItem.loadedTimeRanges":
                if let range = currentItem.loadedTimeRanges.last?.timeRangeValue {
                    eventListener?.onEvent(
                        PlayerEvent.loadedMoreRange(range.start, range.end), generetedBy: self)
                }
            
            case "currentItem.timedMetadata":
                if let metadata = currentItem.timedMetadata {
                    eventListener?.onEvent(PlayerEvent.loadedMetadata(metadata), generetedBy: self)
                }

            default:
                break
            }
        }
    }

    #if os(iOS) || os(tvOS)
    /// Audio session got interrupted by the system (call, Siri, ...). If interruption begins, we should ensure the
    /// audio pauses and if it ends, we should restart playing if state was `.playing` before.
    ///
    /// - Parameter note: The notification information.
    @objc fileprivate func audioSessionGotInterrupted(note: NSNotification) {
        if let userInfo = note.userInfo,
            let typeInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeInt) {
            if type == .began {
                eventListener?.onEvent(PlayerEvent.interruptionBegan, generetedBy: self)
            } else {
                if let optionInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSessionInterruptionOptions(rawValue: optionInt)
                    if options.contains(.shouldResume) {
                        eventListener?.onEvent(PlayerEvent.interruptionEnded, generetedBy: self)
                    }
                }
            }
        }
    }
    #endif

    /// Audio session route changed (ex: earbuds plugged in/out). This can change the player state, so we just adapt it.
    ///
    /// - Parameter note: The notification information.
    @objc fileprivate func audioSessionRouteChanged(note: NSNotification) {
        eventListener?.onEvent(PlayerEvent.routeChanged, generetedBy: self)
    }

    /// Audio session got messed up (media services lost or reset). We gotta reactive the audio session and reset
    /// player.
    ///
    /// - Parameter note: The notification information.
    @objc fileprivate func audioSessionMessedUp(note: NSNotification) {
        eventListener?.onEvent(PlayerEvent.sessionMessedUp, generetedBy: self)
    }

    /// Playing item did end. We can play next or stop the player if queue is empty.
    ///
    /// - Parameter note: The notification information.
    @objc fileprivate func playerItemDidEnd(note: NSNotification) {
        if let currentItem = player?.currentItem {
            if currentItem.duration.seconds.isNormal && currentItem.currentTime().seconds < currentItem.duration.seconds {
                // AVPlayer thinks we are at end, but we did not actually play the full duration.
                // This usually happens when internet connection is lost during playback
                eventListener?.onEvent(PlayerEvent.endedPlaying(EndedError.ItemEndedEarly), generetedBy: self)
            } else {
                // succesfully played to end of item
                eventListener?.onEvent(PlayerEvent.endedPlaying(nil), generetedBy: self)
            }
        }
        
    }
}
