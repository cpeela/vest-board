import Foundation

/// Config + cached meetings shared between the app and the widget via App Group.
///
/// The widget extension can't show a permission prompt, so the *app* is the only
/// EventKit reader: it fetches meetings and writes them here; the widget reads the
/// cache. Keep the app (your board) running to keep the widget fresh.
enum SharedConfig {
    static let appGroup = "group.com.lendapi.vestboard"

    private static var store: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private static let selectedKey = "selectedCalendarIDs"
    private static let cacheKey = "cachedMeetings"

    /// Calendar identifiers the user chose to show (e.g. the LendAPI work calendar).
    /// Empty = all calendars.
    static var selectedCalendarIDs: [String] {
        get { store.stringArray(forKey: selectedKey) ?? [] }
        set { store.set(newValue, forKey: selectedKey) }
    }

    private static let soundKey = "soundEnabled"
    static var soundEnabled: Bool {
        get { store.object(forKey: soundKey) as? Bool ?? true }
        set { store.set(newValue, forKey: soundKey) }
    }

    static func saveMeetings(_ meetings: [Meeting]) {
        guard let data = try? JSONEncoder().encode(meetings) else { return }
        store.set(data, forKey: cacheKey)
    }

    static func loadMeetings() -> [Meeting] {
        guard let data = store.data(forKey: cacheKey),
              let meetings = try? JSONDecoder().decode([Meeting].self, from: data)
        else { return [] }
        // Drop anything already over.
        return meetings.filter { $0.end > Date() }
    }
}
