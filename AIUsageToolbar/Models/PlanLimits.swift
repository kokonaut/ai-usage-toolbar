import Foundation

/// Plan tier thresholds for the rolling 5-hour window and the trailing 7-day cap.
///
/// These numbers are NOT exposed by any Anthropic API or local file as of writing.
/// They're heuristics adapted from community tools (Claude-Code-Usage-Monitor)
/// and WILL drift. Expose an override in Settings.
enum PlanTier: String, CaseIterable, Identifiable, Codable {
    case pro
    case max5
    case max20

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pro:   "Pro"
        case .max5:  "Max 5×"
        case .max20: "Max 20×"
        }
    }

    var sessionTokenLimit: Int {
        switch self {
        case .pro:   44_000
        case .max5:  88_000
        case .max20: 220_000
        }
    }

    var weeklyTokenLimit: Int {
        switch self {
        case .pro:   880_000
        case .max5:  4_400_000
        case .max20: 22_000_000
        }
    }

    var opusWeeklyTokenLimit: Int {
        switch self {
        case .pro:   0
        case .max5:  440_000
        case .max20: 2_200_000
        }
    }
}
