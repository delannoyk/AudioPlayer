//
//  AudioPlayer+SeekEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 2016-10-27.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

extension AudioPlayer {
    func handleSeekEvent(from producer: EventProducer, with event: SeekEventProducer.SeekEvent) {
        guard let currentItemProgression = currentItemProgression,
            case .changeTime(_, let delta) = seekingBehavior else { return }

        switch event {
        case .seekBackward:
            seek(to: currentItemProgression - delta)

        case .seekForward:
            seek(to: currentItemProgression + delta)
        }
    }
}
