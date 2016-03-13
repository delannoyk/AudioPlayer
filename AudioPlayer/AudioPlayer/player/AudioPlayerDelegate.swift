//
//  AudioPlayerDelegate.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 09/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import AVFoundation

/// This typealias only serves the purpose of saving user to `import AVFoundation`.
public typealias Metadata = [AVMetadataItem]

/**
 This protocol contains helpful methods to alert you of specific events.
 If you want to be notified about those events, you will have to set a delegate
 to your `audioPlayer` instance.
 */
public protocol AudioPlayerDelegate: NSObjectProtocol {
    /**
     This method is called when the audio player changes its state. A fresh created audioPlayer
     starts in `.Stopped` mode.

     - parameter audioPlayer: The audio player.
     - parameter fromState:   The state before any changes.
     - parameter toState:     The new state.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didChangeFromState fromState: AudioPlayerState,
        toState: AudioPlayerState)

    /**
     This method is called when the audio player is about to start playing a new item.

     - parameter audioPlayer: The audio player.
     - parameter item:        The item that is about to start being played.
     */
    func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem)

    /**
     This method is called a regular time interval while playing. It notifies the delegate that the
     current playing progression changed.

     - parameter audioPlayer:    The audio player.
     - parameter time:           The current progression.
     - parameter percentageRead: The percentage of the file that has been read. It's a Float value
        between 0 & 100 so that you can easily update an `UISlider` for example.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval,
        percentageRead: Float)

    /**
     This method gets called when the current item duration has been found.

     - parameter audioPlayer: The audio player.
     - parameter duration:    Current item's duration.
     - parameter item:        Current item.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval,
        forItem item: AudioItem)

    /**
     This methods gets called before duration gets updated with discovered metadata.

     - parameter audioPlayer: The audio player.
     - parameter item:        Found metadata.
     - parameter data:        Current item.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didUpdateEmptyMetadataOnItem item: AudioItem,
        withData data: Metadata)

    /**
     This method gets called while the audio player is loading the file (over the network or
     locally). It lets the delegate know what time range has already been loaded.

     - parameter audioPlayer: The audio player.
     - parameter range:       The time range that the audio player loaded.
     - parameter item:        Current item.
     */
    func audioPlayer(audioPlayer: AudioPlayer, didLoadRange range: AudioPlayer.TimeRange,
        forItem item: AudioItem)
}
