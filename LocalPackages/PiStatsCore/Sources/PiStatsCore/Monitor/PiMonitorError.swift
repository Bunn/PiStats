//
//  PiMetricError.swift
//  
//
//  Created by Fernando Bunn on 25/07/2020.
//

import Foundation

public enum PiMonitorError: Error, LocalizedError {
    case malformedURL
    case sessionError(Error)
    case invalidResponseCode(Int)
    case invalidResponse
    case invalidDecode(Error)
    
    public var errorDescription: String? {
        switch self {
        case .malformedURL:
            return "Invalid Pi Monitor URL."
        case .sessionError(let error):
            return "Pi Monitor connection error: \(error.localizedDescription)"
        case .invalidResponseCode(let code):
            return "Pi Monitor returned error code \(code)."
        case .invalidResponse:
            return "Invalid response from Pi Monitor."
        case .invalidDecode(let error):
            return "Unable to parse Pi Monitor response: \(error.localizedDescription)"
        }
    }
}
