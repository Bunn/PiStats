//
//  PiholeConfigurationView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 19/02/2022.
//

import SwiftUI

struct PiholeConfigurationView: View {
    @Binding var piholeViewModel: PiholeConfigurationViewModel
    @State private var width: CGFloat?
    
    @State var piholeGradient = [Color.red, Color.gray, Color.black]
    @State var piMonitorGradient = [Color.black, Color.green, Color.blue]
    @State var startPoint = UnitPoint(x: 0, y: 0)
    @State var endPoint = UnitPoint(x: 0, y: 2)
    
    @State var textSample: String = ""

    enum LabelWidth: Preference {}
    let labelWidth = GeometryPreferenceReader(
        key: AppendValue<LabelWidth>.self,
        value: { [$0.size.width] }
    )
    
    var body: some View {
        GroupBox {
            //PiMetricsConfigurationPanelView()
            PiholeConfigurationPanelView(piholeViewModel: $piholeViewModel, width: $width)
            
                Divider()
                
                PiMonitorConfigurationPanelView(piholeViewModel: $piholeViewModel, width: $width)
                
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

//struct PiholeConfigurationView_Previews: PreviewProvider {
//    static var previews: some View {
//        PiholeConfigurationView(piholeViewModel: PiholeConfigurationViewModel.preview())
//    }
//}
