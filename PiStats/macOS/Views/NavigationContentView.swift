//
//  NavigationContentView.swift
//  PiStats
//
//  Created by Fernando Bunn on 12/06/2021.
//

import SwiftUI

struct NavigationContentView: View {
    let message: String

    var body: some View {
        Text("Details for \(message)")
            .toolbar {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
    }
}

struct NavigationContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContentView(message: "Test")
    }
}
