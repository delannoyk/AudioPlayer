//
//  AudioPlayer+RetryEvent.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 15/04/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

extension AudioPlayer {
    func handleRetryEvent(producer: EventProducer, event: RetryEventProducer.RetryEvent) {
        switch event {
        case .RetryAvailable:
            retryOrPlayNext()

        case .RetryFailed:
            state = .Failed(.MaximumRetryCountHit)
            producer.stopProducingEvents()
        }
    }
}
