//
//  HTTPMessage.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/26/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * A thin wrapper for Swift-incompatible type `CFHTTPMessage`.
 */
final class HTTPMessage {
    private let cfHTTPMessage: CFHTTPMessage

    init(_ httpMessage: HTTPMessage) {
        self.cfHTTPMessage = CFHTTPMessageCreateCopy(kCFAllocatorDefault, httpMessage.cfHTTPMessage).takeRetainedValue()
    }

    init(isRequest: Bool) {
        self.cfHTTPMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, isRequest).takeRetainedValue()
    }

    init(requestMethod: String, url: URL, httpVersion: String) {
        self.cfHTTPMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod as CFString, url as CFURL, httpVersion as CFString).takeRetainedValue()
    }

    init(statusCode: Int, statusDescription: String? = nil, httpVersion: String) {
        self.cfHTTPMessage = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, statusDescription as CFString?, httpVersion as CFString).takeRetainedValue()
    }

    convenience init(httpURLResponse: HTTPURLResponse, httpVersion: String) {
        self.init(statusCode: httpURLResponse.statusCode, httpVersion: httpVersion)
        for case (let headerField as String, let value as String) in httpURLResponse.allHeaderFields {
            self.setValue(value, for: headerField)
        }
    }

    var body: Data? {
        get { return CFHTTPMessageCopyBody(cfHTTPMessage)?.takeRetainedValue() as Data? }
        set { CFHTTPMessageSetBody(cfHTTPMessage, (newValue ?? Data()) as CFData) }
    }

    var isHeaderComplete: Bool {
        return CFHTTPMessageIsHeaderComplete(cfHTTPMessage)
    }

    var isRequest: Bool {
        return CFHTTPMessageIsRequest(cfHTTPMessage)
    }

    var version: String {
        return CFHTTPMessageCopyVersion(cfHTTPMessage).takeRetainedValue() as String
    }

    var requestURL: URL? {
        return CFHTTPMessageCopyRequestURL(cfHTTPMessage)?.takeRetainedValue() as URL?
    }

    var requestMethod: String? {
        return CFHTTPMessageCopyRequestMethod(cfHTTPMessage)?.takeRetainedValue() as String?
    }

    var responseStatusCode: Int {
        return CFHTTPMessageGetResponseStatusCode(cfHTTPMessage)
    }

    var responseStatusLine: String? {
        return CFHTTPMessageCopyResponseStatusLine(cfHTTPMessage)?.takeRetainedValue() as String?
    }

    var allHeaderFields: [String: String]? {
        return CFHTTPMessageCopyAllHeaderFields(cfHTTPMessage)?.takeRetainedValue() as? [String: String]
    }

    func value(for headerField: String) -> String? {
        return CFHTTPMessageCopyHeaderFieldValue(cfHTTPMessage, headerField as CFString)?.takeRetainedValue() as String?
    }

    func setValue(_ value: String, for headerField: String) {
        CFHTTPMessageSetHeaderFieldValue(cfHTTPMessage, headerField as CFString, value as CFString)
    }

    func append(_ data: Data) -> Bool {
        let nsData = data as NSData
        return CFHTTPMessageAppendBytes(cfHTTPMessage, nsData.bytes.bindMemory(to: UInt8.self, capacity: data.count), data.count)
    }

    func serialize() -> Data? {
        return CFHTTPMessageCopySerializedMessage(cfHTTPMessage)?.takeRetainedValue() as Data?
    }
}

extension HTTPMessage: Equatable {
    static func == (lhs: HTTPMessage, rhs: HTTPMessage) -> Bool {
        return CFEqual(lhs.cfHTTPMessage, rhs.cfHTTPMessage)
    }
}

extension HTTPMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(cfHTTPMessage))
    }
}
