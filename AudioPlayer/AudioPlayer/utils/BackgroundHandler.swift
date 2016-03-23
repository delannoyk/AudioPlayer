//
//  BackgroundHandler.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 22/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

#if os(OSX)
    import Foundation
#else
    import UIKit
#endif

/**
 *  A `BackgroundHandler` handles background.
 */
class BackgroundHandler: NSObject {
    /// The backround task identifier if a background task started. Nil if not.
    private var backgroundTaskIdentifier: Int?

    /**
     Starts a background task if there isn't already one.

     - returns: A boolean value indicating whether a background task was created or not.
     */
    func beginBackgroundTask() -> Bool {
        #if os(OSX)
            return false
        #else
            guard backgroundTaskIdentifier == nil else {
                return false
            }

            let application = UIApplication.sharedApplication()
            backgroundTaskIdentifier = application.beginBackgroundTaskWithExpirationHandler {
                [weak self] in

                if let backgroundTaskIdentifier = self?.backgroundTaskIdentifier {
                    application.endBackgroundTask(backgroundTaskIdentifier)
                }
                self?.backgroundTaskIdentifier = nil
            }
            return true
        #endif
    }

    /**
     Ends the background task if there is one.

     - returns: A boolean value indicating whether a background task was ended or not.
     */
    func endBackgroundTask() -> Bool {
        #if os(OSX)
            return false
        #else
            guard let backgroundTaskIdentifier = backgroundTaskIdentifier else {
                return false
            }

            let application = UIApplication.sharedApplication()
            if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                application.endBackgroundTask(backgroundTaskIdentifier)
            }
            self.backgroundTaskIdentifier = nil
            return true
        #endif
    }
}
