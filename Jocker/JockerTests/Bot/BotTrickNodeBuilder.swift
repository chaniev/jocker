//
//  BotTrickNodeBuilder.swift
//  JockerTests
//
//  Created by Codex on 06.03.2026.
//

@testable import Jocker

enum BotTrickNodeBuilder {
    struct Move {
        let card: Card
        let playerNumber: Int
        let jokerPlayStyle: JokerPlayStyle
        let jokerLeadDeclaration: JokerLeadDeclaration?

        init(
            card: Card,
            fromPlayer playerNumber: Int = 1,
            jokerPlayStyle: JokerPlayStyle = .faceUp,
            jokerLeadDeclaration: JokerLeadDeclaration? = nil
        ) {
            self.card = card
            self.playerNumber = playerNumber
            self.jokerPlayStyle = jokerPlayStyle
            self.jokerLeadDeclaration = jokerLeadDeclaration
        }
    }

    static func make(rendersCards: Bool = false) -> TrickNode {
        return TrickNode(rendersCards: rendersCards)
    }

    static func make(
        moves: [Move],
        rendersCards: Bool = false
    ) -> TrickNode {
        let trickNode = make(rendersCards: rendersCards)
        for move in moves {
            play(
                move.card,
                fromPlayer: move.playerNumber,
                jokerPlayStyle: move.jokerPlayStyle,
                jokerLeadDeclaration: move.jokerLeadDeclaration,
                into: trickNode
            )
        }
        return trickNode
    }

    static func make(
        _ moves: Move...,
        rendersCards: Bool = false
    ) -> TrickNode {
        return make(moves: moves, rendersCards: rendersCards)
    }

    static func play(
        _ card: Card,
        fromPlayer playerNumber: Int = 1,
        jokerPlayStyle: JokerPlayStyle = .faceUp,
        jokerLeadDeclaration: JokerLeadDeclaration? = nil,
        into trickNode: TrickNode
    ) {
        _ = trickNode.playCard(
            card,
            fromPlayer: playerNumber,
            jokerPlayStyle: jokerPlayStyle,
            jokerLeadDeclaration: jokerLeadDeclaration,
            animated: false
        )
    }
}
