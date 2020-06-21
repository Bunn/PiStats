//
//  Logger.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 21/06/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import os.log

struct Logger {
    func osLog(category: String) -> OSLog {
        return OSLog(subsystem: "PiStats", category: category)
    }
    
    func osLog<Subject>(describing instance: Subject) -> OSLog {
        return osLog(category: String(describing: instance))
    }
}
