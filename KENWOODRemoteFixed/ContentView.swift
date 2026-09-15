import SwiftUI

struct ContentView: View {
    @State private var status = "Запуск…"
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "car.fill").font(.system(size: 52))
            Text("KENWOOD Remote").font(.title2.bold())
            Text(status).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("Проверить подключение") {
                KenwoodSession.shared.start()
                status = KenwoodSession.shared.lastError
            }.buttonStyle(.borderedProminent)
            Text("На магнитоле: Remote App → iOS → YES, затем источник iPod BT.")
                .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }.padding().onAppear {
            KenwoodSession.shared.start(); status = KenwoodSession.shared.lastError
        }
    }
}
