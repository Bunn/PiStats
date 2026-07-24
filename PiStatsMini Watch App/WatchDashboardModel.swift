import Foundation
import Observation
import PiStatsCore
@preconcurrency import WatchConnectivity

@MainActor
@Observable
final class WatchDashboardModel: NSObject {
    static let initialSyncMessage =
        "Open Pi Stats on your iPhone to fetch your Pi-hole settings."

    private(set) var piholes: [WatchPiholeModel]
    private(set) var syncMessage: String?
    private(set) var isSyncing = false
    private(set) var isPerformingBulkAction = false
    private(set) var bulkActionCompletionID = 0

    @ObservationIgnored
    private let configurationStore: WatchConfigurationStore

    @ObservationIgnored
    private let session: WCSession?

    override convenience init() {
        self.init(
            configurationStore: WatchConfigurationStore(),
            session: WCSession.isSupported() ? .default : nil
        )
    }

    init(
        configurationStore: WatchConfigurationStore,
        session: WCSession?
    ) {
        self.configurationStore = configurationStore
        self.session = session
        piholes = configurationStore.load()
            .sorted(by: Self.configurationSort)
            .map { WatchPiholeModel(pihole: $0) }
        super.init()
    }

    init(piholes: [WatchPiholeModel]) {
        configurationStore = WatchConfigurationStore()
        session = nil
        self.piholes = piholes
        super.init()
    }

    var connectedPiholeCount: Int {
        piholes.count { $0.status != .unknown }
    }

    var emptyStateMessage: String {
        syncMessage ?? Self.initialSyncMessage
    }

    var shouldResumeAll: Bool {
        let connectedPiholes = piholes.filter { $0.status != .unknown }
        return !connectedPiholes.isEmpty
            && connectedPiholes.allSatisfy { $0.status == .disabled }
    }

    func startConnectivity() {
        guard let session else {
            if piholes.isEmpty {
                syncMessage = Self.initialSyncMessage
            }
            return
        }

        session.delegate = self
        if session.activationState == .notActivated {
            isSyncing = true
            session.activate()
        } else {
            acceptApplicationContext(session.receivedApplicationContext)
            requestConfigurations()
        }
    }

    func requestConfigurations() {
        guard let session else { return }
        guard session.activationState == .activated else {
            startConnectivity()
            return
        }

        guard session.isReachable else {
            isSyncing = false
            if piholes.isEmpty {
                syncMessage = Self.initialSyncMessage
            }
            return
        }

        isSyncing = true
        session.sendMessage(
            [PiholeWatchPayload.configurationRequestKey: true],
            replyHandler: { [weak self] context in
                let result = Self.decodePiholes(from: context)
                Task { @MainActor in
                    self?.acceptDecodedPiholes(result)
                }
            },
            errorHandler: { [weak self] _ in
                Task { @MainActor in
                    self?.isSyncing = false
                    if self?.piholes.isEmpty == true {
                        self?.syncMessage = Self.initialSyncMessage
                    }
                }
            }
        )
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for pihole in piholes {
                group.addTask {
                    await pihole.refresh()
                }
            }
        }
    }

    func pauseAll(timer: Int?) async {
        guard !isPerformingBulkAction else { return }
        let enabledPiholes = piholes.filter { $0.status == .enabled }
        guard !enabledPiholes.isEmpty else { return }

        isPerformingBulkAction = true
        defer {
            isPerformingBulkAction = false
            bulkActionCompletionID &+= 1
        }

        await withTaskGroup(of: Void.self) { group in
            for pihole in enabledPiholes {
                group.addTask {
                    await pihole.disable(timer: timer)
                }
            }
        }
    }

    func resumeAll() async {
        guard !isPerformingBulkAction else { return }
        let disabledPiholes = piholes.filter { $0.status == .disabled }
        guard !disabledPiholes.isEmpty else { return }

        isPerformingBulkAction = true
        defer {
            isPerformingBulkAction = false
            bulkActionCompletionID &+= 1
        }

        await withTaskGroup(of: Void.self) { group in
            for pihole in disabledPiholes {
                group.addTask {
                    await pihole.enable()
                }
            }
        }
    }

    func pihole(withID id: UUID) -> WatchPiholeModel? {
        piholes.first { $0.id == id }
    }

    private func acceptApplicationContext(_ context: [String: Any]) {
        guard !context.isEmpty else { return }
        acceptDecodedPiholes(Self.decodePiholes(from: context))
    }

    private func acceptDecodedPiholes(_ result: Result<[Pihole], any Error>) {
        isSyncing = false

        do {
            let configurations = try result.get()
            let sortedConfigurations = configurations.sorted(by: Self.configurationSort)
            let didChange = piholes.map(\.pihole) != sortedConfigurations
            try configurationStore.save(configurations)
            replacePiholes(with: sortedConfigurations)
            syncMessage = configurations.isEmpty
                ? "Add a Pi-hole in the iPhone app, then sync again."
                : nil

            if didChange {
                Task { [weak self] in
                    await self?.refreshAll()
                }
            }
        } catch {
            syncMessage = error.localizedDescription
        }
    }

    private func replacePiholes(with configurations: [Pihole]) {
        let existing = Dictionary(uniqueKeysWithValues: piholes.map { ($0.id, $0) })
        piholes = configurations
            .map { configuration in
                if let current = existing[configuration.uuid],
                   current.pihole == configuration {
                    current
                } else {
                    WatchPiholeModel(pihole: configuration)
                }
            }
    }

    private nonisolated static func decodePiholes(
        from context: [String: Any]
    ) -> Result<[Pihole], any Error> {
        do {
            guard let data = context[PiholeWatchPayload.applicationContextKey] as? Data else {
                throw CocoaError(.coderValueNotFound)
            }
            return .success(try PiholeWatchPayload.decode(data).piholes)
        } catch {
            return .failure(error)
        }
    }

    private nonisolated static func configurationSort(
        _ lhs: Pihole,
        _ rhs: Pihole
    ) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}

extension WatchDashboardModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            isSyncing = false

            if error != nil {
                if piholes.isEmpty {
                    syncMessage = Self.initialSyncMessage
                }
                return
            }

            acceptApplicationContext(session.receivedApplicationContext)
            requestConfigurations()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        let result = Self.decodePiholes(from: applicationContext)
        Task { @MainActor [weak self] in
            self?.acceptDecodedPiholes(result)
        }
    }
}
