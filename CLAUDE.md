# Guidance for Claude sessions in this repo

This file is for future Claude (and human) sessions. Read it before starting work here.

## What this project is

A native macOS menu-bar app that reads `~/.claude/projects/**/*.jsonl` and surfaces live Claude usage in the menu bar. The audience is solo developers on Claude Pro/Max who need glanceable rate-limit awareness. Full context is in `PRODUCT.md`; the engineering plan is in `DESIGN.md`.

## Stack and conventions

- **Swift 6, SwiftUI + AppKit.** Use `MenuBarExtra` for the host, drop to `NSStatusItem` via `MenuBarExtraAccess` when `MenuBarExtra`'s API is insufficient (settings window, popover size control, etc.). Several known gotchas are documented in `DESIGN.md`.
- **macOS 14+.** Don't introduce APIs newer than the deployment target without raising it deliberately.
- **XcodeGen.** The `.xcodeproj` is generated from `project.yml` and gitignored. After editing `project.yml`, run `xcodegen generate`. Do not hand-edit the `.xcodeproj` — your changes will be blown away.
- **Dependencies stay tiny.** Two SPM deps at most: `MenuBarExtraAccess` and (later) `Sparkle`. Everything else is stdlib. If you reach for a third, justify it in the PR description.

## Build commands

```bash
xcodegen generate                          # regenerate the .xcodeproj
xcodebuild -scheme AIUsageToolbar build    # CLI build
xcodebuild -scheme AIUsageToolbar test     # run tests
open AIUsageToolbar.xcodeproj              # interactive
```

## Data-source ground truth

- Per-session JSONL lives at `~/.claude/projects/<url-encoded-cwd>/<session-uuid>.jsonl`. Also check `~/.config/claude/projects/` and honor `CLAUDE_CONFIG_DIR`.
- Each assistant turn has `message.usage` with four token fields: `input_tokens` (post-cache-breakpoint), `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`. **Total input is the sum of the three non-output fields.** Using `input_tokens` alone undercounts cached prompts by 5–15%.
- Dedupe by `message.id + requestId`. Claude Code occasionally writes duplicate assistant lines.
- 5-hour windows ("blocks") use ccusage's algorithm: sort chronologically, start a new block whenever the gap exceeds 5 hours.
- Plan-tier limits (Pro / Max5 / Max20) are undocumented and may drift; we hardcode in `PlanLimits.swift` and expose a settings override. Watch upstream tools for changes.

## What lives where

- `PRODUCT.md` — what we're building and why. The market is crowded; differentiation strategy lives here.
- `DESIGN.md` — module map, data flow, performance budget. Update when architecture changes.
- `AIUsageToolbar/App/` — entry point and global state.
- `AIUsageToolbar/Services/` — file watching, JSONL parsing, aggregation, pricing. Pure logic, testable.
- `AIUsageToolbar/Views/` — SwiftUI. Should be a thin layer over `UsageSnapshot`.
- `AIUsageToolbar/Resources/pricing.json` — vendored model prices. Drifts. Refresh script comes in v1.1.

## Things to avoid

- Don't add `print` debugging that ships. Use `os.Logger`.
- Don't reach for Combine. Use Swift concurrency (`AsyncStream`, `Task`, `actor`) — it's the right grain for a polling/streaming app.
- Don't add Electron / web-frontend layers. The stack decision is in `PRODUCT.md` and `DESIGN.md`; if you want to revisit it, start a discussion.
- Don't fetch from network for live numbers in v1 — the local JSONL is the only data source. Admin API and OpenRouter are deferred to v1.1.

## When you finish a substantial change

Verify a real build (`xcodebuild`) and at minimum smoke-test the app launches and shows numbers (or zeros, before data is wired). Type-check passing is not enough for UI work.

## Prior art worth reading

- `ccusage` — https://github.com/ryoppippi/ccusage — the authoritative JSONL parsing reference.
- Claude Code Usage Monitor — https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor — plan-tier thresholds and TUI patterns.
- CodexBar — https://github.com/steipete/CodexBar — production Swift menu-bar app, 40+ providers. Our biggest competitor.
- MenuBarExtraAccess — https://github.com/orchetect/MenuBarExtraAccess — escape hatches for `MenuBarExtra`'s limitations.
