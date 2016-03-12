//
//  Fakes.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 09/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import AVFoundation
import SystemConfiguration
@testable import AudioPlayer

class FakeEventListener: EventListener {
    var eventClosure: ((Event, EventProducer) -> ())?

    func onEvent(event: Event, generetedBy eventProducer: EventProducer) {
        eventClosure?(event, eventProducer)
    }
}

class FakeReachability: Reachability {
    var reachabilityStatus = Reachability.NetworkStatus.NotReachable {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(ReachabilityChangedNotification,
                object: self)
        }
    }

    override var currentReachabilityStatus: Reachability.NetworkStatus {
        get {
            return reachabilityStatus
        }
    }

    override class func reachabilityForInternetConnection() -> FakeReachability {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let ref = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        return FakeReachability(reachabilityRef: ref)
    }
}

class FakeItem: AVPlayerItem {
    var bufferEmpty = true {
        willSet {
            willChangeValueForKey("playbackBufferEmpty")
        }
        didSet {
            didChangeValueForKey("playbackBufferEmpty")
        }
    }

    override var playbackBufferEmpty: Bool {
        return bufferEmpty
    }

    var likelyToKeepUp = false {
        willSet {
            willChangeValueForKey("playbackLikelyToKeepUp")
        }
        didSet {
            didChangeValueForKey("playbackLikelyToKeepUp")
        }
    }

    override var playbackLikelyToKeepUp: Bool {
        return likelyToKeepUp
    }

    var timeRanges = [NSValue]() {
        willSet {
            willChangeValueForKey("loadedTimeRanges")
        }
        didSet {
            didChangeValueForKey("loadedTimeRanges")
        }
    }

    override var loadedTimeRanges: [NSValue] {
        return timeRanges
    }

    var stat = AVPlayerItemStatus.Unknown {
        willSet {
            willChangeValueForKey("status")
        }
        didSet {
            didChangeValueForKey("status")
        }
    }

    override var status: AVPlayerItemStatus {
        return stat
    }

    var dur = CMTime() {
        willSet {
            willChangeValueForKey("duration")
        }
        didSet {
            didChangeValueForKey("duration")
        }
    }

    override var duration: CMTime {
        return dur
    }
}

class FakePlayer: AVPlayer {
    var timer: NSTimer?
    var startDate: NSDate?
    var observerClosure: (CMTime -> Void)?
    var item: FakeItem? {
        willSet {
            willChangeValueForKey("currentItem")
        }
        didSet {
            didChangeValueForKey("currentItem")
        }
    }

    override var currentItem: AVPlayerItem? {
        return item
    }

    override func addPeriodicTimeObserverForInterval(interval: CMTime, queue: dispatch_queue_t?, usingBlock block: (CMTime) -> Void) -> AnyObject {
        observerClosure = block
        startDate = NSDate()
        timer = NSTimer.scheduledTimerWithTimeInterval(CMTimeGetSeconds(interval), target: self, selector: "timerTicked:", userInfo: nil, repeats: true)
        return self
    }

    override func removeTimeObserver(observer: AnyObject) {
        timer?.invalidate()
        timer = nil
        startDate = nil
        observerClosure = nil
    }

    @objc private func timerTicked(_: NSTimer) {
        let t = fabs(startDate!.timeIntervalSinceNow)
        observerClosure?(CMTime(seconds: t, preferredTimescale: 1000000000))
    }
}
