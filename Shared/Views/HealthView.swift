//
//  HealthView.swift
//  PiStats
//
//  Health overview for a Pi-hole: component versions, update availability,
//  and any FTL diagnosis messages.
//

import SwiftUI
import PiStatsCore

struct HealthView: View {
    let health: PiholeHealth
    /// When provided and there are messages, a "Clear" button is shown.
    var onClear: (() async -> Void)? = nil

    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            versionRow("Core", health.coreVersion)
            versionRow("FTL", health.ftlVersion)
            versionRow("Web", health.webVersion)

            updateStatus

            ForEach(health.messages) { message in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: SystemImages.errorMessageWarning)
                        .font(.caption)
                        .foregroundStyle(AppColors.statusWarning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.text)
                            .font(.caption)
                            .foregroundStyle(AppColors.statusWarning)
                            .fixedSize(horizontal: false, vertical: true)
                        if let timestamp = message.timestamp {
                            Text(timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !health.messages.isEmpty, onClear != nil {
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label(UserText.clearMessages, systemImage: SystemImages.trash)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
        .alert(UserText.clearMessagesConfirmTitle, isPresented: $showingClearConfirmation) {
            Button(UserText.clearMessages, role: .destructive) {
                Task { await onClear?() }
            }
            Button(UserText.cancelButton, role: .cancel) { }
        } message: {
            Text(UserText.clearMessagesConfirmMessage)
        }
    }

    @ViewBuilder
    private var updateStatus: some View {
        if health.updateAvailable {
            Label(UserText.healthUpdateAvailable, systemImage: SystemImages.healthUpdate)
                .font(.caption)
                .bold()
                .foregroundStyle(AppColors.statusWarning)
        } else if health.coreVersion != nil {
            Label(UserText.healthUpToDate, systemImage: SystemImages.healthUpToDate)
                .font(.caption)
                .foregroundStyle(AppColors.statusOnline)
        }
    }

    @ViewBuilder
    private func versionRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.caption)
                    .bold()
                    .monospaced()
            }
        }
    }
}

#Preview("Update available") {
    HealthView(health: PiholeHealth(
        coreVersion: "v6.0",
        webVersion: "v6.0",
        ftlVersion: "v6.0.1",
        updateAvailable: true,
        messages: [DiagnosisMessage(text: "1 domain on the gravity database failed to load", timestamp: Date(timeIntervalSince1970: 1609459200))]
    ))
    .padding()
}

#Preview("Up to date") {
    HealthView(health: PiholeHealth(
        coreVersion: "v6.1",
        webVersion: "v6.1",
        ftlVersion: "v6.1",
        updateAvailable: false,
        messages: []
    ))
    .padding()
}
