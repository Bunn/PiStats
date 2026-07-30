//
//  TopDomainsView.swift
//  PiStats
//
//  Created by Fernando Bunn on 28/02/2026.
//

import SwiftUI
import PiStatsCore

struct TopDomainsView: View {
    let topDomains: TopDomainsResult
    var syncOptions = PiholeConfigurationSyncOptions(
        configuredPiholeCount: 1,
        automaticallySyncsChanges: false
    )
    /// Supplied only for Pi-hole v6: adds the tapped domain to an allow/deny list.
    var onAddDomain: ((DomainRule, PiholeConfigurationChangeScope) async -> Void)? = nil
    @State private var selectedTab: DomainTab = .blocked
    @State private var pendingRule: DomainRule?

    enum DomainTab: String, CaseIterable {
        case blocked = "Top Blocked"
        case permitted = "Top Permitted"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $selectedTab) {
                ForEach(DomainTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            let items = selectedTab == .blocked ? topDomains.topBlocked : topDomains.topPermitted

            if items.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(items.prefix(5).enumerated()), id: \.element.domain) { index, item in
                    TopDomainRow(item: item, rank: index + 1, maxCount: items.first?.count ?? 1, isBlocked: selectedTab == .blocked)
                        .contextMenu { domainActions(for: item) }
                }
            }
        }
        .piholeConfigurationSyncDialog(
            pendingChange: $pendingRule,
            options: syncOptions,
            perform: perform
        )
    }

    @ViewBuilder
    private func domainActions(for item: TopDomainItem) -> some View {
        if let onAddDomain {
            Button {
                request(
                    DomainRule(domain: item.domain, type: .allow, kind: .exact),
                    action: onAddDomain
                )
            } label: {
                Label(UserText.allowDomainAction, systemImage: SystemImages.allowDomain)
            }
            Button {
                request(
                    DomainRule(domain: item.domain, type: .deny, kind: .exact),
                    action: onAddDomain
                )
            } label: {
                Label(UserText.blockDomainAction, systemImage: SystemImages.blockDomain)
            }
        }
    }

    private func request(
        _ rule: DomainRule,
        action: @escaping (DomainRule, PiholeConfigurationChangeScope) async -> Void
    ) {
        if syncOptions.requiresScopeConfirmation {
            pendingRule = rule
        } else {
            Task {
                await action(rule, syncOptions.automaticScope)
            }
        }
    }

    private func perform(_ rule: DomainRule, scope: PiholeConfigurationChangeScope) {
        guard let onAddDomain else { return }
        Task {
            await onAddDomain(rule, scope)
        }
    }
}

private struct TopDomainRow: View {
    let item: TopDomainItem
    let rank: Int
    let maxCount: Int
    let isBlocked: Bool

    private var barFraction: CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(item.count) / CGFloat(maxCount)
    }

    private var barColor: Color {
        isBlocked ? AppColors.queriesBlocked : AppColors.totalQueries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.domain)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(item.count.formatted())
                    .font(.caption)
                    .bold()
                    .contentTransition(.numericText())
            }

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor.opacity(0.6))
                    .frame(width: geometry.size.width * barFraction, height: 4)
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    TopDomainsView(topDomains: TopDomainsResult(
        topPermitted: [
            TopDomainItem(domain: "google.com", count: 500),
            TopDomainItem(domain: "apple.com", count: 300),
            TopDomainItem(domain: "github.com", count: 150),
        ],
        topBlocked: [
            TopDomainItem(domain: "ads.doubleclick.net", count: 1200),
            TopDomainItem(domain: "tracker.facebook.com", count: 800),
            TopDomainItem(domain: "analytics.google.com", count: 400),
        ]
    ))
    .padding()
}
