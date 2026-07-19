import SwiftUI

@main
struct VestBoardApp: App {
    @StateObject private var model = BoardModel()

    var body: some Scene {
        WindowGroup("VestBoard", id: "board") {
            RootView(model: model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            // The actual mini Vestaboard in the menu bar — flips when the
            // countdown / next meeting changes.
            SplitFlapText(text: model.menuFlapText, columns: 14, cell: 12, spacing: 1.5)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
