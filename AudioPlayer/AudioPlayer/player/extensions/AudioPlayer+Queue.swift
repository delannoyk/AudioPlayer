//
//  AudioPlayer+Queue.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 29/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

extension AudioPlayer {
    /// The items in the queue if any.
    public var items: [AudioItem]? {
        return queue?.queue
    }

    /// The current item index in queue.
    public var currentItemIndexInQueue: Int? {
        if let currentItem = currentItem {
            return queue?.items.indexOf(currentItem)
        }
        return nil
    }

    /// A boolean value indicating whether there is a next item to play or not.
    public var hasNext: Bool {
        return queue?.hasNextItem ?? false
    }

    /// A boolean value indicating whether there is a previous item to play or not.
    public var hasPrevious: Bool {
        return queue?.hasPreviousItem ?? false
    }

    /**
     Play an item.

     - parameter item: The item to play.
     */
    public func playItem(item: AudioItem) {
        playItems([item])
    }

    /**
     Creates a queue according to the current mode and plays it.

     - parameter items: The items to play.
     - parameter index: The index to start the player with.
     */
    public func playItems(items: [AudioItem], startAtIndex index: Int = 0) {
        if items.count > 0 {
            queue = AudioItemQueue(items: items, mode: mode)
            if let realIndex = queue?.queue.indexOf(items[index]) {
                queue?.nextPosition = realIndex
            }
            currentItem = queue?.nextItem()
        } else {
            stop()
            queue = nil
        }
    }

    /**
     Adds an item at the end of the queue. If queue is empty and player isn't
     playing, the behaviour will be similar to `playItem(item)`.

     - parameter item: The item to add.
     */
    public func addItemToQueue(item: AudioItem) {
        addItemsToQueue([item])
    }

    /**
     Adds items at the end of the queue. If the queue is empty and player isn't
     playing, the behaviour will be similar to `playItems(items)`.

     - parameter items: The items to add.
     */
    public func addItemsToQueue(items: [AudioItem]) {
        if let queue = queue {
            queue.addItems(items)
        } else {
            playItems(items)
        }
    }

    /**
     Removes an item at a specific index in the queue.

     - parameter index: The index of the item to remove.
     */
    public func removeItemAtIndex(index: Int) {
        queue?.removeItemAtIndex(index)
    }
}
