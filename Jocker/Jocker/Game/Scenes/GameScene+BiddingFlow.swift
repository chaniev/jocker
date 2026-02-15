//
//  GameScene+BiddingFlow.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit

extension GameScene {
    // MARK: - Bidding Flow

    func applyOrderedTricks(_ bids: [Int]) {
        guard bids.count == playerCount else { return }
        guard gameState.phase == .bidding else { return }
        pendingBids = bids
        if pendingBlindSelections.count != playerCount {
            pendingBlindSelections = Array(repeating: false, count: playerCount)
        }
        isRunningBiddingFlow = false
        applyBidsToGameStateAndStartPlaying(bids, blindSelections: pendingBlindSelections)
    }

    func presentTricksOrder() {
        let playerNames = gameState.players.map { $0.name }
        let currentBids = gameState.players.map { $0.currentBid }
        onTricksButtonTapped?(playerNames, gameState.currentCardsPerPlayer, currentBids, gameState.currentDealer)
    }

    func startBiddingFlowIfNeeded() {
        guard gameState.phase == .bidding else { return }
        guard !isRunningBiddingFlow else { return }

        isRunningBiddingFlow = true
        if gameState.currentBlock != .fourth {
            pendingBids = Array(repeating: 0, count: playerCount)
            pendingBlindSelections = Array(repeating: false, count: playerCount)
        } else {
            if pendingBids.count != playerCount {
                pendingBids = Array(repeating: 0, count: playerCount)
            }
            if pendingBlindSelections.count != playerCount {
                pendingBlindSelections = Array(repeating: false, count: playerCount)
            }
        }

        let order = biddingOrder().filter { playerIndex in
            gameState.currentBlock != .fourth || !pendingBlindSelections[playerIndex]
        }
        processBiddingStep(order: order, step: 0)
    }

    private func processBiddingStep(order: [Int], step: Int) {
        guard gameState.phase == .bidding else {
            isRunningBiddingFlow = false
            pendingBids.removeAll()
            pendingBlindSelections.removeAll()
            return
        }

        guard step < order.count else {
            let bids = pendingBids
            let blindSelections = pendingBlindSelections
            pendingBids.removeAll()
            pendingBlindSelections.removeAll()
            isRunningBiddingFlow = false
            applyBidsToGameStateAndStartPlaying(bids, blindSelections: blindSelections)
            return
        }

        let playerIndex = order[step]
        let allowedBids = gameState.allowedBids(forPlayer: playerIndex, bids: pendingBids)
        let fallbackBid = allowedBids.first ?? 0
        let forbidden = forbiddenDealerBidIfNeeded(
            for: playerIndex,
            bids: pendingBids
        )

        if isHumanPlayer(playerIndex) {
            let displayedBidsByPlayer = displayedBidsForBiddingModal(order: order, step: step)
            requestHumanBid(
                forPlayer: playerIndex,
                handCards: players[playerIndex].hand.cards,
                allowedBids: allowedBids,
                displayedBidsByPlayer: displayedBidsByPlayer,
                biddingOrder: biddingOrder(),
                forbiddenBid: forbidden
            ) { [weak self] selectedBid in
                guard let self = self else { return }
                guard self.gameState.phase == .bidding else { return }

                let resolvedBid = allowedBids.contains(selectedBid) ? selectedBid : fallbackBid
                self.pendingBids[playerIndex] = resolvedBid
                self.players[playerIndex].setBid(resolvedBid, isBlind: false, animated: true)
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                self.processBiddingStep(order: order, step: step + 1)
            }
            return
        }

        let candidateBid = botBiddingService.makeBid(
            hand: players[playerIndex].hand.cards,
            cardsInRound: gameState.currentCardsPerPlayer,
            trump: currentTrump,
            forbiddenBid: forbidden
        )
        let bid = allowedBids.contains(candidateBid) ? candidateBid : fallbackBid
        pendingBids[playerIndex] = bid
        players[playerIndex].setBid(bid, isBlind: false, animated: true)
        updateGameInfoLabel()
        updateTurnUI(animated: true)

        run(
            .sequence([
                .wait(forDuration: botTuning.timing.biddingStepDelay),
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
            let isBlindBid = pendingBlindSelections.indices.contains(playerIndex)
                ? pendingBlindSelections[playerIndex]
                : false
            let isRevealedInCurrentFlow = revealedPlayers.contains(playerIndex)
            guard isBlindBid || isRevealedInCurrentFlow else { continue }
            guard pendingBids.indices.contains(playerIndex) else { continue }
            displayedBids[playerIndex] = pendingBids[playerIndex]
        }

        return displayedBids
    }

    private func forbiddenDealerBidIfNeeded(for playerIndex: Int, bids: [Int]) -> Int? {
        guard playerIndex == gameState.currentDealer else { return nil }
        guard playerCount > 1 else { return nil }

        let totalWithoutDealer = bids.enumerated().reduce(0) { partial, pair in
            let (index, bid) = pair
            return partial + ((index == gameState.currentDealer) ? 0 : bid)
        }

        let forbidden = gameState.currentCardsPerPlayer - totalWithoutDealer
        guard forbidden >= 0 && forbidden <= gameState.currentCardsPerPlayer else { return nil }
        return forbidden
    }

    func biddingOrder() -> [Int] {
        guard playerCount > 0 else { return [] }
        let start = (gameState.currentDealer + 1) % playerCount
        return (0..<playerCount).map { offset in
            (start + offset) % playerCount
        }
    }
}
