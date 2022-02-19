//
//  PiholeConfigurationView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 19/02/2022.
//

import SwiftUI

struct PiholeConfigurationView: View {
    @State private var width: CGFloat?
    @State private var showingPopover = false
    
    @State var piholeGradient = [Color.red, Color.gray, Color.black]
    @State var piMonitorGradient = [Color.black, Color.green, Color.blue]
    @State var startPoint = UnitPoint(x: 0, y: 0)
    @State var endPoint = UnitPoint(x: 0, y: 2)
    
    @State var textSample: String = ""
    @State private var protocolTag: Int = 0
    @State var piMonitorEnabled: Bool = false

    enum LabelWidth: Preference {}
    let labelWidth = GeometryPreferenceReader(
        key: AppendValue<LabelWidth>.self,
        value: { [$0.size.width] }
    )
    
    var body: some View {
        GroupBox {

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
                    
                
                
            }.frame(width: 400)
            
        }
    }
    
    
    var piholeSettings: some View {
        VStack (alignment: .leading) {
            HStack {
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(gradient: Gradient(colors: self.piholeGradient), startPoint: self.startPoint, endPoint: self.endPoint))
                        .frame(width: 35, height: 35)
                        .onTapGesture {
                            withAnimation (.easeInOut(duration: 3)){
                                self.startPoint = UnitPoint(x: 1, y: -1)
                                self.endPoint = UnitPoint(x: 0, y: 1)
                            }
                        }.shadow(radius: 1)

                Image(systemName: "shield")
                    .renderingMode(.original)
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(radius: 1)
                }
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
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(gradient: Gradient(colors: self.piMonitorGradient), startPoint: self.startPoint, endPoint: self.endPoint))
                        .frame(width: 35, height: 35)
                        .onTapGesture {
                            withAnimation (.easeInOut(duration: 3)){
                                self.startPoint = UnitPoint(x: 1, y: -1)
                                self.endPoint = UnitPoint(x: 0, y: 1)
                            }
                        }.shadow(radius: 1)

                Image(systemName: "waveform.path.ecg.rectangle")
                    //.renderingMode(.original)
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(radius: 1)
                }
                Text("Pi Monitor")
                
                Button {
                    showingPopover = true
                } label: {
                    Image(systemName: "info.circle.fill")
                        .renderingMode(.original)
                }.popover(isPresented: $showingPopover) {
                    VStack(alignment: .center) {
                        Text("Pi Monitor is a service that helps you to monitor your Raspberry Pi by showing you information like temperature, memory usage and more!\n\nIn order to use it you'll need to install it in your Raspberry Pi.")
                            .multilineTextAlignment(.center)
                            .font(.callout)
                        
                        HStack {
                            Button {
                                showingPopover = false
                            } label: {
                                Text("OK")
                            }
                            
                            Button {
                                showingPopover = false
                            } label: {
                                Text("Learn More")
                            }
                        }.font(.body)
                        
                    }.frame(width: 300)
                    
                        .padding()
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
}

struct PiholeConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        PiholeConfigurationView()
    }
}