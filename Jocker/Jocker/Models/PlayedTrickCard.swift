//
//  PlayedTrickCard.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Карта, сыгранная во взятку, с контекстом розыгрыша джокера.
struct PlayedTrickCard: Equatable {
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

    var isFaceUpJoker: Bool {
        return card.isJoker && jokerPlayStyle == .faceUp
    }
}
