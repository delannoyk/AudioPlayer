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
        item = FakeItem(URL: NSURL(string: "https://github.com")!)
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

    func testNetworkEventEquatable() {
        let endedSuccess = PlayerEventProducer.PlayerEvent.EndedPlaying(nil)
        let endedFailure = PlayerEventProducer.PlayerEvent.EndedPlaying(NSError(domain: "", code: -1, userInfo: nil))
        let interruptBegan = PlayerEventProducer.PlayerEvent.InterruptionBegan
        let interruptEnded = PlayerEventProducer.PlayerEvent.InterruptionEnded
        let loadedDuration = PlayerEventProducer.PlayerEvent.LoadedDuration(CMTime())
        let loadedMetadata = PlayerEventProducer.PlayerEvent.LoadedMetadata([])
        let loadedMoreRange = PlayerEventProducer.PlayerEvent.LoadedMoreRange(CMTime(), CMTime())
        let progressed = PlayerEventProducer.PlayerEvent.Progressed(CMTime())
        let readyToPlay = PlayerEventProducer.PlayerEvent.ReadyToPlay
        let routeChanged = PlayerEventProducer.PlayerEvent.RouteChanged
        let sessionMessedUp = PlayerEventProducer.PlayerEvent.SessionMessedUp
        let startedBuffering = PlayerEventProducer.PlayerEvent.StartedBuffering

        XCTAssertEqual(endedSuccess, endedSuccess)
        XCTAssertEqual(endedFailure, endedFailure)
        XCTAssertEqual(interruptBegan, interruptBegan)
        XCTAssertEqual(interruptEnded, interruptEnded)
        XCTAssertEqual(loadedDuration, loadedDuration)
        XCTAssertEqual(loadedMetadata, loadedMetadata)
        XCTAssertEqual(loadedMoreRange, loadedMoreRange)
        XCTAssertEqual(progressed, progressed)
        XCTAssertEqual(readyToPlay, readyToPlay)
        XCTAssertEqual(routeChanged, routeChanged)
        XCTAssertEqual(sessionMessedUp, sessionMessedUp)
        XCTAssertEqual(startedBuffering, startedBuffering)

        XCTAssertNotEqual(endedSuccess, endedFailure)
        XCTAssertNotEqual(endedSuccess, interruptBegan)
        XCTAssertNotEqual(endedSuccess, interruptEnded)
        XCTAssertNotEqual(endedSuccess, loadedDuration)
        XCTAssertNotEqual(endedSuccess, loadedMetadata)
        XCTAssertNotEqual(endedSuccess, loadedMoreRange)
        XCTAssertNotEqual(endedSuccess, progressed)
        XCTAssertNotEqual(endedSuccess, readyToPlay)
        XCTAssertNotEqual(endedSuccess, routeChanged)
        XCTAssertNotEqual(endedSuccess, sessionMessedUp)
        XCTAssertNotEqual(endedSuccess, startedBuffering)

        XCTAssertNotEqual(endedFailure, interruptBegan)
        XCTAssertNotEqual(endedFailure, interruptEnded)
        XCTAssertNotEqual(endedFailure, loadedDuration)
        XCTAssertNotEqual(endedFailure, loadedMetadata)
        XCTAssertNotEqual(endedFailure, loadedMoreRange)
        XCTAssertNotEqual(endedFailure, progressed)
        XCTAssertNotEqual(endedFailure, readyToPlay)
        XCTAssertNotEqual(endedFailure, routeChanged)
        XCTAssertNotEqual(endedFailure, sessionMessedUp)
        XCTAssertNotEqual(endedFailure, startedBuffering)

        XCTAssertNotEqual(interruptBegan, interruptEnded)
        XCTAssertNotEqual(interruptBegan, loadedDuration)
        XCTAssertNotEqual(interruptBegan, loadedMetadata)
        XCTAssertNotEqual(interruptBegan, loadedMoreRange)
        XCTAssertNotEqual(interruptBegan, progressed)
        XCTAssertNotEqual(interruptBegan, readyToPlay)
        XCTAssertNotEqual(interruptBegan, routeChanged)
        XCTAssertNotEqual(interruptBegan, sessionMessedUp)
        XCTAssertNotEqual(interruptBegan, startedBuffering)

        XCTAssertNotEqual(interruptEnded, loadedDuration)
        XCTAssertNotEqual(interruptEnded, loadedMetadata)
        XCTAssertNotEqual(interruptEnded, loadedMoreRange)
        XCTAssertNotEqual(interruptEnded, progressed)
        XCTAssertNotEqual(interruptEnded, readyToPlay)
        XCTAssertNotEqual(interruptEnded, routeChanged)
        XCTAssertNotEqual(interruptEnded, sessionMessedUp)
        XCTAssertNotEqual(interruptEnded, startedBuffering)

        XCTAssertNotEqual(loadedDuration, loadedMetadata)
        XCTAssertNotEqual(loadedDuration, loadedMoreRange)
        XCTAssertNotEqual(loadedDuration, progressed)
        XCTAssertNotEqual(loadedDuration, readyToPlay)
        XCTAssertNotEqual(loadedDuration, routeChanged)
        XCTAssertNotEqual(loadedDuration, sessionMessedUp)
        XCTAssertNotEqual(loadedDuration, startedBuffering)

        XCTAssertNotEqual(loadedMetadata, loadedMoreRange)
        XCTAssertNotEqual(loadedMetadata, progressed)
        XCTAssertNotEqual(loadedMetadata, readyToPlay)
        XCTAssertNotEqual(loadedMetadata, routeChanged)
        XCTAssertNotEqual(loadedMetadata, sessionMessedUp)
        XCTAssertNotEqual(loadedMetadata, startedBuffering)

        XCTAssertNotEqual(loadedMoreRange, progressed)
        XCTAssertNotEqual(loadedMoreRange, readyToPlay)
        XCTAssertNotEqual(loadedMoreRange, routeChanged)
        XCTAssertNotEqual(loadedMoreRange, sessionMessedUp)
        XCTAssertNotEqual(loadedMoreRange, startedBuffering)

        XCTAssertNotEqual(progressed, readyToPlay)
        XCTAssertNotEqual(progressed, routeChanged)
        XCTAssertNotEqual(progressed, sessionMessedUp)
        XCTAssertNotEqual(progressed, startedBuffering)

        XCTAssertNotEqual(readyToPlay, routeChanged)
        XCTAssertNotEqual(readyToPlay, sessionMessedUp)
        XCTAssertNotEqual(readyToPlay, startedBuffering)

        XCTAssertNotEqual(routeChanged, sessionMessedUp)
        XCTAssertNotEqual(routeChanged, startedBuffering)
    }

    func testEventListenerGetsCalledWhenTimeObserverGetsCalled() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? PlayerEventProducer.PlayerEvent,
                PlayerEventProducer.PlayerEvent.Progressed(CMTime()))
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1) { e in
            self.producer.player = nil

            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenPlayerEndsPlaying() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.EndedPlaying(nil) {
                    expectation.fulfill()
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(AVPlayerItemDidPlayToEndTimeNotification,
            object: player)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenServiceReset() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.SessionMessedUp {
                    expectation.fulfill()
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(AVAudioSessionMediaServicesWereResetNotification,
            object: player)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenServiceGotLost() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.SessionMessedUp {
                    expectation.fulfill()
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(AVAudioSessionMediaServicesWereLostNotification,
            object: player)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenRouteChanges() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.RouteChanged {
                    expectation.fulfill()
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(AVAudioSessionRouteChangeNotification,
            object: player)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenInterruptionBeginsAndEnds() {
        let expectationBegins = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.InterruptionBegan {
                    expectationBegins.fulfill()
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(AVAudioSessionInterruptionNotification,
            object: player,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: NSNumber(unsignedInteger: AVAudioSessionInterruptionType.Began.rawValue)
            ])

        let expectationEnds = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.InterruptionEnded {
                    expectationEnds.fulfill()
            }
        }

        NSNotificationCenter.defaultCenter().postNotificationName(AVAudioSessionInterruptionNotification,
            object: player,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: NSNumber(unsignedInteger: AVAudioSessionInterruptionType.Ended.rawValue),
                AVAudioSessionInterruptionOptionKey: NSNumber(unsignedInteger: AVAudioSessionInterruptionOptions.ShouldResume.rawValue)
            ])

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenItemDurationIsAvailable() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.LoadedDuration(CMTime()) {
                    expectation.fulfill()
            }
        }

        item.dur = CMTime(seconds: 10, preferredTimescale: 10000000)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenItemBufferIsEmpty() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.StartedBuffering {
                    expectation.fulfill()
            }
        }

        item.bufferEmpty = true

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenItemBufferIsReadyToPlay() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.ReadyToPlay {
                    expectation.fulfill()
            }
        }

        item.likelyToKeepUp = true

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenItemStatusChangesToAnyOtherThanError() {
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event != .Progressed(CMTime()) {
                    XCTFail()
            }
        }

        item.stat = AVPlayerItemStatus.Unknown
        item.stat = AVPlayerItemStatus.ReadyToPlay
    }

    func testEventListenerGetsCalledWhenItemStatusChangesToError() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.EndedPlaying(nil) {
                    expectation.fulfill()
            }
        }

        item.stat = AVPlayerItemStatus.Failed

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenNewItemRangesAreAvailable() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? PlayerEventProducer.PlayerEvent
                where event == PlayerEventProducer.PlayerEvent.LoadedMoreRange(CMTime(), CMTime()) {
                    expectation.fulfill()
            }
        }

        item.timeRanges = [NSValue(CMTimeRange: CMTimeRange(start: CMTime(),
            duration: CMTime(seconds: 10, preferredTimescale: 1000000)))]

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
