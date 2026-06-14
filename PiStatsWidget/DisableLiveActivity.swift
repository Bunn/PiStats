//
//  DisableLiveActivity.swift
//  PiStatsWidget
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
                Image(systemName: context.isStale ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(context.isStale ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ad blocking")
                        .font(.headline)
                        .lineLimit(1)
                    Text(context.isStale
                         ? "Resumed"
                         : "Paused until \(context.state.endDate, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if !context.isStale {
                    Button(intent: ReenableIntent()) {
                        Text("Re-enable")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color.black.opacity(0.4))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.isStale ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title3)
                        .foregroundStyle(context.isStale ? .green : .orange)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        Text(context.isStale
                             ? "Ad blocking resumed"
                             : "Ad blocking paused until \(context.state.endDate, style: .time)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if context.isStale {
                            Label("Pi-hole is blocking again", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Button(intent: ReenableIntent()) {
                                Label("Re-enable now", systemImage: "checkmark.shield.fill")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: context.isStale ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(context.isStale ? .green : .orange)
            } compactTrailing: {
                if !context.isStale {
                    Text(context.state.endDate, style: .time)
                        .foregroundStyle(.orange)
                }
            } minimal: {
                Image(systemName: context.isStale ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(context.isStale ? .green : .orange)
            }
        }
    }
}
