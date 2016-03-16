//
//  AudioItemEventProducer_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 14/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class AudioItemEventProducer_Tests: XCTestCase {
    var listener: FakeEventListener!
    var producer: AudioItemEventProducer!
    var item: AudioItem!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        item = AudioItem(highQualitySoundURL: NSURL(string: "https://github.com"))
        producer = AudioItemEventProducer()
        producer.item = item
        producer.eventListener = listener
        producer.startProducingEvents()
    }

    override func tearDown() {
        listener = nil
        item = nil
        producer.stopProducingEvents()
        producer = nil
        super.tearDown()
    }

    func testEventListenerGetsCalledWhenArtistIsUpdated() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent
                where event == AudioItemEventProducer.AudioItemEvent.UpdatedArtist {
                    expectation.fulfill()
            }
        }

        item.artist = "artist"

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenTitleIsUpdated() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent
                where event == AudioItemEventProducer.AudioItemEvent.UpdatedTitle {
                    expectation.fulfill()
            }
        }

        item.title = "title"

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenAlbumIsUpdated() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent
                where event == AudioItemEventProducer.AudioItemEvent.UpdatedAlbum {
                    expectation.fulfill()
            }
        }

        item.album = "album"

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenTrackCountIsUpdated() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent
                where event == AudioItemEventProducer.AudioItemEvent.UpdatedTrackCount {
                    expectation.fulfill()
            }
        }

        item.trackCount = NSNumber(integer: 1)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenTrackNumberIsUpdated() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent
                where event == AudioItemEventProducer.AudioItemEvent.UpdatedTrackNumber {
                    expectation.fulfill()
            }
        }

        item.trackNumber = NSNumber(integer: 1)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenArtworkImageIsUpdated() {
        let expectation = expectationWithDescription("Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent
                where event == AudioItemEventProducer.AudioItemEvent.UpdatedArtworkImage {
                    expectation.fulfill()
            }
        }

        item.artworkImage = UIImage(named: "image",
            inBundle: NSBundle(forClass: self.dynamicType),
            compatibleWithTraitCollection: nil)

        waitForExpectationsWithTimeout(1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
