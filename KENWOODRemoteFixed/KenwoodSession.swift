import Foundation
import ExternalAccessory

final class KenwoodSession: NSObject, StreamDelegate {
    static let shared = KenwoodSession()

    private let supportedProtocols = [
        "com.jvckenwood.jkts.kwdremoteapp.comm.v1",
        "com.jvckenwood.jkts.kwdremoteapp.BT",
        "com.jvckenwood.jkts.kwdremoteapp.USB",
        "com.jvckenwood.jkts.kwdremoteapp.WIFI",
        "com.jvckenwood.jkts.kwdremoteapp.COMM1",
        "com.jvckenwood.jkts.kwdremoteapp.COMM2",
        "com.jvckenwood.jkts.kwdremoteapp.COMM3"
    ]

    private var session: EASession?
    private var retryWork: DispatchWorkItem?
    private var observersRegistered = false
    private(set) var lastError = ""

    func start() {
        let manager = EAAccessoryManager.shared()

        if !observersRegistered {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(accessoryConnected(_:)),
                name: .EAAccessoryDidConnect,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(accessoryDisconnected(_:)),
                name: .EAAccessoryDidDisconnect,
                object: nil
            )
            manager.registerForLocalNotifications()
            observersRegistered = true
        }

        connectToAvailableAccessory()
    }

    func stop() {
        retryWork?.cancel()
        retryWork = nil
        closeSession()
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

        let candidates = supportedProtocols.filter {
            accessory.protocolStrings.contains($0)
        }

        if candidates.isEmpty {
            lastError = "KENWOOD найден, ждём готовности протокола…"
            scheduleRetry(for: accessory, attempt: attempt)
            return
        }

        for proto in candidates {
            guard let newSession = EASession(accessory: accessory, forProtocol: proto) else {
                continue
            }

            session = newSession
            newSession.inputStream?.delegate = self
            newSession.outputStream?.delegate = self

            if let input = newSession.inputStream {
                input.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
                input.open()
            }

            if let output = newSession.outputStream {
                output.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
                output.open()
            }

            lastError = "Подключено"
            return
        }

        lastError = "EASession пока недоступен, повторяем…"
        scheduleRetry(for: accessory, attempt: attempt)
    }

    private func scheduleRetry(for accessory: EAAccessory, attempt: Int) {
        guard attempt < 20 else {
            lastError = "Не удалось открыть соединение KENWOOD."
            return
        }

        retryWork?.cancel()

        let delay = min(5.0, 0.5 + Double(attempt) * 0.25)
        let work = DispatchWorkItem { [weak self, weak accessory] in
            guard let self, let accessory else { return }
            self.attemptSession(accessory, attempt: attempt + 1)
        }

        retryWork = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay,
            execute: work
        )
    }

    private func closeSession() {
        if let current = session {
            current.inputStream?.close()
            current.outputStream?.close()
            current.inputStream?.remove(from: RunLoop.main, forMode: RunLoop.Mode.default)
            current.outputStream?.remove(from: RunLoop.main, forMode: RunLoop.Mode.default)
            current.close()
        }
        session = nil
    }

    @objc private func accessoryConnected(_ notification: Notification) {
        connectToAvailableAccessory()
    }

    @objc private func accessoryDisconnected(_ notification: Notification) {
        closeSession()
        lastError = "KENWOOD отключён"
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .errorOccurred:
            closeSession()
            lastError = "Ошибка соединения с KENWOOD"
        case .endEncountered:
            closeSession()
            lastError = "Соединение с KENWOOD закрыто"
        default:
            break
        }
    }
}
