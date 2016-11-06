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
    let item1 = AudioItem(highQualitySoundURL: URL(string: "https://github.com"))!
    let item2 = AudioItem(highQualitySoundURL: URL(string: "https://github.com/delannoyk"))!
    let item3 = AudioItem(highQualitySoundURL: URL(string: "https://google.com"))!

    func testEmptyQueueGivesNilAsNextItem() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssert((try! queue.nextItem()) === nil)
    }

    func testQueueInNormalModeAndHistoric() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssert((try! queue.nextItem()) === item1)
        XCTAssert((try! queue.nextItem()) === item2)
        XCTAssert((try! queue.nextItem()) === item3)
        XCTAssert((try! queue.nextItem()) === nil)
        XCTAssert((try! queue.nextItem()) === nil)

        XCTAssertEqual(queue.historic.count, 3)
        XCTAssert(queue.historic[0] === item1)
        XCTAssert(queue.historic[1] === item2)
        XCTAssert(queue.historic[2] === item3)
    }

    func testQueueInShuffleMode() {
        //TODO: how to test randomness?
    }

    func testQueueInRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        for _ in 0...100 {
            XCTAssert((try! queue.nextItem()) === item1)
        }
    }

    func testQueueInRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        for _ in 0...100 {
            XCTAssert((try! queue.nextItem()) === item1)
            XCTAssert((try! queue.nextItem()) === item2)
            XCTAssert((try! queue.nextItem()) === item3)
        }
    }

    func testQueueInNormalModelAfterSwitchingIfFromRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        _ = try! queue.nextItem()

        queue.mode = .normal
        XCTAssert((try! queue.nextItem()) === item2)

        let queue2 = AudioItemQueue(items: [item1], mode: .repeat)
        _ = try! queue2.nextItem()

        queue2.mode = .normal
        XCTAssert((try! queue2.nextItem()) === nil)
    }

    func testQueueInShuffleModeAfterSwitchingItFromNormalMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssert((try! queue.nextItem()) === item1)

        queue.mode = .shuffle
        for _ in 0...100 {
            XCTAssert((try! queue.nextItem()) !== item1)
        }
        queue.nextPosition = 0
        queue.mode = .normal
    }

    func testQueueInShuffleModeCombinedWithRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.repeat, .shuffle])
        let item = try! queue.nextItem()

        for _ in 0...100 {
            XCTAssert(try! queue.nextItem() === item)
        }
    }

    func testQueueInShuffleModeCombinedWithRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.repeatAll, .shuffle])
        let queued = queue.queue

        for _ in 0...100 {
            let q = try! [queue.nextItem()!, queue.nextItem()!, queue.nextItem()!]
            XCTAssertEqual(queued, q)
        }
    }

    func testAdaptModeWhenQueueIsEmpty() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssertEqual(try! queue.nextItem(), nil)
        queue.mode = .shuffle
        XCTAssertEqual(try! queue.nextItem(), nil)
    }

    func testHasNextItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.normal])
        XCTAssert(queue.hasNextItem)
        _ = try! queue.nextItem()
        XCTAssert(queue.hasNextItem)
        _ = try! queue.nextItem()
        XCTAssert(queue.hasNextItem)
        _ = try! queue.nextItem()
        XCTAssertFalse(queue.hasNextItem)

        queue.mode = .repeat
        for _ in 0...100 {
            _ = try! queue.nextItem()
            XCTAssert(queue.hasNextItem)
        }

        queue.mode = .repeatAll
        for _ in 0...100 {
            _ = try! queue.nextItem()
            XCTAssert(queue.hasNextItem)
        }

        let queue2 = AudioItemQueue(items: [], mode: .normal)
        XCTAssertFalse(queue2.hasNextItem)
        queue2.mode = .repeatAll
        XCTAssertFalse(queue2.hasNextItem)
        queue2.mode = .repeat
        XCTAssertFalse(queue2.hasNextItem)
    }

    func testPreviousInNormalMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssertFalse(queue.hasPreviousItem)
        XCTAssertNil(try! queue.previousItem())

        _ = try! queue.nextItem()
        XCTAssert(queue.hasNextItem)
        XCTAssert((try! queue.previousItem()) === item1)
    }

    func testPreviousInRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        XCTAssert(queue.hasPreviousItem)

        for _ in 0...100 {
            XCTAssert((try! queue.previousItem()) === item1)
        }

        queue.mode = .normal
        XCTAssert(queue.nextItem() === item2)

        queue.mode = .repeat
        for _ in 0...100 {
            XCTAssert(queue.previousItem() === item2)
        }
    }

    func testPreviousInRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        for _ in 0...100 {
            XCTAssert(queue.hasPreviousItem)
            XCTAssert((try! queue.previousItem()) === item3)
            XCTAssert((try! queue.previousItem()) === item2)
            XCTAssert((try! queue.previousItem()) === item1)
        }
    }

    func testPreviousItemWhenQueueIsEmpty() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssertEqual(try! queue.previousItem(), nil)
    }

    func testAddItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2], mode: .normal)
        queue.add(items: [item3])
        XCTAssertEqual(queue.queue, [item1, item2, item3])
    }

    func testRemoveItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        queue.remove(at: 2)
        XCTAssertEqual(queue.queue, [item1, item2])
    }

    func testEmptyQueueHasNoPreviousNorNextItem() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssertFalse(queue.hasPreviousItem)
        XCTAssertFalse(queue.hasNextItem)
    }
}
