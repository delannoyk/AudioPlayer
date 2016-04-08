/*
Copyright (c) 2014, Ashley Mills
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

import SystemConfiguration
import Foundation

let kReachabilityChangedNotification = "ReachabilityChangedNotification"

func callback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags,
    info: UnsafeMutablePointer<Void>) {
        let reachability = Unmanaged<Reachability>.fromOpaque(COpaquePointer(info))
            .takeUnretainedValue()

        dispatch_async(dispatch_get_main_queue()) {
            reachability.reachabilityChanged(flags)
        }
}

class Reachability: NSObject {
    enum NetworkStatus {
        case NotReachable, ReachableViaWiFi, ReachableViaWWAN
    }

    // MARK: - *** properties ***

    var reachableOnWWAN: Bool
    var notificationCenter = NSNotificationCenter.defaultCenter()

    var currentReachabilityStatus: NetworkStatus {
        if isReachable() {
            if isReachableViaWiFi() {
                return .ReachableViaWiFi
            }
            if isRunningOnDevice {
                return .ReachableViaWWAN
            }
        }
        return .NotReachable
    }

    // MARK: - *** Initialisation methods ***

    required init(reachabilityRef: SCNetworkReachability?) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }

    class func reachabilityForInternetConnection() -> Reachability {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let ref = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        return Reachability(reachabilityRef: ref)
    }

    // MARK: - *** Notifier methods ***

    func startNotifier() -> Bool {
        if notifierRunning {
            return true
        }

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil,
            copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

        if SCNetworkReachabilitySetCallback(reachabilityRef!, callback, &context) {
            if SCNetworkReachabilitySetDispatchQueue(reachabilityRef!, reachabilitySerialQueue) {
                notifierRunning = true
                return true
            }
        }

        stopNotifier()
        return false
    }

    func stopNotifier() {
        if let reachabilityRef = reachabilityRef {
            SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        }
        notifierRunning = false
    }

    // MARK: - *** Connection test methods ***

    func isReachable() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isReachableWithFlags(flags)
        })
    }

    func isReachableViaWiFi() -> Bool {
        return isReachableWithTest() { flags -> Bool in
            // Check we're reachable
            if self.isReachable(flags) {
                if self.isRunningOnDevice {
                    // Check we're NOT on WWAN
                    if self.isOnWWAN(flags) {
                        return false
                    }
                }
                return true
            }
            return false
        }
    }

    // MARK: - *** Private methods ***

    #if (arch(i386) || arch(x86_64)) && os(iOS)
    private let isRunningOnDevice = false
    #else
    private let isRunningOnDevice = true
    #endif

    private var notifierRunning = false

    private var reachabilityRef: SCNetworkReachability?

    private let reachabilitySerialQueue = dispatch_queue_create("uk.co.ashleymills.reachability",
        DISPATCH_QUEUE_SERIAL)

    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        notificationCenter.postNotificationName(kReachabilityChangedNotification, object:self)
    }

    private func isReachableWithFlags(flags: SCNetworkReachabilityFlags) -> Bool {
        let reachable = isReachable(flags)
        if !reachable {
            return false
        }

        if isConnectionRequiredOrTransient(flags) {
            return false
        }

        if isRunningOnDevice {
            if isOnWWAN(flags) && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        return true
    }

    private func isReachableWithTest(test: (SCNetworkReachabilityFlags) -> (Bool)) -> Bool {
        if let reachabilityRef = reachabilityRef {
            var flags = SCNetworkReachabilityFlags(rawValue: 0)
            let gotFlags = withUnsafeMutablePointer(&flags) {
                SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
            }

            if gotFlags {
                return test(flags)
            }
        }
        return false
    }

    // WWAN may be available, but not active until a connection has been established.
    // WiFi may require a connection for VPN on Demand.

    private func isOnWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags.contains(.IsWWAN)
            #else
            return false
        #endif
    }

    private func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.Reachable)
    }

    private func isConnectionRequiredOrTransient(flags: SCNetworkReachabilityFlags) -> Bool {
        let testcase: SCNetworkReachabilityFlags = [.ConnectionRequired, .TransientConnection]
        return flags.intersect(testcase) == testcase
    }

    private var reachabilityFlags: SCNetworkReachabilityFlags {
        if let reachabilityRef = reachabilityRef {

            var flags = SCNetworkReachabilityFlags(rawValue: 0)
            let gotFlags = withUnsafeMutablePointer(&flags) {
                SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
            }

            if gotFlags {
                return flags
            }
        }

        return []
    }

    deinit {
        stopNotifier()
        reachabilityRef = nil
    }
}
