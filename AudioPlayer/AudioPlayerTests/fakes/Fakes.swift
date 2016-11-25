//
//  Fakes.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 09/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit
import AVFoundation
import SystemConfiguration
@testable import AudioPlayer

class FakeEventListener: EventListener {
    var eventClosure: ((Event, EventProducer) -> ())?

    func onEvent(_ event: Event, generetedBy eventProducer: EventProducer) {
        eventClosure?(event, eventProducer)
    }
}

class FakeReachability: Reachability {
    var reachabilityStatus = Reachability.NetworkStatus.notReachable {
        didSet {
            NotificationCenter.default.post(name: .ReachabilityChanged, object: self)
        }
    }

    override var currentReachabilityStatus: Reachability.NetworkStatus {
        get {
            return reachabilityStatus
        }
    }
}

class FakeItem: AVPlayerItem {
    var bufferEmpty = true {
        willSet {
            willChangeValue(forKey: "playbackBufferEmpty")
        }
        didSet {
            didChangeValue(forKey: "playbackBufferEmpty")
        }
    }

    override var isPlaybackBufferEmpty: Bool {
        return bufferEmpty
    }

    var likelyToKeepUp = false {
        willSet {
            willChangeValue(forKey: "playbackLikelyToKeepUp")
        }
        didSet {
            didChangeValue(forKey: "playbackLikelyToKeepUp")
        }
    }

    override var isPlaybackLikelyToKeepUp: Bool {
        return likelyToKeepUp
    }

    var timeRanges = [NSValue]() {
        willSet {
            willChangeValue(forKey: "loadedTimeRanges")
        }
        didSet {
            didChangeValue(forKey: "loadedTimeRanges")
        }
    }

    override var loadedTimeRanges: [NSValue] {
        return timeRanges
    }

    var stat = AVPlayerItemStatus.unknown {
        willSet {
            willChangeValue(forKey: "status")
        }
        didSet {
            didChangeValue(forKey: "status")
        }
    }

    override var status: AVPlayerItemStatus {
        return stat
    }

    var dur = CMTime() {
        willSet {
            willChangeValue(forKey: "duration")
        }
        didSet {
            didChangeValue(forKey: "duration")
        }
    }

    override var duration: CMTime {
        return dur
    }
}

private extension Selector {
    static let fakePlayerTimerTicked = #selector(FakePlayer.timerTicked(_:))
}

class FakePlayer: AVPlayer {
    var timer: Timer?
    var startDate: NSDate?
    var observerClosure: ((CMTime) -> Void)?
    var item: FakeItem? {
        willSet {
            willChangeValue(forKey: "currentItem")
        }
        didSet {
            didChangeValue(forKey: "currentItem")
        }
    }

    override var currentItem: AVPlayerItem? {
        return item
    }

    override func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any {
        observerClosure = block
        startDate = NSDate()
        timer = Timer.scheduledTimer(timeInterval: CMTimeGetSeconds(interval), target: self, selector: .fakePlayerTimerTicked, userInfo: nil, repeats: true)
        return self
    }

    override func removeTimeObserver(_ observer: Any) {
        timer?.invalidate()
        timer = nil
        startDate = nil
        observerClosure = nil
    }

    @objc fileprivate func timerTicked(_: Timer) {
        let t = fabs(startDate!.timeIntervalSinceNow)
        observerClosure?(CMTime(timeInterval: t))
    }
}

class FakeMetadataItem: AVMetadataItem {
    var _commonKey: String
    var _value: NSCopying & NSObjectProtocol

    init(commonKey: String, value: NSCopying & NSObjectProtocol) {
        _commonKey = commonKey
        _value = value
    }

    override var commonKey: String? {
        return _commonKey
    }

    override var value: NSCopying & NSObjectProtocol {
        return _value
    }
}

class FakeApplication: BackgroundTaskCreator {
    var onBegin: (((() -> Void)?) -> UIBackgroundTaskIdentifier)?
    var onEnd: ((UIBackgroundTaskIdentifier) -> Void)?

    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        return onBegin?(handler) ?? UIBackgroundTaskInvalid
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        onEnd?(identifier)
    }
}

class FakeAudioPlayer: AudioPlayer {
    var avPlayer = FakePlayer()

    override var player: AVPlayer? {
        get {
            return avPlayer
        }
        set { }
    }
}

class FakeAudioPlayerDelegate: AudioPlayerDelegate {
    var didChangeState: ((AudioPlayer, AudioPlayerState, AudioPlayerState) -> Void)?

    var willStartPlaying: ((AudioPlayer, AudioItem) -> Void)?

    var didUpdateProgression: ((AudioPlayer, TimeInterval, Float) -> Void)?

    var didLoadRange: ((AudioPlayer, TimeRange, AudioItem) -> Void)?

    var didFindDuration: ((AudioPlayer, TimeInterval, AudioItem) -> Void)?

    var didUpdateEmptyMetadata: ((AudioPlayer, AudioItem, Metadata) -> Void)?


    func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        didChangeState?(audioPlayer, from, state)
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioItem) {
        willStartPlaying?(audioPlayer, item)
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        didUpdateProgression?(audioPlayer, time, percentageRead)
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didLoad range: TimeRange, for item: AudioItem) {
        didLoadRange?(audioPlayer, range, item)
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioItem) {
        didFindDuration?(audioPlayer, duration, item)
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateEmptyMetadataOn item: AudioItem, withData data: Metadata) {
        didUpdateEmptyMetadata?(audioPlayer, item, data)
    }
}
