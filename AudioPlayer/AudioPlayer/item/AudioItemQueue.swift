//
//  AudioItemQueue.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 11/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

// MARK: - Array+Shuffe

private extension Array {
    /**
     Shuffles the element in the array and returns the new array.

     - returns: A shuffled array.
     */
    func shuffled() -> [Element] {
        return sort { element1, element2 in
            random() % 2 == 0
        }
    }
}

// MARK: - AudioItemQueue

/**
 *  `AudioItemQueue` handles queueing items with a playing mode.
 */
class AudioItemQueue {
    /// The original items, keeping the same order.
    private(set) var items: [AudioItem]

    /// The items stored in the way the mode requires.
    private(set) var queue: [AudioItem]

    /// The historic of items played in the queue.
    private(set) var historic: [AudioItem]

    /// The current position in the queue.
    var nextPosition = 0

    /// The player mode. It will affect the queue.
    var mode: AudioPlayerMode {
        didSet {
            adaptQueue(oldValue)
        }
    }

    /**
     Initializes a queue with a list of items and the mode.

     - parameter items: The list of items to play.
     - parameter mode:  The mode to play items with.
     */
    init(items: [AudioItem], mode: AudioPlayerMode) {
        self.items = items
        self.mode = mode
        queue = mode.contains(.Shuffle) ? items.shuffled() : items
        historic = []
    }

    /**
     Adapts the queue to the new mode.
     Behaviour is:
       - `oldMode` contains .Repeat, `mode` doesn't and last item played == nextItem, we increment
            position.
       - `oldMode` contains .Shuffle, `mode` doesnt. We should set the queue to `items` and set
            current position to the current item index in the new queue.
       - `mode` contains .Shuffle, `oldMode` doesn't. We should shuffle the leftover items in queue.
            Also, the items already played should also be shuffled. Current implementation has a
            limitation which is that the "already played items" will be shuffled at the begining of
            the queue while the leftovers will be shuffled at the end of the array.

     - parameter oldMode: The mode before it changed.
     */
    private func adaptQueue(oldMode: AudioPlayerMode) {
        //Early exit if queue is empty
        guard queue.count > nextPosition else {
            return
        }

        if oldMode.contains(.Repeat) && !mode.contains(.Repeat) &&
            historic.last == queue[nextPosition] {
                nextPosition += 1
        }
        if oldMode.contains(.Shuffle) && !mode.contains(.Shuffle) {
            queue = items
            if let last = historic.last, index = queue.indexOf(last) {
                nextPosition = index + 1
            }
        } else if mode.contains(.Shuffle) && !oldMode.contains(.Shuffle) {
            let alreadyPlayed = queue.prefixUpTo(nextPosition)
            let leftovers = queue.suffixFrom(nextPosition)
            queue = Array(alreadyPlayed).shuffled() + Array(leftovers).shuffled()
        }
    }

    /**
     Returns the next item in the queue.

     - returns: The next item in the queue.
     */
    @warn_unused_result
    func nextItem() -> AudioItem? {
        //Early exit if queue is empty
        guard queue.count > 0 else {
            return nil
        }

        if nextPosition < queue.count {
            let item = queue[nextPosition]
            if !mode.contains(.Repeat) {
                nextPosition += 1
            }
            historic.append(item)
            return item
        }

        if mode.contains(.RepeatAll) {
            nextPosition = 0
            return nextItem()
        }
        return nil
    }

    /// A boolean value indicating whether the queue has a next item to play or not.
    var hasNextItem: Bool {
        if queue.count > 0 &&
            (queue.count > nextPosition || mode.contains(.Repeat) || mode.contains(.RepeatAll)) {
                return true
        }
        return false
    }

    /**
     Returns the previous item in the queue.

     - returns: The previous item in the queue.
     */
    @warn_unused_result
    func previousItem() -> AudioItem? {
        //Early exit if queue is empty
        guard queue.count > 0 else {
            return nil
        }

        let previousPosition = mode.contains(.Repeat) ? nextPosition : nextPosition - 1
        if previousPosition >= 0 {
            let item = queue[previousPosition]
            nextPosition = previousPosition
            historic.append(item)
            return item
        }

        if mode.contains(.RepeatAll) {
            nextPosition = queue.count
            return previousItem()
        }
        return nil
    }

    /// A boolean value indicating whether the queue has a previous item to play or not.
    var hasPreviousItem: Bool {
        if queue.count > 0 &&
            (nextPosition > 0 || mode.contains(.Repeat) || mode.contains(.RepeatAll)) {
                return true
        }
        return false
    }

    /**
     Adds a list of items to the queue.

     - parameter newItems: The items to add to the queue.
     */
    func addItems(newItems: [AudioItem]) {
        items.appendContentsOf(newItems)
        queue.appendContentsOf(newItems)
    }

    /**
     Removes an item from the queue.

     - parameter index: The index of the item to remove.
     */
    func removeItemAtIndex(index: Int) {
        assert(index >= 0, "cannot remove an item at negative index")
        assert(index < queue.count, "cannot remove an item at an index > queue.count")

        let item = queue.removeAtIndex(index)
        if let index = items.indexOf(item) {
            items.removeAtIndex(index)
        }
    }
}
