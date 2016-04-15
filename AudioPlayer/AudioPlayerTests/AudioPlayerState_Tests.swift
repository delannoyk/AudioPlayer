//
//  AudioPlayerState_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 17/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class AudioPlayerState_Tests: XCTestCase {
    func testEquatable() {
        let buffering = AudioPlayerState.Buffering
        let failedMaximumRetryCountHit = AudioPlayerState.Failed(.MaximumRetryCountHit)
        let failedWithError = AudioPlayerState.Failed(.FoundationError(NSError(domain: "", code: -1, userInfo: nil)))
        let paused = AudioPlayerState.Paused
        let playing = AudioPlayerState.Playing
        let stopped = AudioPlayerState.Stopped
        let waitingForConnection = AudioPlayerState.WaitingForConnection

        XCTAssertEqual(buffering, buffering)
        XCTAssertEqual(failedMaximumRetryCountHit, failedMaximumRetryCountHit)
        XCTAssertEqual(failedWithError, failedWithError)
        XCTAssertEqual(paused, paused)
        XCTAssertEqual(playing, playing)
        XCTAssertEqual(stopped, stopped)
        XCTAssertEqual(waitingForConnection, waitingForConnection)

        XCTAssertNotEqual(buffering, failedMaximumRetryCountHit)
        XCTAssertNotEqual(buffering, failedWithError)
        XCTAssertNotEqual(buffering, paused)
        XCTAssertNotEqual(buffering, playing)
        XCTAssertNotEqual(buffering, stopped)
        XCTAssertNotEqual(buffering, waitingForConnection)

        XCTAssertNotEqual(failedMaximumRetryCountHit, failedWithError)
        XCTAssertNotEqual(failedMaximumRetryCountHit, paused)
        XCTAssertNotEqual(failedMaximumRetryCountHit, playing)
        XCTAssertNotEqual(failedMaximumRetryCountHit, stopped)
        XCTAssertNotEqual(failedMaximumRetryCountHit, waitingForConnection)

        XCTAssertNotEqual(failedWithError, paused)
        XCTAssertNotEqual(failedWithError, playing)
        XCTAssertNotEqual(failedWithError, stopped)
        XCTAssertNotEqual(failedWithError, waitingForConnection)

        XCTAssertNotEqual(paused, playing)
        XCTAssertNotEqual(paused, stopped)
        XCTAssertNotEqual(paused, waitingForConnection)

        XCTAssertNotEqual(playing, stopped)
        XCTAssertNotEqual(playing, waitingForConnection)
    }
}
