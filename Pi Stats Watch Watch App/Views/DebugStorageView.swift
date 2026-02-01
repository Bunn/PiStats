//
//  DebugStorageView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI
import PiStatsCore

struct DebugStorageView: View {
    @State private var debugLog: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Test data button
                Button {
                    createTestData()
                } label: {
                    Label("Create Test Pi-hole", systemImage: "testtube.2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                // Refresh button
                Button {
                    loadDebugInfo()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Divider()

                // Debug output - logs will also appear in Xcode console
                Text(debugLog)
                    .font(.system(.caption2, design: .monospaced))
            }
            .padding()
        }
        .navigationTitle("Debug")
        .onAppear {
            loadDebugInfo()
        }
    }

    private func log(_ message: String) {
        debugLog += message + "\n"
        // This will appear in Xcode console
        print("🔍 [Watch Debug] \(message)")
    }

    private func loadDebugInfo() {
        debugLog = ""
        log("=== WATCH APP DEBUG ===")
        log("Check Xcode console for full output")
        log("Time: \(Date())")
        log("")

        // App group info
        log("--- APP GROUP ---")
        log("Name: \(AppGroup.name)")
        log("")

        // Check app group UserDefaults
        log("--- APP GROUP USERDEFAULTS ---")
        if let appGroupDefaults = UserDefaults(suiteName: AppGroup.name) {
            log("✅ App group accessible")

            // The key we're looking for
            let key = "PiStatsNewPiHoleList"
            log("Looking for key: \(key)")

            if let data = appGroupDefaults.data(forKey: key) {
                log("✅ Found data!")
                log("Size: \(data.count) bytes")

                // Try to decode
                do {
                    let piholes = try JSONDecoder().decode([Pihole].self, from: data)
                    log("✅ Decoded successfully")
                    log("Count: \(piholes.count) Pi-holes")

                    for (index, pihole) in piholes.enumerated() {
                        log("  [\(index)] \(pihole.name)")
                        log("      Address: \(pihole.address)")
                        log("      Port: \(pihole.port)")
                        log("      Version: \(pihole.version.rawValue)")
                        log("      UUID: \(pihole.uuid)")
                        log("      Has token: \(pihole.token != nil)")
                    }
                } catch {
                    log("❌ Decode failed: \(error)")
                }
            } else {
                log("❌ NO DATA FOUND for key: \(key)")
            }

            // Check legacy key
            log("")
            let legacyKey = "PiHoleStatsPiHoleList"
            if let legacyData = appGroupDefaults.data(forKey: legacyKey) {
                log("⚠️ Found legacy key: \(legacyKey)")
                log("Size: \(legacyData.count) bytes")
            } else {
                log("No legacy data")
            }

            // List ALL keys
            log("")
            log("--- ALL KEYS IN APP GROUP ---")
            let allKeys = appGroupDefaults.dictionaryRepresentation().keys.sorted()
            log("Total keys: \(allKeys.count)")

            if allKeys.isEmpty {
                log("⚠️ APP GROUP IS EMPTY!")
            } else {
                for key in allKeys {
                    let value = appGroupDefaults.object(forKey: key)
                    let type = type(of: value)
                    log("  - \(key) (\(type))")
                }
            }
        } else {
            log("❌ CANNOT ACCESS APP GROUP!")
            log("This is a critical error")
        }

        // Standard UserDefaults (should be empty)
        log("")
        log("--- STANDARD USERDEFAULTS ---")
        if let stdData = UserDefaults.standard.data(forKey: "PiStatsNewPiHoleList") {
            log("⚠️ WARNING: Data in standard defaults!")
            log("Size: \(stdData.count) bytes")
            log("Data should be in app group, not here")
        } else {
            log("✅ No data in standard (correct)")
        }

        // Via piholeStorage
        log("")
        log("--- VIA piholeStorage ---")
        let piholes = piholeStorage.restoreAllPiholes()
        log("Restored: \(piholes.count) Pi-holes")
        for pihole in piholes {
            log("  - \(pihole.name) @ \(pihole.address)")
        }

        log("")
        log("=== END DEBUG ===")
    }

    private func createTestData() {
        log("")
        log("--- CREATING TEST DATA ---")

        let testPihole = Pihole(
            name: "Test Pi-hole (Watch)",
            address: "192.168.1.100",
            version: .v5,
            port: 80,
            secure: false,
            token: "test-token-from-watch",
            piMonitor: nil,
            uuid: UUID()
        )

        log("Created test Pi-hole: \(testPihole.name)")

        // Save it
        piholeStorage.savePihole(testPihole)
        log("Saved via piholeStorage")

        // Verify
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadDebugInfo()
        }
    }
}

#Preview {
    NavigationStack {
        DebugStorageView()
    }
}
