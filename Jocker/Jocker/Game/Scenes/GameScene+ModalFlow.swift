//
//  GameScene+ModalFlow.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import SpriteKit
import UIKit

extension GameScene {
    // MARK: - Modal Flow

    @discardableResult
    func presentGameResultsModal(playerSummaries: [GameFinalPlayerSummary]) -> Bool {
        guard !playerSummaries.isEmpty else { return false }
        guard !isGameResultsModalPresented else { return true }

        let modal = GameResultsViewController(
            playerSummaries: playerSummaries,
            onClose: { [weak self] in
                self?.dismissGameViewControllerToStartScreen()
            }
        )
        return presentOverlayModal(modal)
    }

    func requestTrumpChoice(
        forPlayer playerIndex: Int,
        handCards: [Card],
        completion: @escaping (Suit?) -> Void
    ) {
        let fallbackTrump = botTrumpSelectionService.selectTrump(from: handCards)

        if isBotPlayer(playerIndex) {
            completion(fallbackTrump)
            return
        }

        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : "Игрок \(playerIndex + 1)"

        isAwaitingHumanTrumpChoice = true
        let modal = TrumpSelectionViewController(
            playerName: playerName,
            handCards: handCards
        ) { [weak self] selectedSuit in
            self?.isAwaitingHumanTrumpChoice = false
            completion(selectedSuit)
        }
        if !presentOverlayModal(modal) {
            isAwaitingHumanTrumpChoice = false
            completion(fallbackTrump)
        }
    }

    func requestHumanBid(
        forPlayer playerIndex: Int,
        handCards: [Card],
        allowedBids: [Int],
        displayedBidsByPlayer: [Int?],
        biddingOrder: [Int],
        forbiddenBid: Int?,
        completion: @escaping (Int) -> Void
    ) {
        let normalizedAllowedBids = Array(Set(allowedBids)).sorted()
        guard !normalizedAllowedBids.isEmpty else {
            completion(0)
            return
        }

        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : "Игрок \(playerIndex + 1)"

        isAwaitingHumanBidChoice = true

        let modal = BidSelectionViewController(
            playerName: playerName,
            handCards: handCards,
            allowedBids: normalizedAllowedBids,
            maxBid: gameState.currentCardsPerPlayer,
            playerNames: gameState.players.map { $0.name },
            displayedBidsByPlayer: displayedBidsByPlayer,
            biddingOrder: biddingOrder,
            currentPlayerIndex: playerIndex,
            forbiddenBid: forbiddenBid
        ) { [weak self] selectedBid in
            self?.isAwaitingHumanBidChoice = false
            completion(selectedBid)
        }
        if !presentOverlayModal(modal) {
            isAwaitingHumanBidChoice = false
            completion(normalizedAllowedBids[0])
        }
    }

    func requestHumanPreDealBlindChoice(
        forPlayer playerIndex: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        completion: @escaping (_ isBlind: Bool, _ bid: Int?) -> Void
    ) {
        let normalizedAllowedBlindBids = Array(Set(allowedBlindBids)).sorted()

        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : "Игрок \(playerIndex + 1)"

        isAwaitingHumanBlindChoice = true

        let modal = BidSelectionViewController(
            playerName: playerName,
            allowedBlindBids: normalizedAllowedBlindBids,
            canChooseBlind: canChooseBlind
        ) { [weak self] isBlind, bid in
            self?.isAwaitingHumanBlindChoice = false
            completion(isBlind, bid)
        }
        if !presentOverlayModal(modal) {
            isAwaitingHumanBlindChoice = false
            completion(false, nil)
        }
    }

    func requestJokerDecisionAndPlay(cardNode: CardNode, playerIndex: Int) {
        let isLeadCard = trickNode.playedCards.isEmpty
        let fallbackDecision = isLeadCard ? JokerPlayDecision.defaultLead : JokerPlayDecision.defaultNonLead
        isAwaitingJokerDecision = true

        let applyDecision: (JokerPlayDecision?) -> Void = { [weak self, weak cardNode] decision in
            guard let self = self else { return }
            self.isAwaitingJokerDecision = false

            guard self.players.indices.contains(playerIndex),
                  self.gameState.phase == .playing,
                  self.gameState.currentPlayer == playerIndex else {
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                return
            }

            guard let resolvedDecision = decision else {
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                return
            }

            guard let cardNode,
                  let card = self.players[playerIndex].hand.removeCardNode(cardNode, animated: true) else {
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                return
            }

            self.playCardOnTable(
                card,
                by: playerIndex,
                jokerPlayStyle: resolvedDecision.style,
                jokerLeadDeclaration: resolvedDecision.leadDeclaration
            )
        }

        if let onJokerDecisionRequested {
            onJokerDecisionRequested(isLeadCard, applyDecision)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self else { return }
                guard self.isAwaitingJokerDecision else { return }
                guard !self.isJokerDecisionModalPresented else { return }

                self.presentJokerDecisionFallback(
                    isLeadCard: isLeadCard,
                    fallbackDecision: fallbackDecision,
                    completion: applyDecision
                )
            }
            return
        }

        presentJokerDecisionFallback(
            isLeadCard: isLeadCard,
            fallbackDecision: fallbackDecision,
            completion: applyDecision
        )
    }

    private func presentJokerDecisionFallback(
        isLeadCard: Bool,
        fallbackDecision: JokerPlayDecision,
        completion: @escaping (JokerPlayDecision?) -> Void
    ) {
        let modal = JokerModeSelectionViewController(
            isLeadCard: isLeadCard,
            onSubmit: { decision in
                completion(decision)
            },
            onCancel: {
                completion(nil)
            }
        )

        if !presentOverlayModal(modal) {
            completion(fallbackDecision)
        }
    }

    private func topPresentedViewController() -> UIViewController? {
        guard let view = self.view else { return nil }
        var topController = view.window?.rootViewController

        while let presented = topController?.presentedViewController {
            topController = presented
        }

        return topController
    }

    @discardableResult
    private func presentOverlayModal(_ modal: UIViewController) -> Bool {
        guard let presenter = topPresentedViewController() else { return false }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        presenter.present(modal, animated: true)
        return true
    }

    private var isJokerDecisionModalPresented: Bool {
        return topPresentedViewController() is JokerModeSelectionViewController
    }

    private var isGameResultsModalPresented: Bool {
        return topPresentedViewController() is GameResultsViewController
    }

    private func dismissGameViewControllerToStartScreen() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let rootController = self.view?.window?.rootViewController else { return }
            var topController = rootController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            if let gameViewController = topController as? GameViewController {
                gameViewController.dismiss(animated: true)
                return
            }

            var currentController: UIViewController? = topController
            while let controller = currentController {
                if let gameViewController = controller as? GameViewController {
                    gameViewController.dismiss(animated: true)
                    return
                }
                currentController = controller.presentingViewController
            }
        }
    }
}
