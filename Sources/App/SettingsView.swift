import SwiftUI
import WidgetKit
import EventKit

/// Pick which calendars feed the board. Empty selection = all calendars.
/// Point this at your LendAPI work calendar.
struct SettingsView: View {
    @State private var calendars = CalendarService.shared.availableCalendars()
    @State private var selected = Set(SharedConfig.selectedCalendarIDs)
    @State private var soundOn = SharedConfig.soundEnabled

    var body: some View {
        Form {
            Section("Board") {
                Toggle("Flap sound", isOn: $soundOn)
                    .onChange(of: soundOn) { _, on in
                        SharedConfig.soundEnabled = on
                        FlapClicker.shared.enabled = on
                    }
            }
            Section("Calendars to show") {
                if calendars.isEmpty {
                    Text("Grant calendar access in the main window first.")
                        .foregroundStyle(.secondary)
                }
                ForEach(calendars, id: \.calendarIdentifier) { cal in
                    Toggle(isOn: binding(for: cal.calendarIdentifier)) {
                        HStack {
                            Circle()
                                .fill(Color(cgColor: cal.cgColor ?? .white))
                                .frame(width: 10, height: 10)
                            Text(cal.title)
                            if let src = cal.source?.title {
                                Text(src).foregroundStyle(.secondary).font(.caption)
                            }
                        }
                    }
                }
            }
            Text("Leave all off to show every calendar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 360)
        .onDisappear(perform: persist)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { selected.contains(id) },
            set: { on in
                if on { selected.insert(id) } else { selected.remove(id) }
                persist()
            }
        )
    }

    private func persist() {
        SharedConfig.selectedCalendarIDs = Array(selected)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
