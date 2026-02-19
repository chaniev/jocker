//
//  DealTrainingMoveSample.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// Training-сэмпл одного хода внутри раздачи: state + action + outcome.
struct DealTrainingMoveSample: Equatable {
    let blockIndex: Int
    let roundIndex: Int
    let trickIndex: Int
    let moveIndexInTrick: Int

    let playerIndex: Int
    let playerCount: Int
    let cardsInRound: Int
    let trump: Suit?
    let playerBid: Int?
    let playerTricksTakenBeforeMove: Int?

    let handBeforeMove: [Card]
    let legalCards: [Card]
    let playedCardsInTrickBeforeMove: [DealTrickMove]

    let selectedCard: Card
    let selectedJokerPlayStyle: JokerPlayStyle
    let selectedJokerLeadDeclaration: JokerLeadDeclaration?

    let trickWinnerPlayerIndex: Int
    let didPlayerWinTrick: Bool
}
