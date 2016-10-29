//
//  MPNowPlayingInfoCenter+AudioItem.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 27/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import MediaPlayer

extension MPNowPlayingInfoCenter {
    func ap_update(with item: AudioItem, duration: TimeInterval?, progression: TimeInterval?, playbackRate: Float) {
        var info = [String: Any]()
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
        if let artwork = item.artworkImage {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: artwork)
        }
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
