import Foundation
import XCTest

@testable import AIUsageToolbar

/// Helpers for loading bundled JSONL fixtures and decoding them via the
/// same private path the production reader uses.
enum FixtureLoader {

    /// Locate a `.jsonl` fixture in the test bundle's `Fixtures/` folder.
    static func url(for name: String, in bundle: Bundle) -> URL {
        // XcodeGen with `type: folder` preserves the folder reference, so
        // fixtures live under <TestBundle>/Fixtures/<name>.jsonl.
        if let nested = bundle.url(forResource: name, withExtension: "jsonl", subdirectory: "Fixtures") {
            return nested
        }
        if let flat = bundle.url(forResource: name, withExtension: "jsonl") {
            return flat
        }
        XCTFail("Fixture \(name).jsonl not found in test bundle")
        return URL(fileURLWithPath: "/dev/null")
    }

    /// Parse a fixture file into `UsageEvent`s using the same per-line decode
    /// the production reader uses. We deliberately reimplement only the dedupe
    /// and per-line parse here — the production reader's file walker is not
    /// under test in unit tests.
    static func events(for name: String, in bundle: Bundle) throws -> [UsageEvent] {
        let fileURL = url(for: name, in: bundle)
        return try parseFile(at: fileURL)
    }

    /// Multi-file dedupe mirrors the production reader contract: events with
    /// the same `id` (i.e. `messageId:requestId`) are collapsed.
    static func dedupedEvents(across names: [String], in bundle: Bundle) throws -> [UsageEvent] {
        var seen: Set<String> = []
        var all: [UsageEvent] = []
        for name in names {
            let batch = try events(for: name, in: bundle)
            for event in batch where seen.insert(event.id).inserted {
                all.append(event)
            }
        }
        all.sort { $0.timestamp < $1.timestamp }
        return all
    }

    private static func parseFile(at url: URL) throws -> [UsageEvent] {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var events: [UsageEvent] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let lineData = line.data(using: .utf8) else { continue }
            if let event = try? decode(line: lineData) {
                events.append(event)
            }
        }
        return events
    }

    /// Mirror of `ClaudeJSONLReader.decode` for tests — the production version
    /// is private. We keep these in lockstep; if you change the production
    /// decode shape, update this too.
    private static func decode(line: Data) throws -> UsageEvent? {
        let raw = (try JSONSerialization.jsonObject(with: line) as? [String: Any]) ?? [:]
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
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]
        let timestamp = iso.date(from: timestampString)
            ?? isoNoFrac.date(from: timestampString)
            ?? Date()

        let input = (usage["input_tokens"] as? Int) ?? 0
        let cacheCreate = (usage["cache_creation_input_tokens"] as? Int) ?? 0
        let cacheRead = (usage["cache_read_input_tokens"] as? Int) ?? 0
        let output = (usage["output_tokens"] as? Int) ?? 0

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
