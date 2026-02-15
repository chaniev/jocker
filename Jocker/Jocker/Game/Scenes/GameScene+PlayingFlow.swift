//
//  GameScene+PlayingFlow.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit

extension GameScene {
    // MARK: - Playing Flow

    private func registerTrickWin(for playerIndex: Int) {
        guard playerIndex >= 0, playerIndex < playerCount else { return }
        clearJokerLeadInfo()
        trickNode.clearTrick(
            toPosition: players[playerIndex].position,
            animated: true
        ) { [weak self] in
            self?.runBotTurnIfNeeded()
        }
        gameState.completeTrick(winner: playerIndex)
        players[playerIndex].incrementTricks()
        coordinator.completeRoundIfNeeded(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )
        updateGameInfoLabel()
        updateTurnUI(animated: true)
    }

    func handleSelectedCardTap(playerIndex: Int, cardNode: CardNode) -> Bool {
        guard players.indices.contains(playerIndex) else { return false }
        guard isHumanPlayer(playerIndex) else { return false }

        let player = players[playerIndex]

        guard gameState.phase == .playing else { return false }
        guard playerIndex == gameState.currentPlayer else { return false }

        let selectedCard = cardNode.card
        guard trickNode.canPlayCard(selectedCard, fromHand: player.hand.cards, trump: currentTrump) else {
            return false
        }

        if selectedCard.isJoker {
            requestJokerDecisionAndPlay(
                cardNode: cardNode,
                playerIndex: playerIndex
            )
            return true
        }

        guard let card = player.hand.removeCardNode(cardNode, animated: true) else { return false }
        playCardOnTable(card, by: playerIndex)
        return true
    }

    private func playAutomaticCard(for playerIndex: Int) {
        guard players.indices.contains(playerIndex) else { return }
        guard isBotPlayer(playerIndex) else { return }

        guard !players[playerIndex].hand.cards.isEmpty else {
            assertionFailure("Bot turn requested with empty hand at player index \(playerIndex)")
            updateGameInfoLabel()
            updateTurnUI(animated: true)
            return
        }

        let bid = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].currentBid
            : nil
        let tricksTaken = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].tricksTaken
            : nil

        guard let turnDecision = coordinator.automaticTurnDecision(
            for: playerIndex,
            players: players,
            trickNode: trickNode,
            trump: currentTrump,
            bid: bid,
            tricksTaken: tricksTaken,
            cardsInRound: gameState.currentCardsPerPlayer
        ) else {
            return
        }

        let card = turnDecision.card
        _ = players[playerIndex].hand.removeCard(card, animated: true)
        playCardOnTable(
            card,
            by: playerIndex,
            jokerPlayStyle: turnDecision.jokerDecision.style,
            jokerLeadDeclaration: turnDecision.jokerDecision.leadDeclaration
        )
    }

    func playCardOnTable(
        _ card: Card,
        by playerIndex: Int,
        jokerPlayStyle: JokerPlayStyle = .faceUp,
        jokerLeadDeclaration: JokerLeadDeclaration? = nil
    ) {
        let isLeadCard = trickNode.playedCards.isEmpty
        if isLeadCard {
            clearJokerLeadInfo()
            if card.isJoker {
                showBotJokerLeadInfo(
                    for: playerIndex,
                    declaration: jokerLeadDeclaration
                )
            }
        }

        let targetPosition = trickTargetPosition(for: playerIndex)
        _ = trickNode.playCard(
            card,
            fromPlayer: playerIndex + 1,
            jokerPlayStyle: jokerPlayStyle,
            jokerLeadDeclaration: jokerLeadDeclaration,
            to: targetPosition,
            animated: true
        )

        gameState.playCard(byPlayer: playerIndex)

        if resolveTrickIfNeeded() {
            return
        }

        updateGameInfoLabel()
        updateTurnUI(animated: true)
        runBotTurnIfNeeded()
    }

    @discardableResult
    private func resolveTrickIfNeeded() -> Bool {
        return coordinator.resolveTrickIfNeeded(
            on: self,
            trickNode: trickNode,
            playerCount: playerCount,
            trump: currentTrump,
            resolutionDelay: botTuning.timing.trickResolutionDelay
        ) { [weak self] winnerIndex in
            guard let self = self else { return }
            self.registerTrickWin(for: winnerIndex)
        }
    }

    func selectedHandCard(at point: CGPoint) -> (playerIndex: Int, cardNode: CardNode)? {
        if let localPlayerIndex = players.firstIndex(where: { $0.isLocalPlayer }),
           players.indices.contains(localPlayerIndex),
           let localCardNode = selectedCard(in: players[localPlayerIndex].hand, at: point) {
            return (localPlayerIndex, localCardNode)
        }

        for node in nodes(at: point) {
            guard let tappedCardNode = cardNode(from: node) else { continue }
            guard let ownerPlayer: PlayerNode = findAncestor(from: tappedCardNode, as: PlayerNode.self, maxDepth: 16),
                  let ownerHand: CardHandNode = findAncestor(from: tappedCardNode, as: CardHandNode.self, maxDepth: 16),
                  ownerPlayer.hand === ownerHand else {
                continue
            }

            return (ownerPlayer.playerNumber - 1, tappedCardNode)
        }

        return nil
    }

    private func selectedCard(in hand: CardHandNode, at point: CGPoint) -> CardNode? {
        let tapPadding: CGFloat = 12
        let cardBounds = CGRect(
            x: -CardNode.cardWidth / 2 - tapPadding,
            y: -CardNode.cardHeight / 2 - tapPadding,
            width: CardNode.cardWidth + tapPadding * 2,
            height: CardNode.cardHeight + tapPadding * 2
        )

        let cardsSortedByTop = hand.cardNodes.sorted { lhs, rhs in
            if lhs.zPosition == rhs.zPosition {
                return lhs.position.x > rhs.position.x
            }
            return lhs.zPosition > rhs.zPosition
        }

        for cardNode in cardsSortedByTop {
            let pointInCard = convert(point, to: cardNode)
            if cardBounds.contains(pointInCard) {
                return cardNode
            }
        }

        return nil
    }

    private func cardNode(from node: SKNode) -> CardNode? {
        return findAncestor(from: node, as: CardNode.self, maxDepth: 12)
    }

    private func trickTargetPosition(for playerIndex: Int) -> CGPoint {
        let center = trickNode.centerPosition
        guard players.indices.contains(playerIndex) else { return center }

        let playerPosition = players[playerIndex].position
        let dx = playerPosition.x - center.x
        let dy = playerPosition.y - center.y
        let length = max(1.0, sqrt(dx * dx + dy * dy))

        // Лёгкое смещение к стороне игрока, чтобы карта ложилась в центральный слот "по месту хода".
        let normalizedX = dx / length
        let normalizedY = dy / length
        let horizontalRadius: CGFloat = 118
        let verticalRadius: CGFloat = 70

        return CGPoint(
            x: center.x + normalizedX * horizontalRadius,
            y: center.y + normalizedY * verticalRadius
        )
    }

    func runBotTurnIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            self?.scheduleBotTurnIfNeeded()
        }
    }

    private func scheduleBotTurnIfNeeded() {
        guard gameState.phase == .playing else { return }
        guard !isInteractionBlocked else { return }
        guard players.indices.contains(gameState.currentPlayer) else { return }
        guard isBotPlayer(gameState.currentPlayer) else { return }
        guard action(forKey: ActionKey.botTurn) == nil else { return }

        run(
            .sequence([
                .wait(forDuration: botTuning.timing.playingBotTurnDelay),
                .run { [weak self] in
                    guard let self = self else { return }
                    guard self.gameState.phase == .playing else { return }

                    if self.isInteractionBlocked {
                        self.runBotTurnIfNeeded()
                        return
                    }

                    let playerIndex = self.gameState.currentPlayer
                    guard self.isBotPlayer(playerIndex) else { return }
                    self.playAutomaticCard(for: playerIndex)
                }
            ]),
            withKey: ActionKey.botTurn
        )
    }
}
