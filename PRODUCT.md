# AI Usage Toolbar — Product Spec

A native macOS menu-bar app that surfaces live Claude usage at a glance: how much of your 5-hour window you've burned, how close you are to the weekly cap, and what today is costing.

## Problem

Claude Code power-users run into invisible rate-limit walls. The signals you actually care about — "am I about to get cut off?", "how long until reset?", "what is this conversation costing me?" — live behind a `/usage` slash command that only works inside an active TUI session, or in the web Console two clicks away. Neither is glanceable while you're working.

Existing fixes are either terminal-only (ccusage, Claude-Code-Usage-Monitor) or first-generation menu-bar apps that fight for inline real estate and don't go deep on Claude specifically.

## Audience

Solo developers and AI-heavy engineers on macOS who use Claude Code on a Pro or Max subscription, often with a parallel Anthropic API workspace, and sometimes additional providers (OpenRouter, OpenAI). They care about uptime of their AI flow, not about per-token accounting for finance.

## What it does (v1)

A menu-bar item that shows, inline next to the system clock, a single number — the percent of the current 5-hour session burned — alongside a small template glyph. Clicking opens a 340×420 popover with three stacked cards:

1. **5-Hour Session** — progress bar, percent, time-until-reset countdown.
2. **Weekly** — progress bar, percent, reset date, sub-bar for Opus quota.
3. **Today** — dollar spend, burn rate (tokens/minute), 7-day sparkline of daily cost.

Data comes from the local `~/.claude/projects/**/*.jsonl` transcript files — fully offline, no cloud, no auth required. A `FileMonitor` (FSEvents) tails the directory; the parser dedupes lines by `messageId + requestId` and sums input/output/cache tokens against a local pricing table to estimate USD. The 5-hour window is computed using ccusage's "blocks" algorithm (a new window starts on the first message after a 5h+ idle gap).

Notifications fire at 75% / 90% / 95% of the active window with snooze-until-reset.

## What it does not do (v1)

- No Admin API integration. The Anthropic Admin API requires an organization account and `sk-ant-admin...` key — out of scope for the consumer flow we're optimizing for. Defer to v1.1 as an "advanced mode".
- No OpenAI integration. Their Admin API is org-only; the legacy dashboard endpoints are unreliable.
- No OpenRouter integration in v1 — but it's the cheapest provider to add later (a single authenticated GET returns daily/weekly/monthly spend) and is the natural v1.1 expansion.
- No multi-machine sync, no team views, no historical export.

## Differentiation

The market is crowded. CodexBar (12.7k★) already covers 40+ providers; ClaudeBar, ClaudeMeter, ClaudeUsageBar, SessionWatcher, Hamed's Claude Usage Tracker all overlap with the obvious feature set. To matter, this app needs at least one of:

- **Predictive rate-limit warning** — "at your current burn rate, you'll hit the 5-hour cap in 47 minutes" — surfaced in the menu bar itself, not buried in a popover.
- **Project-level breakdown** — JSONL transcripts already carry `cwd` and `gitBranch`. Slice usage per repo so you can see which project is eating your budget.
- **Claude Code-native hooks integration** — write a hook that pipes session events directly into the app, eliminating the polling lag entirely.

We will prioritize the predictive warning and per-project breakdown for v1. Hook integration is v1.1.

## Success criteria (v1)

- Idle RAM under 60 MB.
- Updates within 2 seconds of a new Claude Code message landing on disk.
- The inline menu-bar text is readable at every macOS scaling level and reflows correctly on dark mode.
- Ships signed and notarized with a working Sparkle-based auto-update channel.
- A new user can install, open, and see live numbers within 30 seconds with zero configuration.

## Open questions

- Should the inline text default to percent, time-to-reset, or dollars? User research suggests percent — but make it a setting and remember per-user.
- How do we communicate that the displayed numbers are *estimates* (pricing table can drift, plan thresholds are heuristic) without undermining trust? Probably a small "i" affordance in the popover footer linking to an explanation page.
- Distribution: Mac App Store vs Developer ID + direct download. Direct download is faster to ship and avoids sandbox friction with `~/.claude/` access. Default: direct download with Sparkle, App Store as a v2 consideration.
