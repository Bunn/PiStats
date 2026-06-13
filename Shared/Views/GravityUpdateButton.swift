//
//  GravityUpdateButton.swift
//  PiStats
//
//  Triggers a gravity (blocklist) rebuild and shows when gravity last ran. Owns
//  its own transient progress/error state; the work and the last-updated lookup
//  are injected so the view stays context-agnostic. Pi-hole v6 only — callers
//  gate on version before passing the closures.
//

import SwiftUI

struct GravityUpdateButton: View {
    let action: () async throws -> Void
    var lastUpdatedProvider: (() async throws -> Date?)? = nil

    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var lastUpdated: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                Task { await runUpdate() }
            } label: {
                Label {
                    Text(isUpdating ? "Updating Gravity…" : "Update Gravity")
                } icon: {
                    if isUpdating {
                        ProgressView()
                            #if os(macOS)
                            .controlSize(.small)
                            #endif
                    } else {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(isUpdating)

            if let lastUpdated {
                Text("Last updated \(lastUpdated, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("Gravity Update Failed", isPresented: errorPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await loadLastUpdated() }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func runUpdate() async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        do {
            try await action()
            // Gravity just finished, so reflect it immediately. The server's
            // per-list `date_updated` can lag a beat behind the action returning,
            // so re-fetching here would show a stale time.
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadLastUpdated() async {
        guard let lastUpdatedProvider else { return }
        lastUpdated = try? await lastUpdatedProvider()
    }
}
