
import Foundation

public struct ServerSettings {
    enum Version {
        case v5
        case v6
    }

    enum RequestProtocol: String {
        case http
        case https
    }

    var version: Version
    var host: String
    var port: Int?
    var requestProtocol: RequestProtocol = .http
}

public class Pihole {

    public enum Status {
        case enabled
        case disabled
        case unknown
    }

    public var serverSettings: ServerSettings
    public var status: Status = .unknown
    public var summary: Summary?
    var credentials: Credentials


    init(serverSettings: ServerSettings, credentials: Credentials) {
        self.serverSettings = serverSettings
        self.credentials = credentials
    }
}
