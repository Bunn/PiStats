//
//  OptionsButtonView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 01/03/2022.
//

import SwiftUI

struct OptionsButtonView: View {
    var body: some View {
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
}

struct OptionsButtonView_Previews: PreviewProvider {
    static var previews: some View {
        OptionsButtonView()
    }
}
