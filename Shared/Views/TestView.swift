//
//  TestView.swift
//  PiStats
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        #if os(macOS)
        Text("macOS")
        #elseif os(iOS)
        Text("iOS")
        #else
        Text("Unsupported Platform")
        #endif
    }
}
