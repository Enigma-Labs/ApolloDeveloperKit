//
//  EventStreamQueueMap.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

public class EventStreamQueueMap<Key: AnyObject> {
    private let queuesByKey = NSMapTable<Key, EventStreamQueue>.weakToStrongObjects()

    var count: Int {
        return queuesByKey.keyEnumerator().allObjects.count
    }

    var isEmpty: Bool {
        return count == 0
    }

    func enqueue(chunk: EventStreamChunk, forKey key: Key) {
        if let queue = queuesByKey.object(forKey: key) {
            queue.enqueue(chunk: chunk)
        } else {
            let queue = EventStreamQueue()
            queue.enqueue(chunk: chunk)
            queuesByKey.setObject(queue, forKey: key)
        }
    }

    func enqueueForAllKeys(chunk: EventStreamChunk) {
        for key in queuesByKey.keyEnumerator() {
            enqueue(chunk: chunk, forKey: key as! Key)
        }
    }

    func dequeue(key: Key) -> EventStreamChunk? {
        return queuesByKey.object(forKey: key)?.dequeue()
    }
}
