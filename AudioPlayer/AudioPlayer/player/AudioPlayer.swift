//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 26/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import AVFoundation
#if os(iOS) || os(tvOS)
    import MediaPlayer
#endif

// MARK: - AudioPlayer

/**
An `AudioPlayer` instance is used to play `AudioPlayerItem`. It's an easy to use
AVPlayer with simple methods to handle the whole playing audio process.

You can get events (such as state change or time observation) by registering a delegate.
*/
public class AudioPlayer: NSObject {
    // MARK: Handlers

    /// The background handler.
    let backgroundHandler = BackgroundHandler()

    /// Reachability for network connection.
    let reachability = Reachability.reachabilityForInternetConnection()


    // MARK: Event producers

    /// The network event producer.
    lazy var networkEventProducer: NetworkEventProducer = {
        NetworkEventProducer(reachability: self.reachability)
    }()

    /// The player event producer.
    let playerEventProducer = PlayerEventProducer()

    /// The quality adjustment event producer.
    var qualityAdjustmentEventProducer = QualityAdjustmentEventProducer()

    /// The audio item event producer.
    var audioItemEventProducer = AudioItemEventProducer()


    //MARK: Player

    /// The queue containing items to play.
    var queue: AudioItemQueue?

    /// The audio player.
    var player: AVPlayer? {
        didSet {
            if #available(OSX 10.11, *) {
                player?.allowsExternalPlayback = false
            }
            player?.volume = volume
            player?.rate = rate

            if let player = player {
                playerEventProducer.player = player
                audioItemEventProducer.item = currentItem
                playerEventProducer.startProducingEvents()
                networkEventProducer.startProducingEvents()
                audioItemEventProducer.startProducingEvents()
                qualityAdjustmentEventProducer.startProducingEvents()
            } else {
                playerEventProducer.player = nil
                audioItemEventProducer.item = nil
                playerEventProducer.stopProducingEvents()
                networkEventProducer.stopProducingEvents()
                audioItemEventProducer.stopProducingEvents()
                qualityAdjustmentEventProducer.stopProducingEvents()
            }
        }
    }

    /// The current item being played.
    public internal(set) var currentItem: AudioItem? {
        didSet {
            if let currentItem = currentItem {
                //Stops the current player
                player?.rate = 0
                player = nil

                //Ensures the audio session got started
                startAudioSession()

                //Sets new state
                let URLInfo = currentItem.URLForQuality(currentQuality)
                if reachability.isReachable() || URLInfo.URL.ap_isOfflineURL {
                    state = .Buffering
                } else {
                    stateWhenConnectionLost = .Buffering
                    state = .WaitingForConnection
                    return
                }

                //Creates new player
                player = AVPlayer(URL: URLInfo.URL)
                currentQuality = URLInfo.quality

                //Updates information on the lock screen
                updateNowPlayingInfoCenter()

                //Calls delegate
                if oldValue != currentItem {
                    delegate?.audioPlayer(self, willStartPlayingItem: currentItem)
                }
            } else {
                stop()
            }
        }
    }


    // MARK: Public properties

    /// The delegate that will be called upon events.
    public weak var delegate: AudioPlayerDelegate?

    /// Defines the maximum to wait after a connection loss before putting the player to Stopped
    /// mode and cancelling the resume. Default value is 60 seconds.
    public var maximumConnectionLossTime = NSTimeInterval(60)

    /// Defines whether the player should automatically adjust sound quality based on the number of
    /// interruption before a delay and the maximum number of interruption whithin this delay.
    /// Default value is `true`.
    public var adjustQualityAutomatically = true

    /// Defines the default quality used to play. Default value is `.Medium`
    public var defaultQuality = AudioQuality.Medium

    /// Defines the delay within which the player wait for an interruption before upgrading the
    /// quality. Default value is 10minutes.
    public var adjustQualityTimeInternal: NSTimeInterval {
        get {
            return qualityAdjustmentEventProducer.adjustQualityTimeInternal
        }
        set {
            qualityAdjustmentEventProducer.adjustQualityTimeInternal = newValue
        }
    }

    /// Defines the maximum number of interruption to have within the `adjustQualityTimeInterval`
    /// delay before downgrading the quality. Default value is 5.
    public var adjustQualityAfterInterruptionCount: Int {
        get {
            return qualityAdjustmentEventProducer.adjustQualityAfterInterruptionCount
        }
        set {
            qualityAdjustmentEventProducer.adjustQualityAfterInterruptionCount = newValue
        }
    }

    /// The maximum number of interruption before putting the player to Stopped mode. Default
    /// value is 10.
    public var maximumRetryCount = 10

    /// The delay to wait before cancelling last retry and retrying. Default value is 10 seconds.
    public var retryTimeout = NSTimeInterval(10)

    /// Defines whether the player should resume after a system interruption or not. Default value
    /// is `true`.
    public var resumeAfterInterruption = true

    /// Defines whether the player should resume after a connection loss or not. Default value
    /// is `true`.
    public var resumeAfterConnectionLoss = true

    /// Defines the mode of the player. Default is `.Normal`.
    public var mode = AudioPlayerMode.Normal {
        didSet {
            queue?.mode = mode
        }
    }

    /// Defines the volume of the player. `1.0` means 100% and `0.0` is 0%.
    public var volume = Float(1) {
        didSet {
            player?.volume = volume
        }
    }

    /// Defines the rate of the player. Default value is 1.
    public var rate = Float(1) {
        didSet {
            if state == .Playing {
                player?.rate = rate
                updateNowPlayingInfoCenter()
            }
        }
    }

    #if os(iOS) || os(tvOS)
    /// Defines the rate multiplier of the player when the backward/forward buttons are pressed.
    /// Default value is 2.
    public var rateMultiplerOnSeeking = Float(2)
    #endif


    // MARK: Readonly properties

    /// The current state of the player.
    public internal(set) var state = AudioPlayerState.Stopped {
        didSet {
            updateNowPlayingInfoCenter()

            if state != oldValue {
                if state == .Buffering {
                    backgroundHandler.beginBackgroundTask()
                } else if oldValue == .Buffering {
                    backgroundHandler.endBackgroundTask()
                }

                delegate?.audioPlayer(self, didChangeFromState: oldValue, toState: state)
            }
        }
    }

    /// The current quality being played.
    public internal(set) var currentQuality: AudioQuality


    // MARK: Private properties

    /// A boolean value indicating whether the player has been paused because of a system
    /// interruption.
    var pausedForInterruption = false

    /// A boolean value indicating if quality is being changed. It's necessary for the interruption
    /// count to not be incremented while new quality is buffering.
    var qualityIsBeingChanged = false

    /// The state before the player went into .Buffering. It helps to know whether to restart or not
    /// the player.
    var stateBeforeBuffering: AudioPlayerState?

    /// The state of the player when the connection was lost
    var stateWhenConnectionLost: AudioPlayerState?


    // MARK: Initialization

    /**
     Initializes a new AudioPlayer.
     */
    public override init() {
        currentQuality = defaultQuality
        super.init()

        playerEventProducer.eventListener = self
        networkEventProducer.eventListener = self
        audioItemEventProducer.eventListener = self
        qualityAdjustmentEventProducer.eventListener = self
    }

    /**
     Deinitializes the AudioPlayer. On deinit, the player will simply stop playing anything
     it was previously playing.
     */
    deinit {
        retryTimer?.invalidate()
        retryTimer = nil

        stop()
    }


    // MARK: Utility methods

    /**
     Updates the MPNowPlayingInfoCenter with current item's info.
     */
    func updateNowPlayingInfoCenter() {
        #if os(iOS) || os(tvOS)
            if let item = currentItem {
                MPNowPlayingInfoCenter.defaultCenter().ap_updateWithItem(
                    item,
                    duration: currentItemDuration,
                    progression: currentItemProgression,
                    playbackRate: player?.rate ?? 0)
            } else {
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
            }
        #endif
    }

    /**
     Activates the `AVAudioSession` and sets the right category.
     */
    func startAudioSession() {
        #if os(iOS) || os(tvOS)
            _ = try? AVAudioSession.sharedInstance().setActive(true)
            _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        #endif
    }













    // MARK: Public computed properties

    /// The current number of retry we already tried
    var retryCount = 0

    /// The timer used to cancel a retry and make a new one
    var retryTimer: NSTimer?

    /// Boolean value indicating whether the player should resume playing (after buffering)
    var shouldResumePlaying: Bool {
        return !pausedForInterruption &&
            state != .Paused &&
            (stateWhenConnectionLost == nil || stateWhenConnectionLost != .Paused) &&
            (stateBeforeBuffering == nil || stateBeforeBuffering != .Paused)
    }

    // MARK: Retrying

    /**
     This will retry to play current item and seek back at the correct position if possible
     (or enabled). If not, it'll just play the next item in queue.
     */
    func retryOrPlayNext() {
        if state == .Playing {
            return
        }

        if maximumRetryCount > 0 {
            if retryCount < maximumRetryCount {
                //We can retry
                let cip = currentItemProgression
                let ci = currentItem

                currentItem = ci
                if let cip = cip {
                    seekToTime(cip)
                }

                retryCount += 1

                //We gonna cancel this current retry and create a new one if the player
                //isn't playing after a certain delay
                /*let target = ClosureContainer() { [weak self] sender in
                    self?.retryOrPlayNext()
                }
                let timer = NSTimer(timeInterval: retryTimeout, target: target,
                //    selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                retryTimer = timer*/

                return
            } else {
                retryCount = 0
            }
        }

        nextOrStop()
    }
}

extension AudioPlayer: EventListener {
    func onEvent(event: Event, generetedBy eventProducer: EventProducer) {
        if let event = event as? NetworkEventProducer.NetworkEvent {
            handleNetworkEvent(event)
        } else if let event = event as? PlayerEventProducer.PlayerEvent {
            handlePlayerEvent(event)
        } else if let event = event as? AudioItemEventProducer.AudioItemEvent {
            handleAudioItemEvent(event)
        } else if let event = event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent {
            handleQualityEvent(event)
        }
    }
}
