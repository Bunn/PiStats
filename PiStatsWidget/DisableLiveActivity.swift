//
//  DisableLiveActivity.swift
//  PiStatsWidget
//
//  Lock Screen + Dynamic Island UI for the "blocking paused" countdown, with a
//  Re-enable action.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import PiStatsCore

struct DisableLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PiholeDisableActivityAttributes.self) { context in
            // Lock Screen / banner presentation.
            HStack(spacing: 12) {
                Image(systemName: "xmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(context.attributes.piholeName) blocking paused")
                        .font(.headline)
                        .lineLimit(1)
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(intent: ReenableIntent(piholeId: context.attributes.piholeID)) {
                    Text("Re-enable")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.4))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "xmark.shield.fill").foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.piholeName).font(.caption).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: ReenableIntent(piholeId: context.attributes.piholeID)) {
                        Label("Re-enable now", systemImage: "checkmark.shield.fill")
                    }
                    .tint(.green)
                }
            } compactLeading: {
                Image(systemName: "xmark.shield.fill").foregroundStyle(.orange)
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "xmark.shield.fill").foregroundStyle(.orange)
            }
        }
    }
}

struct ReenableIntent: AppIntent {
    static var title: LocalizedStringResource = "Re-enable Pi-hole"
    static var description = IntentDescription("Turn Pi-hole blocking back on")

    @Parameter(title: "Pi-hole ID")
    var piholeId: String

    init() {}
    init(piholeId: String) { self.piholeId = piholeId }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: piholeId),
              let pihole = widgetPiholeStorage.restorePihole(uuid) else {
            throw IntentError.message("Pi-hole not found")
        }
        _ = try await PiholeActionService().enable(pihole)
        DisableActivityController().end(piholeID: piholeId)
        WidgetCenter.shared.reloadTimelines(ofKind: "PiStatusControlWidget")
        return .result()
    }
}
