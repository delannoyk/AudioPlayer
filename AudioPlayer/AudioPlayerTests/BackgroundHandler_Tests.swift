//
//  BackgroundHandler_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 22/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class BackgroundHandler_Tests: XCTestCase {
    var application = FakeApplication()
    var backgroundHandler: BackgroundHandler!
    
    override func setUp() {
        super.setUp()
        backgroundHandler = BackgroundHandler()
        backgroundHandler.backgroundTaskCreator = application
    }
    
    override func tearDown() {
        backgroundHandler = nil
        super.tearDown()
    }

    func testMultipleBeginDoesNotChangeIdentifier() {
        application.onBegin = { handler in
            return UIBackgroundTaskIdentifier.init(rawValue: 1)
        }
        XCTAssert(backgroundHandler.beginBackgroundTask())
        application.onBegin = { handler in
            return UIBackgroundTaskIdentifier.init(rawValue: 2)
        }
        XCTAssertFalse(backgroundHandler.beginBackgroundTask())
    }

    func testStartingThenEndingResetState() {
        application.onBegin = { handler in
            return UIBackgroundTaskIdentifier.init(rawValue: 1)
        }
        XCTAssert(backgroundHandler.beginBackgroundTask())

        application.onEnd = { identifier in
            XCTAssertEqual(identifier.rawValue, 1)
        }
        XCTAssert(backgroundHandler.endBackgroundTask())
        XCTAssert(backgroundHandler.beginBackgroundTask())
        XCTAssert(backgroundHandler.endBackgroundTask())
    }

    func testEndingReturnsFalseIfTaskNotStarted() {
        XCTAssertFalse(backgroundHandler.endBackgroundTask())
    }

    func testHandlerEndsTaskIfCalled() {
        var handler: (() -> ())?
        application.onBegin = { h in
            handler = h
            return UIBackgroundTaskIdentifier.init(rawValue: 1)
        }
        XCTAssert(backgroundHandler.beginBackgroundTask())
        XCTAssertNotNil(handler)
        handler?()
        XCTAssertFalse(backgroundHandler.endBackgroundTask())
    }
}
