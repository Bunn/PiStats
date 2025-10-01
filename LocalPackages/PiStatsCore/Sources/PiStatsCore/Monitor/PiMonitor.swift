import Foundation

// MARK: - PiMonitorEnvironment

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

// MARK: - PiMonitorProtocol

public protocol PiMonitorProtocol {
    var timeoutInterval: TimeInterval { get set }
    
    func fetchMetrics(completion: @escaping (Result<PiMonitorMetrics, PiMonitorError>) -> ())
    func fetchMetrics() async throws -> PiMonitorMetrics
}

// MARK: - PiMonitor

public struct PiMonitor: PiMonitorProtocol {
    private var service: PiMonitorServiceProtocol
    private let environment: PiMonitorEnvironment

    public var timeoutInterval: TimeInterval {
        get {
            return service.timeoutInterval
        }
        set {
            service.timeoutInterval = newValue
        }
    }
    
    // MARK: Public Methods
    
    public init(host: String, port: Int? = nil, timeoutInterval: TimeInterval = 30, secure: Bool = false, urlSession: URLSession = .shared) {
        var service = PiMonitorService()
        service.timeoutInterval = timeoutInterval
        service.urlSession = urlSession
        self.service = service
        environment = PiMonitorEnvironment(host: host, port: port, secure: secure)
    }
    
    // Internal initializer for testing with custom service
    internal init(service: PiMonitorServiceProtocol, environment: PiMonitorEnvironment) {
        self.service = service
        self.environment = environment
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
