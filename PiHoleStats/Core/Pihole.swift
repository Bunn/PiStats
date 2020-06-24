//
//  PiHole.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 24/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftHole
import os.log

class Pihole: Identifiable, Codable, ObservableObject {
    private let log = Logger().osLog(describing: Pihole.self)
    var address: String
    var actionError: String?
    var pollingError: String?
    let id: UUID
    private(set) var summary: Summary? {
        didSet {
            if summary?.status.lowercased() == "enabled" {
                active = true
                os_log("%@ summary has enabled status", log: self.log, type: .debug, address)
            } else {
                active = false
                os_log("%@ summary has disabled status", log: self.log, type: .debug, address)
            }
        }
    }
    private(set) var active = false

    private lazy var keychainToken = APIToken(accountName: self.id.uuidString)
    var apiToken: String {
        get {
            keychainToken.token
        }
        set {
            keychainToken.token = newValue
        }
    }
    
    var port: Int? {
        getPort(address)
    }
    
    var host: String {
        address.components(separatedBy: ":").first ?? ""
    }
    
    private var service: SwiftHole {
      SwiftHole(host: host, port: port, apiToken: apiToken)
    }
    
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
    public func updateSummary(completion: @escaping (SwiftHoleError?) -> Void) {
        service.fetchSummary { result in
            switch result {
            case .success(let summary):
                self.summary = summary
                completion(nil)
            case .failure(let error):
                self.summary = nil
                completion(error)
            }
        }
    }
    
    public func enablePiHole(completion: @escaping (Result<Void, SwiftHoleError>) -> Void) {
        service.enablePiHole { result in
            switch result {
            case .success:
                self.active = true
                os_log("%@ enable request success", log: self.log, type: .debug, self.address)
                completion(result)
            case .failure:
                os_log("%@ enable request failure", log: self.log, type: .debug, self.address)
                completion(result)
            }
        }
    }
    
    public func disablePiHole(seconds: Int = 0, completion: @escaping (Result<Void, SwiftHoleError>) -> Void) {
        service.disablePiHole(seconds: seconds) { result in
            switch result {
            case .success:
                self.active = false
                os_log("%@ disable request success", log: self.log, type: .debug, self.address)
                completion(result)
            case .failure:
                os_log("%@ disable request failure", log: self.log, type: .debug, self.address)
                completion(result)
            }
        }
    }
}

// MARK: I/O Methods

extension Pihole {
    private static let piHoleListKey = "PiHoleStatsPiHoleList"
    
    public func delete() {
        var piholeList = Pihole.restoreAll()
        
        if let index = piholeList.firstIndex(of: self) {
            piholeList.remove(at: index)
        }
        save(piholeList)
        self.keychainToken.delete()
    }
    
    public func save() {
        var piholeList = Pihole.restoreAll()
        if let index = piholeList.firstIndex(where: { $0.id == self.id }) {
            piholeList[index] = self
        } else {
            piholeList.append(self)
        }
        save(piholeList)
    }
    
    private func save(_ list: [Pihole]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(list) {
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
