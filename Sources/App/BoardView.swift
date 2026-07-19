import SwiftUI

/// The full Vestaboard: a 6×22 flap grid where everything — time, countdown,
/// title, location, join hint, page — is composed onto the flaps. Per-meeting
/// calendar color drives the accents/chips. Edge chevrons page; tap to join.
struct BoardView: View {
    @ObservedObject var model: BoardModel

    private let cols = 22
    private let rowsN = 6
    private let cell: CGFloat = 30

    var body: some View {
        ZStack {
            VestaBoard(rows: grid, cell: cell)
                .contentShape(Rectangle())
                .onTapGesture { if let m = model.current { model.join(m) } }

            HStack {
                chevron("chevron.left", enabled: model.canPrev, action: model.prev)
                Spacer()
                chevron("chevron.right", enabled: model.canNext, action: model.next)
            }
            .padding(.horizontal, 2)
        }
        .padding(26)
        .background(Theme.board)
        .frame(minWidth: 760, minHeight: 380)
    }

    private var accent: Color {
        model.current.flatMap { Color(hex: $0.colorHex) } ?? Theme.accent
    }

    // MARK: - Grid composition

    private var grid: [[Flap]] {
        guard let m = model.current else {
            return pad([
                compose([("VESTBOARD", 0, Theme.dim)]),
                blank(),
                compose([("NO UPCOMING", 0, Theme.flapText)]),
                compose([("MEETINGS", 0, Theme.flapText)]),
            ])
        }

        let title = m.title.uppercased()
        let line1 = String(title.prefix(cols))
        let line2 = title.count > cols ? String(title.dropFirst(cols).prefix(cols)) : ""
        let page = "\(model.index + 1)/\(model.meetings.count)"
        let cd = m.countdown
        let bottomLeft = m.joinURL != nil ? "TAP TO JOIN" : (m.location ?? "")

        let rows = pad([
            compose([(m.compactRange, 0, Theme.flapText), (cd, cols - cd.count, m.isNow ? Theme.accent : accent)]),
            chipRow(accent, count: 3, at: cols - 3),
            compose([(line1, 0, Theme.flapText)]),
            compose([(line2, 0, Theme.flapText)]),
            compose([(clean(m.location), 0, Theme.dim)]),
            compose([(bottomLeft, 0, accent), (page, cols - page.count, Theme.dim)]),
        ])
        // Scatter Vestaboard chips into empty cells, seeded per meeting so the
        // pattern is stable across refreshes but changes when you page.
        return scatter(rows, seed: stableHash(m.id))
    }

    /// Fill a share of blank cells with random palette chips (deterministic per seed).
    private func scatter(_ rows: [[Flap]], seed: Int, density: Int = 8) -> [[Flap]] {
        var out = rows
        var state = UInt64(bitPattern: Int64(seed)) ^ 0x9E3779B97F4A7C15
        func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state >> 33
        }
        for r in out.indices {
            for c in out[r].indices where out[r][c] == .blank {
                if next() % 100 < UInt64(density) {
                    out[r][c] = .chip(Theme.palette[Int(next() % UInt64(Theme.palette.count))])
                }
            }
        }
        return out
    }

    private func stableHash(_ s: String) -> Int {
        var h = 5381
        for b in s.utf8 { h = (h &* 33) &+ Int(b) }
        return h
    }

    /// Write text segments (text, startColumn, color) onto a blank row.
    private func compose(_ segments: [(String, Int, Color)]) -> [Flap] {
        var row = blank()
        for (text, at, color) in segments {
            for (i, ch) in Array(text.uppercased()).enumerated() {
                let idx = at + i
                if idx >= 0 && idx < cols { row[idx] = .glyph(ch, color) }
            }
        }
        return row
    }

    private func blank() -> [Flap] { Array(repeating: .blank, count: cols) }

    private func chipRow(_ color: Color, count: Int, at: Int) -> [Flap] {
        var row = blank()
        for i in 0..<count where at + i < cols { row[at + i] = .chip(color) }
        return row
    }

    private func pad(_ rows: [[Flap]]) -> [[Flap]] {
        var out = rows
        while out.count < rowsN { out.append(blank()) }
        return Array(out.prefix(rowsN))
    }

    private func clean(_ s: String?) -> String {
        guard let s, !s.isEmpty else { return "" }
        return s
    }

    // MARK: - Chevrons

    private func chevron(_ name: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(enabled ? Theme.flapText : .white.opacity(0.12))
                .frame(width: 40, height: 84)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(enabled ? 0.3 : 0.05)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .keyboardShortcut(name.contains("left") ? .leftArrow : .rightArrow, modifiers: [])
    }
}
