//
//  PiHoleItemConfig.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 30/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PiholeItemConfigView: View {
    @ObservedObject var piholeViewModel: PiholeViewModel
    @EnvironmentObject var preferences: UserPreferences
    @State private var width: CGFloat?
    @State private var presentingQRCodePopOver = false
    private let qrcodeSize: CGFloat = 300

    private var qrcodeValue: String {
        switch preferences.qrcodeFormat {
        case .piStats:
            return piholeViewModel.json
        case .webInterface:
            return piholeViewModel.token
        }
    }
    
    private var selectedQRCodeFormatLabel: String {
        switch preferences.qrcodeFormat {
        case .webInterface:
            return UIConstants.Strings.preferencesQRCodeFormatWebInterface
        case .piStats:
            return UIConstants.Strings.preferencesQRCodeFormatPiStats
        }
    }
    
    enum LabelWidth: Preference {}
    let labelWidth = GeometryPreferenceReader(
        key: AppendValue<LabelWidth>.self,
        value: { [$0.size.width] }
    )
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Text(UIConstants.Strings.host)
                    .read(labelWidth)
                    .frame(width: width, alignment: .leading)
                TextField(UIConstants.Strings.hostPlaceholder, text: $piholeViewModel.address)
            }
            
            HStack {
                Text(UIConstants.Strings.apiToken)
                    .read(labelWidth)
                    .frame(width: width, alignment: .leading)
                SecureField(UIConstants.Strings.apiTokenPlaceholder, text: $piholeViewModel.token)
            }
            
            HStack {
                Text(UIConstants.Strings.preferencesProtocol)
                    .read(labelWidth)
                
                Picker(selection: $piholeViewModel.secureTag, label: Text("")) {
                    Text(UIConstants.Strings.preferencesProtocolHTTP).tag(SecureTag.unsecure)
                    Text(UIConstants.Strings.preferencesProtocolHTTPS).tag(SecureTag.secure)
                }
            }
            
            HStack {
                
                Button(action: {
                    if let url = URL(string: "http://\(self.piholeViewModel.address)/admin/") {
                        NSWorkspace.shared.open(url) }
                }, label: {
                        HStack {
                            Image(UIConstants.Images.globe)
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 15)
                        }
                })
                    .overlay(Tooltip(tooltip: UIConstants.Strings.preferencesWebToolTip))
                
                Button(action: {
                    self.presentingQRCodePopOver.toggle()
                }, label: {
                    HStack {
                        Image(UIConstants.Images.QRCode)
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 13)
                    }
                })
                    .overlay(Tooltip(tooltip: UIConstants.Strings.preferencesQRCodeToolTip))
                    .popover(isPresented: $presentingQRCodePopOver) {
                    VStack {
                        Image(nsImage: QRCodeGenerator().generateQRCode(from: self.qrcodeValue, with: NSSize(width: self.qrcodeSize, height: self.qrcodeSize)))
                        .interpolation(.none)
                        .padding()
                        
                        HStack {
                            Text(UIConstants.Strings.preferencesQRCodeFormat)
                            MenuButton(label: Text(self.selectedQRCodeFormatLabel)) {
                                Button(action: {
                                    self.preferences.qrcodeFormat = .webInterface
                                }, label: { Text(UIConstants.Strings.preferencesQRCodeFormatWebInterface) })
                                Button(action: {
                                    self.preferences.qrcodeFormat = .piStats
                                }, label: { Text(UIConstants.Strings.preferencesQRCodeFormatPiStats) })
                            }
                        }
                        .padding(.bottom)
                        .padding(.horizontal)
                    }
                }
                
                Button(action: {
                    self.piholeViewModel.save()
                }, label: {
                    Text(UIConstants.Strings.savePiholeButton)
                })
            }
            
            Divider()
            
            Text(UIConstants.Strings.findAPITokenInfo)
                .font(.caption)
                .multilineTextAlignment(.center)
                .layoutPriority(1)
            Divider()
            Text(UIConstants.Strings.tokenStoredOnKeychainInfo)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .foregroundColor(.secondary)
        } .assignMaxPreference(for: labelWidth.key, to: $width)
    }
}
