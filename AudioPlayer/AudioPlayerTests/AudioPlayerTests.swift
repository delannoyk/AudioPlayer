//
//  AudioPlayerTests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 02/12/15.
//  Copyright © 2015 Kevin Delannoy. All rights reserved.
//

import XCTest
import AudioPlayer

class AudioPlayerTests: XCTestCase {
    let player = AudioPlayer()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let URL = NSURL(string: "https://www.google.be")
        let item = AudioItem(highQualitySoundURL: URL, mediumQualitySoundURL: URL, lowQualitySoundURL: URL)
        player.playItem(item!)

        let expect = expectationWithDescription("")
        waitForExpectationsWithTimeout(10) { (error) -> Void in
            expect.fulfill()
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
