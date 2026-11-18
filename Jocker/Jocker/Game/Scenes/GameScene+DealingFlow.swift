import SpriteKit

extension GameScene {
    func dealCards() {
        guard self.canDealCards else { self.updateDealButtonState(); return }
        self.removeAction(forKey: ActionKey.botTurn)
        self.resetTransientDealFlowState()
        self.coordinator.cancelPendingTrickResolution(on: self)
        guard self.coordinator.prepareForDealing(gameState: self.gameState, scoreManager: self.scoreManager, playerCount: self.playerCount) else {
            _ = self.tryPresentGameResultsIfNeeded()
            return
        }
        self.markDidDealAtLeastOnce()
        self.coordinator.markDidDeal()
        self.deck.reset()
        self.deck.shuffle()
        for player in self.players {
            player.hand.removeAllCards(animated: false)
            player.resetForNewRound()
        }
        self.trickNode.clearTrick(toPosition: self.trickNode.centerPosition, animated: false)
        self.currentTrump = nil
        self.clearJokerLeadInfo()
        self.flow = GameFlowResumeState()
        self.flow.bids = Array(repeating: 0, count: self.playerCount)
        self.flow.blindSelections = Array(repeating: false, count: self.playerCount)
        self.flow.answered = Array(repeating: false, count: self.playerCount)
        self.sessionState.pendingBids = self.flow.bids
        self.sessionState.pendingBlindSelections = self.flow.blindSelections
        self.dealHistoryStore.startDeal(blockIndex: self.gameState.currentBlock.rawValue - 1, roundIndex: self.gameState.currentRoundInBlock)
        self.flow.stage = self.gameState.currentBlock == .fourth ? .blind : .deal
        self.flow.order = self.biddingOrder()
        self.checkpoint()
        self.resumeSessionFlow()
    }

    func continueBlindFlow() {
        self.setPrimaryInteractionFlow(.preDealBlind)
        guard self.flow.step < self.flow.order.count else {
            self.clearPrimaryInteractionFlow(.preDealBlind)
            self.flow.stage = .deal
            self.checkpoint()
            self.runDealFlowForCurrentRound()
            return
        }
        let player = self.flow.order[self.flow.step]
        let generation = self.flowGeneration
        let step = self.flow.step
        let bids = self.gameState.allowedBids(forPlayer: player, bids: self.flow.bids)
        let canChoose = self.gameState.canChooseBlindBid(forPlayer: player, blindSelections: self.flow.blindSelections)
        let apply: (Bool, Int?) -> Void = { [weak self] blind, bid in
            guard let self, self.flowGeneration == generation, self.flow.step == step, !self.isSessionPaused, !self.isExitingSession else { return }
            let isBlind = blind && canChoose
            self.flow.bids[player] = isBlind ? (bid.flatMap { bids.contains($0) ? $0 : nil } ?? bids.first ?? 0) : 0
            self.flow.blindSelections[player] = isBlind
            self.flow.answered[player] = true
            self.flow.step += 1
            self.sessionState.pendingBids = self.flow.bids
            self.sessionState.pendingBlindSelections = self.flow.blindSelections
            if isBlind { self.players[player].setBid(self.flow.bids[player], isBlind: true, animated: true) }
            self.checkpoint()
            self.scheduleResume(after: 0.35)
        }
        if !canChoose { apply(false, nil) }
        else if self.isHumanPlayer(player) {
            self.requestHumanPreDealBlindChoice(context: .init(playerIndex: player, allowedBlindBids: bids, canChooseBlind: true), completion: apply)
        } else {
            let bid = self.botBiddingService(for: player).makePreDealBlindBid(playerIndex: player,
                dealerIndex: self.gameState.currentDealer, cardsInRound: self.gameState.currentCardsPerPlayer,
                allowedBlindBids: bids, canChooseBlind: true, totalScores: self.scoreManager.totalScoresIncludingCurrentBlock,
                matchContext: self.botMatchContext(for: player))
            apply(bid != nil, bid)
        }
    }

    func runDealFlowForCurrentRound() {
        let cards = self.gameState.currentCardsPerPlayer
        let first = (self.gameState.currentDealer + 1) % self.playerCount
        let rule = TrumpSelectionRules.rule(for: self.gameState.currentBlock, cardsPerPlayer: cards,
            dealerIndex: self.gameState.currentDealer, playerCount: self.playerCount)
        switch rule.strategy {
        case .automaticTopDeckCard:
            let deal = self.deck.dealCards(playerCount: self.playerCount, cardsPerPlayer: cards, startingPlayerIndex: first)
            self.displayDealtHands(deal.hands)
            self.currentTrump = deal.trump?.suit
            self.trumpIndicator.setTrumpSuit(self.currentTrump, animated: true)
            self.dealHistoryStore.setInitialHands(deal.hands, blockIndex: self.gameState.currentBlock.rawValue - 1, roundIndex: self.gameState.currentRoundInBlock)
            self.dealHistoryStore.setTrump(self.currentTrump, blockIndex: self.gameState.currentBlock.rawValue - 1, roundIndex: self.gameState.currentRoundInBlock)
            self.startBiddingFlowIfNeeded()
        case .playerOnDealerLeft:
            let initialCount = min(cards, rule.cardsToDealBeforeChoicePerPlayer)
            let initial = self.deck.dealCards(playerCount: self.playerCount, cardsPerPlayer: initialCount, startingPlayerIndex: first)
            let remaining = self.deck.dealCards(playerCount: self.playerCount, cardsPerPlayer: cards - initialCount, startingPlayerIndex: first)
            self.displayDealtHands(initial.hands)
            self.flow.remainingHands = remaining.hands.map { $0.map(CardSnapshot.init) }
            self.flow.chooser = rule.chooserPlayerIndex
            self.flow.stage = .trump
            self.dealHistoryStore.setInitialHands((0..<self.playerCount).map { initial.hands[$0] + remaining.hands[$0] },
                blockIndex: self.gameState.currentBlock.rawValue - 1, roundIndex: self.gameState.currentRoundInBlock)
            self.checkpoint()
            self.continueTrumpFlow()
        }
    }

    func continueTrumpFlow() {
        self.setPrimaryInteractionFlow(.trumpSelection)
        self.trumpIndicator.setAwaitingTrumpSelection(animated: false)
        let generation = self.flowGeneration
        self.requestTrumpChoice(context: .init(playerIndex: self.flow.chooser, handCards: self.players[self.flow.chooser].hand.cards)) { [weak self] trump in
            guard let self, self.flowGeneration == generation, !self.isSessionPaused, !self.isExitingSession else { return }
            self.currentTrump = trump
            self.trumpIndicator.setTrumpSuit(trump, animated: true)
            self.dealHistoryStore.setTrump(trump, blockIndex: self.gameState.currentBlock.rawValue - 1, roundIndex: self.gameState.currentRoundInBlock)
            for index in self.players.indices {
                let cards = self.flow.remainingHands[index].compactMap { try? $0.restore() }
                self.players[index].hand.addCards(cards, animated: false)
                self.players[index].hand.sortCardsStandard(animated: true)
            }
            self.flow.remainingHands = []
            self.clearPrimaryInteractionFlow(.trumpSelection)
            self.startBiddingFlowIfNeeded()
        }
    }

    private func displayDealtHands(_ hands: [[Card]]) {
        for index in self.players.indices {
            self.players[index].hand.addCards(hands[index], animated: false)
            self.players[index].hand.sortCardsStandard(animated: false)
            for (cardIndex, node) in self.players[index].hand.cardNodes.enumerated() {
                node.alpha = 0
                node.run(.sequence([.wait(forDuration: Double(cardIndex) * 0.04), .fadeIn(withDuration: 0.15)]))
            }
        }
    }
}
