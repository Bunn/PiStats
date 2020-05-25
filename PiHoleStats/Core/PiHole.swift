//
//  PiHole.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 24/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftHole

class PiHole: Codable {
    var address: String
    let piHoleID: UUID
    private lazy var keychainToken = APIToken(accountName: self.piHoleID.uuidString)
    var apiToken: String {
        keychainToken.token
    }
    var port: Int? {
        getPort(address)
    }
    var host: String {
        address.components(separatedBy: ":").first ?? ""
    }
    private lazy var service = SwiftHole(host: host, port: port, apiToken: apiToken)
    
    public init(address: String, apiToken: String? = nil, piHoleID: UUID? = nil) {
        self.address = address
        
        if let piHoleID = piHoleID {
            self.piHoleID = piHoleID
        } else {
            self.piHoleID = UUID()
        }
        
        if let apiToken = apiToken {
            keychainToken.token = apiToken
        }
    }
    
    private func getPort(_ address: String) -> Int? {
        let split = address.components(separatedBy: ":")
        guard let port = split.last else { return nil }
        return Int(port)
    }
}

// MARK: Network Methods

extension PiHole {
    public func fetchSummary(completion: @escaping (Result<Summary, SwiftHoleError>) -> Void) {
        service.fetchSummary(completion: completion)
    }
    
    public func enablePiHole(completion: @escaping (Result<Void, SwiftHoleError>) -> Void) {
        service.enablePiHole(completion)
    }
    
    public func disablePiHole(seconds: Int = 0, completion: @escaping (Result<Void, SwiftHoleError>) -> Void) {
        service.disablePiHole(seconds: seconds, completion: completion)
    }
}

// MARK: I/O Methods

extension PiHole {
    private static let piHoleListKey = "PiHoleStatsPiHoleList"
    
    public func save() {
        var piHoleList = PiHole.restoreAll()
        if let index = piHoleList.firstIndex(where: { $0.piHoleID == self.piHoleID }) {
            piHoleList[index] = self
        } else {
            piHoleList.append(self)
        }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(piHoleList) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: PiHole.piHoleListKey)
        }
    }
    
    static func restoreAll() -> [PiHole] {
        if let piHoleList = UserDefaults.standard.object(forKey: PiHole.piHoleListKey) as? Data {
            let decoder = JSONDecoder()
            
            if let list = try? decoder.decode([PiHole].self, from: piHoleList) {
                return list
            } else {
                return [PiHole]()
            }
        } else {
            return [PiHole]()
        }
    }
    
    static func restore(_ uuid: UUID) -> PiHole? {
        return PiHole.restoreAll().filter { $0.piHoleID == uuid }.first
    }
}
