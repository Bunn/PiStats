//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/22/24.
//

import Foundation

struct JSONMock {

    static func summaryJSON(totalQueries: String = "10",
                            queriesBlocked: String = "10",
                            percentBlocked: String = "10",
                            domainsOnList: String = "10",
                            activeClients: String = "10") -> String {
    """
 {
   "queries": {
     "total": \(totalQueries),
     "blocked": \(queriesBlocked),
     "percent_blocked": \(percentBlocked),
     "unique_domains": 10,
     "forwarded": 120,
     "cached": 36,
     "types": {
       "A": 41,
       "AAAA": 42,
       "ANY": 0,
       "SRV": 0,
       "SOA": 1,
       "PTR": 0,
       "TXT": 0,
       "NAPTR": 0,
       "MX": 0,
       "DS": 26,
       "RRSIG": 0,
       "DNSKEY": 7,
       "NS": 0,
       "SVCB": 2,
       "HTTPS": 50,
       "OTHER": 0
     },
     "status": {
       "UNKNOWN": 0,
       "GRAVITY": 13,
       "FORWARDED": 120,
       "CACHE": 27,
       "REGEX": 0,
       "DENYLIST": 0,
       "EXTERNAL_BLOCKED_IP": 0,
       "EXTERNAL_BLOCKED_NULL": 0,
       "EXTERNAL_BLOCKED_NXRA": 0,
       "GRAVITY_CNAME": 0,
       "REGEX_CNAME": 0,
       "DENYLIST_CNAME": 0,
       "RETRIED": 0,
       "RETRIED_DNSSEC": 0,
       "IN_PROGRESS": 0,
       "DBBUSY": 0,
       "SPECIAL_DOMAIN": 0,
       "CACHE_STALE": 9
     },
     "replies": {
       "UNKNOWN": 0,
       "NODATA": 61,
       "NXDOMAIN": 2,
       "CNAME": 64,
       "IP": 29,
       "DOMAIN": 0,
       "RRNAME": 0,
       "SERVFAIL": 0,
       "REFUSED": 0,
       "NOTIMP": 0,
       "OTHER": 0,
       "DNSSEC": 12,
       "NONE": 0,
       "BLOB": 1
     }
   },
   "clients": {
     "active": \(activeClients),
     "total": 2
   },
   "gravity": {
     "domains_being_blocked": \(domainsOnList)
   },
   "took": 0.00023365020751953125
 }
"""
    }
}

