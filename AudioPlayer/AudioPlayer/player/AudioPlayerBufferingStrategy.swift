//
//  AudioPlayerBufferingStrategy.swift
//  AudioPlayer
//
//  Created by Daniel Freiling on 10/05/2017.
//  Copyright © 2017 Kevin Delannoy. All rights reserved.
//

import Foundation

@objc public enum AudioPlayerBufferingStrategy: Int {
    /// Uses the default AVPlayer buffering strategy, which buffers very aggressively before starting playback.
    /// This often leads to start of playback being delayed more than necessary.
    case defaultBuffering = 0
    
    /// Uses a strategy better at quickly starting playback, but might lead to stalls on slower connections.
    /// Uses `prebufferDurationBeforePlayback` to determine when to start playback. Requires iOS 10+ to have any effect.
    case playWhenPreferredBufferDurationFull = 1
    
    /// Uses a strategy that simply starts playback whenever the AVPlayerItem buffer is non-empty. Requires iOS 10+ to have any effect.
    case playWhenBufferNotEmpty = 2
}
