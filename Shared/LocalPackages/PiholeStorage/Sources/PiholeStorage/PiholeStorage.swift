// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public protocol StorageData: Codable {
    var id: UUID { get }
    var data: Data { get }
    var secret: Data { get set }
}

public protocol PiholeStorage {
    func save(data: StorageData)
    func retrieveAll<T: StorageData>(ofType type: T.Type) -> [T]
    func retrieve<T: StorageData>(id: UUID, ofType type: T.Type) -> T?
}

public struct DefaultPiholeStorage: PiholeStorage {
    private let userDefaults: UserDefaults
    private let keychainHelper = KeychainHelper()
    private let storageKey = "PiholeStorageData"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func save(data: StorageData) {
        do {
            let secretKey = secretKey(with: data.id)
            guard keychainHelper.save(data: data.secret, for: secretKey) else {
                print("Error saving secret to keychain")
                return
            }

            var currentData = retrieveStoredDictionary()
            currentData[data.id.uuidString] = try JSONEncoder().encode(data)
            let jsonData = try JSONEncoder().encode(currentData)
            userDefaults.set(jsonData, forKey: storageKey)
        } catch {
            print("Error saving data: \(error)")
        }
    }

    public func retrieveAll<T: StorageData>(ofType type: T.Type) -> [T] {
        var storedData = [T]()
        let currentData = retrieveStoredDictionary()

        for (_, value) in currentData {
            if let storedDataObject = try? JSONDecoder().decode(T.self, from: value) {
                storedData.append(storedDataObject)
            }
        }

        return storedData
    }

    public func retrieve<T: StorageData>(id: UUID, ofType type: T.Type) -> T? {
        let currentData = retrieveStoredDictionary()
        if let data = currentData[id.uuidString] {
            if var storedData = try? JSONDecoder().decode(T.self, from: data) {

                let secretKey = secretKey(with: id)
                if let secret = keychainHelper.retrieve(for: secretKey) {
                    storedData.secret = secret
                    return storedData
                }
            }
        }

        return nil
    }

    private func retrieveStoredDictionary() -> [String: Data] {
        guard let jsonData = userDefaults.data(forKey: storageKey) else {
            return [:]
        }

        if let dictionary = try? JSONDecoder().decode([String: Data].self, from: jsonData) {
            return dictionary
        }

        return [:]
    }

    private func secretKey(with id: UUID) -> String {
        let secretKeyPrefix = "pi-stats-secret"
        return "\(secretKeyPrefix)-\(id.uuidString)"
    }
}


import Security

public class KeychainHelper {

    func save(data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Delete existing item if any
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func retrieve(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }

    func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
