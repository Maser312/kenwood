import SwiftUI

struct ContentView: View {
    @StateObject private var kenwood = KenwoodSession.shared
    @State private var mode: RemoteMode = .passenger
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                connectionBar
                Picker("Режим", selection: $mode) {
                    ForEach(RemoteMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    if mode == .driver {
                        DriverRemoteView()
                    } else {
                        PassengerRemoteView()
                    }
                }
            }
            .navigationTitle("KENWOOD Remote")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) {
                ReceiverSettingsView()
            }
        }
        .onAppear { kenwood.start() }
    }

    private var connectionBar: some View {
        HStack(spacing: 8) {
            Circle().fill(kenwood.isConnected ? Color.green : Color.red).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(kenwood.isConnected ? "Подключено" : "Не подключено").font(.headline)
                Text(kenwood.accessoryName.isEmpty ? kenwood.status : kenwood.accessoryName)
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Button("Повтор") { kenwood.start() }.font(.caption)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

enum RemoteMode: String, CaseIterable, Identifiable {
    case driver, passenger
    var id: String { rawValue }
    var title: String { self == .driver ? "Водитель" : "Пассажир" }
}

struct DriverRemoteView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Управление жестами").font(.headline)
            Text("Проводите пальцем по панели для навигации и управления громкостью.")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
            RoundedRectangle(cornerRadius: 24).strokeBorder(lineWidth: 2)
                .frame(height: 280)
                .overlay(Text("Жестовая панель").foregroundColor(.secondary))
            TransportButtons()
        }.padding()
    }
}

struct PassengerRemoteView: View {
    let sources = ["Радио", "iPod", "USB", "Bluetooth"]
    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                RemoteButton("−", system: "speaker.wave.1")
                Text("ГРОМКОСТЬ").font(.caption).frame(maxWidth: .infinity)
                RemoteButton("+", system: "speaker.wave.3")
            }
            HStack(spacing: 12) {
                RemoteButton("◀", system: "backward.end.fill")
                RemoteButton("▶", system: "play.fill")
                RemoteButton("▶|", system: "forward.end.fill")
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(sources, id: \.self) { source in
                    Button(source) { }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(12)
                }
            }
            Divider().padding(.vertical, 6)
            Text("Настройки ресивера").font(.headline)
            SettingsGrid()
        }.padding()
    }
}

struct TransportButtons: View {
    var body: some View {
        HStack(spacing: 14) {
            RemoteButton("◀", system: "backward.end.fill")
            RemoteButton("▶", system: "play.fill")
            RemoteButton("▶|", system: "forward.end.fill")
        }
    }
}

struct RemoteButton: View {
    let title: String
    let system: String
    init(_ title: String, system: String) { self.title = title; self.system = system }
    var body: some View {
        Button { } label: {
            VStack(spacing: 4) { Image(systemName: system); Text(title).font(.caption) }
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Color.secondary.opacity(0.12)).cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsGrid: View {
    private let items = ["EQ", "Fader / Balance", "Time Alignment", "Sound Effect", "Car Setting", "Speaker Setting", "Subwoofer", "Crossover", "Подсветка"]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.self) { item in
                NavigationLink(destination: SettingPlaceholder(title: item)) {
                    Text(item).frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct ReceiverSettingsView: View {
    var body: some View {
        NavigationView { List { Section("Режим управления") { Text("Водитель — жесты"); Text("Пассажир — кнопки") }; Section("Ресивер") { Text("KMM-BT305"); Text("iPod BT / iPod USB") } }.navigationTitle("Настройки") }
    }
}

struct SettingPlaceholder: View {
    let title: String
    var body: some View {
        Form {
            Section(title) {
                Text("Экран настройки подготовлен под оригинальную KENWOOD Remote.")
                    .foregroundColor(.secondary)
                Text("Команды ресиверу будут привязаны к iAP-каналу после определения протокола.")
                    .foregroundColor(.secondary)
            }
        }.navigationTitle(title)
    }
}
