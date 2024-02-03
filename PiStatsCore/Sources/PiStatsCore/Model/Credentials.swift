//
//  Credentials.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation
import Security

final public class Credentials {

    struct SessionID: Codable {
        let sid: String
        let csrf: String
    }

    private enum KeyChainKey: String {
        case apiToken
        case applicationPassword
    }

    var apiToken: String?
    var applicationPassword: String?
    var sessionID: SessionID?

    public init(apiToken: String? = nil, applicationPassword: String? = nil) {
        self.apiToken = apiToken
        self.applicationPassword = applicationPassword
    }

    public func saveToKeychain() {
        if let apiToken = apiToken {
            saveToKeychain(service: KeyChainKey.apiToken.rawValue, data: apiToken)
        }
        if let applicationPassword = applicationPassword {
            saveToKeychain(service: KeyChainKey.applicationPassword.rawValue, data: applicationPassword)
        }
    }

    public func restoreFromKeychain() {
        apiToken = retrieveFromKeychain(service: KeyChainKey.apiToken.rawValue)
        applicationPassword = retrieveFromKeychain(service: KeyChainKey.applicationPassword.rawValue)
    }

    public func clearKeychain() {
        deleteFromKeychain(service: KeyChainKey.apiToken.rawValue)
        deleteFromKeychain(service: KeyChainKey.applicationPassword.rawValue)
    }

    private func deleteFromKeychain(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        SecItemDelete(query as CFDictionary)
    }

    private func saveToKeychain(service: String, data: String) {
        if let data = data.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecValueData as String: data
            ]

            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private func retrieveFromKeychain(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data, let result = String(data: data, encoding: .utf8) {
                return result
            }
        }

        return nil
    }
}
