//
//  PreferencesView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 05/02/2022.
//

import SwiftUI

struct PreferencesView: View {
    @State var piMonitorEnabled: Bool = false
    @State var textSample: String = ""
    @State private var width: CGFloat?
    @State private var protocolTag: Int = 0

    var body: some View {
        HStack {
            VStack(spacing:0) {
                List {
                    piholeRow
                }.border(.gray)
                
                VStack(spacing:0) {
                    Spacer()
                    settingsRow
                    Spacer()
                    Divider()
                }.background(Color.white)
                    .frame(height: 40)
                
                addRemoveFooter
                
            }.border(.gray)
                .frame(width: 200)
            
            detailsView
        }
        .padding()
    }
    
    var piholeRow: some View {
        HStack {
            Image(systemName: "shield")
            Text("192.123.4.5")
            Spacer()
            
        }
    }
    
    var settingsRow: some View {
        HStack {
            Button {
                print("settings")
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .padding(.leading)
                    Text("Pi Stats Options")
                }
            } .buttonStyle(.plain)
            
            
            Spacer()
        }
    }
    
    var addRemoveFooter: some View {
        let buttonWidth: CGFloat = 25
        let buttonHeight: CGFloat = 20
        let footerHeight: CGFloat = 20
        
        return HStack(spacing:0) {
            Button {
                print("+")
            } label: {
                Image(systemName: "plus")
                    .frame(width: buttonWidth, height: buttonHeight)
                    .contentShape(Rectangle())
                
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Button {
                print("-")
            } label: {
                Image(systemName: "minus")
                    .frame(width: buttonWidth, height: buttonHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            
            Divider()
            Spacer()
        }.frame(height:footerHeight)
    }
    
    enum LabelWidth: Preference {}
    let labelWidth = GeometryPreferenceReader(
        key: AppendValue<LabelWidth>.self,
        value: { [$0.size.width] }
    )
    
    var piholeSettings: some View {
        VStack (alignment: .leading) {
            HStack {
                Image(systemName: "shield")
                    .renderingMode(.original)
                Text("Pi-hole")
            }.font(.title2)
            
            VStack(alignment: .leading) {
                    
                HStack {
                    Text("Name")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    TextField("Raspberry Pi", text: $textSample)
                }
                
                    HStack {
                        Text("Host")
                            .read(labelWidth)
                            .frame(width: width, alignment: .leading)
                        TextField("192.168.1.1", text: $textSample)
                    }
                    
                    HStack {
                        Text("Port")
                            .read(labelWidth)
                            .frame(width: width, alignment: .leading)
                        TextField("80", text: $textSample)
                    }
                
                HStack {
                    Text("API Token")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    
                    TextField("dsfsdfsdsdgs", text: $textSample)

                }
       
                    HStack {
                        Text("Protocol")
                            .read(labelWidth)

                        Picker(selection: $protocolTag, label: Text("")) {
                            Text("HTTP").tag(0)
                            Text("HTTPS").tag(1)
                        }.frame(width: 85)
                    }

                }
                .assignMaxPreference(for: labelWidth.key, to: $width)
            
        }
        
        .padding()
    }
    
    var piMonitorSettings: some View {
        VStack (alignment: .leading) {
            HStack {
                Image(systemName: "waveform.path.ecg.rectangle")
                    .renderingMode(.original)
                Text("Pi Monitor")
                
                Button {
                    print("monitor")
                } label: {
                    Image(systemName: "info.circle.fill")
                            .renderingMode(.original)
                }
                .buttonStyle(.plain)

            }.font(.title2)
            VStack(alignment: .leading)  {
                HStack {
                    Text("Enabled")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    
                    Toggle("", isOn: $piMonitorEnabled)

                }
                
                HStack {
                    Text("Port")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    TextField("8088", text: $textSample)
                }

            }.assignMaxPreference(for: labelWidth.key, to: $width)
        }.padding()
    }
    
    var detailsView: some View {
        GroupBox {
            
            
            ScrollView(.vertical, showsIndicators: true) {
                piholeSettings
                
                Divider()
                
                piMonitorSettings
                
                Divider()
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        print("Save")
                    } label: {
                        Text("Save")
                    }
                    
                    Button {
                        print("Save")
                    } label: {
                        Text("Save")
                    }
                    
                    Button {
                        print("Save")
                    } label: {
                        Text("Save")
                    }

                }
                
            }.frame(width: 400)
            
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
