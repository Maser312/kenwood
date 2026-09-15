import Foundation
import Combine
import ExternalAccessory

final class KenwoodSession: NSObject, StreamDelegate, ObservableObject {
    static let shared = KenwoodSession()

    @Published private(set) var status = "Не подключено"
    @Published private(set) var accessoryName = ""
    @Published private(set) var protocols = [String]()
    @Published private(set) var isConnected = false

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

    func start() {
        let manager = EAAccessoryManager.shared()
        if !observersRegistered {
            NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected(_:)), name: .EAAccessoryDidConnect, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected(_:)), name: .EAAccessoryDidDisconnect, object: nil)
            manager.registerForLocalNotifications()
            observersRegistered = true
        }
        connectToAvailableAccessory()
    }

    func stop() {
        retryWork?.cancel()
        retryWork = nil
        closeSession()
        status = "Отключено"
    }

    private func connectToAvailableAccessory() {
        guard session == nil else { return }
        guard let accessory = EAAccessoryManager.shared().connectedAccessories.first else {
            accessoryName = ""
            protocols = []
            isConnected = false
            status = "KENWOOD не найден. На магнитоле включи Remote App → iOS → YES и iPod BT."
            return
        }
        accessoryName = accessory.name
        protocols = accessory.protocolStrings
        isConnected = false
        status = "KENWOOD найден: \(accessory.name). Открываем канал…"
        attemptSession(accessory, attempt: 0)
    }

    private func attemptSession(_ accessory: EAAccessory, attempt: Int) {
        guard session == nil else { return }
        let candidates = supportedProtocols.filter { accessory.protocolStrings.contains($0) }
        if candidates.isEmpty {
            status = "KENWOOD найден, но iAP-протокол ещё не готов. Повторяем…"
            scheduleRetry(for: accessory, attempt: attempt)
            return
        }
        for proto in candidates {
            guard let newSession = EASession(accessory: accessory, forProtocol: proto) else { continue }
            session = newSession
            newSession.inputStream?.delegate = self
            newSession.outputStream?.delegate = self
            if let input = newSession.inputStream {
                input.schedule(in: RunLoop.main, forMode: .default)
                input.open()
            }
            if let output = newSession.outputStream {
                output.schedule(in: RunLoop.main, forMode: .default)
                output.open()
            }
            isConnected = true
            status = "Подключено по \(proto)"
            return
        }
        status = "KENWOOD найден, EASession пока недоступен. Повторяем…"
        scheduleRetry(for: accessory, attempt: attempt)
    }

    private func scheduleRetry(for accessory: EAAccessory, attempt: Int) {
        guard attempt < 30 else {
            isConnected = false
            status = "Не удалось открыть EASession. Перезапусти Remote App на магнитоле."
            return
        }
        retryWork?.cancel()
        let delay = min(5.0, 0.5 + Double(attempt) * 0.25)
        let work = DispatchWorkItem { [weak self] in
            self?.attemptSession(accessory, attempt: attempt + 1)
        }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func closeSession() {
        if let current = session {
            current.inputStream?.close()
            current.outputStream?.close()
            current.inputStream?.remove(from: .main, forMode: .default)
            current.outputStream?.remove(from: .main, forMode: .default)
        }
        session = nil
        isConnected = false
    }

    @objc private func accessoryConnected(_ notification: Notification) { connectToAvailableAccessory() }

    @objc private func accessoryDisconnected(_ notification: Notification) {
        closeSession()
        accessoryName = ""
        protocols = []
        status = "KENWOOD отключён"
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if session != nil { isConnected = true }
        case .errorOccurred:
            closeSession()
            status = "Ошибка потока KENWOOD — повторяем подключение…"
            connectToAvailableAccessory()
        case .endEncountered:
            closeSession()
            status = "Соединение закрыто — повторяем подключение…"
            connectToAvailableAccessory()
        default:
            break
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
