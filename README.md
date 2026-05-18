# AI Usage Toolbar

A native macOS menu-bar app that shows live Claude usage at a glance — your 5-hour session window, weekly cap, and today's spend, all without leaving whatever you're working in.

Status: **v0, scaffolding in place.** Bootable Xcode project, real data wiring is in progress.

## Why

Claude Code power users run into rate-limit walls invisibly. Today the answer is `/usage` inside a session, or the Console UI two clicks away. Neither is glanceable. This puts the number where you live: next to your clock.

## What ships

- Menu-bar icon + inline percent of the current 5-hour window
- Click to open a 340×420 popover with three cards: 5-hour, weekly, today
- Threshold notifications at 75 / 90 / 95 percent
- Pure local: reads `~/.claude/projects/**/*.jsonl` directly. No cloud, no auth.

See `PRODUCT.md` for the spec and `DESIGN.md` for the engineering plan.

## Stack

- Swift 6 + SwiftUI (`MenuBarExtra`) with AppKit escape hatches via [`MenuBarExtraAccess`](https://github.com/orchetect/MenuBarExtraAccess)
- macOS 14+ deployment target
- XcodeGen for the project file (the `.xcodeproj` is generated, not committed)
- Swift Charts for sparklines

## Building

You will need:

- macOS 14+
- Xcode 15+ (Xcode 26 known good)
- `brew install xcodegen`

Then:

```bash
xcodegen generate
open AIUsageToolbar.xcodeproj
```

Build and run the `AIUsageToolbar` scheme. The app installs in your menu bar (no Dock icon).

## Repo layout

```
PRODUCT.md           — product spec
DESIGN.md            — engineering design
CLAUDE.md            — guidance for future Claude sessions in this repo
project.yml          — XcodeGen project definition
AIUsageToolbar/      — Swift sources
  App/               — @main + AppState
  Models/            — data structures
  Services/          — JSONL reader, file monitor, aggregator
  Views/             — menu-bar label and popover cards
  Resources/         — Info.plist, vendored pricing.json
```

## Prior art and credit

This app stands on research and conventions from [`ccusage`](https://github.com/ryoppippi/ccusage), [Claude Code Usage Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor), and other open-source Claude usage tools. The 5-hour "blocks" algorithm and the `messageId + requestId` dedupe convention come from ccusage; the plan-tier token thresholds are adapted from Claude Code Usage Monitor.

## License

TBD.
