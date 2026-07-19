import EventKit
import AppKit

/// EventKit access. Only the app instantiates this (the widget reads the cache).
final class CalendarService {
    static let shared = CalendarService()
    let store = EKEventStore()

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    var status: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        let before = status
        do {
            let granted = try await store.requestFullAccessToEvents()
            NSLog("VB: requestAccess before=\(before.rawValue) granted=\(granted) after=\(status.rawValue)")
            return granted
        } catch {
            NSLog("VB: requestAccess error=\(error.localizedDescription)")
            return false
        }
    }

    /// All event calendars, for the settings picker.
    func availableCalendars() -> [EKCalendar] {
        store.calendars(for: .event).sorted { $0.title < $1.title }
    }

    /// Upcoming, timed (non all-day) meetings within `hoursAhead`, soonest first.
    /// No auth guard: if access isn't granted, EventKit simply returns no events —
    /// and querying works immediately after a grant even while status still lags.
    func upcomingMeetings(limit: Int = 12, hoursAhead: Double = 24) -> [Meeting] {
        let selected = SharedConfig.selectedCalendarIDs
        let cals = selected.isEmpty
            ? nil
            : store.calendars(for: .event).filter { selected.contains($0.calendarIdentifier) }

        let now = Date()
        let predicate = store.predicateForEvents(
            withStart: now,
            end: now.addingTimeInterval(hoursAhead * 3600),
            calendars: cals
        )
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.endDate > now && $0.status != .canceled }
            .sorted { $0.startDate < $1.startDate }
            .prefix(limit)
            .map(Self.makeMeeting)
    }

    // MARK: - Mapping

    private static func makeMeeting(_ e: EKEvent) -> Meeting {
        Meeting(
            id: e.eventIdentifier ?? UUID().uuidString,
            title: e.title ?? "Untitled",
            start: e.startDate,
            end: e.endDate,
            location: e.location,
            joinURL: detectJoinURL(e),
            colorHex: hex(from: e.calendar?.cgColor)
        )
    }

    private static func hex(from cg: CGColor?) -> String {
        guard let cg, let ns = NSColor(cgColor: cg)?.usingColorSpace(.sRGB) else { return "FFFFFF" }
        let r = Int(round(ns.redComponent * 255))
        let g = Int(round(ns.greenComponent * 255))
        let b = Int(round(ns.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }

    /// Pull a Zoom/Meet/Teams/Webex link from url, location, or notes.
    private static func detectJoinURL(_ e: EKEvent) -> URL? {
        if let u = e.url, isMeetingURL(u) { return u }
        let blob = [e.location, e.notes].compactMap { $0 }.joined(separator: "\n")
        guard !blob.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return nil }
        let range = NSRange(blob.startIndex..., in: blob)
        for match in detector.matches(in: blob, range: range) {
            if let u = match.url, isMeetingURL(u) { return u }
        }
        return nil
    }

    private static func isMeetingURL(_ u: URL) -> Bool {
        let host = (u.host ?? "").lowercased()
        return ["zoom.us", "meet.google.com", "teams.microsoft.com",
                "teams.live.com", "webex.com", "whereby.com"].contains { host.contains($0) }
    }
}
