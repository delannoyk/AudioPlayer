//
//  NSURL+Offline_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 15/05/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class NSURL_Offline_Tests: XCTestCase {
    func testOfflineURLs() {
        XCTAssertTrue(NSURL(fileURLWithPath: "/home/xxx").ap_isOfflineURL)
        XCTAssertTrue(NSURL(string: "http://localhost://")!.ap_isOfflineURL)
        XCTAssertTrue(NSURL(string: "http://127.0.0.1/xxx")!.ap_isOfflineURL)
    }

    func testOnlineURL() {
        XCTAssertFalse(NSURL(string: "http://google.com")!.ap_isOfflineURL)
        XCTAssertFalse(NSURL(string: "http://apple.com")!.ap_isOfflineURL)
    }
}
