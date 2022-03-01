//
//  PiholeConfigurationPanelVie.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 01/03/2022.
//

import SwiftUI

struct PiholeConfigurationPanelView: View {
    @Binding var piholeViewModel: PiholeConfigurationViewModel
    @State private var protocolTag: Int = 0
    @Binding var width: CGFloat?
    
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
                    TextField("Raspberry Pi", text: $piholeViewModel.name)
                }
                
                HStack {
                    Text("Host")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    TextField("192.168.1.1", text: $piholeViewModel.name)
                }
                
                HStack {
                    Text("Port")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    TextField("80", text: $piholeViewModel.name)
                }
                
                HStack {
                    Text("API Token")
                        .read(labelWidth)
                        .frame(width: width, alignment: .leading)
                    
                    TextField("dsfsdfsdsdgs", text: $piholeViewModel.name)
                    
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
}

//struct PiholeConfigurationPanelVie_Previews: PreviewProvider {
//    static var previews: some View {
//        PiholeConfigurationPanelView()
//    }
//}
