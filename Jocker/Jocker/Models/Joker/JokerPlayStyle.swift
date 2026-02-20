//
//  JokerPlayStyle.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Способ выкладывания джокера на кон.
enum JokerPlayStyle: Equatable {
    /// Джокер лежит лицом вверх и участвует как активная карта.
    case faceUp
    /// "Подпихивание": джокер кладётся рубашкой вверх и считается младшей картой.
    case faceDown
}
