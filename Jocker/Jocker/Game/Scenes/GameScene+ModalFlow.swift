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

    struct TrumpChoiceContext {
        let playerIndex: Int
        let handCards: [Card]
    }

    struct BidChoiceContext {
        let playerIndex: Int
        let handCards: [Card]
        let allowedBids: [Int]
        let displayedBidsByPlayer: [Int?]
        let biddingOrder: [Int]
        let forbiddenBid: Int?
    }

    struct BlindChoiceContext {
        let playerIndex: Int
        let allowedBlindBids: [Int]
        let canChooseBlind: Bool
    }

    func presentFirstPlayerAnnouncementModal(firstPlayerName: String) {
        if isUITestMode {
            return
        }
        guard !firstPlayerName.isEmpty else { return }
        let modal = FirstPlayerAnnouncementViewController(firstPlayerName: firstPlayerName)
        _ = presentOverlayModal(modal)
    }

    @discardableResult
    func presentGameResultsModal(playerSummaries: [GameFinalPlayerSummary]) -> Bool {
        guard !playerSummaries.isEmpty else { return false }
        guard !isGameResultsModalPresented else { return true }

        let modal = GameResultsViewController(
            playerSummaries: playerSummaries,
            onClose: { [weak self] in
                guard let self else { return }
                self.persistGameStatisticsIfNeeded(playerSummaries: playerSummaries)
                self.dismissGameViewControllerToStartScreen()
            }
        )
        return presentOverlayModal(modal)
    }

    @discardableResult
    func presentBlockResultsModal(forCompletedBlockCount completedBlockCount: Int) -> Bool {
        guard completedBlockCount > 0 else { return false }
        guard completedBlockCount < GameConstants.totalBlocks else { return false }

        let blockIndex = completedBlockCount - 1
        let dealsInBlock = GameConstants.deals(
            for: GameBlock(rawValue: completedBlockCount) ?? .first,
            playerCount: playerCount
        )
        let lastRoundIndex = max(0, dealsInBlock.count - 1)

        let modal = ScoreTableViewController(
            scoreManager: scoreManager,
            firstColumnPlayerIndex: scoreTableFirstPlayerIndex,
            playerNames: currentPlayerNames,
            currentBlockIndex: blockIndex,
            currentRoundIndex: lastRoundIndex,
            focusOnBlockSummary: true
        )
        modal.onDealSelected = { [weak self, weak modal] selectedBlockIndex, selectedRoundIndex in
            guard let self, let modal else { return }
            self.presentDealHistoryModal(
                from: modal,
                blockIndex: selectedBlockIndex,
                roundIndex: selectedRoundIndex
            )
        }
        return presentOverlayModal(modal)
    }

    func requestTrumpChoice(
        forPlayer playerIndex: Int,
        handCards: [Card],
        completion: @escaping (Suit?) -> Void
    ) {
        requestTrumpChoice(
            context: .init(
                playerIndex: playerIndex,
                handCards: handCards
            ),
            completion: completion
        )
    }

    func requestTrumpChoice(
        context: TrumpChoiceContext,
        completion: @escaping (Suit?) -> Void
    ) {
        let fallbackTrump = botTrumpSelectionService(for: context.playerIndex).selectTrump(
            from: context.handCards,
            isPlayerChosenTrumpStage: true
        )

        if isBotPlayer(context.playerIndex) {
            completion(fallbackTrump)
            return
        }

        let playerName = gameState.players.indices.contains(context.playerIndex)
            ? gameState.players[context.playerIndex].name
            : "Игрок \(context.playerIndex + 1)"

        presentPendingChoiceModal(
            .humanTrumpChoice,
            fallbackResult: fallbackTrump,
            completion: completion
        ) { resolve in
            TrumpSelectionViewController(
                playerName: playerName,
                handCards: context.handCards
            ) { selectedSuit in
                resolve(selectedSuit)
            }
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
        requestHumanBid(
            context: .init(
                playerIndex: playerIndex,
                handCards: handCards,
                allowedBids: allowedBids,
                displayedBidsByPlayer: displayedBidsByPlayer,
                biddingOrder: biddingOrder,
                forbiddenBid: forbiddenBid
            ),
            completion: completion
        )
    }

    func requestHumanBid(
        context: BidChoiceContext,
        completion: @escaping (Int) -> Void
    ) {
        let normalizedAllowedBids = Array(Set(context.allowedBids)).sorted()
        guard !normalizedAllowedBids.isEmpty else {
            completion(0)
            return
        }

        let playerName = gameState.players.indices.contains(context.playerIndex)
            ? gameState.players[context.playerIndex].name
            : "Игрок \(context.playerIndex + 1)"

        presentPendingChoiceModal(
            .humanBidChoice,
            fallbackResult: normalizedAllowedBids[0],
            completion: completion
        ) { resolve in
            BidSelectionViewController(
                playerName: playerName,
                handCards: context.handCards,
                allowedBids: normalizedAllowedBids,
                maxBid: gameState.currentCardsPerPlayer,
                playerNames: gameState.players.map { $0.name },
                displayedBidsByPlayer: context.displayedBidsByPlayer,
                biddingOrder: context.biddingOrder,
                currentPlayerIndex: context.playerIndex,
                forbiddenBid: context.forbiddenBid,
                trumpSuit: currentTrump
            ) { selectedBid in
                resolve(selectedBid)
            }
        }
    }

    func requestHumanPreDealBlindChoice(
        forPlayer playerIndex: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        completion: @escaping (_ isBlind: Bool, _ bid: Int?) -> Void
    ) {
        requestHumanPreDealBlindChoice(
            context: .init(
                playerIndex: playerIndex,
                allowedBlindBids: allowedBlindBids,
                canChooseBlind: canChooseBlind
            ),
            completion: completion
        )
    }

    func requestHumanPreDealBlindChoice(
        context: BlindChoiceContext,
        completion: @escaping (_ isBlind: Bool, _ bid: Int?) -> Void
    ) {
        let normalizedAllowedBlindBids = Array(Set(context.allowedBlindBids)).sorted()

        let playerName = gameState.players.indices.contains(context.playerIndex)
            ? gameState.players[context.playerIndex].name
            : "Игрок \(context.playerIndex + 1)"

        presentPendingChoiceModal(
            .humanBlindChoice,
            fallbackResult: (false, nil as Int?),
            completion: { result in
                completion(result.0, result.1)
            }
        ) { resolve in
            PreDealBlindSelectionViewController(
                playerName: playerName,
                allowedBlindBids: normalizedAllowedBlindBids,
                canChooseBlind: context.canChooseBlind
            ) { isBlind, bid in
                resolve((isBlind, bid))
            }
        }
    }

    func requestJokerDecisionAndPlay(cardNode: CardNode, playerIndex: Int) {
        let isLeadCard = trickNode.playedCards.isEmpty
        let fallbackDecision = isLeadCard ? JokerPlayDecision.defaultLead : JokerPlayDecision.defaultNonLead
        setPendingInteractionModal(.jokerDecision)

        let applyDecision: (JokerPlayDecision?) -> Void = { [weak self, weak cardNode] decision in
            guard let self = self else { return }
            self.clearPendingInteractionModal(.jokerDecision)

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

    private func presentPendingChoiceModal<Result>(
        _ pendingModal: GameSceneInteractionState.PendingModal,
        fallbackResult: @autoclosure () -> Result,
        completion: @escaping (Result) -> Void,
        makeModal: (@escaping (Result) -> Void) -> UIViewController
    ) {
        setPendingInteractionModal(pendingModal)

        let resolve: (Result) -> Void = { [weak self] result in
            self?.clearPendingInteractionModal(pendingModal)
            completion(result)
        }

        let modal = makeModal(resolve)
        if !presentOverlayModal(modal) {
            clearPendingInteractionModal(pendingModal)
            completion(fallbackResult())
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

    private func persistGameStatisticsIfNeeded(playerSummaries: [GameFinalPlayerSummary]) {
        guard !hasSavedGameStatistics else { return }
        guard !playerSummaries.isEmpty else { return }
        guard !scoreManager.completedBlocks.isEmpty else { return }

        markGameStatisticsSaved()
        gameStatisticsStore.recordCompletedGame(
            playerCount: playerCount,
            playerSummaries: playerSummaries,
            completedBlocks: scoreManager.completedBlocks
        )
    }

    private func presentDealHistoryModal(from presenter: UIViewController, blockIndex: Int, roundIndex: Int) {
        guard let dealHistory = dealHistory(forBlockIndex: blockIndex, roundIndex: roundIndex) else {
            showMissingDealHistoryAlert(
                from: presenter,
                blockIndex: blockIndex,
                roundIndex: roundIndex
            )
            return
        }

        let historyViewController = DealHistoryViewController(
            dealHistory: dealHistory,
            playerNames: currentPlayerNames,
            playerControlTypes: playerControlTypes
        )
        historyViewController.modalPresentationStyle = .fullScreen
        historyViewController.modalTransitionStyle = .crossDissolve
        presenter.present(historyViewController, animated: true)
    }

    private func showMissingDealHistoryAlert(from presenter: UIViewController, blockIndex: Int, roundIndex: Int) {
        let alert = UIAlertController(
            title: "История недоступна",
            message: "Для блока \(blockIndex + 1), раздачи \(roundIndex + 1) ещё нет сохранённых ходов.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        presenter.present(alert, animated: true)
    }
}
