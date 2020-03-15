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
        item = AudioItem(highQualitySoundURL: URL(string: "https://github.com"))
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
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent,
                event == AudioItemEventProducer.AudioItemEvent.updatedArtist {
                    e.fulfill()
            }
        }

        item.artist = "artist"

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenTitleIsUpdated() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent,
                event == AudioItemEventProducer.AudioItemEvent.updatedTitle {
                    e.fulfill()
            }
        }

        item.title = "title"

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenAlbumIsUpdated() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent,
                event == AudioItemEventProducer.AudioItemEvent.updatedAlbum {
                    e.fulfill()
            }
        }

        item.album = "album"

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenTrackCountIsUpdated() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent,
                event == AudioItemEventProducer.AudioItemEvent.updatedTrackCount {
                    e.fulfill()
            }
        }

        item.trackCount = NSNumber(value: 1)

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenTrackNumberIsUpdated() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent,
                event == AudioItemEventProducer.AudioItemEvent.updatedTrackNumber {
                    e.fulfill()
            }
        }

        item.trackNumber = NSNumber(value: 1)

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testEventListenerGetsCalledWhenArtworkImageIsUpdated() {
        let e = expectation(description: "Waiting for `onEvent` to get called")
        listener.eventClosure = { event, producer in
            if let event = event as? AudioItemEventProducer.AudioItemEvent,
                event == AudioItemEventProducer.AudioItemEvent.updatedArtwork {
                    e.fulfill()
            }
        }

        item.artworkImage = UIImage(
            named: "image",
            in: Bundle(for: type(of: self)),
            compatibleWith: nil)

        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
