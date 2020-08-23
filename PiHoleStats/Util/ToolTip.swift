//
//  ToolTip.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 23/08/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct Tooltip: NSViewRepresentable {
    let tooltip: String
    func makeNSView(context: NSViewRepresentableContext<Tooltip>) -> NSView {
        let view = NSView()
        view.toolTip = tooltip
        return view
    }
    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<Tooltip>) {
    }
}
