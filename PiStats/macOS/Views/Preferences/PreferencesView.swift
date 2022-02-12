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
    @State private var showingPopover = false
    
    var body: some View {
        HStack {
            VStack(spacing:0) {
                List {
                    piholeRow
                    Divider()
                    piholeRow
                    Divider()
                    piholeRow
                    Divider()
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
        .frame(maxWidth: 600, minHeight: 450, idealHeight: 450)
        .padding()
    }
    
    var piholeRow: some View {
        HStack {
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
                VStack (alignment: .leading) {
                Text("192.168.1.123")
                        .font(.title3)
                    Text("Enabled")
                        .font(.caption)
                }
            }
            
            
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
    
    @State var piholeGradient = [Color.red, Color.gray, Color.black]
    @State var piMonitorGradient = [Color.black, Color.green, Color.blue]
       @State var startPoint = UnitPoint(x: 0, y: 0)
       @State var endPoint = UnitPoint(x: 0, y: 2)
    
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
    
    var detailsView: some View {
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
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
