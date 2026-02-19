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

    func presentFirstPlayerAnnouncementModal(firstPlayerName: String) {
        guard !firstPlayerName.isEmpty else { return }
        let modal = makeFirstPlayerAnnouncementModal(firstPlayerName: firstPlayerName)
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
            forbiddenBid: forbiddenBid,
            trumpSuit: currentTrump
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

    private func makeFirstPlayerAnnouncementModal(firstPlayerName: String) -> UIViewController {
        let overlayColor = GameColors.sceneBackground.withAlphaComponent(0.62)
        let surfaceColor = UIColor(red: 0.15, green: 0.21, blue: 0.32, alpha: 0.98)
        let borderColor = GameColors.goldTranslucent
        let titleColor = GameColors.textPrimary
        let subtitleColor = GameColors.textSecondary
        let accentColor = GameColors.buttonFill
        let accentBorderColor = GameColors.buttonStroke
        let accentTextColor = GameColors.buttonText

        let modal = UIViewController()
        modal.isModalInPresentation = true
        modal.view.backgroundColor = overlayColor

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = surfaceColor
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = borderColor.cgColor
        containerView.clipsToBounds = true
        modal.view.addSubview(containerView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Первый по списку"
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24)
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = firstPlayerName
        nameLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 22)
        nameLabel.textColor = subtitleColor
        nameLabel.textAlignment = .center
        containerView.addSubview(nameLabel)

        let confirmButton = UIButton(type: .system)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle("ОК", for: .normal)
        confirmButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        confirmButton.setTitleColor(accentTextColor, for: .normal)
        confirmButton.backgroundColor = accentColor
        confirmButton.layer.cornerRadius = 12
        confirmButton.layer.borderWidth = 1
        confirmButton.layer.borderColor = accentBorderColor.cgColor
        confirmButton.addAction(
            UIAction { [weak modal] _ in
                modal?.dismiss(animated: true)
            },
            for: .touchUpInside
        )
        containerView.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: modal.view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: modal.view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: modal.view.widthAnchor, multiplier: 0.74),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 360),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            confirmButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18)
        ])

        return modal
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

        hasSavedGameStatistics = true
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
            playerNames: currentPlayerNames
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
