//
//  CustomDisableTimesView.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//

import SwiftUI
import UIKit

struct CustomDisableTimesView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingAddTimeSheet = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 5
    @State private var selectedSeconds = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.customDisableTimes) { disableTime in
                    HStack {
                        Text(disableTime.displayName)
                            .font(.body)
                        Spacer()
                    }
                }
                .onDelete(perform: deleteItems)
            } footer: {
                if viewModel.customDisableTimes.isEmpty {
                    Button(action: {
                        showingAddTimeSheet = true
                    }) {
                        HStack {
                            Spacer()
                            Text(UserText.CustomizeDisabletime.emptyListMessage)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(UserText.Settings.customizeDisableTimes)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddTimeSheet = true
                }) {
                    Image(systemName: SystemImages.addNewCustomDisableTime)
                }
            }
        }
        .sheet(isPresented: $showingAddTimeSheet) {
            AddCustomDisableTimeView(
                selectedHours: $selectedHours,
                selectedMinutes: $selectedMinutes,
                selectedSeconds: $selectedSeconds,
                onSave: addNewTime,
                onCancel: {
                    showingAddTimeSheet = false
                    resetForm()
                }
            )
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let disableTime = viewModel.customDisableTimes[index]
            viewModel.removeCustomDisableTime(disableTime)
        }
    }
    
    private func addNewTime() {
        let seconds = selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
        guard seconds > 0 else {
            alertMessage = "Please select a duration greater than 0."
            showingAlert = true
            return
        }
        
        let newDisableTime = DisableTime(seconds: seconds)
        viewModel.addCustomDisableTime(newDisableTime)
        
        showingAddTimeSheet = false
        resetForm()
    }
    
    private func resetForm() {
        selectedHours = 0
        selectedMinutes = 5
        selectedSeconds = 0
    }
}

private struct AddCustomDisableTimeView: View {
    @Binding var selectedHours: Int
    @Binding var selectedMinutes: Int
    @Binding var selectedSeconds: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(UserText.CustomizeDisabletime.title)) {
                    CountdownPicker(
                        selectedHours: $selectedHours,
                        selectedMinutes: $selectedMinutes,
                        selectedSeconds: $selectedSeconds
                    )
                    .frame(height: 120)
                }
            }
            .navigationTitle("Add Disable Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(UserText.cancelButton, action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(UserText.saveButton, action: onSave)
                }
            }
        }
    }
}

struct CountdownPicker: UIViewRepresentable {
    @Binding var selectedHours: Int
    @Binding var selectedMinutes: Int
    @Binding var selectedSeconds: Int
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        
        // Set initial values
        picker.selectRow(selectedHours, inComponent: 0, animated: false)
        picker.selectRow(selectedMinutes, inComponent: 1, animated: false)
        picker.selectRow(selectedSeconds, inComponent: 2, animated: false)
        
        return picker
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        uiView.selectRow(selectedHours, inComponent: 0, animated: true)
        uiView.selectRow(selectedMinutes, inComponent: 1, animated: true)
        uiView.selectRow(selectedSeconds, inComponent: 2, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        let parent: CountdownPicker
        
        init(_ parent: CountdownPicker) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 3 // hours, minutes, seconds
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 24 // hours
            case 1: return 60 // minutes
            case 2: return 60 // seconds
            default: return 0
            }
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch component {
            case 0: return "\(row)"
            case 1: return "\(row)"
            case 2: return "\(row)"
            default: return nil
            }
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: parent.selectedHours = row
            case 1: parent.selectedMinutes = row
            case 2: parent.selectedSeconds = row
            default: break
            }
        }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 22)
            
            switch component {
            case 0:
                if row == 0 {
                    label.text = "0 hours"
                } else {
                    label.text = "\(row) hour\(row == 1 ? "" : "s")"
                }
            case 1:
                if row == 0 {
                    label.text = "0 min"
                } else {
                    label.text = "\(row) min"
                }
            case 2:
                if row == 0 {
                    label.text = "0 sec"
                } else {
                    label.text = "\(row) sec"
                }
            default:
                label.text = "\(row)"
            }
            
            return label
        }
        
        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            switch component {
            case 0: return 120 // hours (wider for "X hours" text)
            case 1: return 80  // minutes
            case 2: return 80  // seconds
            default: return 100
            }
        }
    }
}

#Preview {
    let viewModel = SettingsViewModel()
    return CustomDisableTimesView(viewModel: viewModel)
} 
