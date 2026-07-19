# VestBoard

A split-flap ("Vestaboard"-style) macOS app that shows your upcoming meetings on
animated flaps — with the classic terminal-board flip and a soft flap-clack sound.

- **Menu bar** — a live mini split-flap board in the menu bar (`6M STANDUP`) that
  flips as the countdown/next meeting changes. Click it for the next meeting on
  mini flaps, a **Join** button, ←/→ paging, and an **Up Next** list.
- **Board window** — the full 6×22 Vestaboard: time + countdown, title, location,
  tap-to-join, page counter, scattered color chips, and per-meeting calendar color.

Reads meetings from **Apple Calendar** via EventKit — point it at your work
calendar in Settings.

## Features

- Split-flap animation with palette color-roll while flipping (small changes flip
  minimally instead of cycling the whole deck)
- Synthesized soft "flap-clack" audio (no asset), toggle in Settings
- Live countdown, **auto-cycle** through meetings, **launch at login**
- Join opens the meeting link in your existing browser session, new tab

## Requirements

- **Xcode** (full app, not just Command Line Tools)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build & run

```bash
xcodegen generate          # creates VestBoard.xcodeproj from project.yml
open VestBoard.xcodeproj
```

In Xcode: select the **VestBoard** target → *Signing & Capabilities* → pick your
**Team**, then Run (⌘R). Grant Calendar access when prompted, then
**VestBoard ▸ Settings…** to choose which calendar(s) to show.

> The app runs **non-sandboxed** (personal desktop use) so it works on a free
> Apple Developer team without App Group / extension provisioning.

## Widget (optional, needs a paid team)

A `systemMedium` WidgetKit widget exists in `Sources/Widget/` but is **not embedded**
by default — free personal teams can't provision an embedded extension or an App
Group. On a **paid** Apple Developer team, re-enable the `dependencies` block in
`project.yml`, add an App Group to both entitlements, and the widget renders your
next meeting on the desktop and in Notification Center.

## Layout

```
Sources/
  Shared/   Meeting · CalendarService (EventKit) · SharedConfig · Theme
            SplitFlapView (flap engine + grid) · FlapClicker (audio)
  App/      VestBoardApp · RootView · BoardView · BoardModel
            MenuBarView · SettingsView · PermissionView
  Widget/   VestBoardWidget (shelved unless on a paid team)
project.yml  XcodeGen spec — source of truth; .xcodeproj is generated + gitignored
```

## License

MIT — see [LICENSE](LICENSE).
