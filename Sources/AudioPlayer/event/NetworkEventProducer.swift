//
//  NetworkEventProducer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 08/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation
import SystemConfiguration

/// A `NetworkEventProducer` generates `NetworkEvent`s when there is changes on the network.
final class NetworkEventProducer: EventProducer {
    /// A `NetworkEvent` is an event a network monitor.
    enum NetworkEvent: Event {
        case networkChanged
        case connectionRetrieved
        case connectionLost
    }

    /// The different status for reachability.
    enum Status {
        case reachableViaWiFi
        case reachableViaData
        case unreachable

        var isReachable: Bool {
            return self != .unreachable
        }
    }

    // MARK: Properties

    /// Reachability queue
    private let queue = DispatchQueue(label: "Reachability Queue")

    /// The reachability reference
    private let reachability: SCNetworkReachability?

    /// A boolean value indicating whether we're currently listening to events on the player.
    private var listening = false

    /// The current reachability status
    var status: Status {
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        if let reachability = reachability {
            _ = withUnsafeMutablePointer(to: &flags, { SCNetworkReachabilityGetFlags(reachability, $0) })
        }

        #if targetEnvironment(simulator)
        let isOnWWAN = true
        #else
        let isOnWWAN = flags.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
        #endif

        guard flags.contains(.reachable), isOnWWAN else { return .unreachable }

        #if os(iOS)
            return flags.contains(.isWWAN) ? .reachableViaData : .reachableViaWiFi
        #else
            return .reachableViaWiFi
        #endif
    }

    /// The date at which connection was lost.
    private(set) var connectionLossDate: Date?

    /// The last status before
    private var lastStatus: Status

    /// The listener that will be alerted a new event occured.
    var eventListener: EventListener?

    // MARK: Initialization

    init() {
        var address = sockaddr()
        address.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        address.sa_family = sa_family_t(AF_INET)

        reachability = withUnsafePointer(to: &address) { SCNetworkReachabilityCreateWithAddress(nil, $0) }
        lastStatus = .unreachable
        connectionLossDate = nil

        lastStatus = status
        if lastStatus == .unreachable {
            connectionLossDate = Date()
        }
    }

    deinit {
        stopProducingEvents()
    }

    // MARK: EventProducer

    func startProducingEvents() {
        guard !listening else { return }

        lastStatus = status
        if let reachability = reachability {
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            SCNetworkReachabilitySetDispatchQueue(reachability, queue)
            SCNetworkReachabilitySetCallback(reachability, _reachabilityCallback, &context)
        }
        listening = true
    }

    func stopProducingEvents() {
        guard listening else { return }

        if let reachability = reachability {
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
        }
        listening = false
    }

    // MARK: Status updates

    fileprivate func updateStatus() {
        let status = self.status
        guard status != lastStatus else { return }

        switch status {
        case .reachableViaWiFi, .reachableViaData:
            connectionLossDate = nil
            if lastStatus == .unreachable {
                eventListener?.onEvent(NetworkEvent.connectionRetrieved, generetedBy: self)
            } else {
                eventListener?.onEvent(NetworkEvent.networkChanged, generetedBy: self)
            }
        case .unreachable:
            connectionLossDate = Date()
            eventListener?.onEvent(NetworkEvent.connectionLost, generetedBy: self)
        }
    }
}

private func _reachabilityCallback(_: SCNetworkReachability, _: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }

    let eventProducer = Unmanaged<NetworkEventProducer>.fromOpaque(info).takeUnretainedValue()
    DispatchQueue.main.async {
        eventProducer.updateStatus()
    }
}
