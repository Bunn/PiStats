//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/21/24.
//

import Foundation

internal struct Environment {
    var host: String
    var port: Int?
    var apiToken: String
}

protocol PiholeService {
    func fetchSummary(_ environment: Environment) -> Summary
}
