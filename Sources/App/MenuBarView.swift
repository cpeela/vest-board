import SwiftUI

/// The menu-bar dropdown: next meeting on mini split-flaps, a Join button, paging,
/// and quick actions. Reliable on a free team (no widget extension needed).
struct MenuBarView: View {
    @ObservedObject var model: BoardModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !model.authorized {
                unauthorized
            } else if let m = model.current {
                meeting(m)
                if model.meetings.count > 1 { upNext }
            } else {
                Text("No upcoming meetings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }

            Divider().overlay(Color.white.opacity(0.1))
            footer
        }
        .padding(16)
        .frame(width: 340)
        .background(Theme.board)
    }

    // MARK: - Sections

    private func meeting(_ m: Meeting) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(m.countdown)
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(m.isNow ? Theme.accent : color(m))
                Spacer()
                Text(m.compactRange)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.dim)
                Circle().fill(color(m)).frame(width: 8, height: 8)
            }

            SplitFlapText(text: m.title, columns: 16, cell: 17, spacing: 2)

            if let loc = m.location, !loc.isEmpty {
                Label(loc, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                if m.joinURL != nil {
                    Button { model.join(m) } label: {
                        Label("Join", systemImage: "video.fill")
                            .font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
                Spacer()
                if model.meetings.count > 1 {
                    pager("chevron.left", model.canPrev, model.prev)
                    Text("\(model.index + 1)/\(model.meetings.count)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.dim)
                    pager("chevron.right", model.canNext, model.next)
                }
            }
        }
    }

    private var upNext: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UP NEXT")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.dim)
            ForEach(Array(model.meetings.enumerated().dropFirst(model.index + 1).prefix(3)), id: \.element.id) { _, m in
                Button { select(m) } label: {
                    HStack(spacing: 8) {
                        Circle().fill(color(m)).frame(width: 6, height: 6)
                        Text(m.shortCountdown)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.dim)
                            .frame(width: 42, alignment: .leading)
                        Text(m.title)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.flapText)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private var unauthorized: some View {
        VStack(spacing: 8) {
            Text("Calendar access needed")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.flapText)
            Button("Open VestBoard") { openBoard() }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Button("Open Board") { openBoard() }
            Spacer()
            SettingsLink { Text("Settings") }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .font(.system(size: 12, weight: .medium))
        .buttonStyle(.plain)
        .foregroundStyle(Theme.dim)
    }

    // MARK: - Helpers

    private func pager(_ name: String, _ enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? Theme.flapText : Theme.dim.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func select(_ m: Meeting) {
        if let i = model.meetings.firstIndex(where: { $0.id == m.id }) { model.index = i }
    }

    private func openBoard() {
        openWindow(id: "board")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func color(_ m: Meeting) -> Color { Color(hex: m.colorHex) ?? Theme.accent }
}
