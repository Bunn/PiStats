//
//  ErrorMessageView.swift
//  PiStats
//
//  Created by Fernando Bunn on 21/09/2025.
//

import SwiftUI

struct ErrorMessageView: View {
    let error: PiholeError
    let isCollapsible: Bool
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: SystemImages.errorMessageWarning)
                    .foregroundColor(AppColors.errorMessage)
                    .font(.system(size: 14))

                Text(error.humanReadableMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.errorMessage)
                    .lineLimit(isCollapsible ? (isExpanded ? nil : 2) : nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if isCollapsible {
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppColors.errorMessage)
                        .font(.system(size: 12))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }

            if isExpanded || !isCollapsible {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Technical Details:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .bold()

                    Text(error.technicalDetails)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Time: \(error.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 22)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.errorMessage.opacity(0.1))
                .stroke(AppColors.errorMessage.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .highPriorityGesture(
            isCollapsible ? TapGesture().onEnded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } : nil
        )
    }
}

// MARK: - Convenience Initializers
extension ErrorMessageView {
    /// Creates an ErrorMessageView with default collapsible behavior
    init(error: PiholeError) {
        self.error = error
        self.isCollapsible = true
    }
}

#Preview {

    ErrorMessageView(error: .init(type: .authenticationError,
                                  originalError: MockPreviewError.sample,
                                  timestamp: Date()),
                     isCollapsible: false)
    .frame(width: 200)
}

private enum MockPreviewError: Error { case sample }
