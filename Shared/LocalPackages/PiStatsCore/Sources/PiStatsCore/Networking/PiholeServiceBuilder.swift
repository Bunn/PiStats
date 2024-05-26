//
//  PiholeServiceBuilder.swift
//  
//
//  Created by Fernando Bunn on 5/26/24.
//

import Foundation

public protocol PiholeServiceBuilder {
    func buildService(version: ServerSettings.Version) -> PiholeService
}

public struct DefaultPiholeServiceBuilder: PiholeServiceBuilder {
    public init() { }

    public func buildService(version: ServerSettings.Version) -> PiholeService {
        switch version {
        case .v5:
            return PiholeV5Service()
        case .v6:
            return PiholeV6Service()
        }
    }
}
