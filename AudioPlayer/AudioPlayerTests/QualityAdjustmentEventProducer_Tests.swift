//
//  QualityAdjustmentEventProducer_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 12/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class QualityAdjustmentEventProducer_Tests: XCTestCase {
    var listener: FakeEventListener!
    var producer: QualityAdjustmentEventProducer!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        producer = QualityAdjustmentEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledWhenInterruptionCountHitsLimit() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent,
                QualityAdjustmentEventProducer.QualityAdjustmentEvent.GoDown)
            expectation.fulfill()
        }

        producer.adjustQualityAfterInterruptionCount = 5
        producer.interruptionCount = producer.adjustQualityAfterInterruptionCount

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerDoesNotGetCalledWhenInterruptionCountIsIncrementedToLessThanLimits() {
        listener.eventClosure = { event, producer in
            XCTFail()
        }

        producer.adjustQualityAfterInterruptionCount = 5
        producer.interruptionCount = 1
        producer.interruptionCount = 2
        producer.interruptionCount = 3
        producer.interruptionCount = 4
    }

    func testEventListenerGetsCalledWhenInterruptionShouldGoUp() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent,
                QualityAdjustmentEventProducer.QualityAdjustmentEvent.GoUp)
            expectation.fulfill()
        }

        producer.adjustQualityTimeInternal = 1

        waitForExpectationsWithTimeout(1.5) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledImmediatelyWhenAdjustQualityTimeIntervalIsChangedToAValueThatShouldAlreadyHaveBeenFired() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            XCTAssertEqual(event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent,
                QualityAdjustmentEventProducer.QualityAdjustmentEvent.GoUp)
            expectation.fulfill()
        }

        producer.adjustQualityTimeInternal = 5
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.producer.adjustQualityTimeInternal = 1
        }

        waitForExpectationsWithTimeout(2.5) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
