//
//  Credentials.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

final public class Credentials {

    struct SessionID: Codable {
        let sid: String
        let csrf: String
    }

    var apiToken: String?
    var applicationPassword: String?
    var sessionID: SessionID?

    init(apiToken: String? = nil, applicationPassword: String? = nil) {
        self.apiToken = apiToken
        self.applicationPassword = applicationPassword
    }
}

