//
//  SummaryItem.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 12/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct SummaryItem: View {
    var value: String
    var type: SummaryItemType

    enum SummaryItemType {
        case totalQuery
        case queryBlocked
        case percentBlocked
        case domainsOnBlocklist
    }
        
    private var circleColor: Color {
        get {
            switch type {
            case .domainsOnBlocklist:
                return UIConstants.Colors.domainBlocked
            case .percentBlocked:
                return UIConstants.Colors.percentBlocked
            case .queryBlocked:
                return UIConstants.Colors.queryBlocked
            case .totalQuery:
                return UIConstants.Colors.totalQuery
            }
        }
    }
    
    private var text: String {
        get {
            switch type {
            case .domainsOnBlocklist:
                return UIConstants.Strings.domainsOnBlocklist
            case .percentBlocked:
                return UIConstants.Strings.percentBlocked
            case .queryBlocked:
                return UIConstants.Strings.queriesBlocked
            case .totalQuery:
                return UIConstants.Strings.totalQueries
            }
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(circleColor)
                .frame(width: UIConstants.Geometry.circleSize, height: UIConstants.Geometry.circleSize)
            Text(text)
            Spacer()
            Text(value)
        }
    }
}
