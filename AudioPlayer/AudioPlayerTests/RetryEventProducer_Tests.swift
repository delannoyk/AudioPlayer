//
//  RetryEventProducer_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 15/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class RetryEventProducer_Tests: XCTestCase {
    var listener: FakeEventListener!
    var producer: RetryEventProducer!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        producer = RetryEventProducer()
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }
}
