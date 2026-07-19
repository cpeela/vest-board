import SwiftUI

struct RootView: View {
    @ObservedObject var model: BoardModel

    var body: some View {
        Group {
            if model.authorized {
                BoardView(model: model)
            } else {
                PermissionView(model: model)
            }
        }
        .task { model.reload() }
    }
}

/// Shown until the user grants Calendar access.
struct PermissionView: View {
    @ObservedObject var model: BoardModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("VESTBOARD")
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .foregroundStyle(Theme.flapText)
            Text("Show your upcoming meetings on a split-flap board.\nVestBoard needs access to your Calendar.")
                .multilineTextAlignment(.center)
                .font(.system(size: 13))
                .foregroundStyle(Theme.dim)
            Button("Grant Calendar Access") {
                Task { await model.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)

            Button("Open System Settings ▸ Calendars") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.system(size: 12))
        }
        .padding(40)
        .frame(minWidth: 460, minHeight: 300)
        .background(Theme.board)
    }
}
