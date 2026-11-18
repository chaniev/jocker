import SpriteKit
import UIKit

extension GameScene {
    func makeSessionSnapshot(revision: Int) -> GameSessionSnapshot {
        GameSessionSnapshot(matchID: self.persistence?.matchID ?? UUID(), revision: revision,
            slot: GameSessionSlot(playerCount: self.playerCount, gameMode: self.gameMode),
            controls: self.playerControlTypes.map { $0 == .human ? "human" : "bot" },
            difficulties: (0..<self.playerCount).map { self.botDifficulty(for: $0).rawValue },
            firstDealer: self.firstDealerIndex, state: GameStateSnapshot(self.gameState),
            scores: ScoreManagerSnapshot(self.scoreManager), roundService: self.coordinator.roundSnapshot,
            history: self.dealHistoryStore.snapshot(), flow: self.flow,
            hands: self.players.map { $0.hand.cards.map(CardSnapshot.init) }, deck: self.deck.cards.map(CardSnapshot.init),
            trick: self.trickNode.playedCards.map { DealTrickMoveSnapshot(DealTrickMove(playerIndex: $0.playerIndex, card: $0.card, jokerPlayStyle: $0.jokerPlayStyle, jokerLeadDeclaration: $0.jokerLeadDeclaration)) },
            trump: self.currentTrump.map(CardSnapshot.identifier), lastPresentedBlock: self.sessionState.lastPresentedBlockResultsCount)
    }

    func checkpoint(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let persistence = self.persistence else { completion?(.success(())); return }
        guard self.flow.stage != .terminal, !self.terminalCommitted else { completion?(.failure(GameSessionError.retiredMatch)); return }
        self.syncInProgressRoundResultsForScoreTable()
        persistence.save(self.makeSessionSnapshot(revision: persistence.nextRevision()), completion: completion)
    }

    func restoreSession(_ snapshot: GameSessionSnapshot) throws {
        try snapshot.validate()
        try snapshot.state.restore(into: self.gameState)
        try snapshot.scores.restore(into: self.scoreManager)
        try self.dealHistoryStore.restore(snapshot.history)
        self.coordinator.restoreRound(snapshot.roundService)
        self.firstDealerIndex = snapshot.firstDealer
        self.deck.restore(cards: try snapshot.deck.map { try $0.restore() })
        self.currentTrump = try snapshot.trump.map(GameSessionSnapshot.decodeSuit)
        self.flow = snapshot.flow
        self.sessionState.pendingBids = snapshot.flow.bids
        self.sessionState.pendingBlindSelections = snapshot.flow.blindSelections
        self.sessionState.hasDealtAtLeastOnce = snapshot.roundService.hasDealt
        self.sessionState.lastPresentedBlockResultsCount = snapshot.lastPresentedBlock
        for index in self.players.indices {
            let player = self.players[index]
            player.hand.removeAllCards(animated: false)
            player.hand.removeAllChildren()
            player.hand.addCards(try snapshot.hands[index].map { try $0.restore() }, animated: false)
            player.resetForNewRound()
            let saved = snapshot.state.players[index]
            let bid = snapshot.flow.bids.indices.contains(index) ? snapshot.flow.bids[index] : saved.bid
            let blind = snapshot.flow.blindSelections.indices.contains(index) ? snapshot.flow.blindSelections[index] : saved.blind
            player.setBid(bid, isBlind: blind, animated: false)
            for _ in 0..<saved.tricks { player.incrementTricks() }
        }
        self.trickNode.clearTrick(toPosition: self.trickNode.centerPosition, animated: false)
        self.trickNode.removeAllChildren()
        for saved in snapshot.trick {
            let move = try saved.restore()
            _ = self.trickNode.playCard(move.card, fromPlayer: move.playerIndex + 1,
                jokerPlayStyle: move.jokerPlayStyle, jokerLeadDeclaration: move.jokerLeadDeclaration,
                to: self.trickTargetPosition(for: move.playerIndex), animated: false)
        }
        self.trumpIndicator.setTrumpSuit(self.currentTrump, animated: false)
        self.resetAllInteractionFlowState()
        self.updateGameInfoLabel()
        self.updateTurnUI(animated: false)
        self.updateDealButtonState()
    }

    func scheduleResume(after delay: TimeInterval) {
        let generation = self.flowGeneration
        self.run(.sequence([.wait(forDuration: delay), .run { [weak self] in
            guard let self, self.flowGeneration == generation else { return }
            self.resumeSessionFlow()
        }]), withKey: "sessionContinuation")
    }

    func resumeSessionFlow() {
        guard !self.isSessionPaused, !self.isExitingSession else { return }
        self.updateGameInfoLabel()
        self.updateTurnUI(animated: false)
        self.updateDealButtonState()
        switch self.flow.stage {
        case .readyToDeal: break
        case .blind: self.continueBlindFlow()
        case .deal: self.runDealFlowForCurrentRound()
        case .trump: self.continueTrumpFlow()
        case .bidding: self.processBiddingStep(order: self.flow.order, step: self.flow.step)
        case .playing:
            if self.trickNode.playedCards.count == self.playerCount,
               let winner = TrickTakingResolver.winnerPlayerIndex(playedCards: self.trickNode.playedCards, trump: self.currentTrump) {
                self.registerTrickWin(for: winner)
            } else { self.runBotTurnIfNeeded() }
        case .joker:
            let player = self.gameState.currentPlayer
            if let card = self.players[player].hand.cardNodes.first(where: { $0.card.isJoker }) {
                self.requestJokerDecisionAndPlay(cardNode: card, playerIndex: player)
            }
        case .roundEnd:
            _ = self.tryPresentBlockResultsIfNeeded()
            _ = self.tryPresentGameResultsIfNeeded()
        case .terminal:
            if self.terminalCommitted { _ = self.tryPresentGameResultsIfNeeded() }
            else { self.commitTerminalSession() }
        }
    }

    func pauseSession() {
        guard !self.isSessionPaused, !self.isExitingSession else { return }
        self.isSessionPaused = true
        self.flowGeneration += 1
        self.removeAllActions()
        self.enumerateChildNodes(withName: "//*") { node, _ in node.removeAllActions() }
        self.coordinator.cancelPendingTrickResolution(on: self)
        if self.flow.stage != .terminal { self.checkpoint() }
    }

    func foregroundSession() {
        guard self.isSessionPaused, !self.isExitingSession else { return }
        self.settleSessionPresentation()
        if self.persistence != nil {
            let live = self.makeSessionSnapshot(revision: self.persistence?.liveRevision ?? 0)
            do { try self.restoreSession(live) }
            catch { self.showSessionError(message: "Не удалось восстановить отображение игры."); return }
        }
        self.isSessionPaused = false
        if self.terminalCommitted { self.sessionState.hasPresentedGameResultsModal = false }
        self.resetAllInteractionFlowState()
        self.resumeSessionFlow()
    }

    func exitSession(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !self.isExitingSession else { return }
        self.pauseSession()
        self.isExitingSession = true
        self.flowGeneration += 1
        if self.terminalInFlight, let persistence = self.persistence {
            persistence.store.recover { [weak self] _ in
                completion(self?.terminalCommitted == true ? .success(()) : .failure(GameSessionError.invalidSnapshot))
            }
            return
        }
        if self.terminalCommitted { completion(.success(())); return }
        if self.flow.stage == .terminal { completion(.failure(GameSessionError.invalidSnapshot)); return }
        self.checkpoint(completion: completion)
    }

    func commitTerminalSession() {
        guard !self.terminalInFlight, !self.terminalCommitted, let persistence = self.persistence else { return }
        self.flow.stage = .terminal
        self.terminalInFlight = true
        let snapshot = self.makeSessionSnapshot(revision: persistence.nextRevision())
        persistence.store.markTerminal(snapshot) { [weak self] result in
            guard let self else { return }
            self.terminalInFlight = false
            switch result {
            case .success:
                self.terminalCommitted = true
                persistence.store.recover { [weak self] recovery in
                    guard let self, !self.isExitingSession else { return }
                    if case .failure = recovery {
                        self.showSessionError(message: "Итог сохранён. Не удалось обновить статистику или историю; запись будет повторена при следующем запуске.", completion: { _ = self.tryPresentGameResultsIfNeeded() })
                    } else { _ = self.tryPresentGameResultsIfNeeded() }
                }
            case .failure:
                guard !self.isExitingSession else { return }
                let alert = UIAlertController(title: "Не удалось сохранить итог", message: "Повторите запись или выйдите в меню. При выходе несохранённый результат будет потерян.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in self?.commitTerminalSession() })
                alert.addAction(UIAlertAction(title: "Выйти в меню", style: .destructive) { [weak self] _ in self?.onExitRequested?() })
                _ = self.modalPresenter.presentOverlay(alert, from: self.view)
            }
        }
    }

    func installExitButton(on controller: UIViewController) {
        guard self.onExitRequested != nil else { return }
        let button = UIButton(type: .system)
        button.setTitle("В меню", for: .normal)
        button.accessibilityIdentifier = controller is GameViewController ? "session_exit_button" : "session_modal_exit_button"
        if !(controller is GameViewController) { controller.view.accessibilityViewIsModal = true }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
        button.backgroundColor = UIColor(red: 0.13, green: 0.35, blue: 0.20, alpha: 0.95)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.7).cgColor
        button.addAction(UIAction { [weak self] _ in self?.onExitRequested?() }, for: .touchUpInside)
        controller.view.addSubview(button)
        let leading = button.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor,
            constant: controller is GameViewController ? self.tableExitLeadingInset() : 16)
        if controller is GameViewController { self.tableExitLeadingConstraint = leading }
        NSLayoutConstraint.activate([
            leading,
            button.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor, constant: 4),
            button.widthAnchor.constraint(equalToConstant: 90), button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func showSessionError(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Сохранение игры", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default) { _ in completion?() })
        _ = self.modalPresenter.presentOverlay(alert, from: self.view)
    }
}
