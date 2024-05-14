//
//  URLProtocolMock.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

class URLProtocolMock: URLProtocol {
    static var expectedData: Data? = nil

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let data = URLProtocolMock.expectedData {
            client?.urlProtocol(self, didLoad: data)
        } else {
            client?.urlProtocol(self, didLoad: Data("".utf8))
        }

        client?.urlProtocol(self, didReceive: HTTPURLResponse(), cacheStoragePolicy: .allowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}
