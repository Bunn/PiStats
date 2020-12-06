//
//  AddRemoveButton.swift
//  PiHoleStats
//
//  Created by David Albert on 12/6/20.
//

import SwiftUI

struct AddRemoveButton: NSViewRepresentable {
    let removeEnabled: Bool
    let action: (Bool) -> Void
    
    func makeNSView(context: Context) -> NSSegmentedControl {
        let images = [
            NSImage(named: NSImage.addTemplateName)!,
            NSImage(named: NSImage.removeTemplateName)!,
        ]
        
        let control = NSSegmentedControl(images: images, trackingMode: .momentary, target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        
        control.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        return control
    }
    
    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        control.setEnabled(removeEnabled, forSegment: 1)
        context.coordinator.action = action
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: (Bool) -> Void
        
        init(action: @escaping (Bool) -> Void) {
            self.action = action
        }
        
        @objc func handleClick(_ sender: NSSegmentedControl) {
            action(sender.selectedSegment == 0)
        }
    }
}

struct AddRemoveButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddRemoveButton(removeEnabled: true) { isAdd in print(isAdd, "hmm") }
            AddRemoveButton(removeEnabled: false) { isAdd in print(isAdd, "hmm") }
        }
    }
}
