//
//  AudioPlayer+AudioItemEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 03/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

extension AudioPlayer {
    func handleAudioItemEvent(from producer: EventProducer, with event: AudioItemEventProducer.AudioItemEvent) {
        updateNowPlayingInfoCenter()
    }
}
