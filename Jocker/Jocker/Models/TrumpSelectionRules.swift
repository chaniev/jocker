//
//  TrumpSelectionRules.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Правила выбора козыря в зависимости от блока и параметров раунда.
struct TrumpSelectionRules {
    enum Strategy: Equatable {
        /// Козырь автоматически определяется верхней неразданной картой.
        case automaticTopDeckCard
        /// Козырь выбирает игрок слева от дилера (возможен вариант "без козыря").
        case playerOnDealerLeft
    }

    struct Rule: Equatable {
        let strategy: Strategy
        let chooserPlayerIndex: Int
        let cardsToDealBeforeChoicePerPlayer: Int
    }

    static func rule(
        for block: GameBlock,
        cardsPerPlayer: Int,
        dealerIndex: Int,
        playerCount: Int
    ) -> Rule {
        let safePlayerCount = max(1, playerCount)
        let chooserIndex = normalizedPlayerIndex(dealerIndex + 1, playerCount: safePlayerCount)
        let safeCardsPerPlayer = max(0, cardsPerPlayer)

        switch block {
        case .first, .third:
            return Rule(
                strategy: .automaticTopDeckCard,
                chooserPlayerIndex: chooserIndex,
                cardsToDealBeforeChoicePerPlayer: safeCardsPerPlayer
            )
        case .second, .fourth:
            return Rule(
                strategy: .playerOnDealerLeft,
                chooserPlayerIndex: chooserIndex,
                cardsToDealBeforeChoicePerPlayer: cardsToDealForPlayerChoice(cardsPerPlayer: safeCardsPerPlayer)
            )
        }
    }

    private static func cardsToDealForPlayerChoice(cardsPerPlayer: Int) -> Int {
        guard cardsPerPlayer > 0 else { return 0 }
        return max(1, cardsPerPlayer / 3)
    }

    private static func normalizedPlayerIndex(_ index: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((index % playerCount) + playerCount) % playerCount
    }
}
