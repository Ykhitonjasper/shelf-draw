import Foundation
import SwiftData

enum SeedData {
    struct ToySeed {
        let name: String
        let series: String
        let box: Int
        let hue: Double
        let addedDaysAgo: Int
    }

    struct ShelfSeed {
        let name: String
        let columns: Int
        let rows: Int
        let series: [String]
        let staleWeight: Double
        let mode: DrawMode
        let rowSize: Int
    }

    struct PlacementSeed {
        let toy: String
        let shelf: String
        let slot: Int
        let dayOffset: Int
        let mode: DrawMode
        let favorite: Bool
    }

    static let drawModes: [DrawMode] = [.one, .row, .slot, .coin, .wheel]

    static let seriesNames = ["Kaiju Vinyl", "Forest Folk", "Space Crew", "Night Market", "Mini Guild"]

    static let toys: [ToySeed] = [
        ToySeed(name: "Kaiju Rex", series: "Kaiju Vinyl", box: 3, hue: 0.33, addedDaysAgo: 400),
        ToySeed(name: "Moss Golem", series: "Forest Folk", box: 7, hue: 0.28, addedDaysAgo: 210),
        ToySeed(name: "Tin Pilot", series: "Space Crew", box: 2, hue: 0.58, addedDaysAgo: 330),
        ToySeed(name: "Neon Kitsune", series: "Night Market", box: 5, hue: 0.92, addedDaysAgo: 120),
        ToySeed(name: "Lab Bunny", series: "Mini Guild", box: 1, hue: 0.08, addedDaysAgo: 95),
        ToySeed(name: "Sumo Frog", series: "Forest Folk", box: 7, hue: 0.36, addedDaysAgo: 260),
        ToySeed(name: "Pocket Yeti", series: "Kaiju Vinyl", box: 3, hue: 0.55, addedDaysAgo: 180),
        ToySeed(name: "Paper Samurai", series: "Mini Guild", box: 1, hue: 0.02, addedDaysAgo: 75),
        ToySeed(name: "Glow Squid", series: "Night Market", box: 5, hue: 0.72, addedDaysAgo: 150),
        ToySeed(name: "Cactus Knight", series: "Forest Folk", box: 8, hue: 0.24, addedDaysAgo: 45),
        ToySeed(name: "Retro Astronaut", series: "Space Crew", box: 2, hue: 0.62, addedDaysAgo: 500),
        ToySeed(name: "Clay Owl", series: "Forest Folk", box: 8, hue: 0.10, addedDaysAgo: 30),
        ToySeed(name: "Cyber Tanuki", series: "Night Market", box: 6, hue: 0.80, addedDaysAgo: 60),
        ToySeed(name: "Rain Ghost", series: "Night Market", box: 6, hue: 0.52, addedDaysAgo: 88),
        ToySeed(name: "Brick Wizard", series: "Mini Guild", box: 4, hue: 0.70, addedDaysAgo: 140),
        ToySeed(name: "Lighthouse Keeper", series: "Mini Guild", box: 4, hue: 0.15, addedDaysAgo: 230),
        ToySeed(name: "Toast Cat", series: "Kaiju Vinyl", box: 9, hue: 0.11, addedDaysAgo: 20),
        ToySeed(name: "Arcade Dragon", series: "Kaiju Vinyl", box: 9, hue: 0.45, addedDaysAgo: 310),
        ToySeed(name: "Snow Moth", series: "Forest Folk", box: 10, hue: 0.60, addedDaysAgo: 70),
        ToySeed(name: "Pixel Ranger", series: "Space Crew", box: 11, hue: 0.40, addedDaysAgo: 190),
        ToySeed(name: "Mushroom Scout", series: "Forest Folk", box: 10, hue: 0.03, addedDaysAgo: 105),
        ToySeed(name: "Deep Diver", series: "Space Crew", box: 11, hue: 0.50, addedDaysAgo: 360),
        ToySeed(name: "Comet Fox", series: "Space Crew", box: 12, hue: 0.06, addedDaysAgo: 16),
        ToySeed(name: "Lantern Imp", series: "Night Market", box: 12, hue: 0.13, addedDaysAgo: 40),
    ]

    static let shelves: [ShelfSeed] = [
        ShelfSeed(name: "Living room · top", columns: 4, rows: 2, series: [], staleWeight: 1.5, mode: .one, rowSize: 2),
        ShelfSeed(name: "Living room · lower", columns: 4, rows: 2, series: ["Kaiju Vinyl", "Space Crew"], staleWeight: 1.0, mode: .row, rowSize: 3),
        ShelfSeed(name: "Detolf glass 1", columns: 4, rows: 1, series: ["Night Market"], staleWeight: 2.0, mode: .one, rowSize: 2),
        ShelfSeed(name: "Detolf glass 2", columns: 4, rows: 1, series: ["Forest Folk"], staleWeight: 2.0, mode: .slot, rowSize: 2),
        ShelfSeed(name: "Detolf glass 3", columns: 4, rows: 1, series: ["Mini Guild"], staleWeight: 1.2, mode: .coin, rowSize: 2),
        ShelfSeed(name: "Detolf glass 4", columns: 4, rows: 1, series: [], staleWeight: 0.8, mode: .wheel, rowSize: 2),
        ShelfSeed(name: "Desk strip", columns: 3, rows: 1, series: ["Mini Guild", "Space Crew"], staleWeight: 1.0, mode: .one, rowSize: 1),
        ShelfSeed(name: "Windowsill", columns: 6, rows: 1, series: ["Forest Folk", "Kaiju Vinyl"], staleWeight: 1.4, mode: .row, rowSize: 3),
        ShelfSeed(name: "Bookcase gap", columns: 2, rows: 1, series: [], staleWeight: 2.5, mode: .one, rowSize: 1),
        ShelfSeed(name: "Hallway niche", columns: 3, rows: 1, series: ["Night Market", "Kaiju Vinyl"], staleWeight: 1.1, mode: .coin, rowSize: 1),
        ShelfSeed(name: "October row", columns: 5, rows: 1, series: ["Night Market", "Forest Folk"], staleWeight: 0.6, mode: .wheel, rowSize: 3),
        ShelfSeed(name: "Winter row", columns: 5, rows: 1, series: ["Forest Folk", "Space Crew"], staleWeight: 0.9, mode: .row, rowSize: 4),
    ]

    static let placements: [PlacementSeed] = [
        PlacementSeed(toy: "Kaiju Rex", shelf: "Living room · top", slot: 0, dayOffset: -2, mode: .one, favorite: true),
        PlacementSeed(toy: "Neon Kitsune", shelf: "Living room · top", slot: 1, dayOffset: -2, mode: .row, favorite: false),
        PlacementSeed(toy: "Tin Pilot", shelf: "Living room · top", slot: 2, dayOffset: -3, mode: .row, favorite: false),
        PlacementSeed(toy: "Moss Golem", shelf: "Living room · top", slot: 4, dayOffset: -5, mode: .slot, favorite: true),
        PlacementSeed(toy: "Lab Bunny", shelf: "Living room · top", slot: 5, dayOffset: -6, mode: .one, favorite: false),
        PlacementSeed(toy: "Glow Squid", shelf: "Living room · top", slot: 6, dayOffset: -7, mode: .wheel, favorite: false),
        PlacementSeed(toy: "Sumo Frog", shelf: "Living room · top", slot: 0, dayOffset: -16, mode: .one, favorite: false),
        PlacementSeed(toy: "Pocket Yeti", shelf: "Living room · top", slot: 1, dayOffset: -16, mode: .coin, favorite: false),
        PlacementSeed(toy: "Retro Astronaut", shelf: "Living room · lower", slot: 0, dayOffset: -4, mode: .row, favorite: true),
        PlacementSeed(toy: "Arcade Dragon", shelf: "Living room · lower", slot: 1, dayOffset: -4, mode: .row, favorite: false),
        PlacementSeed(toy: "Deep Diver", shelf: "Living room · lower", slot: 2, dayOffset: -4, mode: .row, favorite: false),
        PlacementSeed(toy: "Rain Ghost", shelf: "Detolf glass 1", slot: 0, dayOffset: -9, mode: .one, favorite: false),
        PlacementSeed(toy: "Cyber Tanuki", shelf: "Detolf glass 1", slot: 2, dayOffset: -12, mode: .one, favorite: true),
        PlacementSeed(toy: "Cactus Knight", shelf: "Detolf glass 2", slot: 3, dayOffset: -10, mode: .slot, favorite: false),
        PlacementSeed(toy: "Snow Moth", shelf: "Detolf glass 2", slot: 1, dayOffset: -21, mode: .slot, favorite: false),
        PlacementSeed(toy: "Brick Wizard", shelf: "Detolf glass 3", slot: 0, dayOffset: -11, mode: .coin, favorite: false),
        PlacementSeed(toy: "Paper Samurai", shelf: "Detolf glass 3", slot: 1, dayOffset: -25, mode: .coin, favorite: true),
        PlacementSeed(toy: "Lantern Imp", shelf: "Detolf glass 4", slot: 0, dayOffset: -8, mode: .wheel, favorite: false),
        PlacementSeed(toy: "Toast Cat", shelf: "Desk strip", slot: 0, dayOffset: -1, mode: .one, favorite: false),
        PlacementSeed(toy: "Pixel Ranger", shelf: "Desk strip", slot: 1, dayOffset: -14, mode: .one, favorite: false),
        PlacementSeed(toy: "Mushroom Scout", shelf: "Windowsill", slot: 0, dayOffset: -13, mode: .row, favorite: false),
        PlacementSeed(toy: "Clay Owl", shelf: "Windowsill", slot: 1, dayOffset: -13, mode: .row, favorite: true),
        PlacementSeed(toy: "Pocket Yeti", shelf: "Windowsill", slot: 2, dayOffset: -13, mode: .row, favorite: false),
        PlacementSeed(toy: "Lighthouse Keeper", shelf: "Bookcase gap", slot: 0, dayOffset: -18, mode: .one, favorite: false),
        PlacementSeed(toy: "Comet Fox", shelf: "Bookcase gap", slot: 1, dayOffset: -15, mode: .one, favorite: false),
        PlacementSeed(toy: "Glow Squid", shelf: "Hallway niche", slot: 0, dayOffset: -27, mode: .coin, favorite: false),
        PlacementSeed(toy: "Kaiju Rex", shelf: "Hallway niche", slot: 1, dayOffset: -30, mode: .coin, favorite: false),
        PlacementSeed(toy: "Rain Ghost", shelf: "October row", slot: 0, dayOffset: -24, mode: .wheel, favorite: true),
        PlacementSeed(toy: "Lantern Imp", shelf: "October row", slot: 1, dayOffset: -24, mode: .wheel, favorite: false),
        PlacementSeed(toy: "Snow Moth", shelf: "Winter row", slot: 0, dayOffset: 3, mode: .row, favorite: false),
        PlacementSeed(toy: "Comet Fox", shelf: "Winter row", slot: 1, dayOffset: 3, mode: .row, favorite: false),
        PlacementSeed(toy: "Mushroom Scout", shelf: "October row", slot: 2, dayOffset: 6, mode: .wheel, favorite: false),
    ]

    static func install(into context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        let hues = Dictionary(uniqueKeysWithValues: toys.map { ($0.name, $0) })
        var lastShown: [String: Date] = [:]
        var inserted: [SpinResult] = []

        for placement in placements {
            let date = calendar.date(byAdding: .day, value: placement.dayOffset, to: now) ?? now
            let seed = hues[placement.toy]
            let result = SpinResult(
                toyName: placement.toy,
                series: seed?.series ?? "",
                hue: seed?.hue ?? 0.1,
                shelfName: placement.shelf,
                slot: placement.slot,
                placedAt: date,
                modeID: placement.mode.rawValue,
                daysBoxed: 20 + abs(placement.dayOffset) * 2,
                isFavorite: placement.favorite
            )
            inserted.append(result)
            if date <= now, date > (lastShown[placement.toy] ?? .distantPast) {
                lastShown[placement.toy] = date
            }
        }

        for seed in toys {
            let added = calendar.date(byAdding: .day, value: -seed.addedDaysAgo, to: now) ?? now
            context.insert(Toy(name: seed.name, series: seed.series, boxNumber: seed.box, hue: seed.hue, lastShown: lastShown[seed.name], addedAt: added))
        }
        for (index, seed) in shelves.enumerated() {
            context.insert(ChanceSetup(
                name: seed.name,
                columns: seed.columns,
                rows: seed.rows,
                series: seed.series,
                staleWeight: seed.staleWeight,
                modeID: seed.mode.rawValue,
                rowSize: seed.rowSize,
                sortOrder: index
            ))
        }
        inserted.forEach(context.insert)
        try? context.save()
    }

    static func wipe(_ context: ModelContext) {
        try? context.delete(model: SpinResult.self)
        try? context.delete(model: ChanceSetup.self)
        try? context.delete(model: Toy.self)
        try? context.save()
    }
}
