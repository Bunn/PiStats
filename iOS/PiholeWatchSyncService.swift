import Foundation
@preconcurrency import WatchConnectivity

@MainActor
final class PiholeWatchSyncService: NSObject {
    static let shared = PiholeWatchSyncService()

    private let session: WCSession?
    private let storage: PiholeStorage
    private var isStarted = false

    init(
        session: WCSession? = WCSession.isSupported() ? .default : nil,
        storage: PiholeStorage = piholeStorage
    ) {
        self.session = session
        self.storage = storage
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configurationDidChange),
            name: .piholeConfigurationDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        guard !isStarted, let session else { return }
        isStarted = true
        session.delegate = self
        session.activate()
    }

    func syncConfigurations() {
        guard let session, session.activationState == .activated else { return }

        do {
            let payload = PiholeWatchPayload(piholes: storage.restoreAllPiholes())
            try session.updateApplicationContext([
                PiholeWatchPayload.applicationContextKey: payload.encoded()
            ])
        } catch {
            // WatchConnectivity retains the previous valid context. The next
            // activation or configuration change retries the update.
        }
    }

    @objc
    private func configurationDidChange() {
        syncConfigurations()
    }
}

extension PiholeWatchSyncService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        guard activationState == .activated, error == nil else { return }
        Task { @MainActor [weak self] in
            self?.syncConfigurations()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[PiholeWatchPayload.configurationRequestKey] as? Bool == true else {
            replyHandler([:])
            return
        }

        replyHandler(session.applicationContext)
    }
}
