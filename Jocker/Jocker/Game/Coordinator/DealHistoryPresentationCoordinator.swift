//
//  DealHistoryPresentationCoordinator.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

/// Presents deal history details or a fallback alert when history is missing.
struct DealHistoryPresentationCoordinator {
    func presentDealHistory(
        from presenter: UIViewController,
        dealHistory: DealHistory?,
        playerNames: [String],
        playerControlTypes: [PlayerControlType],
        blockIndex: Int,
        roundIndex: Int
    ) {
        guard let dealHistory else {
            presentMissingDealHistoryAlert(
                from: presenter,
                blockIndex: blockIndex,
                roundIndex: roundIndex
            )
            return
        }

        let historyViewController = DealHistoryViewController(
            dealHistory: dealHistory,
            playerNames: playerNames,
            playerControlTypes: playerControlTypes
        )
        historyViewController.modalPresentationStyle = .fullScreen
        historyViewController.modalTransitionStyle = .crossDissolve
        presenter.present(historyViewController, animated: true)
    }

    private func presentMissingDealHistoryAlert(
        from presenter: UIViewController,
        blockIndex: Int,
        roundIndex: Int
    ) {
        let alert = UIAlertController(
            title: "История недоступна",
            message: "Для блока \(blockIndex + 1), раздачи \(roundIndex + 1) ещё нет сохранённых ходов.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        presenter.present(alert, animated: true)
    }
}
