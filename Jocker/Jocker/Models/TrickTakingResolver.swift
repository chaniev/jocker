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
/// - Для обычного хода действуют стандартные правила масти/козыря.
/// - Джокер лицом вверх перебивает всё; при нескольких джокерах выигрывает последний.
/// - Джокер рубашкой вверх ("подпихивание") не может выиграть взятку.
/// - Если первый ход сделан джокером, учитывается объявление:
///   - "хочу" — выигрывает первый джокер, если позже не сыгран другой джокер лицом вверх;
///   - "выше" — джокер как старшая карта указанной масти;
///   - "забирает" — джокер как младшая карта указанной масти.
struct TrickTakingResolver {

    /// - Parameters:
    ///   - playedCards: карты в порядке хода.
    ///   - trump: козырная масть раунда.
    /// - Returns: индекс игрока-победителя (0-based) либо `nil`, если карт нет.
    static func winnerPlayerIndex(
        playedCards: [PlayedTrickCard],
        trump: Suit?
    ) -> Int? {
        guard !playedCards.isEmpty else { return nil }

        let leadCard = playedCards[0]
        if leadCard.card.isJoker {
            return winnerWhenLeadCardIsJoker(playedCards: playedCards, trump: trump)
        }

        if let jokerWinner = lastFaceUpJokerPlayerIndex(in: playedCards) {
            return jokerWinner
        }

        return winnerByStandardRules(
            playedCards: playedCards,
            trump: trump,
            leadSuit: leadCard.card.suit
        )
    }

    /// Обратная совместимость: старый контракт без контекста джокера.
    static func winnerPlayerIndex(
        playedCards: [(playerIndex: Int, card: Card)],
        trump: Suit?
    ) -> Int? {
        let normalizedCards = playedCards.map { entry in
            PlayedTrickCard(
                playerIndex: entry.playerIndex,
                card: entry.card
            )
        }
        return winnerPlayerIndex(playedCards: normalizedCards, trump: trump)
    }

    private static func winnerWhenLeadCardIsJoker(
        playedCards: [PlayedTrickCard],
        trump: Suit?
    ) -> Int {
        let leadCard = playedCards[0]

        if let overridingJoker = lastFaceUpJokerPlayerIndex(
            in: playedCards,
            excludingLeadCard: true
        ) {
            return overridingJoker
        }

        switch leadCard.jokerLeadDeclaration {
        case .wish, .none:
            return leadCard.playerIndex

        case .above(let requestedSuit):
            guard let trump, trump != requestedSuit else {
                return leadCard.playerIndex
            }

            let trumpCards = playedCards.filter { !$0.card.isJoker && $0.card.suit == trump }
            return highestCardPlayerIndex(in: trumpCards) ?? leadCard.playerIndex

        case .takes(let requestedSuit):
            if let trump {
                let trumpCards = playedCards.filter { !$0.card.isJoker && $0.card.suit == trump }
                if let winner = highestCardPlayerIndex(in: trumpCards) {
                    return winner
                }
            }

            let requestedSuitCards = playedCards.filter { !$0.card.isJoker && $0.card.suit == requestedSuit }
            return highestCardPlayerIndex(in: requestedSuitCards) ?? leadCard.playerIndex
        }
    }

    private static func winnerByStandardRules(
        playedCards: [PlayedTrickCard],
        trump: Suit?,
        leadSuit: Suit?
    ) -> Int {
        if let trump {
            let trumpCards = playedCards.filter { !$0.card.isJoker && $0.card.suit == trump }
            if let winner = highestCardPlayerIndex(in: trumpCards) {
                return winner
            }
        }

        guard let leadSuit else {
            return playedCards[0].playerIndex
        }

        let leadSuitCards = playedCards.filter { !$0.card.isJoker && $0.card.suit == leadSuit }

        // Если никто не поддержал масть первого хода, взятку забирает лидер.
        if leadSuitCards.count <= 1 {
            return playedCards[0].playerIndex
        }

        return highestCardPlayerIndex(in: leadSuitCards) ?? playedCards[0].playerIndex
    }

    private static func lastFaceUpJokerPlayerIndex(
        in playedCards: [PlayedTrickCard],
        excludingLeadCard: Bool = false
    ) -> Int? {
        let cardSlice = excludingLeadCard ? Array(playedCards.dropFirst()) : playedCards
        return cardSlice.last(where: { $0.isFaceUpJoker })?.playerIndex
    }

    private static func highestCardPlayerIndex(
        in playedCards: [PlayedTrickCard]
    ) -> Int? {
        guard var winningEntry = playedCards.first else { return nil }

        for candidate in playedCards.dropFirst() {
            // Здесь сравниваются карты одинаковой масти, поэтому trump не нужен.
            if candidate.card.beats(winningEntry.card, trump: nil) {
                winningEntry = candidate
            }
        }

        return winningEntry.playerIndex
    }
}
