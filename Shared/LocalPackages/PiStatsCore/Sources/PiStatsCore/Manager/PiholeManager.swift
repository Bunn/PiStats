//
//  PiholeManager.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

protocol PiholeManagerProtocol {
    var pihole: Pihole { get }

    func updateSummary() async throws
    func updateStatus() async throws
    func updateSystemInfo() async throws
    func updateSensorData() async throws
    func setStatus(_ status: Pihole.Status) async throws
    func updateDNSQueries() async throws
}

final public class PiholeManager: PiholeManagerProtocol {
    public let pihole: Pihole
    private let service: PiholeService

    public init(pihole: Pihole, serviceBuilder: PiholeServiceBuilder = DefaultPiholeServiceBuilder()) {
        self.pihole = pihole
        self.service = serviceBuilder.buildService(version: pihole.serverSettings.version)
    }

    public func updateSummary() async throws {
        do {
            pihole.summary = try await service.fetchSummary(serverSettings: pihole.serverSettings,
                                                            credentials: pihole.credentials)
        } catch {
            pihole.addErrorLog(error)
        }
    }

    public func updateStatus() async throws {
        do {
            pihole.status = try await service.fetchStatus(serverSettings: pihole.serverSettings,
                                                          credentials: pihole.credentials)
        } catch {
            pihole.addErrorLog(error)
        }
    }

    public func updateSystemInfo() async throws {
        do {
            pihole.systemInfo = try await service.fetchSystemInfo(serverSettings: pihole.serverSettings,
                                                                  credentials: pihole.credentials)
        } catch {
            pihole.addErrorLog(error)
        }
    }

    public func updateSensorData() async throws {
        do {
            pihole.sensorData = try await service.fetchSensorData(serverSettings: pihole.serverSettings,
                                                                  credentials: pihole.credentials)
        } catch {
            pihole.addErrorLog(error)
        }
    }

    public func setStatus(_ status: Pihole.Status) async throws {
        do {
            pihole.status = try await service.setStatus(status, timer: nil,
                                                        serverSettings: pihole.serverSettings,
                                                        credentials: pihole.credentials)
        } catch {
            pihole.addErrorLog(error)
        }
    }

    public func updateDNSQueries() async throws {
        do {
            pihole.DNSQueries = try await service.fetchDNSQueries(serverSettings: pihole.serverSettings,
                                                                  credentials: pihole.credentials)
        } catch {
            pihole.addErrorLog(error)
        }
    }
}
