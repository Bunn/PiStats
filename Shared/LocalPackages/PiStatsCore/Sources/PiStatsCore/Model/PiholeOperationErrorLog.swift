//
//  PiholeOperationErrorLog.swift
//
//
//  Created by Fernando Bunn on 5/26/24.
//

import Foundation

public struct PiholeOperationErrorLog: Identifiable {
    public let id = UUID()
    public let timestamp: TimeInterval
    public let error: Error
}

extension PiholeOperationErrorLog {
    public static func logError(_ error: Error) -> PiholeOperationErrorLog {
        return PiholeOperationErrorLog(timestamp: Date().timeIntervalSince1970, error: error)
    }
}

extension PiholeOperationErrorLog: Hashable {
    public static func == (lhs: PiholeOperationErrorLog, rhs: PiholeOperationErrorLog) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
