//
//  SeekEventProducer_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 2016-10-27.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class SeekEventProducer_Tests: XCTestCase {
    var listener: FakeEventListener!
    var producer: SeekEventProducer!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        producer = SeekEventProducer()
        producer.eventListener = listener
    }

    override func tearDown() {
        listener = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledAtRegularTimeIntervals() {
        var calls = [Date]()
        let interval = 1

        let r = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            calls.append(Date())

            if calls.count == 2 {
                let diff = Int(calls[1].timeIntervalSince1970 - calls[0].timeIntervalSince1970)
                XCTAssertEqual(diff, interval)

                r.fulfill()
            }
        }

        producer.intervalBetweenEvents = TimeInterval(interval)
        producer.startProducingEvents()

        waitForExpectations(timeout: 5) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventsAreBackwardWhenAskedFor() {
        let r = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? SeekEventProducer.SeekEvent, .seekBackward)
            r.fulfill()
        }

        producer.intervalBetweenEvents = TimeInterval(1)
        producer.isBackward = true
        producer.startProducingEvents()

        waitForExpectations(timeout: 5) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventsAreForwardWhenAskedFor() {
        let r = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? SeekEventProducer.SeekEvent, .seekForward)
            r.fulfill()
        }

        producer.intervalBetweenEvents = TimeInterval(1)
        producer.isBackward = false
        producer.startProducingEvents()

        waitForExpectations(timeout: 5) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
