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

    private class MockDelegate: AudioItemQueueDelegate {
        private let ununavailableItems: [AudioItem]

        init(ununavailableItems: [AudioItem]) {
            self.ununavailableItems = ununavailableItems
        }

        func audioItemQueue(_ queue: AudioItemQueue, shouldConsiderItem item: AudioItem) -> Bool {
            return !ununavailableItems.contains(item)
        }
    }

    func testEmptyQueueGivesNilAsNextItem() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssert(queue.nextItem() === nil)
    }

    func testQueueInNormalModeAndHistoric() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
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
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
        }
    }

    func testQueueInRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
            XCTAssert(queue.nextItem() === item2)
            XCTAssert(queue.nextItem() === item3)
        }
    }

    func testQueueInNormalModelAfterSwitchingIfFromRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        XCTAssertNotNil(queue.nextItem())

        queue.mode = .normal
        XCTAssert(queue.nextItem() === item2)

        let queue2 = AudioItemQueue(items: [item1], mode: .repeat)
        XCTAssertNotNil(queue2.nextItem())

        queue2.mode = .normal
        XCTAssert(queue2.nextItem() === nil)
    }

    func testQueueInShuffleModeAfterSwitchingItFromNormalMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssert(queue.nextItem() === item1)

        queue.mode = .shuffle
        for _ in 0...100 {
            XCTAssert(queue.nextItem() !== item1)
        }
        queue.nextPosition = 0
        queue.mode = .normal
    }

    func testQueueInShuffleModeCombinedWithRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.repeat, .shuffle])
        let item = queue.nextItem()

        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item)
        }
    }

    func testQueueInShuffleModeCombinedWithRepeatAllMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: [.repeatAll, .shuffle])
        let queued = queue.queue

        for _ in 0...100 {
            let q = [queue.nextItem()!, queue.nextItem()!, queue.nextItem()!]
            XCTAssertEqual(queued, q)
        }
    }

    func testAdaptModeWhenQueueIsEmpty() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssertEqual(queue.nextItem(), nil)
        queue.mode = .shuffle
        XCTAssertEqual(queue.nextItem(), nil)
    }

    func testHasNextItemInQueue() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        XCTAssert(queue.hasNextItem)
        XCTAssertNotNil(queue.nextItem())
        XCTAssert(queue.hasNextItem)
        XCTAssertNotNil(queue.nextItem())
        XCTAssert(queue.hasNextItem)
        XCTAssertNotNil(queue.nextItem())
        XCTAssertFalse(queue.hasNextItem)

        queue.mode = .repeat
        for _ in 0...100 {
            XCTAssertNotNil(queue.nextItem())
            XCTAssert(queue.hasNextItem)
        }

        queue.mode = .repeatAll
        for _ in 0...100 {
            XCTAssertNotNil(queue.nextItem())
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
        XCTAssertNil(queue.previousItem())

        XCTAssertNotNil(queue.nextItem())
        XCTAssert(queue.hasNextItem)
        XCTAssert(queue.previousItem() === item1)
    }

    func testPreviousInRepeatMode() {
        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        XCTAssert(queue.hasPreviousItem)

        for _ in 0...100 {
            XCTAssert(queue.previousItem() === item1)
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
            XCTAssert(queue.previousItem() === item3)
            XCTAssert(queue.previousItem() === item2)
            XCTAssert(queue.previousItem() === item1)
        }
    }

    func testPreviousItemWhenQueueIsEmpty() {
        let queue = AudioItemQueue(items: [], mode: .normal)
        XCTAssertEqual(queue.previousItem(), nil)
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

    func testPreviousWhenOnItemIsNotAvailableInNormalMode() {
        let delegate = MockDelegate(ununavailableItems: [item2])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        queue.nextPosition = queue.queue.count
        queue.delegate = delegate

        XCTAssert(queue.previousItem() === item3)
        XCTAssert(queue.previousItem() === item1)
        XCTAssertNil(queue.previousItem())
    }

    func testPreviousWhenOnItemIsNotAvailableInRepeatMode() {
        let delegate = MockDelegate(ununavailableItems: [item2])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeat)
        queue.nextPosition = queue.queue.count - 1
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssert(queue.previousItem() === item2)
        }
    }

    func testPreviousWhenOnItemIsNotAvailableInRepeatAllMode() {
        let delegate = MockDelegate(ununavailableItems: [item2])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssert(queue.previousItem() === item3)
            XCTAssert(queue.previousItem() === item1)
        }
    }

    func testPreviousWhenNoItemIsNotAvailableInNormalMode() {
        let delegate = MockDelegate(ununavailableItems: [item1, item2, item3])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        queue.nextPosition = queue.queue.count - 1
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssertNil(queue.previousItem())
        }
    }

    func testPreviousWhenNoItemIsNotAvailableInRepeatAllMode() {
        let delegate = MockDelegate(ununavailableItems: [item1, item2, item3])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        queue.nextPosition = queue.queue.count - 1
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssertNil(queue.previousItem())
        }
    }

    func testNextWhenOnItemIsNotAvailableInNormalMode() {
        let delegate = MockDelegate(ununavailableItems: [item2])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        queue.delegate = delegate

        XCTAssert(queue.nextItem() === item1)
        XCTAssert(queue.nextItem() === item3)
        XCTAssertNil(queue.nextItem())
    }

    func testNextWhenOnItemIsNotAvailableInRepeatMode() {
        let delegate = MockDelegate(ununavailableItems: [item2])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        _ = queue.nextItem()
        queue.mode = .repeat
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item2)
        }
    }

    func testNextWhenOnItemIsNotAvailableInRepeatAllMode() {
        let delegate = MockDelegate(ununavailableItems: [item2])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssert(queue.nextItem() === item1)
            XCTAssert(queue.nextItem() === item3)
        }
    }

    func testNextWhenNoItemIsNotAvailableInNormalMode() {
        let delegate = MockDelegate(ununavailableItems: [item1, item2, item3])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .normal)
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssertNil(queue.nextItem())
        }
    }

    func testNextWhenNoItemIsNotAvailableInRepeatAllMode() {
        let delegate = MockDelegate(ununavailableItems: [item1, item2, item3])

        let queue = AudioItemQueue(items: [item1, item2, item3], mode: .repeatAll)
        queue.delegate = delegate

        for _ in 0...100 {
            XCTAssertNil(queue.nextItem())
        }
    }
}
