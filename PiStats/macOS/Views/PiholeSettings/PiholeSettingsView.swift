//
//  PiholeSettingsView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 05/02/2022.
//

import SwiftUI
enum SecureTag: Int {
    case unsecure
    case secure
}


struct PiholeSettingsView: View {
    @State private var width: CGFloat?

    @State private var text: String = "test"
    
    @State var secureTag: SecureTag = .secure
    
    @State private var presentingQRCodePopOver = false

    private let qrcodeSize: CGFloat = 300

    enum LabelWidth: Preference {}
    let labelWidth = GeometryPreferenceReader(
        key: AppendValue<LabelWidth>.self,
        value: { [$0.size.width] }
    )
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Text(UserText.host)
                    .read(labelWidth)
                    .frame(width: width, alignment: .leading)
                TextField(UserText.hostPlaceholder, text: $text)
            }
            
            HStack {
                Text(UserText.apiToken)
                    .read(labelWidth)
                    .frame(width: width, alignment: .leading)
                SecureField(UserText.apiTokenPlaceholder, text: $text)
            }
            
            HStack {
                Text(UserText.preferencesProtocol)
                    .read(labelWidth)
                
                Picker(selection: $secureTag, label: Text("")) {
                    Text(UserText.preferencesProtocolHTTP).tag(SecureTag.unsecure)
                    Text(UserText.preferencesProtocolHTTPS).tag(SecureTag.secure)
                }
            }
            
            HStack {
                
                Button(action: {
                    if let url = URL(string: "http://\("test")/admin/") {
                        NSWorkspace.shared.open(url) }
                }, label: {
                        HStack {
                            Image(UserImages.globe)
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 15)
                        }
                })
                    .overlay(Tooltip(tooltip: UserText.preferencesWebToolTip))
                
                Button(action: {
                    self.presentingQRCodePopOver.toggle()
                }, label: {
                    HStack {
                        Image(UserImages.QRCode)
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 13)
                    }
                })
                    .overlay(Tooltip(tooltip: UserText.preferencesQRCodeToolTip))
                    .popover(isPresented: $presentingQRCodePopOver) {
                    VStack {
                        Image(nsImage: QRCodeGenerator().generateQRCode(from: "test", with: NSSize(width: self.qrcodeSize, height: self.qrcodeSize)))
                        .interpolation(.none)
                        .padding()
                        
                        HStack {
                            Text(UserText.preferencesQRCodeFormat)
                            MenuButton(label: Text("Test")) {
                                Button(action: {
                                    //self.preferences.qrcodeFormat = .webInterface
                                }, label: { Text(UserText.preferencesQRCodeFormatWebInterface) })
                                Button(action: {
                                   // self.preferences.qrcodeFormat = .piStats
                                }, label: { Text(UserText.preferencesQRCodeFormatPiStats) })
                            }
                        }
                        .padding(.bottom)
                        .padding(.horizontal)
                    }
                }
                
                Button(action: {
                   // self.piholeViewModel.save()
                }, label: {
                   // Text(UserText.savePiholeButton)
                })
            }
            
            Divider()
            
            Text(UserText.findAPITokenInfo)
                .font(.caption)
                .multilineTextAlignment(.center)
                .layoutPriority(1)
            Divider()
            Text(UserText.tokenStoredOnKeychainInfo)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .foregroundColor(.secondary)
        }
    }
}

struct PiholeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PiholeSettingsView()
    }
}
