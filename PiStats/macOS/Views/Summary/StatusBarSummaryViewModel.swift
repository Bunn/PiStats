
import Foundation
import PiStatsCore
import Combine

class StatusBarSummaryViewModel: ObservableObject {
    
    enum Status {
        case enabled
        case disabled
        case mixture
    }
    
    private var piholes: [Pihole]
    private var selectedPihole: Pihole?
    
    private var summaryProvider: SummaryDataProvider?
    private var monitorProvider: MonitorDataProvider?
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var summaryDisplay: SummaryDisplay?
    @Published var summaryError: String?
    
    @Published var monitorDisplay: MonitorDisplay?
    @Published var monitorError: String?
    
    var status: SummaryDisplay.PiholeStatus {
        summaryDisplay?.status ?? .allDisabled
    }

    private var providers: [DataProvider?] {
        [summaryProvider, monitorProvider]
    }
    
    init(_ piholes: [Pihole]) {
        self.piholes = piholes
        setupProviders()
    }
    
    func startPolling() {
        providers.forEach { $0?.startPolling() }
    }
    
    func stopPolling() {
        providers.forEach { $0?.stopPolling() }
    }
    
    func selectAppPiholes() {
        selectedPihole = nil
    }
    
    func select(_ pihole: Pihole) {
        selectedPihole = pihole
    }
    
    private func setupProviders() {
        stopPolling()
        cancellables.removeAll()
        
        let piholes = selectedPihole != nil ? [selectedPihole!] : piholes
        summaryProvider = SummaryDataProvider(piholes: piholes)
        monitorProvider = MonitorDataProvider(pihole: piholes.first!, temperatureScale: .celcius)
        
        summaryProvider?.$summaryDisplay.sink(receiveValue: { value in
            self.summaryDisplay = value
        }).store(in: &cancellables)
        
        summaryProvider?.$error.sink(receiveValue: { value in
            self.summaryError = value
        }).store(in: &cancellables)
        
        monitorProvider?.$monitorDisplay.sink(receiveValue: { value in
            self.monitorDisplay = value
        }).store(in: &cancellables)
        
        monitorProvider?.$error.sink(receiveValue: { value in
            self.monitorError = value
        }).store(in: &cancellables)
    }
}
