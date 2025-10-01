//
//  PiMetricError.swift
//  
//
//  Created by Fernando Bunn on 25/07/2020.
//

import Foundation

public enum PiMonitorError: Error {
    case malformedURL
    case sessionError(Error)
    case invalidResponseCode(Int)
    case invalidResponse
    case invalidDecode(Error)
}
