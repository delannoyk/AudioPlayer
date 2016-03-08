//
//  NetworkEventProducer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 08/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `NetworkEventProducer` generates `NetworkEvent`s when there is changes on the network.
 */
class NetworkEventProducer: NSObject, EventProducer {
    /**
       A `NetworkEvent` is an event a network monitor

       - NetworkChanged:           The network changed.
       - ConnectionRetrieved:      The connection is now up.
       - ConnectionLost:           The connection has been lost.
     */
    enum NetworkEvent: Event {
        case NetworkChanged
        case ConnectionRetrieved
        case ConnectionLost
    }

    /// The reachability to work with.
    let reachability: Reachability

    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener?

    /// A boolean value indicating whether we're currently listening to events on the player.
    private var listening = false

    /**
     Initializes a `NetworkEventProducer` with a reachability.

     - parameter reachability: The reachability to work with.
     */
    init(reachability: Reachability) {
        self.reachability = reachability
    }

    /**
     Starts listening to the player events.
     */
    func startProducingEvents() {
        guard !listening else {
            return
        }

        listening = true
    }

    /**
     Stops listening to the player events.
     */
    func stopProducingEvents() {
        guard listening else {
            return
        }

        listening = false
    }

    /**
     The method that will be called when Reachability generates an event.

     - parameter note: The sender information.
     */
    @objc private func reachabilityStatusChanged(note: NSNotification) {

    }
}
