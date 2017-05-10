//
//  AudioPlayerState.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 11/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/// The possible errors an `AudioPlayer` can fail with.
///
/// - maximumRetryCountHit: The player hit the maximum retry count.
/// - foundationError: The `AVPlayer` failed to play.
public enum AudioPlayerError: Error {
    case maximumRetryCountHit
    case foundationError(Error)
}

/// `AudioPlayerState` defines 4 state an `AudioPlayer` instance can be in.
///
/// - buffering: The player is buffering data before playing them.
/// - playing: The player is playing.
/// - paused: The player is paused.
/// - stopped: The player is stopped.
/// - waitingForConnection: The player is waiting for internet connection.
/// - failed: An error occured. It contains AVPlayer's error if any.
@objc public enum AudioPlayerState: Int {
    case buffering = 0
    case playing = 1
    case paused = 2
    case stopped = 3
    case waitingForConnection = 4
    case failed = 5

    /// A boolean value indicating is self = `buffering`.
    var isBuffering: Bool {
        if case .buffering = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `playing`.
    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `paused`.
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `stopped`.
    var isStopped: Bool {
        if case .stopped = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `waitingForConnection`.
    var isWaitingForConnection: Bool {
        if case .waitingForConnection = self {
            return true
        }
        return false
    }

    /// A boolean value indicating is self = `failed`.
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

// MARK: - Equatable

extension AudioPlayerState: Equatable {}

public func == (lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
    if (lhs.isBuffering && rhs.isBuffering) || (lhs.isPlaying && rhs.isPlaying) ||
        (lhs.isPaused && rhs.isPaused) || (lhs.isStopped && rhs.isStopped) ||
        (lhs.isWaitingForConnection && rhs.isWaitingForConnection) ||
        (lhs.isFailed && rhs.isFailed) {
        return true
    }
    return false
}
