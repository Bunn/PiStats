//
//  NavigationContainerView.swift
//  PiStats
//
//  Created by Fernando Bunn on 12/06/2021.
//

import SwiftUI

struct NavigationContainerView: View {
    var body: some View {
        NavigationView {
            Sidebar()
            Text("No Sidebar Selection")            
        }
    }
}

struct NavigationContainerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainerView()
    }
}
