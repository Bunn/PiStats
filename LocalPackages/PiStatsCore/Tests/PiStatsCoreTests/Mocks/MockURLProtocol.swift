//
//  MockURLProtocol.swift
//  PiStatsCoreTests
//
//  Created for testing purposes
//

import Foundation

/// Mock URLProtocol for intercepting and mocking network requests
class MockURLProtocol: URLProtocol {
    
    /// Handler type for processing requests
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)
    
    /// Static handler that will be called for each request
    nonisolated(unsafe) static var requestHandler: RequestHandler?
    
    /// Reset the mock state
    static func reset() {
        requestHandler = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol: No request handler set")
        }
        
        do {
            let (response, data) = try handler(request)
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // Required override, but we don't need to do anything
    }
}

/// Helper to create mock HTTP responses
extension MockURLProtocol {
    static func successResponse(for request: URLRequest, data: Data?, statusCode: Int = 200) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, data)
    }
    
    static func errorResponse(for request: URLRequest, statusCode: Int = 500) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, nil)
    }
}

