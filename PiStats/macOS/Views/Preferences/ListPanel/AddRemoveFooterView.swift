//
//  AddRemoveFooterView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 01/03/2022.
//

import SwiftUI

struct AddRemoveFooterView: View {
    var body: some View {
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
    
}

struct AddRemoveFooterView_Previews: PreviewProvider {
    static var previews: some View {
        AddRemoveFooterView()
    }
}
