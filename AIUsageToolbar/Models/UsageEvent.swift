import Foundation

/// A single assistant turn decoded from a `~/.claude/projects/**/*.jsonl` line.
/// Only lines that carry `message.usage` are converted into events.
struct UsageEvent: Hashable, Identifiable {
    let id: String              // "\(messageId):\(requestId)" — dedupe key
    let timestamp: Date
    let model: String
    let cwd: String?
    let gitBranch: String?

    let inputTokens: Int        // post-cache-breakpoint
    let cacheCreateTokens: Int
    let cacheReadTokens: Int
    let outputTokens: Int

    var totalInputTokens: Int {
        inputTokens + cacheCreateTokens + cacheReadTokens
    }

    var totalTokens: Int {
        totalInputTokens + outputTokens
    }
}
