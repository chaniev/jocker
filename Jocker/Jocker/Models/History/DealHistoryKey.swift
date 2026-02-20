//
//  DealHistoryKey.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// Ключ раздачи внутри партии.
struct DealHistoryKey: Hashable {
    /// Индекс блока (0-based).
    let blockIndex: Int
    /// Индекс раунда в блоке (0-based).
    let roundIndex: Int
}
