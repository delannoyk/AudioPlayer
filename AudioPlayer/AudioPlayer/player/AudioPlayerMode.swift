//
//  AudioPlayerMode.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 19/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 Represents the mode in which the player should play. Modes can be used as masks
 so that you can play in `.Shuffle` mode and still `.RepeatAll`.
 */
public struct AudioPlayerMode: OptionSetType {
    /// The raw value describing the mode.
    public let rawValue: UInt

    /**
     Initializes an `AudioPlayerMode` from a `rawValue`.

     - parameter rawValue: The raw value describing the mode.
     */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// In this mode, player's queue will be played as given.
    public static var Normal = AudioPlayerMode(rawValue: 0)

    /// In this mode, player's queue is shuffled randomly.
    public static var Shuffle = AudioPlayerMode(rawValue: 0b001)

    /// In this mode, the player will continuously play the same item over and over.
    public static var Repeat = AudioPlayerMode(rawValue: 0b010)

    /// In this mode, the player will continuously play the same queue over and over.
    public static var RepeatAll = AudioPlayerMode(rawValue: 0b100)
}
