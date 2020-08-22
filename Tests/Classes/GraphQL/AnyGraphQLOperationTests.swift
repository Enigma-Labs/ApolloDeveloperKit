//
//  AnyGraphQLOperationTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class AnyGraphQLOperationTests: XCTestCase {
    func testInitWithJSONObject_withValidJSONObject() throws {
        let jsonObject: JSONObject = [
            "variables": [
                "input": [
                    "string": "foo" as NSString,
                    "integer": 42 as NSNumber,
                    "float": 4.2 as NSNumber,
                    "boolean": true as CFBoolean,
                    "array": ["foo"] as NSArray,
                    "null": NSNull()
                ]
            ],
            "operationName": NSNull(),
            "query": "query { posts { id } }"
        ]
        let operation = try Operation(jsonValue: jsonObject)
        let request = try AnyGraphQLOperation(operation: operation)
        XCTAssertNil(request.operationIdentifier)
        XCTAssertEqual(request.operationType, .query)
        XCTAssertEqual(request.operationDefinition, "query { posts { id } }")
        XCTAssertEqual(request.variables?.count, 1)
        guard let input = request.variables?["input"] as? [String: Any] else{
            return XCTFail()
        }
        XCTAssertEqual(input["string"] as? String, "foo")
        XCTAssertEqual(input["integer"] as? Int, 42)
        XCTAssertEqual(input["float"] as? Double, 4.2)
        XCTAssertEqual(input["boolean"] as? Bool, true)
        XCTAssertEqual(input["array"] as? [String], ["foo"])
    }
}
