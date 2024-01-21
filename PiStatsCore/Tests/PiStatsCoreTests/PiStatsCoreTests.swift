import XCTest
@testable import PiStatsCore

final class PiStatsCoreTests: XCTestCase {
    let v5Host = ""
    let v5Token = ""

    let v6Host = ""
    let v6Password = ""

    func testSummaryV5() async throws {
        let settings = ServerSettings(version: .v5, host: v5Host)
        let credentials = Credentials(apiToken: v5Token)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.fetchSummary()
        print("PH \(pihole.summary)")
    }

    func testV6Auth() async throws {
        let settings = ServerSettings(version: .v5, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let service = PiholeV6Service()
        try await service.authenticate(settings, credentials: credentials)
    }

    func testV6Summary() async throws {
        let settings = ServerSettings(version: .v5, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let service = PiholeV6Service()
        try await service.fetchSummary(settings, credentials: credentials)
    }

    func testSummaryManagerV5() async throws {
        let settings = ServerSettings(version: .v6, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.fetchSummary()
        print("PH \(pihole.summary)")
    }

}

//extension Summary {
//    static func mockSummary() -> Summary {
//        return Summary(
//            domainsBeingBlocked: 100,
//            dnsQueriesToday: 500,
//            adsBlockedToday: 50,
//            adsPercentageToday: 10.5,
//            uniqueDomains: 300,
//            queriesForwarded: 200,
//            queriesCached: 100,
//            clientsEverSeen: 1000,
//            uniqueClients: 800,
//            dnsQueriesAllTypes: 1000,
//            replyNODATA: 20,
//            replyNXDOMAIN: 30,
//            replyCNAME: 40,
//            replyIP: 50,
//            privacyLevel: 2,
//            status: "Active",
//            gravityLastUpdated: GravityLastUpdated(
//                fileExists: true,
//                absolute: 123456,
//                relative: Relative(days: 1, hours: 2, minutes: 30)
//            )
//        )
//    }
//}

/* V5
 {
   "domains_being_blocked": 249944,
   "dns_queries_today": 25652,
   "ads_blocked_today": 349,
   "ads_percentage_today": 1.360518,
   "unique_domains": 911,
   "queries_forwarded": 4139,
   "queries_cached": 20883,
   "clients_ever_seen": 42,
   "unique_clients": 18,
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


 V6
 {
   "queries": {
     "total": 169,
     "blocked": 13,
     "percent_blocked": 7.6923074722290039,
     "unique_domains": 104,
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
     "active": 2,
     "total": 2
   },
   "gravity": {
     "domains_being_blocked": 237779
   },
   "took": 0.00023365020751953125
 }
 */
