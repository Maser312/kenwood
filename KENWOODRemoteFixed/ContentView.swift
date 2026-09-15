import SwiftUI

struct ContentView: View {
    @State private var status = "Проверяем подключение…"

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "car.fill")
                .font(.system(size: 52))

            Text("KENWOOD Remote")
                .font(.title2)

            Text(status)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Проверить подключение") {
                checkConnection()
            }
            .buttonStyle(.borderedProminent)

            Text("На магнитоле: Remote App → iOS → YES, затем источник iPod BT.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            checkConnection()
        }
    }

    private func checkConnection() {
        KenwoodSession.shared.start()
        status = KenwoodSession.shared.lastError
    }
}
