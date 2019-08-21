//
//  HTTPServerTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 7/1/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class HTTPServerTests: XCTestCase {
    private static let server = HTTPServer()
    private static let mockHTTPRequestHandler = MockHTTPRequestHandler()

    override class func setUp() {
        server.requestHandler = mockHTTPRequestHandler
        try! server.start(port: 8085)
    }

    override class func tearDown() {
        server.stop()
    }

    func testIsRunning() {
        XCTAssertTrue(type(of: self).server.isRunning)
    }

    func testServerURL() {
        let serverURL = type(of: self).server.serverURL
        XCTAssertNotNil(serverURL)
        if let serverURL = serverURL {
            let regularExpression = try! NSRegularExpression(pattern: "http://\\d+\\.\\d+\\.\\d+\\.\\d+:8085", options: [])
            let range = NSRange(location: 0, length: serverURL.absoluteString.count)
            let matches = regularExpression.matches(in: serverURL.absoluteString, options: [], range: range)
            XCTAssertFalse(matches.isEmpty)
        }
    }

    func testGetRequest() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:8085")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["X-Request-Method"], "GET")
            XCTAssertEqual(headerFields?["X-Request-Url"], "/")
            XCTAssertEqual(data?.count, 0)
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testPostRequestWithContentLength() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:8085")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "foo".data(using: .utf8)!
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue("close", forHTTPHeaderField: "Connection")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["Content-Length"], "3")
            XCTAssertEqual(headerFields?["X-Request-Method"], "POST")
            XCTAssertEqual(headerFields?["X-Request-Url"], "/")
            let bodyString = data.flatMap { data in String(data: data, encoding: .utf8) }
            XCTAssertEqual(bodyString, "foo")
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}

class MockHTTPRequestHandler: HTTPRequestHandler {
    func server(_ server: HTTPServer, didReceiveRequest request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void) {
        let url = CFHTTPMessageCopyRequestURL(request)!.takeRetainedValue()
        let method = CFHTTPMessageCopyRequestMethod(request)!.takeRetainedValue()
        let body = CFHTTPMessageCopyBody(request)?.takeRetainedValue()
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        CFHTTPMessageSetHeaderFieldValue(response, "X-Request-Method" as CFString, method)
        CFHTTPMessageSetHeaderFieldValue(response, "X-Request-Url" as CFString, CFURLGetString(url))
        if let body = body {
            CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(CFDataGetLength(body)) as CFString)
            CFHTTPMessageSetBody(response, body)
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        fileHandle.write(data)
        completion()
    }
}