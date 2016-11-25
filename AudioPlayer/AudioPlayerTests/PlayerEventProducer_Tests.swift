//
//  PlayerEventProducer_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 08/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
import AVFoundation
@testable import AudioPlayer

class PlayerEventProducer_Tests: XCTestCase {
    var listener: FakeEventListener!
    var producer: PlayerEventProducer!
    var player: FakePlayer!
    var item: FakeItem!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        player = FakePlayer()
        item = FakeItem(url: URL(string: "https://github.com")!)
        player.item = item
        producer = PlayerEventProducer()
        producer.player = player
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        player = nil
        item = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledWhenTimeObserverGetsCalled() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.progressed = event {
                e.fulfill()
            } else {
                XCTFail()
            }
        }

        waitForExpectations(timeout: 1) { e in
            self.producer.player = nil

            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenPlayerEndsPlaying() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.endedPlaying = event {
                e.fulfill()
            }
        }

        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenServiceReset() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.sessionMessedUp = event {
                e.fulfill()
            }
        }

        NotificationCenter.default.post(name: .AVAudioSessionMediaServicesWereReset, object: AVAudioSession.sharedInstance())

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenServiceGotLost() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.sessionMessedUp = event {
                e.fulfill()
            }
        }

        NotificationCenter.default.post(name: .AVAudioSessionMediaServicesWereLost, object: AVAudioSession.sharedInstance())

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenRouteChanges() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent,
                case PlayerEventProducer.PlayerEvent.routeChanged = event {
                    e.fulfill()
            }
        }

        NotificationCenter.default.post(name: .AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenInterruptionBeginsAndEnds() {
        let expectationBegins = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.interruptionBegan = event {
                expectationBegins.fulfill()
            }
        }

        NotificationCenter.default.post(
            name: .AVAudioSessionInterruption,
            object: player,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: NSNumber(value: AVAudioSessionInterruptionType.began.rawValue)
            ])

        let expectationEnds = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.interruptionEnded = event {
                expectationEnds.fulfill()
            }
        }

        NotificationCenter.default.post(
            name: .AVAudioSessionInterruption,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: NSNumber(value: AVAudioSessionInterruptionType.ended.rawValue),
                AVAudioSessionInterruptionOptionKey: NSNumber(value: AVAudioSessionInterruptionOptions.shouldResume.rawValue)
            ])

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenItemDurationIsAvailable() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.loadedDuration = event {
                e.fulfill()
            }
        }

        item.dur = CMTime(timeInterval: 10)
        XCTAssertEqual(item.dur.ap_timeIntervalValue, 10)
        XCTAssertNil(CMTime(value: 0, timescale: 1, flags: [], epoch: 0).ap_timeIntervalValue)

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenItemBufferIsEmpty() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.startedBuffering = event {
                e.fulfill()
            }
        }

        item.bufferEmpty = true

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenItemBufferIsReadyToPlay() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.readyToPlay = event {
                e.fulfill()
            }
        }

        item.likelyToKeepUp = true

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenItemStatusChangesToAnyOtherThanError() {
        listener.eventClosure = { event, producer in
            guard case PlayerEventProducer.PlayerEvent.progressed = event else {
                XCTFail()
                return
            }
        }

        item.stat = AVPlayerItemStatus.unknown
        item.stat = AVPlayerItemStatus.readyToPlay
    }

    func testEventListenerGetsCalledWhenItemStatusChangesToError() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.endedPlaying = event {
                e.fulfill()
            }
        }

        item.stat = AVPlayerItemStatus.failed

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenNewItemRangesAreAvailable() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if case PlayerEventProducer.PlayerEvent.loadedMoreRange = event {
                e.fulfill()
            }
        }

        item.timeRanges = [
            NSValue(timeRange: CMTimeRange(start: CMTime(), duration: CMTime(timeInterval: 10)))
        ]

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenItemLikelyToKeepUpChangesToFalse() {
        listener.eventClosure = { event, producer in
            guard case PlayerEventProducer.PlayerEvent.progressed = event else {
                XCTFail()
                return
            }
        }

        item.likelyToKeepUp = false
        item.likelyToKeepUp = false
    }
}
