import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Pure draw. Same setup, candidates and seed give the same outcome.
enum RNGEngine {
    struct Setup: Equatable {
        var slotCount: Int
        var series: [String]
        var staleWeight: Double
        var rowSize: Int
    }

    struct Candidate: Equatable {
        var name: String
        var series: String
        var daysBoxed: Int
    }

    struct Outcome: Equatable {
        var mode: DrawMode
        var picks: [Int]
        var slots: [Int]
        var keep: Bool
        var series: String?
    }

    static func weight(_ candidate: Candidate, staleWeight: Double) -> Double {
        1 + staleWeight * Double(candidate.daysBoxed) / 30
    }

    static func roll(
        _ setup: Setup,
        candidates: [Candidate],
        freeSlots: [Int],
        mode: DrawMode,
        seed: UInt64
    ) -> Outcome? {
        var rng = SeededGenerator(seed: seed)
        let pool = candidates.indices.filter { setup.series.isEmpty || setup.series.contains(candidates[$0].series) }
        guard !pool.isEmpty else { return nil }
        let firstFree = freeSlots.first ?? 0

        switch mode {
        case .one:
            let pick = weightedPick(pool, candidates, setup.staleWeight, &rng)
            return Outcome(mode: mode, picks: [pick], slots: [firstFree], keep: false, series: nil)
        case .row:
            var remaining = pool
            var picks: [Int] = []
            let count = max(1, min(setup.rowSize, remaining.count, max(freeSlots.count, 1)))
            for _ in 0..<count {
                let pick = weightedPick(remaining, candidates, setup.staleWeight, &rng)
                picks.append(pick)
                remaining.removeAll { $0 == pick }
            }
            let slots = picks.indices.map { freeSlots.indices.contains($0) ? freeSlots[$0] : $0 }
            return Outcome(mode: mode, picks: picks, slots: slots, keep: false, series: nil)
        case .slot:
            let pick = weightedPick(pool, candidates, setup.staleWeight, &rng)
            let slot = Int.random(in: 0..<max(setup.slotCount, 1), using: &rng)
            return Outcome(mode: mode, picks: [pick], slots: [slot], keep: false, series: nil)
        case .coin:
            let keep = Bool.random(using: &rng)
            let pick = weightedPick(pool, candidates, setup.staleWeight, &rng)
            return Outcome(mode: mode, picks: keep ? [] : [pick], slots: keep ? [] : [firstFree], keep: keep, series: nil)
        case .wheel:
            let names = Array(Set(pool.map { candidates[$0].series })).sorted()
            var totals: [Double] = names.map { name in
                pool.filter { candidates[$0].series == name }
                    .reduce(0) { $0 + weight(candidates[$1], staleWeight: setup.staleWeight) }
            }
            if totals.allSatisfy({ $0 <= 0 }) { totals = names.map { _ in 1 } }
            let segment = pickIndex(totals, &rng)
            let inSeries = pool.filter { candidates[$0].series == names[segment] }
            let pick = weightedPick(inSeries, candidates, setup.staleWeight, &rng)
            return Outcome(mode: mode, picks: [pick], slots: [firstFree], keep: false, series: names[segment])
        }
    }

    private static func weightedPick(_ pool: [Int], _ candidates: [Candidate], _ staleWeight: Double, _ rng: inout SeededGenerator) -> Int {
        let weights = pool.map { weight(candidates[$0], staleWeight: staleWeight) }
        return pool[pickIndex(weights, &rng)]
    }

    private static func pickIndex(_ weights: [Double], _ rng: inout SeededGenerator) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else { return 0 }
        var ticket = Double.random(in: 0..<total, using: &rng)
        for (index, value) in weights.enumerated() {
            if ticket < value { return index }
            ticket -= value
        }
        return weights.count - 1
    }
}
