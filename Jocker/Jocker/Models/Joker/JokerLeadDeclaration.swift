//
//  JokerLeadDeclaration.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Объявление при заходе с джокера первым ходом.
enum JokerLeadDeclaration: Equatable {
    /// "Хочу": остальные игроки могут класть любую карту.
    case wish
    /// "Выше": джокер считается старшей картой указанной масти.
    case above(suit: Suit)
    /// "Забирает": джокер считается младшей картой указанной масти.
    case takes(suit: Suit)
}
