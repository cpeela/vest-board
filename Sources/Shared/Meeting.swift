import Foundation

/// A calendar event trimmed down to what the board renders.
/// Codable so the app can cache it in the App Group for the widget to read.
struct Meeting: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let location: String?
    let joinURL: URL?
    let colorHex: String

    var isNow: Bool {
        let now = Date()
        return now >= start && now < end
    }

    /// "NOW", "IN 8 MIN", "IN 2H 15M", or a clock time if far out.
    var countdown: String {
        if isNow { return "NOW" }
        let mins = Int(start.timeIntervalSinceNow / 60)
        if mins < 1 { return "STARTING" }
        if mins < 60 { return "IN \(mins) MIN" }
        let h = mins / 60, m = mins % 60
        return m == 0 ? "IN \(h) HR" : "IN \(h)H \(m)M"
    }

    var clockRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))".uppercased()
    }

    /// Terse countdown for the menu bar, e.g. "NOW", "8m", "2h15m".
    var shortCountdown: String {
        if isNow { return "NOW" }
        let mins = Int(start.timeIntervalSinceNow / 60)
        if mins < 1 { return "now" }
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h\(m)m"
    }

    var shortTitle: String { String(title.prefix(20)) }

    /// Compact form that fits a 22-flap row, e.g. "10:30A-11:00A".
    var compactRange: String {
        let t = DateFormatter(); t.dateFormat = "h:mm"
        let p = DateFormatter(); p.dateFormat = "a"
        func ampm(_ d: Date) -> String { String(p.string(from: d).uppercased().prefix(1)) }
        return "\(t.string(from: start))\(ampm(start))-\(t.string(from: end))\(ampm(end))"
    }
}
