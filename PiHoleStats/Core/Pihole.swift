//
//  PiHole.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 24/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftHole

class Pihole: Identifiable, Codable, ObservableObject {
    var address: String
    let id: UUID
    private lazy var keychainToken = APIToken(accountName: self.id.uuidString)
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
    
    enum CodingKeys: CodingKey {
        case id
        case address
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        address = try container.decode(String.self, forKey: .address)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(address, forKey: .address)
    }
    
    public init(address: String, apiToken: String? = nil, piHoleID: UUID? = nil) {
        self.address = address
        
        if let piHoleID = piHoleID {
            self.id = piHoleID
        } else {
            self.id = UUID()
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

extension Pihole {
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

extension Pihole {
    private static let piHoleListKey = "PiHoleStatsPiHoleList"
    
    public func save() {
        var piHoleList = Pihole.restoreAll()
        if let index = piHoleList.firstIndex(where: { $0.id == self.id }) {
            piHoleList[index] = self
        } else {
            piHoleList.append(self)
        }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(piHoleList) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: Pihole.piHoleListKey)
        }
    }
    
    static func restoreAll() -> [Pihole] {
        if let piHoleList = UserDefaults.standard.object(forKey: Pihole.piHoleListKey) as? Data {
            let decoder = JSONDecoder()
            
            if let list = try? decoder.decode([Pihole].self, from: piHoleList) {
                return list
            } else {
                return [Pihole]()
            }
        } else {
            return [Pihole]()
        }
    }
    
    static func restore(_ uuid: UUID) -> Pihole? {
        return Pihole.restoreAll().filter { $0.id == uuid }.first
    }
}

extension Pihole: Hashable {
    static func == (lhs: Pihole, rhs: Pihole) -> Bool {
         return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//extension PiHole: Identifiable {
//    static func == (lhs: PiHole, rhs: PiHole) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
