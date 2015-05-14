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

- `Buffering`:            Represents that the player is buffering data before playing them.
- `Playing`:              Represents that the player is playing.
- `Paused`:               Represents that the player is paused.
- `Stopped`:              Represents that the player is stopped.
- `WaitingForConnection`: Represents the state where the player is waiting for internet connection.
*/
public enum AudioPlayerState {
    case Buffering
    case Playing
    case Paused
    case Stopped
    case WaitingForConnection
}


// MARK: - AudioPlayerMode

public struct AudioPlayerModeMask: RawOptionSetType {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public init(nilLiteral: ()) {
        rawValue = 0
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
        return .Normal
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


// MARK: - AVPlayer+KVO

private extension AVPlayer {
    static var ap_KVOItems: [String] {
        return [
            "currentItem.playbackBufferEmpty",
            "currentItem.playbackLikelyToKeepUp",
            "currentItem.duration"
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
    func shuffled() -> [T] {
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
}


// MARK: - AudioPlayerDelegate

public protocol AudioPlayerDelegate: NSObjectProtocol {
    func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState)
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem)
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float)
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem)

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

        currentItem = nil
        enqueuedItems = nil
        player = nil

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

                oldValue.removeTimeObserver(timeObserver)
                timeObserver = nil

                unobserve(AVAudioSessionInterruptionNotification)
                unobserve(AVAudioSessionRouteChangeNotification)
                unobserve(AVAudioSessionMediaServicesWereLostNotification)
                unobserve(AVAudioSessionMediaServicesWereResetNotification)
                unobserve(AVPlayerItemDidPlayToEndTimeNotification)
            }

            if let player = player {
                //Creating the qualityAdjustment timer
                let target = ClosureContainer(closure: { [weak self] sender in
                    self?.adjustQualityIfNecessary()
                    })
                let timer = NSTimer(timeInterval: adjustQualityTimeInternal, target: target, selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                qualityAdjustmentTimer = timer

                timeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 2), queue: dispatch_get_main_queue(), usingBlock: {[weak self] time in
                    self?.currentProgressionUpdated(time)
                    })

                observe(AVAudioSessionInterruptionNotification, selector: "audioSessionGotInterrupted:")
                observe(AVAudioSessionRouteChangeNotification, selector: "audioSessionRouteChanged:")
                observe(AVAudioSessionMediaServicesWereLostNotification, selector: "audioSessionMessedUp:")
                observe(AVAudioSessionMediaServicesWereResetNotification, selector: "audioSessionMessedUp:")
                observe(AVPlayerItemDidPlayToEndTimeNotification, selector: "playerItemDidEnd:")
            }
        }
    }

    private typealias AudioQueueItem = (position: Int, item: AudioItem)

    /// The queue containing items to play.
    private var enqueuedItems: [AudioQueueItem]?

    /// A boolean value indicating whether the player has been paused because of a system interruption.
    private var pausedForInterruption = false

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
    private var currentItemIndexInQueue: Int?

    /// Reachability for network connection
    private let reachability = Reachability.reachabilityForInternetConnection()


    // MARK: Readonly properties

    /// The current state of the player.
    public private(set) var state: AudioPlayerState {
        didSet {
            if state != oldValue {
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
                AVAudioSession.sharedInstance().setActive(true, error: nil)
                AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)

                player?.pause()
                player = nil
                state = .Stopped

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

                if reachability.isReachable() || URLInfo.URL.isFileReferenceURL() {
                    state = .Buffering
                }
                else {
                    connectionLossDate = nil
                    stateWhenConnectionLost = .Buffering
                    state = .WaitingForConnection
                    return
                }

                state = .Buffering
                player = AVPlayer(URL: URLInfo.URL)
                player?.rate = rate
                player?.volume = volume
                currentQuality = URLInfo.quality

                player?.play()
                updateNowPlayingInfoCenter()

                if oldValue == currentItem {
                    delegate?.audioPlayer(self, willStartPlayingItem: currentItem)
                }
            }
            else {
                if let oldValue = oldValue {
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
    public var mode = AudioPlayerModeMask.Normal {
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

    /// Defines the rate multiplier of the player when the backward/forward buttons are pressed. Default value is 2.
    public var rateMultiplerOnSeeking = Float(2)

    /// The delegate that will be called upon special events
    public weak var delegate: AudioPlayerDelegate?


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
            var idx = 0
            enqueuedItems = items.map { (position: idx++, item: $0) }
            adaptQueueToPlayerMode()

            currentItem = enqueuedItems?.first?.item
            currentItemIndexInQueue = 0
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

    :param: item The item to add.
    */
    public func addItemToQueue(item: AudioItem) {
        addItemsToQueue([item])
    }

    /**
    Adds items at the end of the queue. If the queue is empty and player isn't
    playing, the behaviour will be similar to `playItems(items: items)`.

    :param: items The items to add.
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
            pause()

            let newIndex = currentItemIndexInQueue + 1
            if newIndex < enqueuedItems?.count {
                self.currentItemIndexInQueue = newIndex
                currentItem = enqueuedItems?[newIndex].item
            }
            else if mode & .RepeatAll != .Normal {
                self.currentItemIndexInQueue = 0
                currentItem = enqueuedItems?.first?.item
            }
        }
    }

    /**
    Returns whether there is a next item in the queue or not.

    :returns: A boolean value indicating whether there is a next item to play or not.
    */
    public func hasNext() -> Bool {
        if let enqueuedItems = enqueuedItems, currentItemIndexInQueue = currentItemIndexInQueue {
            if currentItemIndexInQueue + 1 < enqueuedItems.count || mode & .RepeatAll != .Normal {
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
            else if mode & .RepeatAll != .Normal {
                self.currentItemIndexInQueue = enqueuedItems.count - 1
                currentItem = enqueuedItems.last?.item
            }
        }
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

            info[MPNowPlayingInfoPropertyPlaybackRate] = rate

            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
        }
        else {
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
        }
    }


    // MARK: Events

    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let player = player where player == object as! NSObject {
            switch keyPath {
            case "currentItem.duration":
                //Duration is available
                updateNowPlayingInfoCenter()

                if let currentItem = currentItem, currentItemDuration = currentItemDuration where currentItemDuration > 0 {
                    delegate?.audioPlayer(self, didFindDuration: currentItemDuration, forItem: currentItem)
                }

            case "currentItem.playbackBufferEmpty":
                //The buffer is empty and player is loading
                if state == .Playing && !qualityIsBeingChanged {
                    interruptionCount++
                }
                state = .Buffering
                beginBackgroundTask()

            case "currentItem.playbackLikelyToKeepUp":
                //There is enough data in the buffer
                if !pausedForInterruption && (stateWhenConnectionLost == nil || stateWhenConnectionLost != .Paused) {
                    state = .Playing
                    player.play()
                }
                else {
                    state = .Paused
                }

                retryCount = 0

                //We cancel the retry we might have asked for
                retryTimer?.invalidate()
                retryTimer = nil

                endBackgroundTask()

            default:
                break
            }
        }
        else if let currentItem = currentItem where currentItem == object as! NSObject {
            updateNowPlayingInfoCenter()
        }
    }

    /**
    Audio session got interrupted by the system (call, Siri, ...). If interruption begins,
    we should ensure the audio pauses and if it ends, we should restart playing if state was
    `.Playing` before.

    :param: note The notification information.
    */
    @objc private func audioSessionGotInterrupted(note: NSNotification) {
        if let typeInt = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, type = AVAudioSessionInterruptionType(rawValue: typeInt) {
            if type == .Began && (state == .Playing || state == .Buffering) {
                //We pause the player when an interruption is detected
                pausedForInterruption = true
                pause()
            }
            else {
                //We resume the player when the interruption is ended and we paused it in this interruption
                if let optionInt = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSessionInterruptionOptions(rawValue: optionInt)
                    if (options & .OptionShouldResume) != .allZeros && pausedForInterruption {
                        if resumeAfterInterruption {
                            resume()
                        }
                        pausedForInterruption = false
                    }
                }
            }
        }
    }

    /**
    Audio session route changed (ex: earbuds plugged in/out). This can change the player
    state, so we just adapt it.

    :param: note The notification information.
    */
    @objc private func audioSessionRouteChanged(note: NSNotification) {
        if let player = player where player.rate == 0 {
            state = .Paused
        }
    }

    /**
    Audio session got messed up (media services lost or reset). We gotta reactive the
    audio session and reset player.

    :param: note The notification information.
    */
    @objc private func audioSessionMessedUp(note: NSNotification) {
        //We reenable the audio session directly in case we're in background
        AVAudioSession.sharedInstance().setActive(true, error: nil)
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)

        //Aaaaand we: restart playing/go to next
        state = .Stopped
        interruptionCount++
        retryOrPlayNext()
    }

    /**
    Playing item did end. We can play next or stop the player if queue is empty.

    :param: note The notification information.
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
        else if state != .Stopped {
            if reachability.isReachable() {
                retryOrPlayNext()
                connectionLossDate = nil
                stateWhenConnectionLost = nil
            }
            else {
                connectionLossDate = NSDate()
                stateWhenConnectionLost = state
                state = .WaitingForConnection
            }
        }
    }

    /**
    The current progression was updated. When playing, this method gets called
    very often so we should consider doing as little work as possible in here.

    :param: time The current time.
    */
    private func currentProgressionUpdated(time: CMTime) {
        if let currentItemProgression = currentItemProgression, currentItemDuration = currentItemDuration where currentItemDuration > 0 {
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
                let target = ClosureContainer(closure: { [weak self] sender in
                    self?.retryOrPlayNext()
                    })
                let timer = NSTimer(timeInterval: retryTimeout, target: target, selector: "callSelectorOnTarget:", userInfo: nil, repeats: false)
                NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                retryTimer = timer
            }
            else {
                retryCount = 0
            }
        }

        nextOrStop()
    }

    private func nextOrStop() {
        if mode & .Repeat != .Normal {
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

            let target = ClosureContainer(closure: { [weak self] sender in
                self?.adjustQualityIfNecessary()
                })
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
        if backgroundTaskIdentifier == nil {
            UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({[weak self] () -> Void in
                self?.backgroundTaskIdentifier = nil
                })
        }
    }
    
    /**
    Ends the background task if there is one.
    */
    private func endBackgroundTask() {
        if let backgroundTaskIdentifier = backgroundTaskIdentifier {
            if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(backgroundTaskIdentifier)
            }
            self.backgroundTaskIdentifier = nil
        }
    }
    
    
    // MARK: Mode
    
    /**
    Sorts the queue depending on the current mode.
    */
    private func adaptQueueToPlayerMode() {
        if mode & .Shuffle != .Normal {
            enqueuedItems = enqueuedItems?.shuffled()
        }
        else {
            enqueuedItems = enqueuedItems?.sorted({ $0.position < $1.position })
        }
    }
}
