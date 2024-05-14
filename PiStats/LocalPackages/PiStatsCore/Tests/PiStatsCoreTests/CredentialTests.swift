//
//  CredentialsTests.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import XCTest
@testable import PiStatsCore

class CredentialsTests: XCTestCase {
    var credentials: Credentials!

    override func setUp() {
        super.setUp()
        credentials = Credentials(apiToken: "testApiToken", applicationPassword: "testApplicationPassword")
    }

    override func tearDown() {
        credentials.clearKeychain()
        credentials = nil
        super.tearDown()
    }

    func testSaveAndRestoreFromKeychain() {
        credentials.saveToKeychain()

        let restoredCredentials = Credentials()
        restoredCredentials.restoreFromKeychain()

        XCTAssertEqual(credentials.apiToken, restoredCredentials.apiToken, "Restored apiToken should match the original")
        XCTAssertEqual(credentials.applicationPassword, restoredCredentials.applicationPassword, "Restored applicationPassword should match the original")
    }

    func testClearKeychain() {
        credentials.saveToKeychain()
        credentials.clearKeychain()

        let restoredCredentials = Credentials()
        restoredCredentials.restoreFromKeychain()

        XCTAssertNil(restoredCredentials.apiToken, "apiToken should be nil after clearing the keychain")
        XCTAssertNil(restoredCredentials.applicationPassword, "applicationPassword should be nil after clearing the keychain")
    }
}
