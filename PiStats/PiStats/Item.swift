//
//  Item.swift
//  PiStats
//
//  Created by Fernando Bunn on 1/21/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp

#if os(macOS)

        MacTest.test()
#endif
    }
}
