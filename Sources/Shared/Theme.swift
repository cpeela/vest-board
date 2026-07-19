import SwiftUI

/// Vestaboard-inspired palette + flap geometry.
enum Theme {
    static let board = Color(red: 0.04, green: 0.05, blue: 0.06)   // near-black case
    static let flap = Color(red: 0.11, green: 0.12, blue: 0.14)    // individual flap face
    static let flapEdge = Color.black.opacity(0.55)                // center hinge line
    static let flapText = Color(red: 0.96, green: 0.96, blue: 0.93) // warm white glyph
    static let accent = Color(red: 0.98, green: 0.79, blue: 0.30)  // amber highlight
    static let dim = Color.white.opacity(0.45)

    /// Characters a flap can display, in flip order. Unknown chars map to space.
    static let deck: [Character] = Array(" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.,'-!?&/@%+#()")

    /// Classic Vestaboard chip colors — used for scatter fill and roll-through.
    static let palette: [Color] = [
        Color(hex: "E23B3B")!, // red
        Color(hex: "E8842B")!, // orange
        Color(hex: "F2C230")!, // yellow
        Color(hex: "3FA34D")!, // green
        Color(hex: "2F6BD6")!, // blue
        Color(hex: "7C4DC4")!, // violet
    ]
}

extension Color {
    /// Parse "#RRGGBB" / "RRGGBB". Returns nil on failure.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
