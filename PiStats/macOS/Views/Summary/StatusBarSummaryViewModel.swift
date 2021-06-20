import Foundation
import PiStatsCore
import Combine

class StatusBarSummaryViewModel: ObservableObject {

    enum Status {
        case enabled
        case disabled
        case mixture
    }

    struct PiholeSelectionOption: Identifiable, Hashable {
        internal init(pihole: Pihole? = nil) {
            self.pihole = pihole
            if let pihole = pihole {
                id = pihole.id
                name = pihole.displayName ?? pihole.address
            } else {
                id = UUID()
                name = "All"
            }
        }

        var name: String
        let pihole: Pihole?
        let id: UUID
    }

    private var piholes: [Pihole]
    private var summaryProvider: SummaryDataProvider?
    private var monitorProvider: MonitorDataProvider?
    private var cancellables = Set<AnyCancellable>()
    private (set) var piholeSelectionOptions: [PiholeSelectionOption]

    @Published var summaryDisplay: SummaryDisplay?
    @Published var summaryError: String?
    @Published var monitorDisplay: MonitorDisplay?
    @Published var monitorError: String?
    @Published var hasMonitorEnabed = false

    var status: SummaryDisplay.PiholeStatus {
        summaryDisplay?.status ?? .allDisabled
    }

    var hasMultiplePiholes: Bool {
        piholes.count > 1
    }
    
    private var providers: [DataProvider?] {
        [summaryProvider, monitorProvider]
    }
    
    @Published var selectedOption: PiholeSelectionOption {
        didSet {
            setupProviders()
        }
    }
    
    init(_ piholes: [Pihole]) {
        var options = [PiholeSelectionOption()]
        options.append(contentsOf: piholes.map { PiholeSelectionOption(pihole: $0) })
        piholeSelectionOptions = options
        selectedOption = options.first!
     
        self.piholes = piholes
        setupProviders()
    }
    
    func startPolling() {
        providers.forEach { $0?.startPolling() }
    }
    
    func stopPolling() {
        providers.forEach { $0?.stopPolling() }
    }
    
    private func setupProviders() {
        stopPolling()
        cancellables.removeAll()
        
        let piholes = selectedOption.pihole != nil ? [selectedOption.pihole!] : piholes
        summaryProvider = SummaryDataProvider(piholes: piholes)
        
        if let pihole = selectedOption.pihole, pihole.hasPiMonitor {
            monitorProvider = MonitorDataProvider(pihole: pihole, temperatureScale: .celcius)
            
            monitorProvider?.$monitorDisplay.sink(receiveValue: { value in
                self.monitorDisplay = value
            }).store(in: &cancellables)
            
            monitorProvider?.$error.sink(receiveValue: { value in
                self.monitorError = value
            }).store(in: &cancellables)
            
            hasMonitorEnabed = true
        } else {
            monitorProvider = nil
            monitorDisplay = nil
            monitorError = nil
            hasMonitorEnabed = false
        }
        
        summaryProvider?.$summaryDisplay.sink(receiveValue: { value in
            self.summaryDisplay = value
        }).store(in: &cancellables)
        
        summaryProvider?.$error.sink(receiveValue: { value in
            self.summaryError = value
        }).store(in: &cancellables)
 
        startPolling()
    }
}
