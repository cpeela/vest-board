import SwiftUI

/// A single flap: either a glyph (with its text color) or a solid color chip
/// (the classic Vestaboard colored tile).
enum Flap: Equatable {
    case glyph(Character, Color)
    case chip(Color)

    static func text(_ c: Character, _ color: Color = Theme.flapText) -> Flap { .glyph(c, color) }
    static let blank = Flap.glyph(" ", Theme.flapText)
}

// MARK: - Animated cell

/// One flap cell. Glyph→glyph transitions roll forward through the deck (the
/// mechanical split-flap effect); chips / type changes do a single flip.
struct AnimatedFlap: View {
    let flap: Flap
    var cell: CGFloat = 30
    var animated: Bool = true
    var stagger: Double = 0

    @State private var display: Flap = .blank
    @State private var flipping = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        FlapFace(flap: display, size: cell, flipping: flipping)
            .onAppear {
                if animated { display = .glyph(" ", Theme.flapText); animate(to: flap) }
                else { display = flap }
            }
            .onChange(of: flap) { _, new in animated ? animate(to: new) : (display = new) }
            .onDisappear { task?.cancel() }
    }

    private func glyph(_ f: Flap) -> (Character, Color)? {
        if case let .glyph(c, col) = f { return (c, col) }
        return nil
    }

    private func deckIndex(_ c: Character) -> Int {
        Theme.deck.firstIndex(of: Character(c.uppercased())) ?? 0
    }

    private func animate(to target: Flap) {
        task?.cancel()
        task = Task { @MainActor in
            if stagger > 0 { try? await Task.sleep(nanoseconds: UInt64(stagger * 1_000_000_000)) }

            if let (tc, tcol) = glyph(target), let (dc, _) = glyph(display) {
                // Roll forward through the deck to the target glyph — fast.
                var i = deckIndex(dc)
                let ti = deckIndex(tc)
                let count = Theme.deck.count
                // Cap the roll: a small change (e.g. a countdown digit) shouldn't
                // cycle the whole deck — jump close and flip only a few times.
                let maxFlips = 5
                if (ti - i + count) % count > maxFlips { i = (ti - maxFlips + count) % count }
                while i != ti {
                    if Task.isCancelled { return }
                    withAnimation(.easeIn(duration: 0.045)) { flipping = true }
                    FlapClicker.shared.tick()
                    try? await Task.sleep(nanoseconds: 14_000_000)
                    i = (i + 1) % count
                    // Roll through the color palette while changing; land on final color.
                    let rolling = Theme.palette[i % Theme.palette.count]
                    display = .glyph(Theme.deck[i], rolling)
                    flipping = false
                    try? await Task.sleep(nanoseconds: 6_000_000)
                }
                display = .glyph(tc, tcol)
            } else {
                // Chip or glyph↔chip change: single flip.
                if Task.isCancelled { return }
                withAnimation(.easeIn(duration: 0.06)) { flipping = true }
                FlapClicker.shared.tick()
                try? await Task.sleep(nanoseconds: 60_000_000)
                display = target
                flipping = false
            }
        }
    }
}

/// Static face: dark tile + glyph, or a solid color chip; tilts when flipping.
private struct FlapFace: View {
    let flap: Flap
    let size: CGFloat
    let flipping: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                )
            if case let .glyph(ch, color) = flap {
                Text(String(ch))
                    .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            Rectangle().fill(Theme.flapEdge).frame(height: 1.1)
        }
        .frame(width: size * 0.72, height: size)
        .rotation3DEffect(
            .degrees(flipping ? -78 : 0),
            axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.6
        )
        .animation(.easeIn(duration: 0.04), value: flipping)
    }

    private var background: Color {
        if case let .chip(c) = flap { return c }
        return Theme.flap
    }
}

// MARK: - Grid

/// A full Vestaboard: a grid of flap rows on a dark case. Caller supplies rows
/// already padded to a uniform width. Cells ripple in with a diagonal stagger.
struct VestaBoard: View {
    let rows: [[Flap]]
    var cell: CGFloat = 30
    var spacing: CGFloat = 3
    var animated: Bool = true

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(rows[r].indices, id: \.self) { c in
                        AnimatedFlap(
                            flap: rows[r][c],
                            cell: cell,
                            animated: animated,
                            stagger: animated ? Double(c) * 0.011 + Double(r) * 0.02 : 0
                        )
                    }
                }
            }
        }
        .padding(cell * 0.42)
        .background(
            RoundedRectangle(cornerRadius: cell * 0.35, style: .continuous)
                .fill(Theme.board)
                .overlay(RoundedRectangle(cornerRadius: cell * 0.35).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
}

/// Single-row convenience (used by the widget). Static when `animated == false`.
struct SplitFlapText: View {
    let text: String
    var columns: Int
    var cell: CGFloat = 40
    var spacing: CGFloat = 3
    var animated: Bool = true
    var color: Color = Theme.flapText

    private var glyphs: [Character] {
        let up = text.uppercased()
        return up.count >= columns
            ? Array(up.prefix(columns))
            : Array(up + String(repeating: " ", count: columns - up.count))
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(glyphs.indices, id: \.self) { i in
                AnimatedFlap(flap: .glyph(glyphs[i], color), cell: cell, animated: animated)
            }
        }
    }
}
