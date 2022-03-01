//
//  PiMonitorConfigurationPanelView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 01/03/2022.
//

import SwiftUI

struct PiMonitorConfigurationPanelView: View {
    @Binding var piholeViewModel: PiholeConfigurationViewModel
    @State private var protocolTag: Int = 0
    @Binding var width: CGFloat?
    @State private var showingPopover = false
    @State var piMonitorEnabled: Bool = false

    //
    @State var piholeGradient = [Color.red, Color.gray, Color.black]
    @State var piMonitorGradient = [Color.black, Color.green, Color.blue]
    @State var startPoint = UnitPoint(x: 0, y: 0)
    @State var endPoint = UnitPoint(x: 0, y: 2)

    //

    enum LabelWidth: Preference {}
    let labelWidth = GeometryPreferenceReader(
        key: AppendValue<LabelWidth>.self,
        value: { [$0.size.width] }
    )

    var body: some View {
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
                    TextField("8088", text: $piholeViewModel.name)
                }
                
            }.assignMaxPreference(for: labelWidth.key, to: $width)
        }.padding()    }
}

//struct PiMetricsConfigurationPanelView_Previews: PreviewProvider {
//    static var previews: some View {
//        PiMonitorConfigurationPanelView()
//    }
//}
