import XCTest
@testable import PiholeStorage

class PiholeStorageTests: XCTestCase {
    var storage: DefaultPiholeStorage!
    var temporaryUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        temporaryUserDefaults = UserDefaults(suiteName: UUID().uuidString)
        storage = DefaultPiholeStorage(userDefaults: temporaryUserDefaults)
    }

    override func tearDown() {
        storage = nil
        temporaryUserDefaults = nil
        super.tearDown()
    }

    func testSaveAndRetrieveData() {
        let testData = MockStorageData(id: UUID(), data: Data(), secret: Data())
        storage.save(data: testData)

        let retrievedData = storage.retrieve(id: testData.id, ofType: MockStorageData.self)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.id, testData.id)
    }

    func testRetrieveAll() {
        let mockData1 = MockStorageData(id: UUID(), data: Data(), secret: Data())
        let mockData2 = MockStorageData(id: UUID(), data: Data(), secret: Data())

        storage.save(data: mockData1)
        storage.save(data: mockData2)

        let retrievedData = storage.retrieveAll(ofType: MockStorageData.self)

        XCTAssertEqual(retrievedData.count, 2)
        XCTAssertTrue(retrievedData.contains(where: { $0.id == mockData1.id }))
        XCTAssertTrue(retrievedData.contains(where: { $0.id == mockData2.id }))
    }
}

class KeychainHelperTests: XCTestCase {
    var keychainHelper: KeychainHelper!

    override func setUp() {
        super.setUp()
        keychainHelper = KeychainHelper()
    }

    override func tearDown() {
        keychainHelper = nil
        super.tearDown()
    }

    func testSaveAndRetrieveFromKeychain() {
        let testData = Data()
        let key = "testKey"
        XCTAssertTrue(keychainHelper.save(data: testData, for: key))

        let retrievedData = keychainHelper.retrieve(for: key)
        XCTAssertNotNil(retrievedData)
    }
}

struct MockStorageData: StorageData {
    var id: UUID
    var data: Data
    var secret: Data

    init(id: UUID = UUID(), data: Data = Data(), secret: Data = Data()) {
        self.id = id
        self.data = data
        self.secret = secret
    }
}
