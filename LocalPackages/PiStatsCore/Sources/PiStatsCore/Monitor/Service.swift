//
//  Service.swift
//  
//
//  Created by Fernando Bunn on 25/07/2020.
//

import Foundation
import OSLog

internal struct PiMonitorService {

    var timeoutInterval: TimeInterval = 30

    func fetchMetrics(host: String, port: Int? = nil, secure: Bool = false, completion: @escaping (Result<PiMonitorMetrics, PiMonitorError>) -> ()) {
        Log.network.info("🖥️ [PiMonitor] Fetching metrics from \(host):\(port ?? 8088)")
        
        guard let url = URLWithComponents(host: host, port: port, secure: secure) else {
            Log.network.error("❌ [PiMonitor] Malformed URL for \(host):\(port ?? 8088)")
            completion(.failure(.malformedURL))
            return
        }
        
        Log.network.debug("🌐 [PiMonitor] Requesting: \(url.absoluteString)")
        
        let session = URLSession(configuration: .default)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = timeoutInterval

        let task = session.dataTask(with: urlRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let error = error {
                Log.network.error("💥 [PiMonitor] Session error for \(host): \(error.localizedDescription)")
                completion(.failure(.sessionError(error)))
                return
            }
            
            guard let data = data else {
                Log.network.error("❌ [PiMonitor] No data received from \(host)")
                completion(.failure(.invalidResponse))
                return
            }
            
            if let response = response as? HTTPURLResponse {
                Log.network.info("📊 [PiMonitor] Response: \(response.statusCode) from \(host)")
                
                if 200 ..< 300 ~= response.statusCode {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let piMetric = try decoder.decode(PiMonitorMetrics.self, from: data)
                        Log.network.info("✅ [PiMonitor] Successfully fetched metrics from \(host) - Temp: \(piMetric.socTemperature)°C, Load: \(piMetric.loadAverage.first ?? 0)")
                        completion(.success(piMetric))
                    } catch {
                        Log.network.error("❌ [PiMonitor] Failed to decode metrics from \(host): \(error.localizedDescription)")
                        completion(.failure(.invalidDecode(error)))
                    }
                } else {
                    Log.network.error("❌ [PiMonitor] Invalid response code \(response.statusCode) from \(host)")
                    completion(.failure(.invalidResponseCode(response.statusCode)))
                    return
                }
            } else {
                Log.network.error("❌ [PiMonitor] Invalid response type from \(host)")
                completion(.failure(.invalidResponse))
                return
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    private func URLWithComponents(host: String, port: Int? = nil, secure: Bool) -> URL? {
        var components = URLComponents()
        components.scheme = secure ? "https" : "http"
        components.host = host
        components.port = port
        components.path = "/monitor.json"
        guard let url = components.url else {
            return nil
        }
        return url
    }
}
