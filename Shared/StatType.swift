//
//  StatType.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/06/2025.
//

import SwiftUI

enum StatType {
    case totalQueries
    case queriesBlocked
    case percentageBlocked
    case domainsOnList

    var title: String {
        switch self {
        case .totalQueries:
            return UserText.totalQueries
        case .domainsOnList:
            return UserText.domainsOnList
        case .queriesBlocked:
            return UserText.queriesBlocked
        case .percentageBlocked:
            return UserText.percentBlocked
        }
    }

    var color: Color {
        switch self {
        case .totalQueries:
            return AppColors.totalQueries
        case .queriesBlocked:
            return AppColors.queriesBlocked
        case .percentageBlocked:
            return AppColors.percentBlocked
        case .domainsOnList:
            return AppColors.domainsOnBlocklist
        }
    }

    var systemImage: String {
        switch self {
        case .totalQueries:
            return SystemImages.totalQueries
        case .queriesBlocked:
            return SystemImages.queriesBlocked
        case .percentageBlocked:
            return SystemImages.percentBlocked
        case .domainsOnList:
            return SystemImages.domainsOnBlockList
        }
    }
}
