//
//  EmptyStateView.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI

struct EmptyStateView: View {
    let onAddPihole: () -> Void
    
    var body: some View {
        VStack(spacing: LayoutConstants.MainView.emptyStateSpacing) {
            Spacer()
            
            emptyStateIcon
            emptyStateContent
            addButton
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateIcon: some View {
        Image(systemName: SystemImages.shieldSlash)
            .font(.system(size: LayoutConstants.MainView.emptyStateIconSize))
            .foregroundStyle(.secondary)
    }
    
    private var emptyStateContent: some View {
        VStack(spacing: LayoutConstants.About.footerSpacing) {
            Text(UserText.MainView.noPiholesTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: LayoutConstants.MainView.setupStepsSpacing) {
                Text(UserText.MainView.getStartedMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                setupSteps
            }
        }
    }
    
    private var setupSteps: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.MainView.setupStepsItemSpacing) {
            Text(UserText.MainView.step1)
            Text(UserText.MainView.step2)
            Text(UserText.MainView.step3)
            Text(UserText.MainView.step4)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        Button(action: onAddPihole) {
            Label(UserText.MainView.addFirstPiholeButton, 
                  systemImage: SystemImages.plusCircleFill)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview {
    EmptyStateView(onAddPihole: {})
}
