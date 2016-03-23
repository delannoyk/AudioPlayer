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
    var application = UIApplication.sharedApplication()
    var backgroundHandler: BackgroundHandler!
    
    override func setUp() {
        super.setUp()
        backgroundHandler = BackgroundHandler()
    }
    
    override func tearDown() {
        backgroundHandler = nil
        super.tearDown()
    }

    func testMultipleBeginDoesNotChangeIdentifier() {
        print("WTF: \(UIApplication.sharedApplication().fake_beginBackgroundTaskWithExpirationHandler({}))")

        application.onBegin = { handler in
            return 1
        }
        XCTAssert(backgroundHandler.beginBackgroundTask())
        application.onBegin = { handler in
            return 2
        }
        XCTAssertFalse(backgroundHandler.beginBackgroundTask())
    }

    func testStartingThenEndingResetState() {
        application.onBegin = { handler in
            return 1
        }
        XCTAssert(backgroundHandler.beginBackgroundTask())

        application.onEnd = { identifier in
            XCTAssertEqual(identifier, 1)
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
            return 1
        }
        XCTAssert(backgroundHandler.beginBackgroundTask())
        XCTAssertNotNil(handler)
        handler?()
        XCTAssertFalse(backgroundHandler.endBackgroundTask())
    }
}
