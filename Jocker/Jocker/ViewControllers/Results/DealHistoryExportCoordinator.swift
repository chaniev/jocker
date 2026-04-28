//
//  DealHistoryExportCoordinator.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import UIKit

final class DealHistoryExportCoordinator {
    private let exportService: DealHistoryExportService
    private var isExportInProgress = false

    init(exportService: DealHistoryExportService) {
        self.exportService = exportService
    }

    func export(
        dealHistory: DealHistory,
        exportData: DealHistoryPresentationBuilder.Presentation.ExportData,
        from presenter: UIViewController,
        sourceButton: UIButton
    ) {
        guard !isExportInProgress else { return }
        guard exportData.playerCount > 0 else {
            showExportErrorAlert(
                message: "Не удалось определить состав игроков для экспорта.",
                from: presenter
            )
            return
        }

        isExportInProgress = true
        sourceButton.isEnabled = false

        let result = exportService.export(
            histories: [dealHistory],
            playerCount: exportData.playerCount,
            gameMode: exportData.gameMode,
            playerNames: exportData.playerNames,
            playerControlTypes: exportData.playerControlTypes,
            reason: .deal(
                blockIndex: dealHistory.key.blockIndex,
                roundIndex: dealHistory.key.roundIndex
            )
        )

        guard let result else {
            finishExport(sourceButton: sourceButton)
            showExportErrorAlert(
                message: "Не удалось подготовить JSON-файл с историей раздачи.",
                from: presenter
            )
            return
        }

        let shareController = UIActivityViewController(
            activityItems: [result.fileURL],
            applicationActivities: nil
        )
        shareController.completionWithItemsHandler = { [weak self, weak sourceButton] _, _, _, _ in
            guard let self, let sourceButton else { return }
            self.finishExport(sourceButton: sourceButton)
        }

        if let popover = shareController.popoverPresentationController {
            popover.sourceView = sourceButton
            popover.sourceRect = sourceButton.bounds
        }

        presenter.present(shareController, animated: true)
    }

    private func finishExport(sourceButton: UIButton) {
        isExportInProgress = false
        sourceButton.isEnabled = true
    }

    private func showExportErrorAlert(
        message: String,
        from presenter: UIViewController
    ) {
        let alert = UIAlertController(
            title: "Экспорт не выполнен",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        presenter.present(alert, animated: true)
    }
}
