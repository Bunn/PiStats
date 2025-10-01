//
//  PiholeStatsList.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//

import SwiftUI
import PiStatsCore

struct PiholeStatsList: View {
    @State var showAddPiholeSheet = false
    @State var editingPihole: Pihole? = nil
    @ObservedObject var settingsStore: SettingsStore

    @StateObject var listUpdater = PiholeListUpdater(
        DefaultPiholeStorage().restoreAllPiholes()
    )

    var body: some View {
        ScrollView {
            VStack {
                if settingsStore.displayAllPiholes {
                    AllPiholesView(listUpdater: listUpdater, settingsStore: settingsStore)
                        .padding()
                }
                
                if listUpdater.dataUpdaters.isEmpty {
                    emptyStateView
                } else {
                    ForEach(listUpdater.dataUpdaters) { dataUpdater in
                        PiStatsCardView(data: dataUpdater.summary, updater: dataUpdater, settingsStore: settingsStore)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingPihole = dataUpdater.pihole
                            }
                            .contextMenu {
                                Button(action: {
                                    editingPihole = dataUpdater.pihole
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive, action: {
                                    deletePihole(dataUpdater.pihole)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .padding()
                    }
                }
                
                addPiholeButton()
            }
        }
        .sheet(item: $editingPihole) { pihole in
            PiholeSetupView(pihole: pihole) { updatedPihole, isDelete in
                handlePiholeChange(updatedPihole, isDelete: isDelete)
            }
        }
        .sheet(isPresented: $showAddPiholeSheet) {
            PiholeSetupView { newPihole, isDelete in
                handlePiholeChange(newPihole, isDelete: isDelete)
            }
        }
        .navigationTitle(UserText.piholesNavigationTitle)
        .onAppear {
            listUpdater.startUpdating()
        }
        .background(Color(.systemGroupedBackground)
            .edgesIgnoringSafeArea(.all)
        )
    }
    
    private func handlePiholeChange(_ pihole: Pihole, isDelete: Bool) {
        if isDelete {
            listUpdater.removePihole(pihole)
        } else {
            // Check if this is an existing pihole (update) or new pihole (add)
            if listUpdater.dataUpdaters.contains(where: { $0.pihole.uuid == pihole.uuid }) {
                listUpdater.updatePihole(pihole)
            } else {
                listUpdater.addPihole(pihole)
            }
        }
    }
    
    private func deletePihole(_ pihole: Pihole) {
        let storage = DefaultPiholeStorage()
        storage.deletePihole(pihole)
        listUpdater.removePihole(pihole)
    }
}

private var emptyStateView: some View {
    VStack(spacing: 20) {
        Image(systemName: "shield.slash")
            .font(.system(size: 60))
            .foregroundColor(.secondary)

        Text("No Pi-holes configured")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.primary)

        Text(UserText.MainView.addFirstPiholeCaption)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

extension PiholeStatsList {
    private func addPiholeButton() -> some View {
        Button {
            showAddPiholeSheet = true
        } label: {
            Image(systemName: SystemImages.plus)
                .foregroundColor(.white)
                .font(.largeTitle)
                .frame(width: LayoutConstants.addPiholeButtonHeight, height: LayoutConstants.addPiholeButtonHeight, alignment: .center)

        }
        .glassEffect(.regular.tint(Color(.systemBlue)).interactive())
        .padding()
    }
}

#Preview {
    PiholeStatsList(settingsStore: SettingsStore())
}
