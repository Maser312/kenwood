import Foundation
import ExternalAccessory

final class KenwoodSession: NSObject, StreamDelegate {
    static let shared = KenwoodSession()
    private let protocols = [
        "com.jvckenwood.jkts.kwdremoteapp.comm.v1",
        "com.jvckenwood.jkts.kwdremoteapp.BT",
        "com.jvckenwood.jkts.kwdremoteapp.USB",
        "com.jvckenwood.jkts.kwdremoteapp.COMM1",
        "com.jvckenwood.jkts.kwdremoteapp.COMM2",
        "com.jvckenwood.jkts.kwdremoteapp.COMM3",
        "com.jvckenwood.jkts.kwdremoteapp.WIFI"
    ]
    private var session: EASession?
    private var retryWork: DispatchWorkItem?
    private(set) var lastError = ""

    func start() {
        let manager = EAAccessoryManager.shared()
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected(_:)), name: .EAAccessoryDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected(_:)), name: .EAAccessoryDidDisconnect, object: nil)
        manager.registerForLocalNotifications()
        connectToAvailableAccessory()
    }

    func stop() {
        retryWork?.cancel(); session?.close(); session = nil
        EAAccessoryManager.shared().unregisterForLocalNotifications()
    }

    private func connectToAvailableAccessory() {
        guard session == nil else { return }
        guard let accessory = EAAccessoryManager.shared().connectedAccessories.first else {
            lastError = "KENWOOD не найден. Запусти iPod BT на магнитоле."
            return
        }
        attemptSession(accessory, attempt: 0)
    }

    private func attemptSession(_ accessory: EAAccessory, attempt: Int) {
        guard session == nil else { return }
        let candidates = protocols.filter { accessory.protocolStrings.contains($0) }
        guard !candidates.isEmpty else { lastError = "KENWOOD найден, ждём готовности протокола…"; scheduleRetry(accessory, attempt: attempt); return }
        for proto in candidates {
            if let s = EASession(accessory: accessory, forProtocol: proto) {
                session = s
                s.inputStream?.delegate = self; s.outputStream?.delegate = self
                if let input = s.inputStream { input.schedule(in: .main, forMode: .default); input.open() }
                if let output = s.outputStream { output.schedule(in: .main, forMode: .default); output.open() }
                lastError = "Подключено"
                return
            }
        }
        lastError = "Ожидаем готовность EASession…"
        scheduleRetry(accessory, attempt: attempt)
    }

    private func scheduleRetry(_ accessory: EAAccessory, attempt: Int) {
        guard attempt < 20 else { return }
        retryWork?.cancel()
        let delay = min(5.0, 0.25 * pow(1.35, Double(attempt)))
        let work = DispatchWorkItem { [weak self] in self?.attemptSession(accessory, attempt: attempt + 1) }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    @objc private func accessoryConnected(_ notification: Notification) { connectToAvailableAccessory() }
    @objc private func accessoryDisconnected(_ notification: Notification) { session?.close(); session = nil; lastError = "KENWOOD отключён" }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if eventCode == .errorOccurred || eventCode == .endEncountered { session?.close(); session = nil }
    }
}
