//
//  ColoredSegmentedPicker.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2026.
//

import SwiftUI

struct ColoredSegmentedPicker<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    let color: (Option) -> Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.subheadline)
                        .fontWeight(selection == option ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            selection == option
                                ? color(option).opacity(0.85)
                                : Color.clear
                        )
                        .foregroundStyle(selection == option ? .white : .secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
