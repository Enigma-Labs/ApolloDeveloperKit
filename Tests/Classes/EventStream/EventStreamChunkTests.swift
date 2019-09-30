//
//  EventStreamChunkTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 9/21/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class EventStreamChunkTests: XCTestCase {
    func testData_withEmptyData() {
        let chunk = EventStreamChunk()
        XCTAssertEqual(chunk.data, "0\r\n\r\n".data(using: .utf8)!)
    }

    func testData_withNonemptyData() {
        let chunk = EventStreamChunk(rawData: "data: foo\n\n".data(using: .utf8)!)
        XCTAssertEqual(chunk.data, "b\r\ndata: foo\n\n\r\n".data(using: .utf8)!)
    }
}
