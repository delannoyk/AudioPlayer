//
//  Fakes.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 09/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation
import SystemConfiguration
@testable import AudioPlayer

class FakeEventListener: EventListener {
    var eventClosure: ((Event, EventProducer) -> ())?

    func onEvent(event: Event, generetedBy eventProducer: EventProducer) {
        eventClosure?(event, eventProducer)
    }
}

class FakeReachability: Reachability {
    var reachabilityStatus = Reachability.NetworkStatus.NotReachable {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(ReachabilityChangedNotification,
                object: self)
        }
    }

    override var currentReachabilityStatus: Reachability.NetworkStatus {
        get {
            return reachabilityStatus
        }
    }

    override class func reachabilityForInternetConnection() -> FakeReachability {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let ref = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        return FakeReachability(reachabilityRef: ref)
    }
}
