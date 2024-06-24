//
//  Credentials.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation
import Security

final public class Credentials {

    public struct SessionID: Codable {
        let sid: String
        let csrf: String
    }

    public let secret: String
    var sessionID: SessionID?

    public init(secret: String) {
        self.secret = secret
    }
}

// MARK: - Codable
extension Credentials: Codable {
    enum CodingKeys: String, CodingKey {
        case secret
        case sessionID
    }

    // Decodable
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let secret = try container.decode(String.self, forKey: .secret)
        let sessionID = try container.decodeIfPresent(SessionID.self, forKey: .sessionID)
        self.init(secret: secret)
        self.sessionID = sessionID
    }

    // Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secret, forKey: .secret)
        try container.encodeIfPresent(sessionID, forKey: .sessionID)
    }
}
