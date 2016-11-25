//
//  AudioPlayer+PlayerEvent_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 2016-11-24.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
import AVFoundation
@testable import AudioPlayer

class AudioPlayer_PlayerEvent_Tests: XCTestCase {
    var player: FakeAudioPlayer!
    var listener: FakeEventListener!

    override func setUp() {
        super.setUp()
        listener = FakeEventListener()
        player = FakeAudioPlayer()
    }

    override func tearDown() {
        listener = nil
        player = nil
        super.tearDown()
    }

    func testProgressEventFiresDelegateCallWithTheRightInfo() {
        player.avPlayer.item = FakeItem(url: URL(string: "https://github.com")!)
        player.avPlayer.item?.stat = .readyToPlay
        player.avPlayer.item?.dur = CMTime(timeInterval: 10)

        let e = expectation(description: "Waiting for `didUpdateProgression` to get called")
        let delegate = FakeAudioPlayerDelegate()
        delegate.didUpdateProgression = { player, progression, percentage in
            XCTAssertEqual(player, self.player)
            XCTAssertEqual(progression, 2)
            XCTAssertEqual(percentage, 20)
            e.fulfill()
        }
        player.delegate = delegate

        player.handlePlayerEvent(from: player.playerEventProducer, with: .progressed(CMTime(timeInterval: 2)))
        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }

    func testProgressEventFiresDelegateCallWithZeroPercentageWhenDurationIsUnknown() {
        player.avPlayer.item = FakeItem(url: URL(string: "https://github.com")!)
        player.avPlayer.item?.stat = .readyToPlay
        player.avPlayer.item?.dur = CMTime(value: 0, timescale: 1, flags: [], epoch: 0)//This is an invalid time

        let e = expectation(description: "Waiting for `didUpdateProgression` to get called")
        let delegate = FakeAudioPlayerDelegate()
        delegate.didUpdateProgression = { player, progression, percentage in
            XCTAssertEqual(player, self.player)
            XCTAssertEqual(progression, 2)
            XCTAssertEqual(percentage, 0)
            e.fulfill()
        }
        player.delegate = delegate

        player.handlePlayerEvent(from: player.playerEventProducer, with: .progressed(CMTime(timeInterval: 2)))
        waitForExpectations(timeout: 1) { e in
            if let _ = e {
                XCTFail()
            }
        }
    }
}
