import Foundation
import SwiftData
import SwiftUI

@Model
final class Toy {
    var name: String
    var series: String
    var boxNumber: Int
    var hue: Double
    var lastShown: Date?
    var photoData: Data?
    var addedAt: Date

    init(name: String, series: String, boxNumber: Int, hue: Double, lastShown: Date? = nil, photoData: Data? = nil, addedAt: Date = .now) {
        self.name = name
        self.series = series
        self.boxNumber = boxNumber
        self.hue = hue
        self.lastShown = lastShown
        self.photoData = photoData
        self.addedAt = addedAt
    }

    var daysBoxed: Int {
        guard let lastShown else { return 90 }
        return max(0, Calendar.current.dateComponents([.day], from: lastShown, to: .now).day ?? 0)
    }

    var tint: Color { Color(hue: hue, saturation: 0.55, brightness: 0.82) }
}

@Model
final class ChanceSetup {
    var name: String
    var columns: Int
    var rows: Int
    var series: [String]
    var staleWeight: Double
    var modeID: String
    var rowSize: Int
    var sortOrder: Int

    init(name: String, columns: Int, rows: Int, series: [String], staleWeight: Double, modeID: String, rowSize: Int, sortOrder: Int) {
        self.name = name
        self.columns = columns
        self.rows = rows
        self.series = series
        self.staleWeight = staleWeight
        self.modeID = modeID
        self.rowSize = rowSize
        self.sortOrder = sortOrder
    }

    var slotCount: Int { columns * rows }

    var snapshot: RNGEngine.Setup {
        RNGEngine.Setup(slotCount: slotCount, series: series, staleWeight: staleWeight, rowSize: rowSize)
    }
}

@Model
final class SpinResult {
    var toyName: String
    var series: String
    var hue: Double
    var shelfName: String
    var slot: Int
    var placedAt: Date
    var modeID: String
    var daysBoxed: Int
    var isFavorite: Bool

    init(toyName: String, series: String, hue: Double, shelfName: String, slot: Int, placedAt: Date, modeID: String, daysBoxed: Int, isFavorite: Bool = false) {
        self.toyName = toyName
        self.series = series
        self.hue = hue
        self.shelfName = shelfName
        self.slot = slot
        self.placedAt = placedAt
        self.modeID = modeID
        self.daysBoxed = daysBoxed
        self.isFavorite = isFavorite
    }

    var isPlanned: Bool { placedAt > .now }
    var tint: Color { Color(hue: hue, saturation: 0.55, brightness: 0.82) }
}

enum DrawMode: String, CaseIterable, Identifiable {
    case one, row, slot, coin, wheel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .one: "One figure"
        case .row: "Row of N"
        case .slot: "Slot number"
        case .coin: "Keep or swap"
        case .wheel: "Series wheel"
        }
    }
}

enum ShelfOccupancy {
    static func current(_ results: [SpinResult], shelf: String, now: Date = .now) -> [Int: SpinResult] {
        var bySlot: [Int: SpinResult] = [:]
        for result in results where result.shelfName == shelf && result.placedAt <= now {
            if let existing = bySlot[result.slot], existing.placedAt >= result.placedAt { continue }
            bySlot[result.slot] = result
        }
        return bySlot
    }
}
