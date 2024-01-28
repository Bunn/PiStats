//
//  JSONMock.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

struct JSONMock {

    static func systemInfo(uptime: String = "10",
                           totalRam: String = "10",
                           freeRam: String = "10",
                           percentUsedRam: String = "0.10",
                           totalSwap: String = "10") -> String {
        """
    {
      "system": {
        "uptime": \(uptime),
        "memory": {
          "ram": {
            "total": \(totalRam),
            "free": \(freeRam),
            "used": 104464,
            "available": 276184,
            "%used": \(percentUsedRam)
          },
          "swap": {
            "total": \(totalSwap),
            "free": 97020,
            "used": 5376,
            "%used": 5.2502050861361775
          }
        },
        "procs": 265,
        "cpu": {
          "nprocs": 4,
          "load": {
            "raw": [
              0.0703125,
              0.06005859375,
              0.00537109375
            ],
            "percent": [
              1.7578125,
              1.50146484375,
              0.13427734375
            ]
          }
        }
      },
      "took": 0.0005588531494140625
    }
    """
    }
    static func summaryV6JSON(totalQueries: String = "10",
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

    static func summaryV5JSON(totalQueries: String = "10",
                              queriesBlocked: String = "10",
                              percentBlocked: String = "10",
                              domainsOnList: String = "10",
                              activeClients: String = "10") -> String {
    """
  {
    "domains_being_blocked": \(domainsOnList),
    "dns_queries_today": \(totalQueries),
    "ads_blocked_today": \(queriesBlocked),
    "ads_percentage_today": \(percentBlocked),
    "unique_domains": 23,
    "queries_forwarded": 4139,
    "queries_cached": 20883,
    "clients_ever_seen": 42,
    "unique_clients": \(activeClients),
    "dns_queries_all_types": 25652,
    "reply_UNKNOWN": 283,
    "reply_NODATA": 1762,
    "reply_NXDOMAIN": 10421,
    "reply_CNAME": 2622,
    "reply_IP": 10145,
    "reply_DOMAIN": 48,
    "reply_RRNAME": 364,
    "reply_SERVFAIL": 0,
    "reply_REFUSED": 0,
    "reply_NOTIMP": 0,
    "reply_OTHER": 0,
    "reply_DNSSEC": 0,
    "reply_NONE": 0,
    "reply_BLOB": 7,
    "dns_queries_all_replies": 25652,
    "privacy_level": 0,
    "status": "enabled",
    "gravity_last_updated": {
      "file_exists": true,
      "absolute": 1705806851,
      "relative": {
        "days": 0,
        "hours": 17,
        "minutes": 49
      }
    },
    "top_queries": {
      "amazon.com": 4331,
      "wikipedia.org": 4331,
    },
    "top_ads": {
      "analytics.plex.tv": 185,
      "logs.netflix.com": 59,
    },
    "top_sources_blocked": {
      "192.168.1.248": 201,
      "192.168.1.163": 59
    }
  }
"""
    }
}



