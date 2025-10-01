//
//  ActionButtonView.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import PiStatsCore

struct ActionButtonView: View {
    let status: PiholeStatus
    let prefs: MacPreferences
    let onEnable: () async -> Void
    let onDisable: (Int?) async -> Void

    var body: some View {
        if status == .enabled {
            disableButton
        } else if status == .disabled {
            enableButton
        }
    }

    private var enableButton: some View {
        Button(action: {
            Task { await onEnable() }
        }) {
            buttonLabel(icon: "play.circle", text: UserText.enableButton)
        }
    }

    @ViewBuilder
    private var disableButton: some View {
        if prefs.disablePermanently {
            permanentDisableButton
        } else {
            timedDisableMenu
        }
    }

    private var permanentDisableButton: some View {
        Button(action: {
            Task { await onDisable(nil) }
        }) {
            buttonLabel(icon: "pause.circle", text: UserText.disableButton)
        }
    }

    private var timedDisableMenu: some View {
        Menu {
            disableTimingOptions
        } label: {
            Label(UserText.disableButton, systemImage: "pause.circle")
        }
        .menuIndicator(.hidden)
    }

    private func buttonLabel(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
        }
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var disableTimingOptions: some View {
        Button("30 seconds") {
            Task { await onDisable(30) }
        }

        Button("1 minute") {
            Task { await onDisable(60) }
        }

        Button("5 minutes") {
            Task { await onDisable(300) }
        }

        Button("10 minutes") {
            Task { await onDisable(600) }
        }

        Button("30 minutes") {
            Task { await onDisable(1800) }
        }

        Button("1 hour") {
            Task { await onDisable(3600) }
        }

        Divider()

        Button(UserText.Popover.disablePermanently) {
            Task { await onDisable(nil) }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            ActionButtonView(
                status: .enabled,
                prefs: previewPrefsWithPermanent,
                onEnable: { print("Enable") },
                onDisable: { timer in print("Disable timer: \(timer?.description ?? "permanent")") }
            )

            ActionButtonView(
                status: .enabled,
                prefs: previewPrefsWithTimed,
                onEnable: { print("Enable") },
                onDisable: { timer in print("Disable timer: \(timer?.description ?? "permanent")") }
            )
        }

        HStack(spacing: 16) {
            ActionButtonView(
                status: .disabled,
                prefs: previewPrefsWithPermanent,
                onEnable: { print("Enable") },
                onDisable: { timer in print("Disable timer: \(timer?.description ?? "permanent")") }
            )

            ActionButtonView(
                status: .disabled,
                prefs: previewPrefsWithTimed,
                onEnable: { print("Enable") },
                onDisable: { timer in print("Disable timer: \(timer?.description ?? "permanent")") }
            )
        }

        HStack(spacing: 16) {
            ActionButtonView(
                status: .unknown,
                prefs: previewPrefsWithPermanent,
                onEnable: { print("Enable") },
                onDisable: { timer in print("Disable timer: \(timer?.description ?? "permanent")") }
            )

            ActionButtonView(
                status: .unknown,
                prefs: previewPrefsWithTimed,
                onEnable: { print("Enable") },
                onDisable: { timer in print("Disable timer: \(timer?.description ?? "permanent")") }
            )
        }
    }
    .padding(33)
}

private let previewPrefsWithPermanent: MacPreferences = {
    let prefs = MacPreferences()
    prefs.disablePermanently = true
    return prefs
}()

private let previewPrefsWithTimed: MacPreferences = {
    let prefs = MacPreferences()
    prefs.disablePermanently = false
    return prefs
}()
