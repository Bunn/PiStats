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
    @State private var qrcodeString = ""
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
                Button(action: {
                    self.presentingQRCodePopOver.toggle()
                }, label: {
                    HStack {
                        Image("qrcode")
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 10)
                    }
                }).popover(isPresented: $presentingQRCodePopOver) {
                    VStack {
                        Image(nsImage: QRCodeGenerator().generateQRCode(from: self.qrcodeString, with: NSSize(width: self.qrcodeSize, height: self.qrcodeSize)))
                        .interpolation(.none)
                        .padding()
                        
                        HStack {
                            Text(UIConstants.Strings.preferencesQRCodeFormat)
                            MenuButton(label: Text(self.selectedQRCodeFormatLabel)) {
                                Button(action: {
                                    self.preferences.qrcodeFormat = .webInterface
                                    self.updateQRCodeString()
                                }, label: { Text(UIConstants.Strings.preferencesQRCodeFormatWebInterface) })
                                Button(action: {
                                    self.preferences.qrcodeFormat = .piStats
                                    self.updateQRCodeString()
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
            .onAppear {
                self.updateQRCodeString()
        }
    }
    
    private func updateQRCodeString() {
        switch preferences.qrcodeFormat {
        case .piStats:
            qrcodeString = piholeViewModel.json
        case .webInterface:
            qrcodeString = piholeViewModel.token
        }
    }
}
