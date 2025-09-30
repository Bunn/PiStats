//
//  AboutView.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI

struct AboutView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: LayoutConstants.About.mainSpacing) {
            appIcon
            appInfo
            footer
            closeButton
        }
        .padding(LayoutConstants.About.contentPadding)
    }
    
    private var appIcon: some View {
        Group {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LayoutConstants.About.iconSize, height: LayoutConstants.About.iconSize)
            } else {
                Image(systemName: SystemImages.shieldLefthalfFill)
                    .font(.system(size: LayoutConstants.About.iconSize))
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var appInfo: some View {
        VStack(spacing: LayoutConstants.About.titleSpacing) {
            Text(UserText.About.appName)
                .font(.title)
                .fontWeight(.bold)
            
            Text(UserText.About.tagline)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text(String(format: UserText.About.versionFormat, version, build))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var footer: some View {
        VStack(spacing: LayoutConstants.About.footerSpacing) {
            Text(UserText.About.copyright)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: LayoutConstants.About.linkSpacing) {
                Link(UserText.About.websiteButton, 
                     destination: URL(string: UserText.About.websiteURL)!)
                    .font(.caption)
                
                Link(UserText.About.supportButton, 
                     destination: URL(string: UserText.About.supportURL)!)
                    .font(.caption)
            }
        }
    }
    
    private var closeButton: some View {
        Button(UserText.About.closeButton) {
            isPresented = false
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    AboutView(isPresented: .constant(true))
}
