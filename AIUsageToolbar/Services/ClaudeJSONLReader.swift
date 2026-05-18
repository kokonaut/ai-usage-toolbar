import Foundation
import OSLog

/// Reads and decodes Claude Code JSONL session transcripts from disk.
///
/// Looks in:
///   - $CLAUDE_CONFIG_DIR (comma-separated overrides), if set
///   - ~/.claude/projects/
///   - ~/.config/claude/projects/
///
/// One file per session: `<base>/projects/<url-encoded-cwd>/<session-uuid>.jsonl`.
/// Each assistant turn carries `message.usage`. We dedupe by `messageId + requestId`
/// because Claude Code occasionally writes duplicate assistant lines.
struct ClaudeJSONLReader: Sendable {
    private let log = Logger(subsystem: "dev.kokonaut.AIUsageToolbar", category: "JSONLReader")

    private var fm: FileManager { FileManager.default }

    func projectsRoots() -> [URL] {
        var roots: [URL] = []
        let env = ProcessInfo.processInfo.environment

        if let override = env["CLAUDE_CONFIG_DIR"], !override.isEmpty {
            for component in override.split(separator: ",") {
                let trimmed = component.trimmingCharacters(in: .whitespaces)
                let expanded = (trimmed as NSString).expandingTildeInPath
                roots.append(URL(fileURLWithPath: expanded).appendingPathComponent("projects"))
            }
        }

        let home = fm.homeDirectoryForCurrentUser
        roots.append(home.appendingPathComponent(".claude/projects"))
        roots.append(home.appendingPathComponent(".config/claude/projects"))

        return roots.filter { fm.fileExists(atPath: $0.path) }
    }

    func sessionFiles() -> [URL] {
        var files: [URL] = []
        for root in projectsRoots() {
            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator where url.pathExtension == "jsonl" {
                files.append(url)
            }
        }
        return files
    }

    func readAllEvents() async throws -> [UsageEvent] {
        let files = sessionFiles()
        log.debug("scanning \(files.count) jsonl files")

        return try await withThrowingTaskGroup(of: [UsageEvent].self) { group in
            for file in files {
                group.addTask { try parseFile(file) }
            }

            var seen: Set<String> = []
            var all: [UsageEvent] = []
            for try await batch in group {
                for event in batch where seen.insert(event.id).inserted {
                    all.append(event)
                }
            }
            all.sort { $0.timestamp < $1.timestamp }
            return all
        }
    }

    private func parseFile(_ url: URL) throws -> [UsageEvent] {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var events: [UsageEvent] = []
        events.reserveCapacity(64)

        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let lineData = line.data(using: .utf8) else { continue }
            if let event = try? Self.decode(line: lineData) {
                events.append(event)
            }
        }
        return events
    }

    nonisolated(unsafe) private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let iso8601NoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func decode(line: Data) throws -> UsageEvent? {
        let raw = try JSONSerialization.jsonObject(with: line) as? [String: Any] ?? [:]
        guard let message = raw["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any],
              let messageId = message["id"] as? String else {
            return nil
        }

        let requestId = (raw["requestId"] as? String) ?? (raw["uuid"] as? String) ?? messageId
        let model = (message["model"] as? String) ?? "unknown"
        let cwd = raw["cwd"] as? String
        let gitBranch = raw["gitBranch"] as? String
        let timestampString = (raw["timestamp"] as? String) ?? ""
        let timestamp = iso8601.date(from: timestampString)
            ?? iso8601NoFraction.date(from: timestampString)
            ?? Date()

        let input = (usage["input_tokens"] as? Int) ?? 0
        let cacheCreate = (usage["cache_creation_input_tokens"] as? Int) ?? 0
        let cacheRead = (usage["cache_read_input_tokens"] as? Int) ?? 0
        let output = (usage["output_tokens"] as? Int) ?? 0

        // Skip degenerate lines that have no token counts.
        if input + cacheCreate + cacheRead + output == 0 {
            return nil
        }

        return UsageEvent(
            id: "\(messageId):\(requestId)",
            timestamp: timestamp,
            model: model,
            cwd: cwd,
            gitBranch: gitBranch,
            inputTokens: input,
            cacheCreateTokens: cacheCreate,
            cacheReadTokens: cacheRead,
            outputTokens: output
        )
    }
}
