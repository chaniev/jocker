//
//  DealTrickMove.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// Один ход игрока во взятке.
struct DealTrickMove: Equatable {
    let playerIndex: Int
    let card: Card
    let jokerPlayStyle: JokerPlayStyle
    let jokerLeadDeclaration: JokerLeadDeclaration?

    init(
        playerIndex: Int,
        card: Card,
        jokerPlayStyle: JokerPlayStyle = .faceUp,
        jokerLeadDeclaration: JokerLeadDeclaration? = nil
    ) {
        self.playerIndex = playerIndex
        self.card = card
        self.jokerPlayStyle = card.isJoker ? jokerPlayStyle : .faceUp
        self.jokerLeadDeclaration = card.isJoker ? jokerLeadDeclaration : nil
    }
}
