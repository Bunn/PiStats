//
//  EmptyStateView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: SystemImages.shieldSlash)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Pi-holes")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Configure on iPhone")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    EmptyStateView()
}
