//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 26/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import AVFoundation

#if os(iOS) || os(tvOS)
    import UIKit
    import MediaPlayer
#endif

private class ClosureContainer: NSObject {
    let closure: (_ sender: AnyObject) -> ()

    init(closure: @escaping (_ sender: AnyObject) -> ()) {
        self.closure = closure
    }

    @objc func callSelectorOnTarget(_ sender: AnyObject) {
        closure(sender)
    }
}

// MARK: - AudioPlayerState

/**
`AudioPlayerState` defines 4 state an `AudioPlayer` instance can be in.

- `Buffering`:            The player is buffering data before playing them.
- `Playing`:              The player is playing.
- `Paused`:               The player is paused.
- `Stopped`:              The player is stopped.
- `WaitingForConnection`: The player is waiting for internet connection.
- `Failed`:               An error occured. It contains AVPlayer's error if any.
*/
public enum AudioPlayerState {
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
    case failed(AudioPlayerError)
}

extension AudioPlayerState: Equatable { }

public func ==(lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
    switch (lhs, rhs) {
    case (.buffering, .buffering):
        return true
    case (.playing, .playing):
        return true
    case (.paused, .paused):
        return true
    case (.stopped, .stopped):
        return true
    case (.waitingForConnection, .waitingForConnection):
        return true
    case (.failed, .failed):
        return true
    default:
        return false
    }
}


// MARK: - AudioPlayerMode

/**
Represents the mode in which the player should play. Modes can be used as masks
so that you can play in `.Shuffle` mode and still `.RepeatAll`.

- `.Shuffle`:   In this mode, player's queue is shuffled randomly.
- `.Repeat`:    In this mode, the player will continuously play the same item over and over.
- `.RepeatAll`: In this mode, the player will continuously play the same queue over and over.
*/
public struct AudioPlayerModeMask: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static var Shuffle: AudioPlayerModeMask {
        return self.init(rawValue: 0b001)
    }

    public static var Repeat: AudioPlayerModeMask {
        return self.init(rawValue: 0b010)
    }

    public static var RepeatAll: AudioPlayerModeMask {
        return self.init(rawValue: 0b100)
    }
}


// MARK: - AudioPlayerError

public enum AudioPlayerError: Error {
    case maximumRetryCountHit
    case foundationError(NSError?)
}


// MARK: - AVPlayer+KVO

private extension AVPlayer {
    static var ap_KVOItems: [String] {
        return [
            "currentItem.playbackBufferEmpty",
            "currentItem.playbackLikelyToKeepUp",
            "currentItem.duration",
            "currentItem.status",
            "currentItem.loadedTimeRanges"
        ]
    }
}


// MARK: - NSObject+Observation

private extension NSObject {
    
    func observe(_ name: NSNotification.Name, selector: Selector, object: AnyObject? = nil) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: object)
    }

    func unobserve(_ name: NSNotification.Name, object: AnyObject? = nil) {
        NotificationCenter.default.removeObserver(self, name: name, object: object)
    }
}


// MARK: - Array+Shuffe

private extension Array {
    func shuffled() -> [Element] {
        return sorted { e1, e2 in
            arc4random() % 2 == 0
        }
    }
}


// MARK: - NSURL+iPodLibrary

private extension URL {
    var isOfflineURL: Bool {
        return isFileURL || scheme == "ipod-library" || host == "localhost"
    }
}


// MARK: - AudioPlayerDelegate

/// This typealias only serves the purpose of saving user to `import AVFoundation`.
public typealias Metadata = [AVMetadataItem]

/**
This protocol contains helpful methods to alert you of specific events.
If you want to be notified about those events, you will have to set a delegate
to your `audioPlayer` instance.
*/
public protocol AudioPlayerDelegate: class {
    /**
     This method is called when the audio player changes its state.
     A fresh created audioPlayer starts in `.Stopped` mode.

     - parameter audioPlayer: The audio player.
     - parameter from:        The state before any changes.
     - parameter to:          The new state.
     */
    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState)

    /**
     This method is called when the audio player is about to start playing
     a new item.

     - parameter audioPlayer: The audio player.
     - parameter item:        The item that is about to start being played.
     */
    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem)

    /**
     This method is called a regular time interval while playing. It notifies
     the delegate that the current playing progression changed.

     - parameter audioPlayer:    The audio player.
     - parameter time:           The current progression.
     - parameter percentageRead: The percentage of the file that has been read. 
                                 It's a Float value between 0 & 100 so that you can
                                easily update an `UISlider` for example.
     */
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionToTime time: TimeInterval, percentageRead: Float)

    /**
     This method gets called when the current item duration has been found.

     - parameter audioPlayer: The audio player.
     - parameter duration:    Current item's duration.
     - parameter item:        Current item.
     */
    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, forItem item: AudioItem)

    /**
     This methods gets called before duration gets updated with discovered metadata.

     - parameter audioPlayer: The audio player.
     - parameter item:        Found metadata.
     - parameter data:        Current item.
     */
    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateEmptyMetadataOnItem item: AudioItem, withData data: Metadata)

    /**
     This method gets called while the audio player is loading the file (over
     the network or locally). It lets the delegate know what time range has
     already been loaded.

     - parameter audioPlayer: The audio player.
     - parameter range:       The time range that the audio player loaded.
     - parameter item:        Current item.
     */
    func audioPlayer(_ audioPlayer: AudioPlayer, didLoadRange range: AudioPlayer.TimeRange, forItem item: AudioItem)
}

extension AudioPlayerDelegate {
    public func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState) {
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem) {
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionToTime time: TimeInterval, percentageRead: Float) {
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, forItem item: AudioItem) {
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateEmptyMetadataOnItem item: AudioItem, withData data: Metadata) {
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didLoadRange range: AudioPlayer.TimeRange, forItem item: AudioItem) {
    }
}


// MARK: - AudioPlayer

/**
An `AudioPlayer` instance is used to play `AudioPlayerItem`. It's an easy to use
AVPlayer with simple methods to handle the whole playing audio process.

You can get events (such as state change or time observation) by registering a delegate.
*/
open class AudioPlayer: NSObject {
    // MARK: Initialization

    public override init() {
        super.init()

        observe(ReachabilityChangedNotification, selector: #selector(AudioPlayer.reachabilityStatusChanged(_:)), object: reachability)
        try? reachability?.startNotifier()
    }

    deinit {
        reachability?.stopNotifier()
        unobserve(ReachabilityChangedNotification, object: reachability)

        qualityAdjustmentTimer?.invalidate()
        qualityAdjustmentTimer = nil

        retryTimer?.invalidate()
        retryTimer = nil

        stop()

        endBackgroundTask()
    }


    // MARK: Private properties

    /// The audio player.
    fileprivate var player: AVPlayer? {
        didSet {
            //Gotta unobserver & observe if necessary
            for keyPath in AVPlayer.ap_KVOItems {
                oldValue?.removeObserver(self, forKeyPath: keyPath)
                player?.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
            }

            if let oldValue = oldValue {
                qualityAdjustmentTimer?.invalidate()
                qualityAdjustmentTimer = nil

                if let timeObserver = timeObserver {
                    oldValue.removeTimeObserver(timeObserver)
                }
                timeObserver = nil

                #if os(iOS) || os(tvOS)
                    unobserve(NSNotification.Name.AVAudioSessionInterruption)
                    unobserve(NSNotification.Name.AVAudioSessionRouteChange)
                    unobserve(NSNotification.Name.AVAudioSessionMediaServicesWereLost)
                    unobserve(NSNotification.Name.AVAudioSessionMediaServicesWereReset)
                #endif
                unobserve(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            }

            if let player = player {
                //Creating the qualityAdjustment timer
                let target = ClosureContainer() { [weak self] sender in
                    self?.adjustQualityIfNecessary()
                }
                let timer = Timer(timeInterval: adjustQualityTimeInternal, target: target, selector: #selector(ClosureContainer.callSelectorOnTarget(_:)), userInfo: nil, repeats: false)
                RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
                qualityAdjustmentTimer = timer

                timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 2), queue: DispatchQueue.main) { [weak self] time in
                    self?.currentProgressionUpdated(time)
                } as AnyObject?

                if #available(OSX 10.11, *) {
                    player.allowsExternalPlayback = false
                }

                #if os(iOS) || os(tvOS)
                    observe(NSNotification.Name.AVAudioSessionInterruption, selector: #selector(AudioPlayer.audioSessionGotInterrupted(_:)))
                    observe(NSNotification.Name.AVAudioSessionRouteChange, selector: #selector(AudioPlayer.audioSessionRouteChanged(_:)))
                    observe(NSNotification.Name.AVAudioSessionMediaServicesWereLost, selector: #selector(AudioPlayer.audioSessionMessedUp(_:)))
                    observe(NSNotification.Name.AVAudioSessionMediaServicesWereReset, selector: #selector(AudioPlayer.audioSessionMessedUp(_:)))
                #endif
                observe(NSNotification.Name.AVPlayerItemDidPlayToEndTime, selector: #selector(AudioPlayer.playerItemDidEnd(_:)))
            }
        }
    }

    fileprivate typealias AudioQueueItem = (position: Int, item: AudioItem)

    /// The queue containing items to play.
    fileprivate var enqueuedItems: [AudioQueueItem]?

    open var items: [AudioItem]? {
        return enqueuedItems?.map { $0.item }
    }

    /// A boolean value indicating whether the player has been paused because of a system interruption.
    fileprivate var pausedForInterruption = false
    
    /// The state before the player went into .Buffering. It helps to know whether to restart or not the player.
    fileprivate var stateBeforeBuffering: AudioPlayerState?
    
    /// The time observer
    fileprivate var timeObserver: AnyObject?

    /// The number of interruption since last quality adjustment/begin playing
    fileprivate var interruptionCount = 0 {
        didSet {
            if adjustQualityAutomatically && interruptionCount > adjustQualityAfterInterruptionCount {
                adjustQualityIfNecessary()
            }
        }
    }

    /// A boolean value indicating if quality is being changed. It's necessary for the interruption count to not be incremented while new quality is buffering.
    fileprivate var qualityIsBeingChanged = false

    /// The current number of retry we already tried
    fileprivate var retryCount = 0

    /// The timer used to cancel a retry and make a new one
    fileprivate var retryTimer: Timer?

    /// The timer used to adjust quality
    fileprivate var qualityAdjustmentTimer: Timer?

    /// The state of the player when the connection was lost
    fileprivate var stateWhenConnectionLost: AudioPlayerState?

    /// The date of the connection loss
    fileprivate var connectionLossDate: Date?

    /// The index of the current item in the queue
    open fileprivate(set) var currentItemIndexInQueue: Int?

    /// Reachability for network connection
    fileprivate let reachability = Reachability()

    /// Boolean value indicating whether the player should resume playing (after buffering)
    fileprivate var shouldResumePlaying: Bool {
        return !pausedForInterruption &&
            state != .paused &&
            (stateWhenConnectionLost == nil || stateWhenConnectionLost != .paused) &&
            (stateBeforeBuffering == nil || stateBeforeBuffering != .paused)
    }


    // MARK: Readonly properties

    /// The current state of the player.
    open fileprivate(set) var state = AudioPlayerState.stopped {
        didSet {
            updateNowPlayingInfoCenter()
            if state != oldValue || state == .waitingForConnection {
                delegate?.audioPlayer(self, didChangeStateFrom: oldValue, toState: state)
            }
        }
    }

    /// The current item being played.
    open fileprivate(set) var currentItem: AudioItem? {
        didSet {
            for keyPath in AudioItem.ap_KVOItems {
                oldValue?.removeObserver(self, forKeyPath: keyPath)
                currentItem?.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
            }

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
                    case .high:
                        return currentItem.highestQualityURL
                    case .medium:
                        return currentItem.mediumQualityURL
                    default:
                        return currentItem.lowestQualityURL
                    }
                    }()

                if (reachability?.isReachable ?? false) || URLInfo.URL.isOfflineURL {
                    state = .buffering
                    beginBackgroundTask()
                }
                else {
                    connectionLossDate = Date()
                    stateWhenConnectionLost = .buffering
                    state = .waitingForConnection
                    beginBackgroundTask()
                    return
                }

                player = AVPlayer(url: URLInfo.URL as URL)
                player?.volume = volume
                currentQuality = URLInfo.quality

                player?.rate = rate

                updateNowPlayingInfoCenter()

                if oldValue != currentItem {
                    delegate?.audioPlayer(self, willStartPlayingItem: currentItem)
                }
            }
            else {
                if let _ = oldValue {
                    stop()
                }
            }
        }
    }

    /// The current item duration or nil if no item or unknown duration.
    open var currentItemDuration: TimeInterval? {
        if let currentItem = player?.currentItem {
            let seconds = CMTimeGetSeconds(currentItem.duration)
            if !seconds.isNaN {
                return TimeInterval(seconds)
            }
        }
        return nil
    }

    /// The current item progression or nil if no item.
    open var currentItemProgression: TimeInterval? {
        if let currentItem = player?.currentItem {
            let seconds = CMTimeGetSeconds(currentItem.currentTime())
            if !seconds.isNaN {
                return TimeInterval(seconds)
            }
        }
        return nil
    }

    /// The current quality being played.
    open fileprivate(set) var currentQuality: AudioQuality?

    public typealias TimeRange = (earliest: TimeInterval, latest: TimeInterval)

    /// The current seekable range.
    open var currentItemSeekableRange: TimeRange? {
        let range = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue
        if let seekableStart = range?.start, let seekableEnd = range?.end {
            return (CMTimeGetSeconds(seekableStart), CMTimeGetSeconds(seekableEnd))
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
    open var currentItemLoadedRange: TimeRange? {
        let range = player?.currentItem?.loadedTimeRanges.last?.timeRangeValue
        if let seekableStart = range?.start, let seekableEnd = range?.end {
            return (CMTimeGetSeconds(seekableStart), CMTimeGetSeconds(seekableEnd))
        }
        return nil
    }


    /// MARK: Public properties

    /// The maximum number of interruption before putting the player to Stopped mode. Default value is 10.
    open var maximumRetryCount = 10

    /// The delay to wait before cancelling last retry and retrying. Default value is 10seconds.
    open var retryTimeout = TimeInterval(10)

    /// Defines whether the player should resume after a system interruption or not. Default value is `true`.
    open var resumeAfterInterruption = true

    /// Defines whether the player should resume after a connection loss or not. Default value is `true`.
    open var resumeAfterConnectionLoss = true

    /// Defines the maximum to wait after a connection loss before putting the player to Stopped mode and cancelling the resume. Default value is 60seconds.
    open var maximumConnectionLossTime = TimeInterval(60)

    /// Defines whether the player should automatically adjust sound quality based on the number of interruption before a delay and the maximum number of interruption whithin this delay. Default value is `true`.
    open var adjustQualityAutomatically = true

    /// Defines the default quality used to play. Default value is `.Medium`
    open var defaultQuality = AudioQuality.medium

    /// Defines the delay within which the player wait for an interruption before upgrading the quality. Default value is 10minutes.
    open var adjustQualityTimeInternal = TimeInterval(10 * 60)

    /// Defines the maximum number of interruption to have within the `adjustQualityTimeInterval` delay before downgrading the quality. Default value is 3.
    open var adjustQualityAfterInterruptionCount = 3

    /// Defines the mode of the player. Default is `.Normal`.
    open var mode: AudioPlayerModeMask = [] {
        didSet {
            adaptQueueToPlayerMode()
        }
    }

    /// Defines the rate of the player. Default value is 1.
    open var rate = Float(1) {
        didSet {
            player?.rate = rate
            updateNowPlayingInfoCenter()
        }
    }

    /// Defines the volume of the player. `1.0` means 100% and `0.0` is 0%.
    open var volume = Float(1) {
        didSet {
            player?.volume = volume
        }
    }

    #if os(iOS) || os(tvOS)
    /// Defines the rate multiplier of the player when the backward/forward buttons are pressed. Default value is 2.
    open var rateMultiplerOnSeeking = Float(2)
    #endif

    /// The delegate that will be called upon special events
    open weak var delegate: AudioPlayerDelegate?


    /// MARK: Public handy functions

    /**
    Play an item.

    - parameter item: The item to play.
    */
    open func playItem(_ item: AudioItem) {
        playItems([item])
    }

    /**
    Plays the first item in `items` and enqueud the rest.

    - parameter items: The items to play.
    */
    open func playItems(_ items: [AudioItem], startAtIndex index: Int = 0) {
        if items.count > 0 {
            var idx = 0
            enqueuedItems = items.map {
                idx += 1
                return (position: idx, item: $0)
            }
            adaptQueueToPlayerMode()

            let startIndex: Int = {
                if index >= items.count || index < 0 {
                    return 0
                }
                return enqueuedItems?.index { $0.position == index } ?? 0
            }()
            currentItemIndexInQueue = startIndex
            currentItem = enqueuedItems?[startIndex].item
        }
        else {
            stop()
            enqueuedItems = nil
            currentItemIndexInQueue = nil
        }
    }

    /**
    Adds an item at the end of the queue. If queue is empty and player isn't
    playing, the behaviour will be similar to `playItem(item: item)`.

    - parameter item: The item to add.
    */
    open func addItemToQueue(_ item: AudioItem) {
        addItemsToQueue([item])
    }

    /**
    Adds items at the end of the queue. If the queue is empty and player isn't
    playing, the behaviour will be similar to `playItems(items: items)`.

    - parameter items: The items to add.
    */
    open func addItemsToQueue(_ items: [AudioItem]) {
        if currentItem != nil {
            var idx = enqueuedItems?.count ?? 0
            var toAdd: [AudioQueueItem] = items.map {
                idx += 1
                return (position: idx, item: $0)
            }
            if mode.contains(.Shuffle) {
                toAdd = toAdd.shuffled()
            }
            enqueuedItems = (enqueuedItems ?? []) + toAdd
        }
        else {
            playItems(items)
        }
    }

    /**
     Removes an item at a specific index in the queue.

     - warning: It asserts that the index is valid for the current "enqueueItems".

     - parameter index: The index of the item to remove.
     */
    open func removeItemAtIndex(_ index: Int) {
        assert(enqueuedItems != nil, "cannot remove an item when queue is nil")
        assert(index >= 0, "cannot remove an item at negative index")
        assert(index < enqueuedItems!.count, "cannot remove an item at an index > queue.count")

        if let enqueuedItems = enqueuedItems {
            if index >= 0 && index < enqueuedItems.count {
                self.enqueuedItems?.remove(at: index)
                if let currentItemIndex = currentItemIndexInQueue,
                    index < currentItemIndex {
                    currentItemIndexInQueue = currentItemIndex - 1
                }
            }
        }
    }

    /**
    Resume the player.
    */
    open func resume() {
        //We ensure the rate is correctly set
        player?.rate = rate

        //We don't wan't to change the state to Playing in case it's Buffering. That
        //would be a lie.
        if state != .playing && state != .buffering {
            state = .playing
        }

        //In case we don't have a retry timer, let's start one.
        //This ensures that the player will eventually restart at some point if the connection
        //was droped by `AVPlayer` (refer to https://github.com/delannoyk/AudioPlayer/issues/21 )
        if retryTimer == nil {
            let target = ClosureContainer() { [weak self] sender in
                self?.retryOrPlayNext()
            }
            let timer = Timer(timeInterval: retryTimeout, target: target, selector: #selector(ClosureContainer.callSelectorOnTarget(_:)), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            retryTimer = timer
        }
    }

    /**
    Pauses the player.
    */
    open func pause() {
        //We ensure the player actually pauses
        player?.rate = 0
        state = .paused
        
        retryTimer?.invalidate()
        retryTimer = nil

        //Let's begin a background task for the player to keep buffering if the app is in
        //background. This will mimic the default behavior of `AVPlayer` when pausing while the
        //app is in foreground.
        beginBackgroundTask()
    }

    /**
    Stops the player and clear the queue.
    */
    open func stop() {
        //Stopping player immediately
        player?.rate = 0

        state = .stopped
        
        retryTimer?.invalidate()
        retryTimer = nil

        enqueuedItems = nil
        currentItem = nil
        player = nil
    }

    /**
    Plays next item in the queue.
    */
    open func next() {
        if let currentItemIndexInQueue = currentItemIndexInQueue, hasNext() {
            //The background task will end when the player will have enough data to play
            beginBackgroundTask()

            let newIndex = currentItemIndexInQueue + 1
            if newIndex < enqueuedItems?.count ?? 0 {
                self.currentItemIndexInQueue = newIndex
                currentItem = enqueuedItems?[newIndex].item
            }
            else if mode.intersection(.RepeatAll) != [] {
                self.currentItemIndexInQueue = 0
                currentItem = enqueuedItems?.first?.item
            }
        }
    }

    /**
    Returns whether there is a next item in the queue or not.

    - returns: A boolean value indicating whether there is a next item to play or not.
    */
    open func hasNext() -> Bool {
        if let enqueuedItems = enqueuedItems, let currentItemIndexInQueue = currentItemIndexInQueue {
            if currentItemIndexInQueue + 1 < enqueuedItems.count || mode.intersection(.RepeatAll) != [] {
                return true
            }
        }
        return false
    }

    /**
    Plays previous item in the queue.
    */
    open func previous() {
        if let currentItemIndexInQueue = currentItemIndexInQueue, let enqueuedItems = enqueuedItems {
            let newIndex = currentItemIndexInQueue - 1
            if newIndex >= 0 {
                self.currentItemIndexInQueue = newIndex
                currentItem = enqueuedItems[newIndex].item
            }
            else if mode.intersection(.RepeatAll) != [] {
                self.currentItemIndexInQueue = enqueuedItems.count - 1
                currentItem = enqueuedItems.last?.item
            }
            else {
                seekToTime(0)
            }
        }
    }

    /**
    Seeks to a specific time.

    - parameter time: The time to seek to.
    */
    open func seekToTime(_ time: TimeInterval, toleranceBefore: CMTime = kCMTimePositiveInfinity, toleranceAfter: CMTime = kCMTimePositiveInfinity, adaptingTimeToSeekableTimeRanges adaptTime: Bool = true) {
        let time = CMTime(seconds: time, preferredTimescale: 1000000000)
        
        // if we specify non-default zero tolerance, skip the range checks: will take longer to play, but necessary for when seek needs to be precise
        if adaptTime {
            let seekableRange = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue
            if let seekableStart = seekableRange?.start, let seekableEnd = seekableRange?.end {
                // check if time is in seekable range
                if time >= seekableStart && time <= seekableEnd {
                    // time is in seekable range
                    player?.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
                }
                else if time < seekableStart {
                    // time is before seekable start, so just move to the most early position as possible
                    seekToSeekableRangeStart(1)
                }
                else if time > seekableEnd {
                    // time is larger than possibly, so just move forward as far as possible
                    seekToSeekableRangeEnd(1)
                }
            }
        } else {
            player?.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        }
        
        updateNowPlayingInfoCenter()
    }
    
    /**
     Seeks forward as far as possible.

     - parameter padding: The padding to apply if any.
     */
    open func seekToSeekableRangeEnd(_ padding: TimeInterval) {
        if let range = currentItemSeekableRange {
            let position = max(range.earliest, range.latest - padding)

            let time = CMTime(seconds: position, preferredTimescale: 1000000000)
            player?.seek(to: time)

            updateNowPlayingInfoCenter()
        }
    }

    /**
     Seeks backwards as far as possible.
     
     - parameter padding: The padding to apply if any.
     */
    open func seekToSeekableRangeStart(_ padding: TimeInterval) {
        if let range = currentItemSeekableRange {
            let position = min(range.latest, range.earliest + padding)

            let time = CMTime(seconds: position, preferredTimescale: 1000000000)
            player?.seek(to: time)

            updateNowPlayingInfoCenter()
        }
    }
    

    #if os(iOS) || os(tvOS)
    /**
     Handle events received from Control Center/Lock screen/Other in UIApplicationDelegate.

     - parameter event: The event received.
     */
    open func remoteControlReceivedWithEvent(_ event: UIEvent) {
        if event.type == .remoteControl {
            //ControlCenter Or Lock screen
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
                if state == .playing {
                    pause()
                }
                else {
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
    fileprivate func updateNowPlayingInfoCenter() {
        #if os(iOS) || os(tvOS)
            if let currentItem = currentItem {
                var info = [String: AnyObject]()
                if let title = currentItem.title {
                    info[MPMediaItemPropertyTitle] = title as AnyObject?
                }
                if let artist = currentItem.artist {
                    info[MPMediaItemPropertyArtist] = artist as AnyObject?
                }
                if let album = currentItem.album {
                    info[MPMediaItemPropertyAlbumTitle] = album as AnyObject?
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
                    info[MPMediaItemPropertyPlaybackDuration] = duration as AnyObject?
                }
                if let progression = currentItemProgression {
                    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression as AnyObject?
                }

                info[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate as AnyObject?? ?? 0 as AnyObject?

                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
            else {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            }
        #endif
    }


    // MARK: Events

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, let object = object as? NSObject {
            if let player = player , object == player {
                switch keyPath {
                case "currentItem.duration":
                    //Duration is available
                    if let currentItem = currentItem {
                        //Let's check for metadata too
                        if let metadata = player.currentItem?.asset.commonMetadata , metadata.count > 0 {
                            currentItem.parseMetadata(metadata)
                            delegate?.audioPlayer(self, didUpdateEmptyMetadataOnItem: currentItem, withData: metadata)
                        }

                        if let currentItemDuration = currentItemDuration , currentItemDuration > 0 {
                            updateNowPlayingInfoCenter()
                            delegate?.audioPlayer(self, didFindDuration: currentItemDuration, forItem: currentItem)
                        }
                    }

                case "currentItem.playbackBufferEmpty":
                    //The buffer is empty and player is loading
                    if state == .playing && !qualityIsBeingChanged {
                        interruptionCount += 1
                    }

                    stateBeforeBuffering = state
                    if (reachability?.isReachable ?? false) || (currentItem?.soundURLs[currentQuality ?? defaultQuality]?.isOfflineURL ?? false) {
                        state = .buffering
                    }
                    else {
                        state = .waitingForConnection
                    }
                    beginBackgroundTask()

                case "currentItem.playbackLikelyToKeepUp":
                    if let playbackLikelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp , playbackLikelyToKeepUp {
                        //There is enough data in the buffer
                        if shouldResumePlaying {
                            stateBeforeBuffering = nil
                            state = .playing
                            player.rate = rate
                        }
                        else {
                            state = .paused
                            player.rate = 0
                        }

                        retryCount = 0

                        //We cancel the retry we might have asked for
                        retryTimer?.invalidate()
                        retryTimer = nil
                        
                        endBackgroundTask()
                    }

                case "currentItem.status":
                    if let item = player.currentItem , item.status == .failed {
                        state = .failed(.foundationError(item.error as NSError?))
                    }

                case "currentItem.loadedTimeRanges":
                    if let currentItem = currentItem, let currentItemLoadedRange = currentItemLoadedRange {
                        delegate?.audioPlayer(self, didLoadRange: currentItemLoadedRange, forItem: currentItem)
                    }

                default:
                    break
                }
            }
            else if let currentItem = currentItem , object == currentItem {
                updateNowPlayingInfoCenter()
            }
        }
    }

    #if os(iOS) || os(tvOS)
    /**
    Audio session got interrupted by the system (call, Siri, ...). If interruption begins,
    we should ensure the audio pauses and if it ends, we should restart playing if state was
    `.Playing` before.

    - parameter note: The notification information.
    */
    @objc fileprivate func audioSessionGotInterrupted(_ note: Notification) {
        if let typeInt = (note as NSNotification).userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSessionInterruptionType(rawValue: typeInt) {
            if type == .began && (state == .playing || state == .buffering) {
                //We pause the player when an interruption is detected
                beginBackgroundTask()
                pausedForInterruption = true
                pause()
            }
            else {
                //We resume the player when the interruption is ended and we paused it in this interruption
                if let optionInt = (note as NSNotification).userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSessionInterruptionOptions(rawValue: optionInt)
                    if (options.intersection(.shouldResume)) != [] && pausedForInterruption {
                        if resumeAfterInterruption {
                            resume()
                        }
                        pausedForInterruption = false
                        endBackgroundTask()
                    }
                }
            }
        }
    }

    /**
    Audio session route changed (ex: earbuds plugged in/out). This can change the player
    state, so we just adapt it.

    - parameter note: The notification information.
    */
    @objc fileprivate func audioSessionRouteChanged(_ note: Notification) {
        if let player = player , player.rate == 0 {
            state = .paused
        }
    }

    /**
    Audio session got messed up (media services lost or reset). We gotta reactive the
    audio session and reset player.

    - parameter note: The notification information.
    */
    @objc fileprivate func audioSessionMessedUp(_ note: Notification) {
        //We reenable the audio session directly in case we're in background
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {}

        //Aaaaand we: restart playing/go to next
        state = .stopped
        interruptionCount += 1
        retryOrPlayNext()
    }
    #endif

    /**
    Playing item did end. We can play next or stop the player if queue is empty.

    - parameter note: The notification information.
    */
    @objc fileprivate func playerItemDidEnd(_ note: Notification) {
        if let sender = note.object as? AVPlayerItem, let currentItem = player?.currentItem , sender == currentItem {
            nextOrStop()
        }
    }

    @objc fileprivate func reachabilityStatusChanged(_ note: Notification) {
        if state == .waitingForConnection {
            if let connectionLossDate = connectionLossDate, reachability?.isReachable ?? false {
                if let stateWhenConnectionLost = stateWhenConnectionLost , stateWhenConnectionLost != .stopped {
                    if fabs(connectionLossDate.timeIntervalSinceNow) < maximumConnectionLossTime {
                        retryOrPlayNext()
                    }
                }
                self.connectionLossDate = nil
            }
        }
        else if state != .stopped && state != .paused {
            if (reachability?.isReachable ?? false) || (currentItem?.soundURLs[currentQuality ?? defaultQuality]?.isOfflineURL ?? false) {
                retryOrPlayNext()
                connectionLossDate = nil
                stateWhenConnectionLost = nil
            }
            else {
                connectionLossDate = Date()
                stateWhenConnectionLost = state
                if let currentItem = player?.currentItem , currentItem.isPlaybackBufferEmpty {
                    if state == .playing && !qualityIsBeingChanged {
                        interruptionCount += 1
                    }
                    state = .waitingForConnection
                    beginBackgroundTask()
                }
            }
        }
    }

    /**
    The current progression was updated. When playing, this method gets called
    very often so we should consider doing as little work as possible in here.

    - parameter time: The current time.
    */
    fileprivate func currentProgressionUpdated(_ time: CMTime) {
        if let currentItemProgression = currentItemProgression, let currentItemDuration = currentItemDuration, let currentItem = player?.currentItem , currentItemDuration > 0 && currentItem.status == .readyToPlay {
            //This fixes the behavior where sometimes the `playbackLikelyToKeepUp`
            //isn't changed even though it's playing (happens mostly at the first play though).
            if state == .buffering || state == .paused {
                if shouldResumePlaying {
                    stateBeforeBuffering = nil
                    state = .playing
                    player?.rate = rate
                }
                else {
                    state = .paused
                    player?.rate = 0
                }
                endBackgroundTask()
            }

            //Then we can call the didUpdateProgressionToTime: delegate method
            let percentage = Float(currentItemProgression / currentItemDuration) * 100
            delegate?.audioPlayer(self, didUpdateProgressionToTime: currentItemProgression, percentageRead: percentage)
        }
    }


    // MARK: Retrying

    /**
    This will retry to play current item and seek back at the correct position if possible (or enabled). If not,
    it'll just play the next item in queue.
    */
    fileprivate func retryOrPlayNext() {
        if state == .playing {
            retryTimer?.invalidate()
            retryTimer = nil
            return
        }

        if maximumRetryCount > 0 && retryCount < maximumRetryCount {
            //We can retry
            let cip = currentItemProgression
            let ci = currentItem

            currentItem = ci
            if let cip = cip {
                //We can't call self.seekToTime in here since the player is new
                //and `cip` is probably not in the seekableTimeRanges.
                player?.seek(to: CMTime(seconds: cip, preferredTimescale: 1000000000))
            }

            retryCount += 1

            //We gonna cancel this current retry and create a new one if the player isn't playing after a certain delay
            let target = ClosureContainer() { [weak self] sender in
                self?.retryOrPlayNext()
            }
            let timer = Timer(timeInterval: retryTimeout, target: target, selector: #selector(ClosureContainer.callSelectorOnTarget(_:)), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            retryTimer = timer
        }
        else {
            retryTimer?.invalidate()
            retryTimer = nil
            retryCount = 0
            state = .failed(.maximumRetryCountHit)
        }
    }

    fileprivate func nextOrStop() {
        if mode.intersection(.Repeat) != [] {
            seekToTime(0)
            resume()
            
            if let currentItem = self.currentItem {
                delegate?.audioPlayer(self, willStartPlayingItem: currentItem)
            }
        }
        else if hasNext() {
            next()
        }
        else {
            stop()
        }
    }


    // MARK: Quality adjustment

    /**
    Adjusts quality if necessary based on interruption count.
    */
    fileprivate func adjustQualityIfNecessary() {
        if let currentQuality = currentQuality , adjustQualityAutomatically {
            if interruptionCount >= adjustQualityAfterInterruptionCount {
                //Decreasing audio quality
                let URLInfo: AudioItemURL? = {
                    if currentQuality == .high {
                        return self.currentItem?.mediumQualityURL
                    }
                    if currentQuality == .medium {
                        return self.currentItem?.lowestQualityURL
                    }
                    return nil
                    }()

                if let URLInfo = URLInfo , URLInfo.quality != currentQuality {
                    let cip = currentItemProgression
                    let item = AVPlayerItem(url: URLInfo.URL as URL)

                    qualityIsBeingChanged = true
                    player?.replaceCurrentItem(with: item)
                    if let cip = cip {
                        //We can't call self.seekToTime in here since the player is loading a new
                        //item and `cip` is probably not in the seekableTimeRanges.
                        player?.seek(to: CMTime(seconds: cip, preferredTimescale: 1000000000))
                    }
                    qualityIsBeingChanged = false

                    self.currentQuality = URLInfo.quality
                }
            }
            else if interruptionCount == 0 {
                //Increasing audio quality
                let URLInfo: AudioItemURL? = {
                    if currentQuality == .low {
                        return self.currentItem?.mediumQualityURL
                    }
                    if currentQuality == .medium {
                        return self.currentItem?.highestQualityURL
                    }
                    return nil
                    }()

                if let URLInfo = URLInfo , URLInfo.quality != currentQuality {
                    let cip = currentItemProgression
                    let item = AVPlayerItem(url: URLInfo.URL as URL)

                    qualityIsBeingChanged = true
                    player?.replaceCurrentItem(with: item)
                    if let cip = cip {
                        //We can't call self.seekToTime in here since the player is loading a new
                        //item and `cip` is probably not in the seekableTimeRanges.
                        player?.seek(to: CMTime(seconds: cip, preferredTimescale: 1000000000))
                    }
                    qualityIsBeingChanged = false

                    self.currentQuality = URLInfo.quality
                }
            }

            interruptionCount = 0

            let target = ClosureContainer() { [weak self] sender in
                self?.adjustQualityIfNecessary()
            }
            let timer = Timer(timeInterval: adjustQualityTimeInternal, target: target, selector: #selector(ClosureContainer.callSelectorOnTarget(_:)), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            qualityAdjustmentTimer = timer
        }
    }


    // MARK: Background

    /// The backround task identifier if a background task started. Nil if not.
    fileprivate var backgroundTaskIdentifier: Int?

    /**
    Starts a background task if there isn't already one running.
    */
    fileprivate func beginBackgroundTask() {
        #if os(iOS) || os(tvOS)
            if backgroundTaskIdentifier == nil {
                backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask (expirationHandler: { [weak self] in
                    if let backgroundTaskIdentifier = self?.backgroundTaskIdentifier {
                        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                    }
                    self?.backgroundTaskIdentifier = nil
                })
            }
        #endif
    }
    
    /**
    Ends the background task if there is one.
    */
    fileprivate func endBackgroundTask() {
        #if os(iOS) || os(tvOS)
            if let backgroundTaskIdentifier = backgroundTaskIdentifier {
                if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                }
                self.backgroundTaskIdentifier = nil
            }
        #endif
    }

    
    // MARK: Mode
    
    /**
    Sorts the queue depending on the current mode.
    */
    fileprivate func adaptQueueToPlayerMode() {
        if mode.intersection(.Shuffle) != [] {
            enqueuedItems = enqueuedItems?.shuffled()
        }
        else {
            enqueuedItems = enqueuedItems?.sorted(by: { $0.position < $1.position })
        }
    }
}
