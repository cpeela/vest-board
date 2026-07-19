import WidgetKit
import SwiftUI

// MARK: - Timeline

struct BoardEntry: TimelineEntry {
    let date: Date
    let meeting: Meeting?
}

/// Reads the cache the app writes (widgets can't prompt for Calendar access).
/// Rebuilds the timeline at each meeting boundary so "next meeting" rolls over.
struct BoardProvider: TimelineProvider {
    func placeholder(in context: Context) -> BoardEntry {
        BoardEntry(date: Date(), meeting: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BoardEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BoardEntry>) -> Void) {
        let meetings = Self.currentMeetings()
        let now = Date()

        // A snapshot now, plus one at each upcoming start/end so the board updates
        // exactly when a meeting begins or ends.
        var boundaries = Set<Date>([now])
        for m in meetings {
            if m.start > now { boundaries.insert(m.start) }
            if m.end > now { boundaries.insert(m.end) }
        }
        let entries = boundaries.sorted().prefix(24).map { entry(at: $0, in: meetings) }

        // Refresh again ~30 min out (or sooner) as a safety net.
        let refresh = (boundaries.filter { $0 > now }.min()) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: entries, policy: .after(min(refresh, now.addingTimeInterval(1800)))))
    }

    private func entry(at date: Date, in meetings: [Meeting]? = nil) -> BoardEntry {
        let list = meetings ?? Self.currentMeetings()
        let next = list.first { $0.end > date }
        return BoardEntry(date: date, meeting: next)
    }

    /// Free-team path: read EventKit directly (no App Group). Falls back to the
    /// shared cache if the widget itself isn't calendar-authorized.
    private static func currentMeetings() -> [Meeting] {
        let live = CalendarService.shared.upcomingMeetings(limit: 8, hoursAhead: 24)
        return live.isEmpty ? SharedConfig.loadMeetings() : live
    }
}

// MARK: - View

struct VestBoardWidgetEntryView: View {
    var entry: BoardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let m = entry.meeting {
                HStack {
                    Text(m.countdown)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(m.isNow ? Theme.accent : Theme.dim)
                    Spacer()
                    Circle().fill(Color(hex: m.colorHex) ?? .white).frame(width: 8, height: 8)
                }
                // Static split-flap snapshot (no live flipping inside a widget).
                SplitFlapText(text: m.title, columns: 16, cell: 20, spacing: 2, animated: false)
                HStack {
                    Text(m.clockRange)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.dim)
                    Spacer()
                    if let url = m.joinURL {
                        Link(destination: url) {
                            Label("JOIN", systemImage: "video.fill")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            } else {
                Spacer()
                SplitFlapText(text: "NO MEETINGS", columns: 12, cell: 20, spacing: 2, animated: false)
                Spacer()
            }
        }
        .padding(14)
        .containerBackground(Theme.board, for: .widget)
        .widgetURL(URL(string: "vestboard://open"))
    }
}

// MARK: - Widget

struct VestBoardWidget: Widget {
    let kind = "VestBoardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BoardProvider()) { entry in
            VestBoardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VestBoard")
        .description("Your next meeting on a split-flap board.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct VestBoardWidgetBundle: WidgetBundle {
    var body: some Widget {
        VestBoardWidget()
    }
}
