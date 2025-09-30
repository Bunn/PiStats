//
//  ContentView.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import PiStatsCore

struct MacMainView: View {
    @ObservedObject var prefs: MacPreferences
    @ObservedObject var dataManager: PiholeDataManager
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettings = false
    @State private var isPresentingAbout = false
    @State private var editingPihole: Pihole?

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.MainView.defaultSpacing) {
            if let listUpdater = dataManager.listUpdater, !listUpdater.dataUpdaters.isEmpty {
                piholesList(listUpdater.dataUpdaters)
            } else {
                EmptyStateView(onAddPihole: { isPresentingAddSheet = true })
            }
        }
        .toolbar {
            toolbarItems
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            MacPiholeSetupView { _, _ in
                dataManager.refreshData()
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            MacSettingsView(prefs: prefs)
        }
        .sheet(isPresented: $isPresentingAbout) {
            AboutView(isPresented: $isPresentingAbout)
        }
        .sheet(item: $editingPihole) { pihole in
            MacPiholeSetupView(pihole: pihole) { _, _ in
                dataManager.refreshData()
            }
        }
        .onAppear(perform: setupView)
        .onDisappear { dataManager.stopUpdating() }
    }
    
    private func piholesList(_ dataUpdaters: [PiholeSummaryDataUpdater]) -> some View {
        List(dataUpdaters.sortedByNameThenHost()) { dataUpdater in
            MacPiholeRowFromDataUpdater(
                dataUpdater: dataUpdater,
                onEditTapped: { editingPihole = dataUpdater.pihole }
            )
            .contextMenu {
                contextMenuItems(for: dataUpdater.pihole)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            Button(action: { isPresentingAbout = true }) {
                Label(UserText.MainView.aboutButton, 
                      systemImage: SystemImages.infoCircle)
            }
        }
        
        ToolbarItem(placement: .secondaryAction) {
            Button(action: { isPresentingSettings = true }) {
                Label(UserText.MainView.settingsButton, 
                      systemImage: SystemImages.gearshape)
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: { isPresentingAddSheet = true }) {
                Label(UserText.MainView.addPiholeButton, 
                      systemImage: SystemImages.plus)
            }
            .keyboardShortcut("n", modifiers: [.command])
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for pihole: Pihole) -> some View {
        Button(UserText.MainView.settingsButton, 
               systemImage: SystemImages.gearshape) {
            editingPihole = pihole
        }
        
        Button(UserText.MainView.deleteButton, 
               systemImage: SystemImages.trash, 
               role: .destructive) {
            deletePihole(pihole)
        }
    }
    
    private func setupView() {
        dataManager.startUpdating()
        NotificationCenter.default.addObserver(
            forName: .showAddPiholeSheet,
            object: nil,
            queue: .main
        ) { _ in
            isPresentingAddSheet = true
        }
    }

    private func deletePihole(_ pihole: Pihole) {
        let storage = DefaultPiholeStorage()
        storage.deletePihole(pihole)
        dataManager.refreshData()
    }
}

#Preview {
    MacMainView(prefs: MacPreferences(), dataManager: PiholeDataManager())
}
