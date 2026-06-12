//
//  QueryLogView.swift
//  PiStats
//
//  A searchable list of recent DNS queries, loaded on demand from the
//  Pi-hole (not part of the periodic summary refresh).
//

import SwiftUI
import PiStatsCore

struct QueryLogView: View {
    let updater: PiholeSummaryDataUpdater

    @State private var entries: [QueryLogEntry] = []
    @State private var isLoading = true
    @State private var didFail = false
    @State private var searchText = ""

    private var filteredEntries: [QueryLogEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.domain.localizedCaseInsensitiveContains(searchText)
                || $0.client.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if isLoading && entries.isEmpty {
                loadingRow
            } else if didFail && entries.isEmpty {
                ContentUnavailableView(
                    "Couldn't Load Queries",
                    systemImage: SystemImages.errorMessageWarning,
                    description: Text("Pull down to try again.")
                )
            } else if filteredEntries.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredEntries) { entry in
                    QueryLogRow(entry: entry)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(UserText.queryLogTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text(UserText.queryLogSearchPrompt))
        .refreshable { await load() }
        .task { await load() }
    }

    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowSeparator(.hidden)
    }

    private func load() async {
        didFail = false
        if entries.isEmpty { isLoading = true }
        do {
            entries = try await updater.fetchQueries(count: 200)
        } catch {
            didFail = true
        }
        isLoading = false
    }
}

private struct QueryLogRow: View {
    let entry: QueryLogEntry

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.domain)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    Text(entry.client)
                    Text("·")
                    Text(entry.type)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch entry.status {
        case .blocked: return AppColors.queriesBlocked
        case .forwarded: return AppColors.statusOnline
        case .cached: return AppColors.totalQueries
        case .unknown: return .secondary
        }
    }
}
