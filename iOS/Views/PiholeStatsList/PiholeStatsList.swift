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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject var listUpdater = PiholeListUpdater(
        DefaultPiholeStorage().restoreAllPiholes()
    )

    @State private var columnCount = 2

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private let cardSpacing: CGFloat = 20
    private let maxColumns = 2
    private let minCardWidth: CGFloat = 340
    private let maxContentWidth: CGFloat = 1100
    private let regularHorizontalInset: CGFloat = 24

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: isRegularWidth ? maxContentWidth : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, isRegularWidth ? regularHorizontalInset : 0)
                .padding(.vertical, isRegularWidth ? 16 : 0)
        }
        .onGeometryChange(for: Int.self) { proxy in
            resolvedColumnCount(for: proxy.size.width)
        } action: { newValue in
            columnCount = newValue
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
        .toolbar {
            if isRegularWidth {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddPiholeSheet = true
                    } label: {
                        Label("Add Pi-hole", systemImage: SystemImages.plus)
                    }
                }
            }
        }
        .onAppear {
            listUpdater.startUpdating()
        }
        .background(Color(.systemGroupedBackground)
            .edgesIgnoringSafeArea(.all)
        )
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            if settingsStore.displayAllPiholes {
                AllPiholesView(listUpdater: listUpdater, settingsStore: settingsStore)
                    .padding(.horizontal, isRegularWidth ? 0 : 16)
                    .padding(.top, isRegularWidth ? 0 : 16)
            }

            if listUpdater.dataUpdaters.isEmpty {
                emptyStateView
            } else if isRegularWidth {
                columnGrid(columns: columnCount)
            } else {
                VStack(spacing: 0) {
                    ForEach(listUpdater.dataUpdaters) { dataUpdater in
                        cardView(for: dataUpdater)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }

            if !isRegularWidth {
                addPiholeButton()
            }
        }
    }

    private func resolvedColumnCount(for paneWidth: CGFloat) -> Int {
        guard isRegularWidth else { return 1 }
        let usableWidth = min(paneWidth, maxContentWidth) - regularHorizontalInset * 2
        guard usableWidth > 0 else { return 1 }
        let fitting = Int((usableWidth + cardSpacing) / (minCardWidth + cardSpacing))
        return max(1, min(fitting, maxColumns))
    }

    private func columnGrid(columns: Int) -> some View {
        let buckets = Array(repeating: [PiholeSummaryDataUpdater](), count: columns)
        let distributed = listUpdater.dataUpdaters.enumerated().reduce(into: buckets) { acc, pair in
            acc[pair.offset % columns].append(pair.element)
        }
        return HStack(alignment: .top, spacing: cardSpacing) {
            ForEach(0..<columns, id: \.self) { column in
                VStack(spacing: cardSpacing) {
                    ForEach(distributed[column]) { dataUpdater in
                        cardView(for: dataUpdater)
                    }
                }
            }
        }
    }

    private func cardView(for dataUpdater: PiholeSummaryDataUpdater) -> some View {
        PiStatsCardView(
            data: dataUpdater.summary,
            updater: dataUpdater,
            settingsStore: settingsStore,
            onSettings: { editingPihole = dataUpdater.pihole }
        )
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
    }

    private func handlePiholeChange(_ pihole: Pihole, isDelete: Bool) {
        if isDelete {
            listUpdater.removePihole(pihole)
        } else {
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
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .padding(.vertical, isRegularWidth ? 80 : 40)
    }
}

extension PiholeStatsList {
    fileprivate func addPiholeButton() -> some View {
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
