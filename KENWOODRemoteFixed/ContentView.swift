import SwiftUI

struct ContentView: View {
    @StateObject private var kenwood = KenwoodSession.shared

    var body: some View {
        NavigationView {
            List {
                Section("Состояние") {
                    HStack {
                        Circle()
                            .fill(kenwood.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(kenwood.isConnected ? "Подключено" : "Не подключено")
                    }
                    Text(kenwood.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                if !kenwood.accessoryName.isEmpty {
                    Section("Магнитола") {
                        HStack {
                            Text("Название")
                            Spacer()
                            Text(kenwood.accessoryName)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Протоколов")
                            Spacer()
                            Text("\(kenwood.protocols.count)")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section("iAP-протоколы") {
                        ForEach(kenwood.protocols, id: \.self) { proto in
                            Text(proto)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                }

                Section {
                    Button("Проверить подключение") {
                        kenwood.start()
                    }
                    Button("Отключить") {
                        kenwood.stop()
                    }
                }

                Section("Подключение KMM-BT305") {
                    Text("1. На магнитоле: Remote App → SELECT → IOS → YES.")
                    Text("2. Выбери источник iPod BT. Для USB используй iPod USB.")
                    Text("3. Запусти приложение. Соединение устанавливается автоматически.")
                }
            }
            .navigationTitle("KENWOOD Remote")
        }
        .onAppear {
            kenwood.start()
        }
    }
}
