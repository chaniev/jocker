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
    private enum DealingTiming {
        static let minStepDuration: TimeInterval = 0.055
        static let maxStepDuration: TimeInterval = 0.18
        static let targetDealDuration: TimeInterval = 2.2
        static let postDealPauseBeforeSort: TimeInterval = 0.3
        static let postSortPause: TimeInterval = 0.28
        static let postTrumpPauseBeforeHighlight: TimeInterval = 0.9
        static let postSortPauseBeforeStageCompletion: TimeInterval = 0.4
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
        let dealSteps = buildDealSteps(
            playerCount: playerCount,
            firstPlayerToDeal: firstPlayerToDeal,
            hands: hands
        )
        let dealStepDuration = stepDuration(forDealStepsCount: dealSteps.count)
        var actions = buildDealActions(
            dealSteps: dealSteps,
            players: players,
            stepDuration: dealStepDuration
        )

        actions.append(SKAction.wait(forDuration: DealingTiming.postDealPauseBeforeSort))
        actions.append(SKAction.run {
            players.forEach { $0.hand.sortCardsStandard(animated: true) }
        })
        actions.append(SKAction.wait(forDuration: DealingTiming.postSortPause))
        actions.append(SKAction.run {
            if let trumpCard {
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
        })
        actions.append(SKAction.wait(forDuration: DealingTiming.postTrumpPauseBeforeHighlight))
        actions.append(SKAction.run(onHighlightTurn))

        cancelDealSequence(on: scene)
        scene.run(SKAction.sequence(actions), withKey: ActionKey.dealSequence)
    }

    func runDealStage(
        on scene: SKNode,
        playerCount: Int,
        firstPlayerToDeal: Int,
        players: [PlayerNode],
        hands: [[Card]],
        onCompleted: @escaping () -> Void
    ) {
        let dealSteps = buildDealSteps(
            playerCount: playerCount,
            firstPlayerToDeal: firstPlayerToDeal,
            hands: hands
        )
        let dealStepDuration = stepDuration(forDealStepsCount: dealSteps.count)
        var actions = buildDealActions(
            dealSteps: dealSteps,
            players: players,
            stepDuration: dealStepDuration
        )

        actions.append(SKAction.wait(forDuration: DealingTiming.postDealPauseBeforeSort))
        actions.append(SKAction.run {
            players.forEach { $0.hand.sortCardsStandard(animated: true) }
        })
        actions.append(SKAction.wait(forDuration: DealingTiming.postSortPauseBeforeStageCompletion))
        actions.append(SKAction.run(onCompleted))

        cancelDealSequence(on: scene)
        scene.run(SKAction.sequence(actions), withKey: ActionKey.dealSequence)
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

    private func buildDealActions(
        dealSteps: [(playerIndex: Int, card: Card)],
        players: [PlayerNode],
        stepDuration: TimeInterval
    ) -> [SKAction] {
        var actions: [SKAction] = []
        actions.reserveCapacity(max(1, dealSteps.count * 2))

        for (index, step) in dealSteps.enumerated() {
            if index > 0 {
                actions.append(SKAction.wait(forDuration: stepDuration))
            }

            let player = players.indices.contains(step.playerIndex) ? players[step.playerIndex] : nil
            let card = step.card
            actions.append(SKAction.run { [weak player] in
                player?.hand.addCard(card, animated: true)
            })
        }

        return actions
    }

    private func buildDealSteps(
        playerCount: Int,
        firstPlayerToDeal: Int,
        hands: [[Card]]
    ) -> [(playerIndex: Int, card: Card)] {
        guard playerCount > 0 else { return [] }

        let maxCardsPerPlayer = hands.map(\.count).max() ?? 0
        guard maxCardsPerPlayer > 0 else { return [] }

        var steps: [(playerIndex: Int, card: Card)] = []
        steps.reserveCapacity(maxCardsPerPlayer * playerCount)

        for cardOffset in 0..<maxCardsPerPlayer {
            for playerOffset in 0..<playerCount {
                let playerIndex = normalizedPlayerIndex(
                    firstPlayerToDeal + playerOffset,
                    playerCount: playerCount
                )
                guard hands.indices.contains(playerIndex) else { continue }
                guard hands[playerIndex].indices.contains(cardOffset) else { continue }

                steps.append((playerIndex, hands[playerIndex][cardOffset]))
            }
        }

        return steps
    }

    private func normalizedPlayerIndex(_ index: Int, playerCount: Int) -> Int {
        guard playerCount > 0 else { return 0 }
        return ((index % playerCount) + playerCount) % playerCount
    }

    private func stepDuration(forDealStepsCount stepCount: Int) -> TimeInterval {
        guard stepCount > 0 else { return 0 }

        let adaptiveStep = DealingTiming.targetDealDuration / Double(stepCount)
        return min(
            DealingTiming.maxStepDuration,
            max(DealingTiming.minStepDuration, adaptiveStep)
        )
    }
}
