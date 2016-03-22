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

    #if !os(OSX)
    /// The application to create background task from.
    private let application: UIApplication

    init(application: UIApplication = UIApplication.sharedApplication()) {
        self.application = application
    }
    #endif

    /**
     Starts a background task if there isn't already one.
     */
    func beginBackgroundTask() {
        #if !os(OSX)
            guard backgroundTaskIdentifier == nil else {
                return
            }

            backgroundTaskIdentifier = application.beginBackgroundTaskWithExpirationHandler {
                [weak self] in

                if let backgroundTaskIdentifier = self?.backgroundTaskIdentifier {
                    self?.application.endBackgroundTask(backgroundTaskIdentifier)
                }
                self?.backgroundTaskIdentifier = nil
            }
        #endif
    }

    /**
     Ends the background task if there is one.
     */
    func endBackgroundTask() {
        #if !os(OSX)
            guard let backgroundTaskIdentifier = backgroundTaskIdentifier else {
                return
            }

            if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                application.endBackgroundTask(backgroundTaskIdentifier)
            }
            self.backgroundTaskIdentifier = nil
        #endif
    }
}
