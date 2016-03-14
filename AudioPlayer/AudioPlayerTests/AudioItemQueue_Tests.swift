//
//  AudioItemQueue_Tests.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 12/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import XCTest
@testable import AudioPlayer

class AudioItemQueue_Tests: XCTestCase {
    let item1 = AudioItem(highQualitySoundURL: NSURL(string: "https://github.com"))!
    let item2 = AudioItem(highQualitySoundURL: NSURL(string: "https://github.com/delannoyk"))!
    let item3 = AudioItem(highQualitySoundURL: NSURL(string: "https://google.com"))!

    func testEmptyQueueGivesNilAsNextItem() {
        let queue = AudioItemQueue(items: [], mode: .Normal)
        XCTAssert(queue.nextItem() === nil)
    }

    func testQueueInNormalModeAndHistoric() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Normal)
        XCTAssert(queue.nextItem() === item1)
        XCTAssert(queue.nextItem() === item2)
        XCTAssert(queue.nextItem() === item3)
        XCTAssert(queue.nextItem() === nil)
        XCTAssert(queue.nextItem() === nil)

        XCTAssertEqual(queue.historic.count, 3)
        XCTAssert(queue.historic[0] === item1)
        XCTAssert(queue.historic[1] === item2)
        XCTAssert(queue.historic[2] === item3)
    }

    func testQueueInShuffleMode() {
        //TODO: how to test randomness?
    }

    func testQueueInRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Repeat)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
        }
    }

    func testQueueInRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .RepeatAll)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
            XCTAssert(queue.nextItem() === item2)
            XCTAssert(queue.nextItem() === item3)
        }
    }

    func testQueueInNormalModelAfterSwitchingIfFromRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Repeat)
        _ = queue.nextItem()

        queue.mode = .Normal
        XCTAssert(queue.nextItem() === item2)

        let queue2 = AudioItemQueue(items: [item1], mode: .Repeat)
        _ = queue2.nextItem()

        queue2.mode = .Normal
        XCTAssert(queue2.nextItem() === nil)
    }

    func testQueueInShuffleModeAfterSwitchingItFromNormalMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Normal)
        XCTAssert(queue.nextItem() === item1)

        queue.mode = .Shuffle
        for _ in 0...100 {
            XCTAssert(queue.nextItem() !== item1)
        }
        queue.nextPosition = 0
        queue.mode = .Normal
    }

    func testQueueInShuffleModeCombinedWithRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.Repeat, .Shuffle])
        let item = queue.nextItem()

        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item)
        }
    }

    func testQueueInShuffleModeCombinedWithRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.RepeatAll, .Shuffle])
        let queued = queue.queue

        for _ in 0...100 {
            let q = [queue.nextItem()!, queue.nextItem()!, queue.nextItem()!]
            XCTAssertEqual(queued, q)
        }
    }

    func testAdaptModeWhenQueueIsEmpty() {
        let queue = AudioItemQueue(items: [], mode: .Normal)
        XCTAssertEqual(queue.nextItem(), nil)
        queue.mode = .Shuffle
        XCTAssertEqual(queue.nextItem(), nil)
    }

    func testHasNextItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.Normal])
        XCTAssert(queue.hasNextItem)
        _ = queue.nextItem()
        XCTAssert(queue.hasNextItem)
        _ = queue.nextItem()
        XCTAssert(queue.hasNextItem)
        _ = queue.nextItem()
        XCTAssertFalse(queue.hasNextItem)

        queue.mode = .Repeat
        for _ in 0...100 {
            _ = queue.nextItem()
            XCTAssert(queue.hasNextItem)
        }

        queue.mode = .RepeatAll
        for _ in 0...100 {
            _ = queue.nextItem()
            XCTAssert(queue.hasNextItem)
        }

        let queue2 = AudioItemQueue(items: [], mode: .Normal)
        XCTAssertFalse(queue2.hasNextItem)
        queue2.mode = .RepeatAll
        XCTAssertFalse(queue2.hasNextItem)
        queue2.mode = .Repeat
        XCTAssertFalse(queue2.hasNextItem)
    }

    func testPreviousInNormalMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Normal)
        XCTAssertFalse(queue.hasPreviousItem)
        XCTAssertNil(queue.previousItem())

        _ = queue.nextItem()
        XCTAssert(queue.hasNextItem)
        XCTAssert(queue.previousItem() === item1)
    }

    func testPreviousInRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Repeat)
        XCTAssert(queue.hasPreviousItem)

        for _ in 0...100 {
            XCTAssert(queue.previousItem() === item1)
        }
    }

    func testPreviousInRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .RepeatAll)
        for _ in 0...100 {
            XCTAssert(queue.hasPreviousItem)
            XCTAssert(queue.previousItem() === item3)
            XCTAssert(queue.previousItem() === item2)
            XCTAssert(queue.previousItem() === item1)
        }
    }

    func testPreviousItemWhenQueueIsEmpty() {
        let queue = AudioItemQueue(items: [], mode: .Normal)
        XCTAssertEqual(queue.previousItem(), nil)
    }

    func testAddItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2], mode: .Normal)
        queue.addItems([item3])
        XCTAssertEqual(queue.queue, [item1, item2, item3])
    }

    func testRemoveItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .Normal)
        queue.removeItemAtIndex(2)
        XCTAssertEqual(queue.queue, [item1, item2])
    }
}
