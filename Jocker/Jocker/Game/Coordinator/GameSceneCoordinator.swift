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

    convenience init(tuning: BotTuning) {
        self.init(turnService: GameTurnService(tuning: tuning))
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

    func runDealStageAnimation(
        on scene: SKNode,
        playerCount: Int,
        firstPlayerToDeal: Int,
        players: [PlayerNode],
        hands: [[Card]],
        onCompleted: @escaping () -> Void
    ) {
        animationService.runDealStage(
            on: scene,
            playerCount: playerCount,
            firstPlayerToDeal: firstPlayerToDeal,
            players: players,
            hands: hands,
            onCompleted: onCompleted
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

    func automaticTurnDecision(
        for playerIndex: Int,
        players: [PlayerNode],
        trickNode: TrickNode,
        trump: Suit?,
        bid: Int?,
        tricksTaken: Int?,
        cardsInRound: Int
    ) -> (card: Card, jokerDecision: JokerPlayDecision)? {
        guard players.indices.contains(playerIndex) else { return nil }
        return turnService.automaticTurnDecision(
            from: players[playerIndex].hand.cards,
            trickNode: trickNode,
            trump: trump,
            bid: bid,
            tricksTaken: tricksTaken,
            cardsInRound: cardsInRound,
            playerCount: players.count
        )
    }

    @discardableResult
    func resolveTrickIfNeeded(
        on scene: SKNode,
        trickNode: TrickNode,
        playerCount: Int,
        trump: Suit?,
        resolutionDelay: TimeInterval = BotTuning(difficulty: .hard).timing.trickResolutionDelay,
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
            self?.isResolvingTrick = false
            onResolved(winnerIndex)
        }

        return true
    }
}
