//
//  GameSceneCoordinator.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit

/// Координатор игровой сцены: склеивает сервисы раунда, хода и анимации.
final class GameSceneCoordinator {
    private let roundService: GameRoundService
    private let turnService: GameTurnService
    private let animationService: GameAnimationService

    private var isResolvingTrick = false

    init(
        roundService: GameRoundService = GameRoundService(),
        turnService: GameTurnService = GameTurnService(),
        animationService: GameAnimationService = GameAnimationService()
    ) {
        self.roundService = roundService
        self.turnService = turnService
        self.animationService = animationService
    }

    var isInteractionLocked: Bool {
        return isResolvingTrick
    }

    func cancelPendingTrickResolution(on scene: SKNode) {
        animationService.cancelTrickResolution(on: scene)
        isResolvingTrick = false
    }

    func prepareForDealing(
        gameState: GameState,
        scoreManager: ScoreManager?,
        playerCount: Int
    ) -> Bool {
        return roundService.prepareForDealing(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )
    }

    func markDidDeal() {
        roundService.markDidDeal()
    }

    func runDealAnimation(
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
        animationService.runDealSequence(
            on: scene,
            playerCount: playerCount,
            firstPlayerToDeal: firstPlayerToDeal,
            players: players,
            hands: hands,
            trumpCard: trumpCard,
            trumpIndicator: trumpIndicator,
            onTrumpResolved: onTrumpResolved,
            onHighlightTurn: onHighlightTurn
        )
    }

    func completeRoundIfNeeded(
        gameState: GameState,
        scoreManager: ScoreManager?,
        playerCount: Int
    ) {
        roundService.completeRoundIfNeeded(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )
    }

    func automaticCard(
        for playerIndex: Int,
        players: [PlayerNode],
        trickNode: TrickNode,
        trump: Suit?
    ) -> Card? {
        guard players.indices.contains(playerIndex) else { return nil }
        return turnService.automaticCard(
            from: players[playerIndex].hand.cards,
            trickNode: trickNode,
            trump: trump
        )
    }

    @discardableResult
    func resolveTrickIfNeeded(
        on scene: SKNode,
        trickNode: TrickNode,
        playerCount: Int,
        trump: Suit?,
        resolutionDelay: TimeInterval = 0.55,
        onResolved: @escaping (Int) -> Void
    ) -> Bool {
        guard !isResolvingTrick else { return true }

        guard let winnerIndex = turnService.trickWinnerIndex(
            trickNode: trickNode,
            playerCount: playerCount,
            trump: trump
        ) else {
            return false
        }

        isResolvingTrick = true
        animationService.scheduleTrickResolution(
            on: scene,
            delay: resolutionDelay
        ) { [weak self] in
            onResolved(winnerIndex)
            self?.isResolvingTrick = false
        }

        return true
    }
}
