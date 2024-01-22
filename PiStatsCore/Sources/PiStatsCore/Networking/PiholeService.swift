//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/21/24.
//

import Foundation

public enum PiholeServiceError: Error {
    case cantGenerateURL
    case cantDecodeSummary
    case noAPIToken
    case noAPIPassword
    case noCredentials
}

protocol PiholeService {
    init(session: URLSession)
    func fetchSummary(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary
    func authenticate(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID
}
