import Foundation
import OSLog

/// Loads `pricing.json` from the app bundle and converts `UsageEvent`s into USD estimates.
///
/// Numbers are vendored and drift. v1.1 will add a refresh script that pulls
/// the latest from LiteLLM's public price index.
final class PricingTable: Sendable {
    static let shared = PricingTable()

    struct ModelRates: Decodable, Sendable {
        let inputPerMTok: Double
        let outputPerMTok: Double
        let cacheWritePerMTok: Double
        let cacheReadPerMTok: Double

        enum CodingKeys: String, CodingKey {
            case inputPerMTok = "input_per_mtok"
            case outputPerMTok = "output_per_mtok"
            case cacheWritePerMTok = "cache_write_per_mtok"
            case cacheReadPerMTok = "cache_read_per_mtok"
        }
    }

    private let rates: [String: ModelRates]
    private let log = Logger(subsystem: "dev.kokonaut.AIUsageToolbar", category: "Pricing")

    init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "pricing", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let dict = try? JSONDecoder().decode([String: ModelRates].self, from: data) {
            self.rates = dict
        } else {
            self.rates = [:]
            log.error("pricing.json missing or unparseable")
        }
    }

    func costUSD(for event: UsageEvent) -> Double {
        let rate = rates[event.model] ?? Self.fallback(for: event.model)
        let perM = 1_000_000.0
        let input = Double(event.inputTokens) / perM * rate.inputPerMTok
        let cacheWrite = Double(event.cacheCreateTokens) / perM * rate.cacheWritePerMTok
        let cacheRead = Double(event.cacheReadTokens) / perM * rate.cacheReadPerMTok
        let output = Double(event.outputTokens) / perM * rate.outputPerMTok
        return input + cacheWrite + cacheRead + output
    }

    private static func fallback(for model: String) -> ModelRates {
        let m = model.lowercased()
        if m.contains("opus") {
            return ModelRates(inputPerMTok: 15, outputPerMTok: 75, cacheWritePerMTok: 18.75, cacheReadPerMTok: 1.5)
        }
        if m.contains("haiku") {
            return ModelRates(inputPerMTok: 1, outputPerMTok: 5, cacheWritePerMTok: 1.25, cacheReadPerMTok: 0.1)
        }
        return ModelRates(inputPerMTok: 3, outputPerMTok: 15, cacheWritePerMTok: 3.75, cacheReadPerMTok: 0.3)
    }
}
