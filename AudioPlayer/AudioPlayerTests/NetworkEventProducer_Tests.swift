//
//  NetworkEventProducer_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 08/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class NetworkEventProducer_Tests: XCTestCase {
    var listener: FakeEventListener!
    var producer: NetworkEventProducer!
    var reachability: FakeReachability!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        reachability = FakeReachability.reachabilityForInternetConnection()
        producer = NetworkEventProducer(reachability: reachability)
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        reachability = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledWhenChangingReachabilityStatus() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? NetworkEventProducer.NetworkEvent,
                NetworkEventProducer.NetworkEvent.ConnectionRetrieved)
            expectation.fulfill()
        }

        reachability.reachabilityStatus = .ReachableViaWiFi

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenReachabilityStatusDoesNotChange() {
        listener.eventClosure = { event, producer in
            XCTFail()
        }
        reachability.reachabilityStatus = reachability.currentReachabilityStatus

        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testConnectionLostEvent() {
        reachability.reachabilityStatus = .ReachableViaWiFi

        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? NetworkEventProducer.NetworkEvent,
                NetworkEventProducer.NetworkEvent.ConnectionLost)
            expectation.fulfill()
        }

        reachability.reachabilityStatus = .NotReachable

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testConnectionChangedEvent() {
        reachability.reachabilityStatus = .ReachableViaWiFi

        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? NetworkEventProducer.NetworkEvent,
                NetworkEventProducer.NetworkEvent.NetworkChanged)
            expectation.fulfill()
        }

        reachability.reachabilityStatus = .ReachableViaWWAN

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
