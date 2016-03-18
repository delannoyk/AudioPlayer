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


// MARK: - AudioPlayerMode

/**
Represents the mode in which the player should play. Modes can be used as masks
so that you can play in `.Shuffle` mode and still `.RepeatAll`.
*/
public struct AudioPlayerModeMask: OptionSetType {
    /// The raw value describing the mode.
    public let rawValue: UInt

    /**
     Initializes an `AudioPlayerModeMask` from a `rawValue`.

     - parameter rawValue: The raw value describing the mode.
     */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// In this mode, player's queue will be played as given.
    public static var Normal = AudioPlayerModeMask(rawValue: 0)

    /// In this mode, player's queue is shuffled randomly.
    public static var Shuffle = AudioPlayerModeMask(rawValue: 0b001)

    /// In this mode, the player will continuously play the same item over and over.
    public static var Repeat = AudioPlayerModeMask(rawValue: 0b010)

    /// In this mode, the player will continuously play the same queue over and over.
    public static var RepeatAll = AudioPlayerModeMask(rawValue: 0b100)
}

// MARK: - NSURL+iPodLibrary

private extension NSURL {
    var isOfflineURL: Bool {
        return fileURL || scheme == "ipod-library" || host == "localhost"
    }
}

// MARK: - AudioPlayer

/**
An `AudioPlayer` instance is used to play `AudioPlayerItem`. It's an easy to use
AVPlayer with simple methods to handle the whole playing audio process.

You can get events (such as state change or time observation) by registering a delegate.
*/
public class AudioPlayer: NSObject {
    // MARK: Private properties

    /// Reachability for network connection.
    private let reachability = Reachability.reachabilityForInternetConnection()

    /// The network event producer.
    private lazy var networkEventProducer: NetworkEventProducer = {
        NetworkEventProducer(reachability: self.reachability)
    }()

    /// The player event producer.
    private let playerEventProducer = PlayerEventProducer()

    /// The quality adjustment event producer.
    private var qualityAdjustmentEventProducer = QualityAdjustmentEventProducer()

    /// The audio item event producer.
    private var audioItemEventProducer = AudioItemEventProducer()

    /// The queue containing items to play.
    private var queue: AudioItemQueue?


    // MARK: Public properties

    /// The items in the queue if any.
    public var items: [AudioItem]? {
        return queue?.queue
    }

    /// The current item being played.
    public private(set) var currentItem: AudioItem? {
        didSet {
            if let currentItem = currentItem {
                #if os(iOS) || os(tvOS)
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    } catch { }
                #endif

                player?.rate = 0
                player = nil

                let URLInfo: AudioItemURL = {
                    switch (self.currentQuality ?? self.defaultQuality) {
                    case .High:
                        return currentItem.highestQualityURL
                    case .Medium:
                        return currentItem.mediumQualityURL
                    default:
                        return currentItem.lowestQualityURL
                    }
                }()

                if reachability.isReachable() || URLInfo.URL.isOfflineURL {
                    state = .Buffering
                } else {
                    connectionLossDate = NSDate()
                    stateWhenConnectionLost = .Buffering
                    state = .WaitingForConnection
                    return
                }

                player = AVPlayer(URL: URLInfo.URL)
                player?.volume = volume
                currentQuality = URLInfo.quality

                player?.rate = rate

                updateNowPlayingInfoCenter()

                if oldValue != currentItem {
                    delegate?.audioPlayer(self, willStartPlayingItem: currentItem)
                }
            } else {
                if let _ = oldValue {
                    stop()
                }
            }
        }
    }

    /// The current item duration or nil if no item or unknown duration.
    public var currentItemDuration: NSTimeInterval? {
        return player?.currentItem?.duration.timeIntervalValue
    }

    /// The current item progression or nil if no item.
    public var currentItemProgression: NSTimeInterval? {
        return player?.currentItem?.currentTime().timeIntervalValue
    }

    /// Defines the maximum to wait after a connection loss before putting the player to Stopped
    /// mode and cancelling the resume. Default value is 60seconds.
    public var maximumConnectionLossTime = NSTimeInterval(60)

    /// Defines whether the player should automatically adjust sound quality based on the number of
    /// interruption before a delay and the maximum number of interruption whithin this delay.
    /// Default value is `true`.
    public var adjustQualityAutomatically = true

    /// Defines the default quality used to play. Default value is `.Medium`
    public var defaultQuality = AudioQuality.Medium

    /// The current quality being played.
    public private(set) var currentQuality: AudioQuality

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





    // MARK: Initialization

    public override init() {
        currentQuality = defaultQuality
        super.init()

        playerEventProducer.eventListener = self
        networkEventProducer.eventListener = self
        audioItemEventProducer.eventListener = self
        qualityAdjustmentEventProducer.eventListener = self
    }

    deinit {
        retryTimer?.invalidate()
        retryTimer = nil

        stop()

        endBackgroundTask()
    }


    // MARK: Private properties

    /// The audio player.
    private var player: AVPlayer? {
        didSet {
            if #available(OSX 10.11, *) {
                player?.allowsExternalPlayback = false
            }

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

    /// A boolean value indicating whether the player has been paused because of a system
    /// interruption.
    private var pausedForInterruption = false

    /// The state before the player went into .Buffering. It helps to know whether to restart or not
    /// the player.
    private var stateBeforeBuffering: AudioPlayerState?

    /// A boolean value indicating if quality is being changed. It's necessary for the interruption
    /// count to not be incremented while new quality is buffering.
    private var qualityIsBeingChanged = false

    /// The current number of retry we already tried
    private var retryCount = 0

    /// The timer used to cancel a retry and make a new one
    private var retryTimer: NSTimer?

    /// The state of the player when the connection was lost
    private var stateWhenConnectionLost: AudioPlayerState?

    /// The date of the connection loss
    private var connectionLossDate: NSDate?

    /// Boolean value indicating whether the player should resume playing (after buffering)
    private var shouldResumePlaying: Bool {
        return !pausedForInterruption &&
            state != .Paused &&
            (stateWhenConnectionLost == nil || stateWhenConnectionLost != .Paused) &&
            (stateBeforeBuffering == nil || stateBeforeBuffering != .Paused)
    }


    // MARK: Readonly properties

    /// The current state of the player.
    public private(set) var state = AudioPlayerState.Stopped {
        didSet {
            updateNowPlayingInfoCenter()
            if state != oldValue || state == .WaitingForConnection {
                delegate?.audioPlayer(self, didChangeFromState: oldValue, toState: state)
            }
        }
    }

    public typealias TimeRange = (earliest: NSTimeInterval, latest: NSTimeInterval)

    /// The current seekable range.
    public var currentItemSeekableRange: TimeRange? {
        if let range = player?.currentItem?.seekableTimeRanges.last?.CMTimeRangeValue,
            start = range.start.timeIntervalValue, end = range.end.timeIntervalValue {
                return (start, end)
        }
        if let currentItemProgression = currentItemProgression {
            // if there is no start and end point of seekable range
            // return the current time, so no seeking possible
            return (currentItemProgression, currentItemProgression)
        }
        // can not seek at all, so return nil
        return nil
    }

    /// The current loaded range.
    public var currentItemLoadedRange: TimeRange? {
        let range = player?.currentItem?.loadedTimeRanges.last?.CMTimeRangeValue
        if let seekableStart = range?.start.timeIntervalValue, seekableEnd = range?.end.timeIntervalValue {
            return (seekableStart, seekableEnd)
        }
        return nil
    }


    // MARK: Public properties

    /// The maximum number of interruption before putting the player to Stopped mode. Default
    /// value is 10.
    public var maximumRetryCount = 10

    /// The delay to wait before cancelling last retry and retrying. Default value is 10seconds.
    public var retryTimeout = NSTimeInterval(10)

    /// Defines whether the player should resume after a system interruption or not. Default value
    /// is `true`.
    public var resumeAfterInterruption = true

    /// Defines whether the player should resume after a connection loss or not. Default value
    /// is `true`.
    public var resumeAfterConnectionLoss = true

    /// Defines the mode of the player. Default is `.Normal`.
    public var mode = AudioPlayerModeMask.Normal {
        didSet {
            queue?.mode = mode
        }
    }

    /// Defines the rate of the player. Default value is 1.
    public var rate = Float(1) {
        didSet {
            player?.rate = rate
            updateNowPlayingInfoCenter()
        }
    }

    /// Defines the volume of the player. `1.0` means 100% and `0.0` is 0%.
    public var volume = Float(1) {
        didSet {
            player?.volume = volume
        }
    }

    #if os(iOS) || os(tvOS)
    /// Defines the rate multiplier of the player when the backward/forward buttons are pressed.
    /// Default value is 2.
    public var rateMultiplerOnSeeking = Float(2)
    #endif

    /// The delegate that will be called upon special events
    public weak var delegate: AudioPlayerDelegate?


    // MARK: Public handy functions

    /**
    Play an item.

    - parameter item: The item to play.
    */
    public func playItem(item: AudioItem) {
        playItems([item])
    }

    /**
     Plays the first item in `items` and enqueud the rest.

     - parameter items: The items to play.
     - parameter index: The index to start the player with.
    */
    public func playItems(items: [AudioItem], startAtIndex index: Int = 0) {
        if items.count > 0 {
            queue = AudioItemQueue(items: items, mode: mode)
            if let realIndex = queue?.queue.indexOf(items[index]) {
                queue?.nextPosition = realIndex
            }
            currentItem = queue?.nextItem()
        } else {
            stop()
            queue = nil
        }
    }

    /**
    Adds an item at the end of the queue. If queue is empty and player isn't
    playing, the behaviour will be similar to `playItem(item: item)`.

    - parameter item: The item to add.
    */
    public func addItemToQueue(item: AudioItem) {
        addItemsToQueue([item])
    }

    /**
    Adds items at the end of the queue. If the queue is empty and player isn't
    playing, the behaviour will be similar to `playItems(items: items)`.

    - parameter items: The items to add.
    */
    public func addItemsToQueue(items: [AudioItem]) {
        if let queue = queue {
            queue.addItems(items)
        } else {
            playItems(items)
        }
    }

    /**
     Removes an item at a specific index in the queue.

     - parameter index: The index of the item to remove.
     */
    public func removeItemAtIndex(index: Int) {
        if let queue = queue {
            queue.removeItemAtIndex(index)
        }
    }

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
    Stops the player and clear the queue.
    */
    public func stop() {
        //Stopping player immediately
        player?.rate = 0

        state = .Stopped

        queue = nil
        currentItem = nil
        player = nil
    }

    /**
    Plays next item in the queue.
    */
    public func next() {
        if let queue = queue where queue.hasNextItem {
            //The background task will end when the player will have enough data to play
            beginBackgroundTask()
            currentItem = queue.nextItem()
        }
    }

    /**
    Returns whether there is a next item in the queue or not.

    - returns: A boolean value indicating whether there is a next item to play or not.
    */
    public func hasNext() -> Bool {
        return queue?.hasNextItem ?? false
    }

    /**
    Plays previous item in the queue or rewind current item.
    */
    public func previous() {
        if let queue = queue {
            if queue.hasPreviousItem {
                currentItem = queue.previousItem()
            } else {
                seekToTime(0)
            }
        }
    }

    /**
    Seeks to a specific time.

    - parameter time: The time to seek to.
    */
    public func seekToTime(time: NSTimeInterval, toleranceBefore: CMTime = kCMTimePositiveInfinity, toleranceAfter: CMTime = kCMTimePositiveInfinity) {
        let time = CMTime(timeInterval: time)
        let seekableRange = player?.currentItem?.seekableTimeRanges.last?.CMTimeRangeValue
        if let seekableStart = seekableRange?.start, let seekableEnd = seekableRange?.end {
            // check if time is in seekable range
            if time >= seekableStart && time <= seekableEnd {
                // time is in seekable range
                player?.seekToTime(time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
            } else if time < seekableStart {
                // time is before seekable start, so just move to the most early position as possible
                seekToSeekableRangeStart(1)
            } else if time > seekableEnd {
                // time is larger than possibly, so just move forward as far as possible
                seekToSeekableRangeEnd(1)
            }
            
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

            let time = CMTime(timeInterval: position)
            player?.seekToTime(time)

            updateNowPlayingInfoCenter()
        }
    }

    /**
     Seeks backwards as far as possible.
     
     - parameter padding: The padding to apply if any.
     */
    public func seekToSeekableRangeStart(padding: NSTimeInterval) {
        if let range = currentItemSeekableRange {
            let position = min(range.latest, range.earliest + padding)

            let time = CMTime(timeInterval: position)
            player?.seekToTime(time)

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
            //ControlCenter Or Lock screen
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


    // MARK: MPNowPlayingInfoCenter

    /**
    Updates the MPNowPlayingInfoCenter with current item's info.
    */
    private func updateNowPlayingInfoCenter() {
        #if os(iOS) || os(tvOS)
            if let currentItem = currentItem {
                var info = [String: AnyObject]()
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
                #if os(iOS)
                    if let artwork = currentItem.artworkImage {
                        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: artwork)
                    }
                #endif
                if let duration = currentItemDuration {
                    info[MPMediaItemPropertyPlaybackDuration] = duration
                }
                if let progression = currentItemProgression {
                    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression
                }

                info[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate ?? 0

                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
            } else {
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
            }
        #endif
    }


    // MARK: Retrying

    /**
    This will retry to play current item and seek back at the correct position if possible
    (or enabled). If not, it'll just play the next item in queue.
    */
    private func retryOrPlayNext() {
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

                retryCount++

                //We gonna cancel this current retry and create a new one if the player isn't playing after a certain delay
                /*let target = ClosureContainer() { [weak self] sender in
                    self?.retryOrPlayNext()
                }
                let timer = NSTimer(timeInterval: retryTimeout, target: target, selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                retryTimer = timer*/

                return
            } else {
                retryCount = 0
            }
        }

        nextOrStop()
    }

    private func nextOrStop() {
        if mode.intersect(.Repeat) != [] {
            seekToTime(0)
            resume()
        } else if hasNext() {
            next()
        } else {
            stop()
        }
    }

    // MARK: Background

    /// The backround task identifier if a background task started. Nil if not.
    private var backgroundTaskIdentifier: Int?

    /**
    Starts a background task if there isn't already one running.
    */
    private func beginBackgroundTask() {
        #if os(iOS) || os(tvOS)
            if backgroundTaskIdentifier == nil {
                backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { [weak self] in
                    if let backgroundTaskIdentifier = self?.backgroundTaskIdentifier {
                        UIApplication.sharedApplication().endBackgroundTask(backgroundTaskIdentifier)
                    }
                    self?.backgroundTaskIdentifier = nil
                }
            }
        #endif
    }
    
    /**
    Ends the background task if there is one.
    */
    private func endBackgroundTask() {
        #if os(iOS) || os(tvOS)
            if let backgroundTaskIdentifier = backgroundTaskIdentifier {
                if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    UIApplication.sharedApplication().endBackgroundTask(backgroundTaskIdentifier)
                }
                self.backgroundTaskIdentifier = nil
            }
        #endif
    }
}

extension AudioPlayer: EventListener {
    private func handleNetworkEvent(event: NetworkEventProducer.NetworkEvent) {
        switch event {
        case .ConnectionLost:
            //Early exit if state prevents us to handle connection loss
            guard let currentItem = currentItem where state != .WaitingForConnection else {
                return
            }

            //In case we're not playing offline file
            if !(currentItem.soundURLs[currentQuality]?.isOfflineURL ?? false) {
                connectionLossDate = NSDate()
                stateWhenConnectionLost = state

                if let currentItem = player?.currentItem where currentItem.playbackBufferEmpty {
                    if state == .Playing {
                        qualityAdjustmentEventProducer.interruptionCount += 1
                    }

                    state = .WaitingForConnection
                    beginBackgroundTask()
                }
            }

        case .ConnectionRetrieved:
            //Early exit if connection wasn't lost during playing or `resumeAfterConnectionLoss`
            //isn't enabled.
            guard let lossDate = connectionLossDate,
                stateWhenLost = stateWhenConnectionLost where resumeAfterConnectionLoss else {
                    return
            }

            let isAllowedToRestart = lossDate.timeIntervalSinceNow < maximumConnectionLossTime
            let wasPlayingBeforeLoss = stateWhenLost != .Stopped

            if isAllowedToRestart && wasPlayingBeforeLoss {
                retryOrPlayNext()
            }

            connectionLossDate = nil
            stateWhenConnectionLost = nil

        case .NetworkChanged:
            break
        }
    }

    private func handlePlayerEvent(event: PlayerEventProducer.PlayerEvent) {
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
                beginBackgroundTask()
                pausedForInterruption = true
                pause()
            }

        case .InterruptionEnded:
            if pausedForInterruption {
                if resumeAfterInterruption {
                    resume()
                }
                pausedForInterruption = false
                endBackgroundTask()
            }

        case .LoadedDuration(let time):
            if let currentItem = currentItem, time = time.timeIntervalValue {
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
            if let currentItemProgression = time.timeIntervalValue,
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
                        endBackgroundTask()
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

            endBackgroundTask()

        case .RouteChanged:
            //In some route changes, the player pause automatically
            //TODO: there should be a check if state == playing
            if let player = player where player.rate == 0 {
                state = .Paused
            }

        case .SessionMessedUp:
            #if os(iOS) || os(tvOS)
                //We reenable the audio session directly in case we're in background
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                } catch {}

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
            if reachability.isReachable() || (currentItem?.soundURLs[currentQuality ?? defaultQuality]?.isOfflineURL ?? false) {
                state = .Buffering
            } else {
                state = .WaitingForConnection
            }
            beginBackgroundTask()
        }
    }

    private func handleQualityEvent(event: QualityAdjustmentEventProducer.QualityAdjustmentEvent) {
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

    private func handleAudioItemEvent(event: AudioItemEventProducer.AudioItemEvent) {
        updateNowPlayingInfoCenter()
    }

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

extension AudioPlayer {
    // MARK: Private handlers
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
