//
//  AudioPlayerBufferingStrategy.swift
//  AudioPlayer
//
//  Created by Daniel Dam Freiling on 10/05/2017.
//  Copyright © 2017 Kevin Delannoy. All rights reserved.
//

import Foundation

@objc public enum AudioPlayerBufferingStrategy: Int {
    case defaultBuffering = 0
    case aggressiveBuffering = 1
}
