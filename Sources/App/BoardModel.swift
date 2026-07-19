import SwiftUI
import EventKit
import WidgetKit

/// Drives the board window: loads meetings, tracks which one is shown, keeps the
/// widget cache fresh, and reacts to calendar changes + a ticking clock.
@MainActor
final class BoardModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var index = 0
    @Published var authorized = CalendarService.shared.isAuthorized

    private var timer: Timer?

    init() {
        FlapClicker.shared.enabled = SharedConfig.soundEnabled
        NotificationCenter.default.addObserver(
            self, selector: #selector(calendarChanged),
            name: .EKEventStoreChanged, object: nil
        )
        startTicking()
    }

    var current: Meeting? { meetings.indices.contains(index) ? meetings[index] : nil }
    var canPrev: Bool { index > 0 }
    var canNext: Bool { index < meetings.count - 1 }

    /// What the menu-bar item shows, e.g. "6m · Standup".
    var menuBarLabel: String {
        guard authorized else { return "VestBoard" }
        guard let m = current else { return "No meetings" }
        let title = String(m.title.prefix(16))
        return m.isNow ? "NOW · \(title)" : "\(m.shortCountdown) · \(title)"
    }

    /// Text rendered as animated flaps in the menu bar, e.g. "6M STANDUP".
    var menuFlapText: String {
        guard authorized else { return "VESTBOARD" }
        guard let m = current else { return "NO MEETINGS" }
        return "\(m.isNow ? "NOW" : m.shortCountdown) \(m.title)"
    }

    func requestAccess() async {
        // Use the grant result directly — authorizationStatus can lag right after
        // the prompt, which would leave us stuck on the permission screen.
        authorized = await CalendarService.shared.requestAccess()
        reload()
    }

    func reload() {
        guard authorized else { return }
        let fresh = CalendarService.shared.upcomingMeetings()
        meetings = fresh
        if index >= fresh.count { index = max(0, fresh.count - 1) }
        SharedConfig.saveMeetings(fresh)          // hand the widget fresh data
        WidgetCenter.shared.reloadAllTimelines()
    }

    func next() { if canNext { withAnimation { index += 1 } } }
    func prev() { if canPrev { withAnimation { index -= 1 } } }

    /// Open the meeting link in the user's existing browser session, new tab.
    func join(_ meeting: Meeting) {
        guard let url = meeting.joinURL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func calendarChanged() { reload() }

    /// Re-render once a minute so countdowns stay honest and past meetings drop.
    private func startTicking() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }
}
