//
//  TestHelpers.swift
//  PiStatsCoreTests
//
//  Created for testing purposes
//

import Foundation

/// Helpers for testing
enum TestHelpers {
    
    /// Create a mock URLSession with MockURLProtocol
    static func createMockURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
    
    /// Setup URLSession to use mock protocol
    static func setupMockURLSession() {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        URLSession.shared.configuration.protocolClasses = [MockURLProtocol.self]
    }
    
    /// Create a network error
    static func createNetworkError() -> NSError {
        NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
    }
}

