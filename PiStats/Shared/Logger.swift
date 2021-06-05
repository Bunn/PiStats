//
//  Logger.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import Foundation

import os.log

struct Logger {
    func osLog(category: String) -> OSLog {
        return OSLog(subsystem: "PiStats", category: category)
    }
    
    func osLog<Subject>(describing instance: Subject) -> OSLog {
        return osLog(category: String(describing: instance))
    }
}
