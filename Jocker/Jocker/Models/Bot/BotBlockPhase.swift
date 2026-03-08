//
//  BotBlockPhase.swift
//  Jocker
//
//  Phase of a block for policy multipliers (early / mid / late).
//

import Foundation

/// Фаза блока для фазовых множителей политики.
/// Детерминированно выводится из прогресса блока.
enum BotBlockPhase: String, Equatable, CaseIterable {
    case early
    case mid
    case late

    /// Границы прогресса: early [0, 1/3), mid [1/3, 2/3), late [2/3, 1].
    /// progress в [0, 1]; 0 — начало блока, 1 — последняя раздача.
    static func from(blockProgressFraction: Double) -> BotBlockPhase {
        let p = min(1.0, max(0.0, blockProgressFraction))
        if p < 1.0 / 3.0 {
            return .early
        }
        if p < 2.0 / 3.0 {
            return .mid
        }
        return .late
    }
}

/// Фазовые множители по трём фазам блока (early / mid / late).
/// Нейтральный baseline — все 1.0.
struct PhaseMultipliers: Equatable {
    var early: Double
    var mid: Double
    var late: Double

    init(early: Double = 1.0, mid: Double = 1.0, late: Double = 1.0) {
        self.early = early
        self.mid = mid
        self.late = late
    }

    static let neutral = PhaseMultipliers(early: 1.0, mid: 1.0, late: 1.0)

    func multiplier(for phase: BotBlockPhase) -> Double {
        switch phase {
        case .early: return early
        case .mid: return mid
        case .late: return late
        }
    }
}
