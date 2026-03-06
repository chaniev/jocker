//
//  GameScene+BiddingFlow.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit

extension GameScene {
    // MARK: - Bidding Flow

    func startBiddingFlowIfNeeded() {
        guard gameState.phase == .bidding else { return }
        guard !isRunningBiddingFlow else { return }

        setPrimaryInteractionFlow(.bidding)
        if gameState.currentBlock != .fourth {
            sessionState.pendingBids = Array(repeating: 0, count: playerCount)
            sessionState.pendingBlindSelections = Array(repeating: false, count: playerCount)
        } else {
            if sessionState.pendingBids.count != playerCount {
                sessionState.pendingBids = Array(repeating: 0, count: playerCount)
            }
            if sessionState.pendingBlindSelections.count != playerCount {
                sessionState.pendingBlindSelections = Array(repeating: false, count: playerCount)
            }
        }

        let order = biddingOrder().filter { playerIndex in
            gameState.currentBlock != .fourth || !sessionState.pendingBlindSelections[playerIndex]
        }
        processBiddingStep(order: order, step: 0)
    }

    private func processBiddingStep(order: [Int], step: Int) {
        guard gameState.phase == .bidding else {
            clearPrimaryInteractionFlow(.bidding)
            sessionState.resetTransientDealFlowState()
            return
        }

        guard step < order.count else {
            let bids = sessionState.pendingBids
            let blindSelections = sessionState.pendingBlindSelections
            sessionState.resetTransientDealFlowState()
            clearPrimaryInteractionFlow(.bidding)
            applyBidsToGameStateAndStartPlaying(bids, blindSelections: blindSelections)
            return
        }

        let playerIndex = order[step]
        let allowedBids = gameState.allowedBids(forPlayer: playerIndex, bids: sessionState.pendingBids)
        let fallbackBid = allowedBids.first ?? 0
        let forbidden = forbiddenDealerBidIfNeeded(
            for: playerIndex,
            bids: sessionState.pendingBids
        )

        if isHumanPlayer(playerIndex) {
            let displayedBidsByPlayer = displayedBidsForBiddingModal(order: order, step: step)
            requestHumanBid(
                context: .init(
                    playerIndex: playerIndex,
                    handCards: players[playerIndex].hand.cards,
                    allowedBids: allowedBids,
                    displayedBidsByPlayer: displayedBidsByPlayer,
                    biddingOrder: biddingOrder(),
                    forbiddenBid: forbidden
                )
            ) { [weak self] selectedBid in
                guard let self = self else { return }
                guard self.gameState.phase == .bidding else { return }

                let resolvedBid = allowedBids.contains(selectedBid) ? selectedBid : fallbackBid
                self.sessionState.pendingBids[playerIndex] = resolvedBid
                self.players[playerIndex].setBid(resolvedBid, isBlind: false, animated: true)
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                self.processBiddingStep(order: order, step: step + 1)
            }
            return
        }

        let candidateBid = botBiddingService(for: playerIndex).makeBid(
            hand: players[playerIndex].hand.cards,
            cardsInRound: gameState.currentCardsPerPlayer,
            trump: currentTrump,
            forbiddenBid: forbidden,
            matchContext: botMatchContext(for: playerIndex)
        )
        let bid = allowedBids.contains(candidateBid) ? candidateBid : fallbackBid
        sessionState.pendingBids[playerIndex] = bid
        players[playerIndex].setBid(bid, isBlind: false, animated: true)
        updateGameInfoLabel()
        updateTurnUI(animated: true)

        run(
            .sequence([
                .wait(forDuration: timing(for: playerIndex).biddingStepDelay),
                .run { [weak self] in
                    self?.processBiddingStep(order: order, step: step + 1)
                }
            ])
        )
    }

    private func applyBidsToGameStateAndStartPlaying(_ bids: [Int], blindSelections: [Bool]) {
        guard bids.count == playerCount else { return }
        guard gameState.phase == .bidding else { return }

        let maxBid = max(0, gameState.currentCardsPerPlayer)
        var safetyCounter = 0

        while gameState.phase == .bidding && safetyCounter < playerCount {
            let playerIndex = gameState.currentPlayer
            var bid = min(max(bids[playerIndex], 0), maxBid)
            let allowedBids = gameState.allowedBids(forPlayer: playerIndex, bids: bids)
            if !allowedBids.contains(bid) {
                bid = allowedBids.first ?? 0
            }

            let isBlindBid = blindSelections.indices.contains(playerIndex)
                ? blindSelections[playerIndex]
                : false
            players[playerIndex].setBid(bid, isBlind: isBlindBid, animated: true)
            _ = gameState.placeBid(
                bid,
                forPlayer: playerIndex,
                isBlind: isBlindBid,
                lockBeforeDeal: isBlindBid
            )
            safetyCounter += 1
        }

        syncInProgressRoundResultsForScoreTable()
        updateGameInfoLabel()
        updateTurnUI(animated: true)
        runBotTurnIfNeeded()
    }

    private func displayedBidsForBiddingModal(order: [Int], step: Int) -> [Int?] {
        guard playerCount > 0 else { return [] }
        var displayedBids = Array(repeating: Optional<Int>.none, count: playerCount)
        let revealedPlayers = Set(order.prefix(step))

        for playerIndex in 0..<playerCount {
            let isBlindBid = sessionState.pendingBlindSelections.indices.contains(playerIndex)
                ? sessionState.pendingBlindSelections[playerIndex]
                : false
            let isRevealedInCurrentFlow = revealedPlayers.contains(playerIndex)
            guard isBlindBid || isRevealedInCurrentFlow else { continue }
            guard sessionState.pendingBids.indices.contains(playerIndex) else { continue }
            displayedBids[playerIndex] = sessionState.pendingBids[playerIndex]
        }

        return displayedBids
    }

    private func forbiddenDealerBidIfNeeded(for playerIndex: Int, bids: [Int]) -> Int? {
        return BiddingRules.dealerForbiddenBid(
            forPlayer: playerIndex,
            dealer: gameState.currentDealer,
            cardsInRound: gameState.currentCardsPerPlayer,
            bids: bids,
            playerCount: playerCount
        )
    }

    func biddingOrder() -> [Int] {
        return BiddingRules.biddingOrder(
            dealer: gameState.currentDealer,
            playerCount: playerCount
        )
    }
}
