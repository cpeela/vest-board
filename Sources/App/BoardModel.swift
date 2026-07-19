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

    private var displayTimer: Timer?
    private var cycleTimer: Timer?
    private var ticks = 0

    init() {
        FlapClicker.shared.enabled = SharedConfig.soundEnabled
        NotificationCenter.default.addObserver(
            self, selector: #selector(calendarChanged),
            name: .EKEventStoreChanged, object: nil
        )
        startTimers()
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

    private func startTimers() {
        // Live countdown: refresh every 10s; drop ended meetings; full refetch each 60s.
        displayTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.displayTick() }
        }
        // Auto-cycle through meetings when enabled (reads the setting live).
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.cycleTick() }
        }
    }

    private func displayTick() {
        let live = meetings.filter { $0.end > Date() }
        if live.count != meetings.count {
            meetings = live
            if index >= live.count { index = max(0, live.count - 1) }
        }
        ticks += 1
        if ticks % 6 == 0 { reload() }       // full calendar refetch each ~60s
        else { objectWillChange.send() }     // recompute countdowns in place
    }

    private func cycleTick() {
        guard SharedConfig.autoCycle, meetings.count > 1 else { return }
        withAnimation { index = (index + 1) % meetings.count }
    }
}
