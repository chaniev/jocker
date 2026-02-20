//
//  GameAnimationService.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit

/// Сервис анимаций игровой сцены (раздача, резолв взятки).
final class GameAnimationService {
    private enum ActionKey {
        static let dealSequence = "GameAnimationService.dealSequence"
        static let resolveTrick = "resolveTrick"
    }

    func cancelDealSequence(on scene: SKNode) {
        scene.removeAction(forKey: ActionKey.dealSequence)
    }

    func runDealSequence(
        on scene: SKNode,
        playerCount: Int,
        firstPlayerToDeal: Int,
        players: [PlayerNode],
        hands: [[Card]],
        trumpCard: Card?,
        trumpIndicator: TrumpIndicator,
        onTrumpResolved: @escaping (Suit?) -> Void,
        onHighlightTurn: @escaping () -> Void
    ) {
        var actions: [SKAction] = []

        // 1. Раздача карт игрокам
        for offset in 0..<playerCount {
            let playerIndex = (firstPlayerToDeal + offset) % playerCount
            let player = players[playerIndex]
            let cards = hands[playerIndex]
            let delay = SKAction.wait(forDuration: Double(offset) * 0.3)
            let deal = SKAction.run { [weak player] in
                player?.hand.addCards(cards, animated: true)
            }
            actions.append(SKAction.sequence([delay, deal]))
        }

        // 2. Сортировка рук
        let sortDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 1.0)
        let sortAction = SKAction.run {
            players.forEach { $0.hand.sortCardsStandard(animated: true) }
        }
        actions.append(SKAction.sequence([sortDelay, sortAction]))

        // 3. Показ козыря
        let trumpDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 0.5)
        let trumpAction = SKAction.run {
            if let trumpCard = trumpCard {
                trumpIndicator.setTrumpCard(trumpCard, animated: true)
                if case .regular(let suit, _) = trumpCard {
                    onTrumpResolved(suit)
                } else {
                    onTrumpResolved(nil)
                }
            } else {
                trumpIndicator.setTrumpSuit(nil, animated: true)
                onTrumpResolved(nil)
            }
        }
        actions.append(SKAction.sequence([trumpDelay, trumpAction]))

        // 4. Подсветка текущего игрока
        let highlightDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 2.2)
        let highlightAction = SKAction.run(onHighlightTurn)
        actions.append(SKAction.sequence([highlightDelay, highlightAction]))

        cancelDealSequence(on: scene)
        scene.run(SKAction.group(actions), withKey: ActionKey.dealSequence)
    }

    func runDealStage(
        on scene: SKNode,
        playerCount: Int,
        firstPlayerToDeal: Int,
        players: [PlayerNode],
        hands: [[Card]],
        onCompleted: @escaping () -> Void
    ) {
        var actions: [SKAction] = []

        for offset in 0..<playerCount {
            let playerIndex = (firstPlayerToDeal + offset) % playerCount
            let player = players[playerIndex]
            let cards = hands.indices.contains(playerIndex) ? hands[playerIndex] : []
            let delay = SKAction.wait(forDuration: Double(offset) * 0.3)
            let deal = SKAction.run { [weak player] in
                guard !cards.isEmpty else { return }
                player?.hand.addCards(cards, animated: true)
            }
            actions.append(SKAction.sequence([delay, deal]))
        }

        let sortDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 1.0)
        let sortAction = SKAction.run {
            players.forEach { $0.hand.sortCardsStandard(animated: true) }
        }
        actions.append(SKAction.sequence([sortDelay, sortAction]))

        let completionDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 1.4)
        let completionAction = SKAction.run(onCompleted)
        actions.append(SKAction.sequence([completionDelay, completionAction]))

        cancelDealSequence(on: scene)
        scene.run(SKAction.group(actions), withKey: ActionKey.dealSequence)
    }

    func cancelTrickResolution(on scene: SKNode) {
        scene.removeAction(forKey: ActionKey.resolveTrick)
    }

    func scheduleTrickResolution(
        on scene: SKNode,
        delay: TimeInterval,
        completion: @escaping () -> Void
    ) {
        let wait = SKAction.wait(forDuration: delay)
        let resolve = SKAction.run(completion)
        scene.run(SKAction.sequence([wait, resolve]), withKey: ActionKey.resolveTrick)
    }
}
