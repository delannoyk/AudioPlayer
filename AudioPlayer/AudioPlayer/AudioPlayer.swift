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
    let closure: (sender: AnyObject) -> ()

    init(closure: (sender: AnyObject) -> ()) {
        self.closure = closure
    }

    @objc func callSelectorOnTarget(sender: AnyObject) {
        closure(sender: sender)
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
    case Buffering
    case Playing
    case Paused
    case Stopped
    case WaitingForConnection
    case Failed(NSError?)
}

extension AudioPlayerState: Equatable { }

public func ==(lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
    switch (lhs, rhs) {
    case (.Buffering, .Buffering):
        return true
    case (.Playing, .Playing):
        return true
    case (.Paused, .Paused):
        return true
    case (.Stopped, .Stopped):
        return true
    case (.WaitingForConnection, .WaitingForConnection):
        return true
    case (.Failed(let e1), .Failed(let e2)):
        return e1 == e2
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
public struct AudioPlayerModeMask: OptionSetType {
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
    func observe(name: String, selector: Selector, object: AnyObject? = nil) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: object)
    }

    func unobserve(name: String, object: AnyObject? = nil) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: name, object: object)
    }
}


// MARK: - Array+Shuffe

private extension Array {
    func shuffled() -> [Element] {
        return sort { e1, e2 in
            random() % 2 == 0
        }
    }
}


// MARK: - NSURL+iPodLibrary

private extension NSURL {
    var isOfflineURL: Bool {
        return fileURL || scheme == "ipod-library" || host == "localhost"
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
public protocol AudioPlayerDelegate: NSObjectProtocol {
    /**
     This method is called when the audio player changes its state.
     A fresh created audioPlayer starts in `.Stopped` mode.

     - parameter audioPlayer: The audio player.
     - parameter from:        The state before any changes.
     - parameter to:          The new state.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState)

    /**
     This method is called when the audio player is about to start playing
     a new item.

     - parameter audioPlayer: The audio player.
     - parameter item:        The item that is about to start being played.
     */
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem)

    /**
     This method is called a regular time interval while playing. It notifies
     the delegate that the current playing progression changed.

     - parameter audioPlayer:    The audio player.
     - parameter time:           The current progression.
     - parameter percentageRead: The percentage of the file that has been read. 
                                 It's a Float value between 0 & 100 so that you can
                                easily update an `UISlider` for example.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float)

    /**
     This method gets called when the current item duration has been found.

     - parameter audioPlayer: The audio player.
     - parameter duration:    Current item's duration.
     - parameter item:        Current item.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem)

    /**
     This methods gets called before duration gets updated with discovered metadata.

     - parameter audioPlayer: The audio player.
     - parameter item:        Found metadata.
     - parameter data:        Current item.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateEmptyMetadataOnItem item: AudioItem, withData data: Metadata)

    /**
     This method gets called while the audio player is loading the file (over
     the network or locally). It lets the delegate know what time range has
     already been loaded.

     - parameter audioPlayer: The audio player.
     - parameter range:       The time range that the audio player loaded.
     - parameter item:        Current item.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didLoadRange range: AudioPlayer.TimeRange, forItem item: AudioItem)
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
        super.init()

        observe(ReachabilityChangedNotification, selector: "reachabilityStatusChanged:", object: reachability)
        reachability.startNotifier()
    }

    deinit {
        reachability.stopNotifier()
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
    private var player: AVPlayer? {
        didSet {
            //Gotta unobserver & observe if necessary
            for keyPath in AVPlayer.ap_KVOItems {
                oldValue?.removeObserver(self, forKeyPath: keyPath)
                player?.addObserver(self, forKeyPath: keyPath, options: .New, context: nil)
            }

            if let oldValue = oldValue {
                qualityAdjustmentTimer?.invalidate()
                qualityAdjustmentTimer = nil

                if let timeObserver = timeObserver {
                    oldValue.removeTimeObserver(timeObserver)
                }
                timeObserver = nil

                #if os(iOS) || os(tvOS)
                    unobserve(AVAudioSessionInterruptionNotification)
                    unobserve(AVAudioSessionRouteChangeNotification)
                    unobserve(AVAudioSessionMediaServicesWereLostNotification)
                    unobserve(AVAudioSessionMediaServicesWereResetNotification)
                #endif
                unobserve(AVPlayerItemDidPlayToEndTimeNotification)
            }

            if let player = player {
                //Creating the qualityAdjustment timer
                let target = ClosureContainer() { [weak self] sender in
                    self?.adjustQualityIfNecessary()
                }
                let timer = NSTimer(timeInterval: adjustQualityTimeInternal, target: target, selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                qualityAdjustmentTimer = timer

                timeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 2), queue: dispatch_get_main_queue()) { [weak self] time in
                    self?.currentProgressionUpdated(time)
                }

                if #available(OSX 10.11, *) {
                    player.allowsExternalPlayback = false
                }

                #if os(iOS) || os(tvOS)
                    observe(AVAudioSessionInterruptionNotification, selector: "audioSessionGotInterrupted:")
                    observe(AVAudioSessionRouteChangeNotification, selector: "audioSessionRouteChanged:")
                    observe(AVAudioSessionMediaServicesWereLostNotification, selector: "audioSessionMessedUp:")
                    observe(AVAudioSessionMediaServicesWereResetNotification, selector: "audioSessionMessedUp:")
                #endif
                observe(AVPlayerItemDidPlayToEndTimeNotification, selector: "playerItemDidEnd:")
            }
        }
    }

    private typealias AudioQueueItem = (position: Int, item: AudioItem)

    /// The queue containing items to play.
    private var enqueuedItems: [AudioQueueItem]?

    public var items: [AudioItem]? {
        return enqueuedItems?.map { $0.item }
    }

    /// A boolean value indicating whether the player has been paused because of a system interruption.
    private var pausedForInterruption = false
    
    /// The state before the player went into .Buffering. It helps to know whether to restart or not the player.
    private var stateBeforeBuffering: AudioPlayerState?
    
    /// The time observer
    private var timeObserver: AnyObject?

    /// The number of interruption since last quality adjustment/begin playing
    private var interruptionCount = 0 {
        didSet {
            if adjustQualityAutomatically && interruptionCount > adjustQualityAfterInterruptionCount {
                adjustQualityIfNecessary()
            }
        }
    }

    /// A boolean value indicating if quality is being changed. It's necessary for the interruption count to not be incremented while new quality is buffering.
    private var qualityIsBeingChanged = false

    /// The current number of retry we already tried
    private var retryCount = 0

    /// The timer used to cancel a retry and make a new one
    private var retryTimer: NSTimer?

    /// The timer used to adjust quality
    private var qualityAdjustmentTimer: NSTimer?

    /// The state of the player when the connection was lost
    private var stateWhenConnectionLost: AudioPlayerState?

    /// The date of the connection loss
    private var connectionLossDate: NSDate?

    /// The index of the current item in the queue
    public private(set) var currentItemIndexInQueue: Int?

    /// Reachability for network connection
    private let reachability = Reachability.reachabilityForInternetConnection()

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
                delegate?.audioPlayer(self, didChangeStateFrom: oldValue, toState: state)
            }
        }
    }

    /// The current item being played.
    public private(set) var currentItem: AudioItem? {
        didSet {
            for keyPath in AudioItem.ap_KVOItems {
                oldValue?.removeObserver(self, forKeyPath: keyPath)
                currentItem?.addObserver(self, forKeyPath: keyPath, options: .New, context: nil)
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
                }
                else {
                    connectionLossDate = nil
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
            }
            else {
                if let _ = oldValue {
                    stop()
                }
            }
        }
    }

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

    public typealias TimeRange = (earliest: NSTimeInterval, latest: NSTimeInterval)

    /// The current seekable range.
    public var currentItemSeekableRange: TimeRange? {
        let range = player?.currentItem?.seekableTimeRanges.last?.CMTimeRangeValue
        if let seekableStart = range?.start, seekableEnd = range?.end {
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
    public var currentItemLoadedRange: TimeRange? {
        let range = player?.currentItem?.loadedTimeRanges.last?.CMTimeRangeValue
        if let seekableStart = range?.start, seekableEnd = range?.end {
            return (CMTimeGetSeconds(seekableStart), CMTimeGetSeconds(seekableEnd))
        }
        return nil
    }


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
    public var mode: AudioPlayerModeMask = [] {
        didSet {
            adaptQueueToPlayerMode()
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
    /// Defines the rate multiplier of the player when the backward/forward buttons are pressed. Default value is 2.
    public var rateMultiplerOnSeeking = Float(2)
    #endif

    /// The delegate that will be called upon special events
    public weak var delegate: AudioPlayerDelegate?


    /// MARK: Public handy functions

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
    */
    public func playItems(items: [AudioItem], startAtIndex index: Int = 0) {
        if items.count > 0 {
            var idx = 0
            enqueuedItems = items.map { (position: idx++, item: $0) }
            adaptQueueToPlayerMode()

            let startIndex: Int = {
                if index >= items.count || index < 0 {
                    return 0
                }
                return enqueuedItems?.indexOf { $0.position == index } ?? 0
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
    public func addItemToQueue(item: AudioItem) {
        addItemsToQueue([item])
    }

    /**
    Adds items at the end of the queue. If the queue is empty and player isn't
    playing, the behaviour will be similar to `playItems(items: items)`.

    - parameter items: The items to add.
    */
    public func addItemsToQueue(items: [AudioItem]) {
        if currentItem != nil {
            var idx = 0
            enqueuedItems = (enqueuedItems ?? []) + items.map { (position: idx++, item: $0) }
            adaptQueueToPlayerMode()
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
    public func removeItemAtIndex(index: Int) {
        assert(enqueuedItems != nil, "cannot remove an item when queue is nil")
        assert(index >= 0, "cannot remove an item at negative index")
        assert(index < enqueuedItems?.count, "cannot remove an item at an index > queue.count")

        if let enqueuedItems = enqueuedItems {
            if index >= 0 && index < enqueuedItems.count {
                self.enqueuedItems?.removeAtIndex(index)
            }
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

        enqueuedItems = nil
        currentItem = nil
        player = nil
    }

    /**
    Plays next item in the queue.
    */
    public func next() {
        if let currentItemIndexInQueue = currentItemIndexInQueue where hasNext() {
            //The background task will end when the player will have enough data to play
            beginBackgroundTask()
            //pause()

            let newIndex = currentItemIndexInQueue + 1
            if newIndex < enqueuedItems?.count {
                self.currentItemIndexInQueue = newIndex
                currentItem = enqueuedItems?[newIndex].item
            }
            else if mode.intersect(.RepeatAll) != [] {
                self.currentItemIndexInQueue = 0
                currentItem = enqueuedItems?.first?.item
            }
        }
    }

    /**
    Returns whether there is a next item in the queue or not.

    - returns: A boolean value indicating whether there is a next item to play or not.
    */
    public func hasNext() -> Bool {
        if let enqueuedItems = enqueuedItems, currentItemIndexInQueue = currentItemIndexInQueue {
            if currentItemIndexInQueue + 1 < enqueuedItems.count || mode.intersect(.RepeatAll) != [] {
                return true
            }
        }
        return false
    }

    /**
    Plays previous item in the queue.
    */
    public func previous() {
        if let currentItemIndexInQueue = currentItemIndexInQueue, enqueuedItems = enqueuedItems {
            let newIndex = currentItemIndexInQueue - 1
            if newIndex >= 0 {
                self.currentItemIndexInQueue = newIndex
                currentItem = enqueuedItems[newIndex].item
            }
            else if mode.intersect(.RepeatAll) != [] {
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
    public func seekToTime(time: NSTimeInterval, toleranceBefore: CMTime = kCMTimePositiveInfinity, toleranceAfter: CMTime = kCMTimePositiveInfinity) {
        let time = CMTime(seconds: time, preferredTimescale: 1000000000)
        let seekableRange = player?.currentItem?.seekableTimeRanges.last?.CMTimeRangeValue
        if let seekableStart = seekableRange?.start, let seekableEnd = seekableRange?.end {
            // check if time is in seekable range
            if time >= seekableStart && time <= seekableEnd {
                // time is in seekable range
                player?.seekToTime(time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
            }
            else if time < seekableStart {
                // time is before seekable start, so just move to the most early position as possible
                seekToSeekableRangeStart(1)
            }
            else if time > seekableEnd {
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

            let time = CMTime(seconds: position, preferredTimescale: 1000000000)
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

            let time = CMTime(seconds: position, preferredTimescale: 1000000000)
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
            }
            else {
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
            }
        #endif
    }


    // MARK: Events

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let keyPath = keyPath, object = object as? NSObject {
            if let player = player where object == player {
                switch keyPath {
                case "currentItem.duration":
                    //Duration is available
                    if let currentItem = currentItem {
                        //Let's check for metadata too
                        if let metadata = player.currentItem?.asset.commonMetadata where metadata.count > 0 {
                            currentItem.parseMetadata(metadata)
                            delegate?.audioPlayer(self, didUpdateEmptyMetadataOnItem: currentItem, withData: metadata)
                        }

                        if let currentItemDuration = currentItemDuration where currentItemDuration > 0 {
                            updateNowPlayingInfoCenter()
                            delegate?.audioPlayer(self, didFindDuration: currentItemDuration, forItem: currentItem)
                        }
                    }

                case "currentItem.playbackBufferEmpty":
                    //The buffer is empty and player is loading
                    if state == .Playing && !qualityIsBeingChanged {
                        interruptionCount++
                    }

                    stateBeforeBuffering = state
                    if reachability.isReachable() || (currentItem?.soundURLs[currentQuality ?? defaultQuality]?.isOfflineURL ?? false) {
                        state = .Buffering
                    }
                    else {
                        state = .WaitingForConnection
                    }
                    beginBackgroundTask()

                case "currentItem.playbackLikelyToKeepUp":
                    if let playbackLikelyToKeepUp = player.currentItem?.playbackLikelyToKeepUp where playbackLikelyToKeepUp {
                        //There is enough data in the buffer
                        if shouldResumePlaying {
                            stateBeforeBuffering = nil
                            state = .Playing
                            player.rate = rate
                        }
                        else {
                            state = .Paused
                        }

                        retryCount = 0

                        //We cancel the retry we might have asked for
                        retryTimer?.invalidate()
                        retryTimer = nil
                        
                        endBackgroundTask()
                    }

                case "currentItem.status":
                    if let item = player.currentItem where item.status == .Failed {
                        state = .Failed(item.error)
                        nextOrStop()
                    }

                case "currentItem.loadedTimeRanges":
                    if let currentItem = currentItem, currentItemLoadedRange = currentItemLoadedRange {
                        delegate?.audioPlayer(self, didLoadRange: currentItemLoadedRange, forItem: currentItem)
                    }

                default:
                    break
                }
            }
            else if let currentItem = currentItem where object == currentItem {
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
    @objc private func audioSessionGotInterrupted(note: NSNotification) {
        if let typeInt = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, type = AVAudioSessionInterruptionType(rawValue: typeInt) {
            if type == .Began && (state == .Playing || state == .Buffering) {
                //We pause the player when an interruption is detected
                beginBackgroundTask()
                pausedForInterruption = true
                pause()
            }
            else {
                //We resume the player when the interruption is ended and we paused it in this interruption
                if let optionInt = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSessionInterruptionOptions(rawValue: optionInt)
                    if (options.intersect(.ShouldResume)) != [] && pausedForInterruption {
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
    @objc private func audioSessionRouteChanged(note: NSNotification) {
        if let player = player where player.rate == 0 {
            state = .Paused
        }
    }

    /**
    Audio session got messed up (media services lost or reset). We gotta reactive the
    audio session and reset player.

    - parameter note: The notification information.
    */
    @objc private func audioSessionMessedUp(note: NSNotification) {
        //We reenable the audio session directly in case we're in background
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {}

        //Aaaaand we: restart playing/go to next
        state = .Stopped
        interruptionCount++
        retryOrPlayNext()
    }
    #endif

    /**
    Playing item did end. We can play next or stop the player if queue is empty.

    - parameter note: The notification information.
    */
    @objc private func playerItemDidEnd(note: NSNotification) {
        if let sender = note.object as? AVPlayerItem, currentItem = player?.currentItem where sender == currentItem {
            nextOrStop()
        }
    }

    @objc private func reachabilityStatusChanged(note: NSNotification) {
        if state == .WaitingForConnection {
            if let connectionLossDate = connectionLossDate where reachability.isReachable() {
                if let stateWhenConnectionLost = stateWhenConnectionLost where stateWhenConnectionLost != .Stopped {
                    if fabs(connectionLossDate.timeIntervalSinceNow) < maximumConnectionLossTime {
                        retryOrPlayNext()
                    }
                }
                self.connectionLossDate = nil
            }
        }
        else if state != .Stopped && state != .Paused {
            if reachability.isReachable() || (currentItem?.soundURLs[currentQuality ?? defaultQuality]?.isOfflineURL ?? false) {
                retryOrPlayNext()
                connectionLossDate = nil
                stateWhenConnectionLost = nil
            }
            else {
                connectionLossDate = NSDate()
                stateWhenConnectionLost = state
            }
        }
    }

    /**
    The current progression was updated. When playing, this method gets called
    very often so we should consider doing as little work as possible in here.

    - parameter time: The current time.
    */
    private func currentProgressionUpdated(time: CMTime) {
        if let currentItemProgression = currentItemProgression, currentItemDuration = currentItemDuration where currentItemDuration > 0 {
            //This fixes the behavior where sometimes the `playbackLikelyToKeepUp`
            //isn't changed even though it's playing (happens mostly at the first play though).
            if state == .Buffering || state == .Paused {
                if shouldResumePlaying {
                    stateBeforeBuffering = nil
                    state = .Playing
                    player?.rate = rate
                }
                else {
                    state = .Paused
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
                let target = ClosureContainer() { [weak self] sender in
                    self?.retryOrPlayNext()
                }
                let timer = NSTimer(timeInterval: retryTimeout, target: target, selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                retryTimer = timer

                return
            }
            else {
                retryCount = 0
            }
        }

        nextOrStop()
    }

    private func nextOrStop() {
        if mode.intersect(.Repeat) != [] {
            seekToTime(0)
            resume()
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
    private func adjustQualityIfNecessary() {
        if let currentQuality = currentQuality where adjustQualityAutomatically {
            if interruptionCount >= adjustQualityAfterInterruptionCount {
                //Decreasing audio quality
                let URLInfo: AudioItemURL? = {
                    if currentQuality == .High {
                        return self.currentItem?.mediumQualityURL
                    }
                    if currentQuality == .Medium {
                        return self.currentItem?.lowestQualityURL
                    }
                    return nil
                    }()

                if let URLInfo = URLInfo where URLInfo.quality != currentQuality {
                    let cip = currentItemProgression
                    let item = AVPlayerItem(URL: URLInfo.URL)

                    qualityIsBeingChanged = true
                    player?.replaceCurrentItemWithPlayerItem(item)
                    if let cip = cip {
                        seekToTime(cip)
                    }
                    qualityIsBeingChanged = false

                    self.currentQuality = URLInfo.quality
                }
            }
            else if interruptionCount == 0 {
                //Increasing audio quality
                let URLInfo: AudioItemURL? = {
                    if currentQuality == .Low {
                        return self.currentItem?.mediumQualityURL
                    }
                    if currentQuality == .Medium {
                        return self.currentItem?.highestQualityURL
                    }
                    return nil
                    }()

                if let URLInfo = URLInfo where URLInfo.quality != currentQuality {
                    let cip = currentItemProgression
                    let item = AVPlayerItem(URL: URLInfo.URL)

                    qualityIsBeingChanged = true
                    player?.replaceCurrentItemWithPlayerItem(item)
                    if let cip = cip {
                        seekToTime(cip)
                    }
                    qualityIsBeingChanged = false

                    self.currentQuality = URLInfo.quality
                }
            }

            interruptionCount = 0

            let target = ClosureContainer() { [weak self] sender in
                self?.adjustQualityIfNecessary()
            }
            let timer = NSTimer(timeInterval: adjustQualityTimeInternal, target: target, selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
            NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            qualityAdjustmentTimer = timer
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

    
    // MARK: Mode
    
    /**
    Sorts the queue depending on the current mode.
    */
    private func adaptQueueToPlayerMode() {
        if mode.intersect(.Shuffle) != [] {
            enqueuedItems = enqueuedItems?.shuffled()
        }
        else {
            enqueuedItems = enqueuedItems?.sort({ $0.position < $1.position })
        }
    }
}
