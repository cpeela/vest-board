# VestBoard

A split-flap ("Vestaboard"-style) macOS board for your upcoming meetings.

- **App window** — the real board: split-flap flip animation, left/right arrows to
  page through meetings, click **JOIN** to open the meeting in your browser (new tab,
  existing session). Keep it open on your desktop.
- **Widget** — a `systemMedium` WidgetKit widget showing your next meeting. Appears on
  the **desktop** *and* in **Notification Center** (right-edge swipe). Tap **JOIN** to
  open the link. (Widgets can't run live animation, so the flaps are a static snapshot.)

Reads meetings from **Apple Calendar** via EventKit — point it at your work calendar in
Settings. The app writes meetings to a shared App Group; the widget reads that cache
(widgets can't prompt for Calendar permission), so keep the app running to stay fresh.

## Requirements

- **Xcode** (full app, from the App Store) — not just Command Line Tools.
- A **paid Apple Developer account** — App Groups (app↔widget sharing) aren't available
  on a free personal team.

## Build & run

```bash
xcodegen generate          # creates VestBoard.xcodeproj from project.yml
open VestBoard.xcodeproj
```

In Xcode:
1. Select the **VestBoard** target → Signing & Capabilities → pick your **Team**
   (repeat for the **VestBoardWidget** target). App Group `group.com.lendapi.vestboard`
   is already declared in the entitlements.
2. Run the **VestBoard** scheme. Grant Calendar access when prompted.
3. **VestBoard ▸ Settings…** → tick your LendAPI calendar.
4. Add the widget: right-click desktop → **Edit Widgets** → search *VestBoard* → drop
   the medium widget. It also shows in Notification Center.

## Layout

```
Sources/
  Shared/     Meeting, CalendarService (EventKit), SharedConfig (App Group cache),
              SplitFlapView (the flip animation), Theme
  App/        VestBoardApp, RootView, BoardView, BoardModel, SettingsView, PermissionView
  Widget/     VestBoardWidget (bundle + TimelineProvider + medium layout)
project.yml   XcodeGen spec (source of truth — .xcodeproj is generated, gitignored)
```

## Notes / limits

- Widget freshness depends on the app running (it owns Calendar access). If the app is
  closed, the widget shows the last cached meetings.
- Widget refresh is rate-limited by macOS; the timeline reloads at each meeting
  start/end and ~every 30 min as a safety net.
- The split-flap is a stylized tilt-flip. Bump `columns`/`cell` in `BoardView` /
  `VestBoardWidget` to taste.
