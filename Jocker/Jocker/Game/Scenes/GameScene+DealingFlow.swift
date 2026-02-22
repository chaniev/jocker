//
//  GameScene+DealingFlow.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit

extension GameScene {
    // MARK: - Dealing Flow

    func dealCards() {
        guard canDealCards else {
            updateDealButtonState()
            return
        }

        removeAction(forKey: ActionKey.botTurn)
        resetTransientDealFlowState()

        coordinator.cancelPendingTrickResolution(on: self)

        guard coordinator.prepareForDealing(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        ) else {
            updateGameInfoLabel()
            updateTurnUI(animated: true)
            updateDealButtonState()
            _ = tryPresentGameResultsIfNeeded()
            return
        }

        hasDealtAtLeastOnce = true
        updateDealButtonState()
        updateGameInfoLabel()
        updateTurnUI(animated: false)

        // Сбрасываем колоду и перемешиваем
        deck.reset()
        deck.shuffle()

        // Очищаем руки игроков и взятку
        for player in players {
            player.hand.removeAllCards(animated: true)
            player.resetForNewRound()
        }
        trickNode.clearTrick(
            toPosition: trickNode.centerPosition,
            animated: false
        )
        clearJokerLeadInfo()
        currentTrump = nil

        pendingBids = Array(repeating: 0, count: playerCount)
        pendingBlindSelections = Array(repeating: false, count: playerCount)

        let blockIndex = max(0, gameState.currentBlock.rawValue - 1)
        dealHistoryStore.startDeal(
            blockIndex: blockIndex,
            roundIndex: gameState.currentRoundInBlock
        )

        if gameState.currentBlock == .fourth {
            startPreDealBlindFlowIfNeeded { [weak self] in
                self?.runDealFlowForCurrentRound()
            }
            return
        }

        runDealFlowForCurrentRound()
    }

    private func runDealFlowForCurrentRound() {
        let cardsPerPlayer = gameState.currentCardsPerPlayer
        let firstPlayerToDeal = (gameState.currentDealer + 1) % playerCount
        let trumpRule = TrumpSelectionRules.rule(
            for: gameState.currentBlock,
            cardsPerPlayer: cardsPerPlayer,
            dealerIndex: gameState.currentDealer,
            playerCount: playerCount
        )

        switch trumpRule.strategy {
        case .automaticTopDeckCard:
            let dealResult = deck.dealCards(
                playerCount: playerCount,
                cardsPerPlayer: cardsPerPlayer,
                startingPlayerIndex: firstPlayerToDeal
            )
            let blockIndex = max(0, gameState.currentBlock.rawValue - 1)
            let roundIndex = gameState.currentRoundInBlock
            dealHistoryStore.setInitialHands(
                dealResult.hands,
                blockIndex: blockIndex,
                roundIndex: roundIndex
            )

            coordinator.runDealAnimation(
                on: self,
                playerCount: playerCount,
                firstPlayerToDeal: firstPlayerToDeal,
                players: players,
                hands: dealResult.hands,
                trumpCard: dealResult.trump,
                trumpIndicator: trumpIndicator,
                onTrumpResolved: { [weak self] trump in
                    guard let self else { return }
                    self.currentTrump = trump
                    let blockIndex = max(0, self.gameState.currentBlock.rawValue - 1)
                    self.dealHistoryStore.setTrump(
                        trump,
                        blockIndex: blockIndex,
                        roundIndex: self.gameState.currentRoundInBlock
                    )
                },
                onHighlightTurn: { [weak self] in
                    self?.updateTurnUI(animated: true)
                    self?.startBiddingFlowIfNeeded()
                }
            )
        case .playerOnDealerLeft:
            runPlayerChosenTrumpDealFlow(
                firstPlayerToDeal: firstPlayerToDeal,
                cardsPerPlayer: cardsPerPlayer,
                chooserPlayerIndex: trumpRule.chooserPlayerIndex,
                cardsToDealBeforeChoicePerPlayer: trumpRule.cardsToDealBeforeChoicePerPlayer
            )
        }

        coordinator.markDidDeal()
    }

    private func startPreDealBlindFlowIfNeeded(onCompleted: @escaping () -> Void) {
        guard gameState.phase == .bidding else {
            onCompleted()
            return
        }
        guard gameState.currentBlock == .fourth else {
            onCompleted()
            return
        }

        setPrimaryInteractionFlow(.preDealBlind)
        processPreDealBlindStep(order: biddingOrder(), step: 0, onCompleted: onCompleted)
    }

    private func processPreDealBlindStep(
        order: [Int],
        step: Int,
        onCompleted: @escaping () -> Void
    ) {
        guard gameState.phase == .bidding else {
            clearPrimaryInteractionFlow(.preDealBlind)
            onCompleted()
            return
        }

        guard step < order.count else {
            clearPrimaryInteractionFlow(.preDealBlind)
            onCompleted()
            return
        }

        let playerIndex = order[step]
        let allowedBlindBids = gameState.allowedBids(forPlayer: playerIndex, bids: pendingBids)
        let canChooseBlind = gameState.canChooseBlindBid(
            forPlayer: playerIndex,
            blindSelections: pendingBlindSelections
        )

        let applySelection: (_ isBlind: Bool, _ bid: Int?) -> Void = { [weak self] isBlind, bid in
            guard let self else { return }
            guard self.gameState.phase == .bidding else { return }

            if isBlind && canChooseBlind {
                let fallbackBlindBid = allowedBlindBids.first ?? 0
                let resolvedBlindBid: Int
                if let bid, allowedBlindBids.contains(bid) {
                    resolvedBlindBid = bid
                } else {
                    resolvedBlindBid = fallbackBlindBid
                }
                self.pendingBlindSelections[playerIndex] = true
                self.pendingBids[playerIndex] = resolvedBlindBid
                self.players[playerIndex].setBid(resolvedBlindBid, isBlind: true, animated: true)
            } else {
                self.pendingBlindSelections[playerIndex] = false
                self.pendingBids[playerIndex] = 0
            }

            self.updateGameInfoLabel()
            self.updateTurnUI(animated: true)

            self.run(
                .sequence([
                    .wait(forDuration: 0.2),
                    .run { [weak self] in
                        self?.processPreDealBlindStep(
                            order: order,
                            step: step + 1,
                            onCompleted: onCompleted
                        )
                    }
                ])
            )
        }

        if !canChooseBlind {
            applySelection(false, nil)
            return
        }

        if isHumanPlayer(playerIndex) {
            requestHumanPreDealBlindChoice(
                forPlayer: playerIndex,
                allowedBlindBids: allowedBlindBids,
                canChooseBlind: canChooseBlind,
                completion: applySelection
            )
            return
        }

        let blindBid = botBiddingService(for: playerIndex).makePreDealBlindBid(
            playerIndex: playerIndex,
            dealerIndex: gameState.currentDealer,
            cardsInRound: gameState.currentCardsPerPlayer,
            allowedBlindBids: allowedBlindBids,
            canChooseBlind: canChooseBlind,
            totalScores: scoreManager.totalScoresIncludingCurrentBlock
        )
        applySelection(blindBid != nil, blindBid)
    }

    private func runPlayerChosenTrumpDealFlow(
        firstPlayerToDeal: Int,
        cardsPerPlayer: Int,
        chooserPlayerIndex: Int,
        cardsToDealBeforeChoicePerPlayer: Int
    ) {
        let cardsBeforeChoice = min(cardsPerPlayer, max(0, cardsToDealBeforeChoicePerPlayer))
        let initialDeal = deck.dealCards(
            playerCount: playerCount,
            cardsPerPlayer: cardsBeforeChoice,
            startingPlayerIndex: firstPlayerToDeal
        )

        let remainingCardsPerPlayer = max(0, cardsPerPlayer - cardsBeforeChoice)
        let remainingDeal = deck.dealCards(
            playerCount: playerCount,
            cardsPerPlayer: remainingCardsPerPlayer,
            startingPlayerIndex: firstPlayerToDeal
        )
        let combinedHands = (0..<playerCount).map { index in
            let initialHand = initialDeal.hands.indices.contains(index) ? initialDeal.hands[index] : []
            let remainingHand = remainingDeal.hands.indices.contains(index) ? remainingDeal.hands[index] : []
            return initialHand + remainingHand
        }
        let blockIndex = max(0, gameState.currentBlock.rawValue - 1)
        let roundIndex = gameState.currentRoundInBlock
        dealHistoryStore.setInitialHands(
            combinedHands,
            blockIndex: blockIndex,
            roundIndex: roundIndex
        )

        setPrimaryInteractionFlow(.trumpSelection)
        trumpIndicator.setAwaitingTrumpSelection(animated: true)

        coordinator.runDealStageAnimation(
            on: self,
            playerCount: playerCount,
            firstPlayerToDeal: firstPlayerToDeal,
            players: players,
            hands: initialDeal.hands
        ) { [weak self] in
            guard let self else { return }
            let chooserHand = initialDeal.hands.indices.contains(chooserPlayerIndex)
                ? initialDeal.hands[chooserPlayerIndex]
                : []

            self.updateTurnUI(animated: true)
            self.requestTrumpChoice(
                forPlayer: chooserPlayerIndex,
                handCards: chooserHand
            ) { [weak self] selectedTrump in
                guard let self else { return }
                self.currentTrump = selectedTrump
                let blockIndex = max(0, self.gameState.currentBlock.rawValue - 1)
                self.dealHistoryStore.setTrump(
                    selectedTrump,
                    blockIndex: blockIndex,
                    roundIndex: self.gameState.currentRoundInBlock
                )
                let animateTrumpReveal = !self.isBotPlayer(chooserPlayerIndex)
                self.trumpIndicator.setTrumpSuit(selectedTrump, animated: animateTrumpReveal)

                if remainingCardsPerPlayer == 0 {
                    self.clearPrimaryInteractionFlow(.trumpSelection)
                    self.updateGameInfoLabel()
                    self.updateTurnUI(animated: true)
                    self.startBiddingFlowIfNeeded()
                    return
                }

                self.coordinator.runDealStageAnimation(
                    on: self,
                    playerCount: self.playerCount,
                    firstPlayerToDeal: firstPlayerToDeal,
                    players: self.players,
                    hands: remainingDeal.hands
                ) { [weak self] in
                    guard let self else { return }
                    self.clearPrimaryInteractionFlow(.trumpSelection)
                    self.updateGameInfoLabel()
                    self.updateTurnUI(animated: true)
                    self.startBiddingFlowIfNeeded()
                }
            }
        }
    }
}
