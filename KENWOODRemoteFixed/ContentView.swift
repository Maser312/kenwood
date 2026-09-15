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
                        LabeledContent("Название", value: kenwood.accessoryName)
                        LabeledContent("Протоколов", value: "\(kenwood.protocols.count)")
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

                Section("Как подключить") {
                    Text("1. На KMM-305BT открой Remote App → iOS → YES.")
                    Text("2. Выбери источник iPod BT.")
                    Text("3. Запусти приложение и нажми «Проверить подключение».")
                }
            }
            .navigationTitle("KENWOOD Remote")
        }
        .onAppear {
            kenwood.start()
        }
    }
}
