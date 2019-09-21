//
//  EventStreamQueueMapTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class EventStreamQueueMapTests: XCTestCase {
    func testDequeue() {
        let queueMap = EventStreamQueueMap<NSObject>()
        let key = NSObject()
        XCTAssertNil(queueMap.dequeue(key: key))
    }

    func testEnqueueAndDequeue() {
        let queueMap = EventStreamQueueMap<NSObject>()
        let chunk = EventStreamChunk()
        let key = NSObject()
        queueMap.enqueue(chunk: chunk, forKey: key)
        let dequeuedChunk = queueMap.dequeue(key: key)
        XCTAssertEqual(dequeuedChunk?.data, chunk.data)
    }

    func testEnqueueForAllKeys() {
        XCTContext.runActivity(named: "while key is being retained") { _ in
            let queueMap = EventStreamQueueMap<NSObject>()
            let chunk = EventStreamChunk()
            let key = NSObject()
            queueMap.enqueue(chunk: chunk, forKey: key)
            queueMap.enqueueForAllKeys(chunk: chunk)
            var dequeuedChunk = queueMap.dequeue(key: key)
            XCTAssertEqual(dequeuedChunk?.data, chunk.data)
            dequeuedChunk = queueMap.dequeue(key: key)
            XCTAssertEqual(dequeuedChunk?.data, chunk.data)
        }
        XCTContext.runActivity(named: "while key is being released") { _ in
            let queueMap = EventStreamQueueMap<NSObject>()
            let chunk = EventStreamChunk()
            do {
                let key = NSObject()
                queueMap.enqueue(chunk: chunk, forKey: key)
            }
            queueMap.enqueueForAllKeys(chunk: chunk)
            XCTAssertTrue(queueMap.isEmpty)
        }
    }
}
