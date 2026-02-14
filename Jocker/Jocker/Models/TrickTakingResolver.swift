//
//  TrickTakingResolver.swift
//  Jocker
//
//  Created by Codex on 14.02.2026.
//

import Foundation

/// Алгоритм определения победителя взятки (забор карт с кона).
///
/// Правила:
/// - Если на кону есть козыри, побеждает старший козырь.
/// - Если козырей нет, учитывается масть первого хода:
///   - если кроме первой карты этой масти нет, побеждает сделавший первый ход;
///   - иначе побеждает старшая карта масти первого хода.
/// - Джокер (если использован в текущей колоде) считается безусловно старшей картой
///   и забирает взятку; при нескольких джокерах побеждает сыгранный последним.
struct TrickTakingResolver {

    /// - Parameters:
    ///   - playedCards: карты в порядке хода.
    ///   - trump: козырная масть раунда.
    /// - Returns: индекс игрока-победителя (0-based) либо `nil`, если карт нет.
    static func winnerPlayerIndex(
        playedCards: [(playerIndex: Int, card: Card)],
        trump: Suit?
    ) -> Int? {
        guard !playedCards.isEmpty else { return nil }

        if let jokerEntry = playedCards.last(where: { $0.card.isJoker }) {
            return jokerEntry.playerIndex
        }

        if let trump {
            let trumpCards = playedCards.filter { $0.card.suit == trump }
            if !trumpCards.isEmpty {
                return highestCardPlayerIndex(in: trumpCards)
            }
        }

        guard let leadSuit = playedCards[0].card.suit else {
            return playedCards[0].playerIndex
        }

        let leadSuitCards = playedCards.filter { $0.card.suit == leadSuit }

        // Если никто не поддержал масть первого хода, взятку забирает лидер.
        if leadSuitCards.count <= 1 {
            return playedCards[0].playerIndex
        }

        return highestCardPlayerIndex(in: leadSuitCards)
    }

    private static func highestCardPlayerIndex(
        in playedCards: [(playerIndex: Int, card: Card)]
    ) -> Int {
        var winningEntry = playedCards[0]

        for candidate in playedCards.dropFirst() {
            // Здесь сравниваются карты одинаковой масти, поэтому trump не нужен.
            if candidate.card.beats(winningEntry.card, trump: nil) {
                winningEntry = candidate
            }
        }

        return winningEntry.playerIndex
    }
}
