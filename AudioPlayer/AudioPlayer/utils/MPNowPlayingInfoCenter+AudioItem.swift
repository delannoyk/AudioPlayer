//
//  MPNowPlayingInfoCenter+AudioItem.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 27/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import MediaPlayer

extension MPNowPlayingInfoCenter {
    func ap_updateWithItem(item: AudioItem,
                           duration: NSTimeInterval?,
                           progression: NSTimeInterval?,
                           playbackRate: Float) {
        var info = [String: AnyObject]()
        if let title = item.title {
            info[MPMediaItemPropertyTitle] = title
        }
        if let artist = item.artist {
            info[MPMediaItemPropertyArtist] = artist
        }
        if let album = item.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        if let trackCount = item.trackCount {
            info[MPMediaItemPropertyAlbumTrackCount] = trackCount
        }
        if let trackNumber = item.trackNumber {
            info[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        }
        #if os(iOS)
            if let artwork = item.artworkImage {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: artwork)
            }
        #endif
        if let duration = duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let progression = progression {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progression
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate

        nowPlayingInfo = info
    }
}
