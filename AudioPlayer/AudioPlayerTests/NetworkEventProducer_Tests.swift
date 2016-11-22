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
        reachability = FakeReachability()
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
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? NetworkEventProducer.NetworkEvent,
                NetworkEventProducer.NetworkEvent.connectionRetrieved)
            e.fulfill()
        }

        reachability.reachabilityStatus = .reachableViaWiFi

        waitForExpectations(timeout: 1) { e in
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

        let e = expectation(description: "Waiting for `onEvent` to get called")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            e.fulfill()
        }

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testConnectionLostEvent() {
        reachability.reachabilityStatus = .reachableViaWiFi

        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? NetworkEventProducer.NetworkEvent,
                NetworkEventProducer.NetworkEvent.connectionLost)
            e.fulfill()
        }

        reachability.reachabilityStatus = .notReachable

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testConnectionChangedEvent() {
        reachability.reachabilityStatus = .reachableViaWiFi

        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? NetworkEventProducer.NetworkEvent,
                NetworkEventProducer.NetworkEvent.networkChanged)
            e.fulfill()
        }

        reachability.reachabilityStatus = .reachableViaWWAN

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
