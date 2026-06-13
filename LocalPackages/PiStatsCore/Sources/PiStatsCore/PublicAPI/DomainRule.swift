//
//  DomainRule.swift
//  PiStatsCore
//
//  A single entry in one of Pi-hole's domain lists. Pi-hole organises domain
//  rules into four buckets along two axes: the list `type` (allow/deny) and the
//  match `kind` (exact/regex). Pi-hole v6 only.
//

import Foundation

/// Whether a domain rule allows (whitelists) or denies (blacklists) matches.
public enum DomainListType: String, Sendable, Codable, CaseIterable {
    case allow
    case deny
}

/// Whether a domain rule matches an exact domain or a regular expression.
public enum DomainListKind: String, Sendable, Codable, CaseIterable {
    case exact
    case regex
}

/// A single allow/deny domain rule. `domain` holds either an exact domain or a
/// regex pattern depending on `kind`.
public struct DomainRule: Identifiable, Sendable, Equatable, Hashable {
    /// Stable identity across the four buckets — a bucket can contain a domain
    /// that also appears in another bucket, so the type/kind are part of the id.
    public var id: String { "\(type.rawValue)/\(kind.rawValue)/\(domain)" }

    public let domain: String
    public let type: DomainListType
    public let kind: DomainListKind
    public var enabled: Bool
    public var comment: String?
    public var groups: [Int]

    public init(
        domain: String,
        type: DomainListType,
        kind: DomainListKind,
        enabled: Bool = true,
        comment: String? = nil,
        groups: [Int] = [0]
    ) {
        self.domain = domain
        self.type = type
        self.kind = kind
        self.enabled = enabled
        self.comment = comment
        self.groups = groups
    }
}
