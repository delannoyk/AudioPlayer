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
    let buffering = AudioPlayerState.buffering
    let failed = AudioPlayerState.failed
    let errorMaximumRetryCountHit = AudioPlayerError.maximumRetryCountHit
    let errorOther = AudioPlayerError.foundationError(NSError(domain: "", code: -1, userInfo: nil))
    let paused = AudioPlayerState.paused
    let playing = AudioPlayerState.playing
    let stopped = AudioPlayerState.stopped
    let waitingForConnection = AudioPlayerState.waitingForConnection

    func testEquatable() {
        XCTAssertEqual(buffering, buffering)
//        XCTAssertEqual(errorMaximumRetryCountHit, errorMaximumRetryCountHit)
//        XCTAssertEqual(errorOther, errorOther)
        XCTAssertEqual(paused, paused)
        XCTAssertEqual(playing, playing)
        XCTAssertEqual(stopped, stopped)
        XCTAssertEqual(waitingForConnection, waitingForConnection)

        XCTAssertNotEqual(buffering, failed)
        XCTAssertNotEqual(buffering, paused)
        XCTAssertNotEqual(buffering, playing)
        XCTAssertNotEqual(buffering, stopped)
        XCTAssertNotEqual(buffering, waitingForConnection)

//        XCTAssertNotEqual(errorMaximumRetryCountHit, errorOther)

        XCTAssertNotEqual(failed, paused)
        XCTAssertNotEqual(failed, playing)
        XCTAssertNotEqual(failed, stopped)
        XCTAssertNotEqual(failed, waitingForConnection)

        XCTAssertNotEqual(paused, playing)
        XCTAssertNotEqual(paused, stopped)
        XCTAssertNotEqual(paused, waitingForConnection)

        XCTAssertNotEqual(playing, stopped)
        XCTAssertNotEqual(playing, waitingForConnection)
    }

    func testIsVariable() {
        XCTAssert(buffering.isBuffering)
        XCTAssertFalse(buffering.isFailed)
        XCTAssertFalse(buffering.isPaused)
        XCTAssertFalse(buffering.isPlaying)
        XCTAssertFalse(buffering.isStopped)
        XCTAssertFalse(buffering.isWaitingForConnection)

        XCTAssertFalse(failed.isBuffering)
        XCTAssert(failed.isFailed)
        XCTAssertFalse(failed.isPaused)
        XCTAssertFalse(failed.isPlaying)
        XCTAssertFalse(failed.isStopped)
        XCTAssertFalse(failed.isWaitingForConnection)

        XCTAssertFalse(failed.isBuffering)
        XCTAssert(failed.isFailed)
        XCTAssertFalse(failed.isPaused)
        XCTAssertFalse(failed.isPlaying)
        XCTAssertFalse(failed.isStopped)
        XCTAssertFalse(failed.isWaitingForConnection)

        XCTAssertFalse(paused.isBuffering)
        XCTAssertFalse(paused.isFailed)
        XCTAssert(paused.isPaused)
        XCTAssertFalse(paused.isPlaying)
        XCTAssertFalse(paused.isStopped)
        XCTAssertFalse(paused.isWaitingForConnection)

        XCTAssertFalse(playing.isBuffering)
        XCTAssertFalse(playing.isFailed)
        XCTAssertFalse(playing.isPaused)
        XCTAssert(playing.isPlaying)
        XCTAssertFalse(playing.isStopped)
        XCTAssertFalse(playing.isWaitingForConnection)

        XCTAssertFalse(stopped.isBuffering)
        XCTAssertFalse(stopped.isFailed)
        XCTAssertFalse(stopped.isPaused)
        XCTAssertFalse(stopped.isPlaying)
        XCTAssert(stopped.isStopped)
        XCTAssertFalse(stopped.isWaitingForConnection)

        XCTAssertFalse(waitingForConnection.isBuffering)
        XCTAssertFalse(waitingForConnection.isFailed)
        XCTAssertFalse(waitingForConnection.isPaused)
        XCTAssertFalse(waitingForConnection.isPlaying)
        XCTAssertFalse(waitingForConnection.isStopped)
        XCTAssert(waitingForConnection.isWaitingForConnection)
    }
}
