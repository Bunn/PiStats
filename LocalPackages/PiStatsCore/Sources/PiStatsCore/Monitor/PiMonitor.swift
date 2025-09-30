import Foundation

public struct PiMonitorEnvironment: Sendable, Hashable {
    public init(host: String, port: Int? = 8088, secure: Bool = false) {
        self.host = host
        self.port = port
        self.secure = secure
    }
    
    public var host: String
    public var port: Int?
    public var secure: Bool = false
}

public struct PiMonitor {
    private var service = PiMonitorService()
    private let environment: PiMonitorEnvironment

    public var timeoutInterval: TimeInterval {
        set {
            service.timeoutInterval = newValue
        }
        get {
            return service.timeoutInterval
        }
    }
    
    // MARK: Public Methods
    
    public init(host: String, port: Int? = nil, timeoutInterval: TimeInterval = 30, secure: Bool = false) {
        service.timeoutInterval = timeoutInterval
        environment = PiMonitorEnvironment(host: host, port: port, secure: secure)
    }
    
    public func fetchMetrics(completion: @escaping (Result<PiMonitorMetrics, PiMonitorError>) -> ()) {
        service.fetchMetrics(host: environment.host, port: environment.port, secure: environment.secure, completion: completion)
    }
    
    public func fetchMetrics() async throws -> PiMonitorMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            fetchMetrics { result in
                continuation.resume(with: result)
            }
        }
    }
}
