//
//  ScoreTableLabelManager.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

/// Управление лейблами таблицы очков: создание, позиционирование, обновление текста.
final class ScoreTableLabelManager {
    private struct LabelConfig {
        let headerFont: UIFont
        let cellFont: UIFont
        let summaryFont: UIFont
        let textPrimaryColor: UIColor
        let textSecondaryColor: UIColor
        let surfaceColor: UIColor

        static let `default` = LabelConfig(
            headerFont: PanelTypography.headerCell,
            cellFont: PanelTypography.cell,
            summaryFont: PanelTypography.summaryCell,
            textPrimaryColor: UIColor(red: 0.10, green: 0.14, blue: 0.22, alpha: 1.0),
            textSecondaryColor: UIColor(red: 0.39, green: 0.45, blue: 0.54, alpha: 1.0),
            surfaceColor: UIColor.white
        )
    }

    private let playerCount: Int
    private let playerDisplayOrder: [Int]
    private let rowMappings: [ScoreTableLayout.RowMapping]
    private let rowPresentationResolver: ScoreTableRowPresentationResolver
    private var labelFrameResolver: ScoreTableLabelFrameResolver
    private let config: LabelConfig
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat
    private let pointsLabelTrailingInset: CGFloat

    private(set) var headerLabels: [UILabel] = []
    private(set) var cardsLabels: [UILabel] = []
    private(set) var tricksLabels: [[UILabel]] = []
    private(set) var pointsLabels: [[UILabel]] = []

    private var isBuilt = false

    init(
        playerCount: Int,
        playerDisplayOrder: [Int],
        rowMappings: [ScoreTableLayout.RowMapping],
        headerHeight: CGFloat,
        rowHeight: CGFloat,
        leftColumnWidth: CGFloat,
        trickColumnWidth: CGFloat,
        pointsColumnWidth: CGFloat,
        pointsLabelTrailingInset: CGFloat = 4
    ) {
        self.playerCount = playerCount
        self.playerDisplayOrder = playerDisplayOrder
        self.rowMappings = rowMappings
        self.rowPresentationResolver = ScoreTableRowPresentationResolver()
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
        self.pointsLabelTrailingInset = pointsLabelTrailingInset
        self.labelFrameResolver = ScoreTableLabelFrameResolver(
            leftColumnWidth: leftColumnWidth,
            trickColumnWidth: trickColumnWidth,
            pointsColumnWidth: pointsColumnWidth,
            headerHeight: headerHeight,
            rowHeight: rowHeight,
            pointsLabelTrailingInset: pointsLabelTrailingInset
        )
        self.config = .default
    }

    // MARK: - Создание лейблов

    func buildLabels(in contentView: UIView) {
        guard !isBuilt else { return }
        isBuilt = true

        buildHeaderLabels(in: contentView)
        buildRowLabels(in: contentView)
    }

    private func buildHeaderLabels(in contentView: UIView) {
        headerLabels = []

        for _ in 0..<playerCount {
            let headerLabel = UILabel()
            headerLabel.font = config.headerFont
            headerLabel.textAlignment = .center
            headerLabel.textColor = config.textPrimaryColor
            headerLabel.backgroundColor = config.surfaceColor
            headerLabel.adjustsFontSizeToFitWidth = true
            headerLabel.minimumScaleFactor = 0.65
            headerLabel.lineBreakMode = .byTruncatingTail
            contentView.addSubview(headerLabel)
            headerLabels.append(headerLabel)
        }
    }

    private func buildRowLabels(in contentView: UIView) {
        cardsLabels = []
        tricksLabels = Array(repeating: [], count: rowMappings.count)
        pointsLabels = Array(repeating: [], count: rowMappings.count)

        for (rowIndex, rowMapping) in rowMappings.enumerated() {
            let pointsLabelStyle = rowPresentationResolver.pointsLabelStyle(for: rowMapping.kind)

            let cardsLabel = buildCardsLabel(for: rowMapping.kind)
            contentView.addSubview(cardsLabel)
            cardsLabels.append(cardsLabel)

            for _ in 0..<playerCount {
                let tricksLabel = buildTricksLabel()
                contentView.addSubview(tricksLabel)
                tricksLabels[rowIndex].append(tricksLabel)

                let pointsLabel = buildPointsLabel(style: pointsLabelStyle)
                contentView.addSubview(pointsLabel)
                pointsLabels[rowIndex].append(pointsLabel)
            }
        }
    }

    private func buildCardsLabel(for rowKind: ScoreTableLayout.RowKind) -> UILabel {
        let label = UILabel()
        label.font = config.cellFont
        label.textAlignment = .center
        label.textColor = config.textSecondaryColor
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.text = rowPresentationResolver.cardsLabelText(for: rowKind)
        return label
    }

    private func buildTricksLabel() -> UILabel {
        let label = UILabel()
        label.font = config.cellFont
        label.textAlignment = .center
        label.textColor = config.textSecondaryColor
        label.text = ""
        return label
    }

    private func buildPointsLabel(style: ScoreTableRowPresentationResolver.PointsLabelStyle) -> UILabel {
        let label = UILabel()
        label.font = style == .summary ? config.summaryFont : config.cellFont
        label.textAlignment = .right
        label.textColor = config.textPrimaryColor
        label.text = ""
        return label
    }

    // MARK: - Позиционирование

    func updateHeaderFrames() {
        for (displayIndex, headerLabel) in headerLabels.enumerated() {
            headerLabel.frame = labelFrameResolver.headerFrame(displayIndex: displayIndex)
        }
    }

    func updateRowFrames() {
        for rowIndex in 0..<rowMappings.count {
            cardsLabels[rowIndex].frame = labelFrameResolver.cardsLabelFrame(rowIndex: rowIndex)

            for displayIndex in 0..<playerCount {
                tricksLabels[rowIndex][displayIndex].frame = labelFrameResolver.tricksLabelFrame(
                    rowIndex: rowIndex,
                    displayIndex: displayIndex
                )
                pointsLabels[rowIndex][displayIndex].frame = labelFrameResolver.pointsLabelFrame(
                    rowIndex: rowIndex,
                    displayIndex: displayIndex
                )
            }
        }
    }

    func updatePinnedHeaderPosition(contentOffsetY: CGFloat) {
        for headerLabel in headerLabels {
            headerLabel.frame = labelFrameResolver.pinnedHeaderFrame(
                from: headerLabel.frame,
                contentOffsetY: contentOffsetY
            )
            if let superview = headerLabel.superview {
                superview.bringSubviewToFront(headerLabel)
            }
        }
    }

    // MARK: - Обновление текста

    func updateTexts(
        cardsTexts: [String],
        tricksTexts: [[String]],
        pointsTexts: [[String]]
    ) {
        guard cardsTexts.count == rowMappings.count,
              tricksTexts.count == rowMappings.count,
              pointsTexts.count == rowMappings.count else {
            return
        }

        for rowIndex in 0..<rowMappings.count {
            cardsLabels[rowIndex].text = cardsTexts[rowIndex]
            guard tricksTexts[rowIndex].count == playerCount,
                  pointsTexts[rowIndex].count == playerCount else {
                continue
            }

            for displayIndex in 0..<playerCount {
                tricksLabels[rowIndex][displayIndex].text = tricksTexts[rowIndex][displayIndex]
                pointsLabels[rowIndex][displayIndex].text = pointsTexts[rowIndex][displayIndex]
            }
        }
    }

    func clearTexts() {
        for rowIndex in 0..<rowMappings.count {
            cardsLabels[rowIndex].text = rowPresentationResolver.cardsLabelText(for: rowMappings[rowIndex].kind)

            for displayIndex in 0..<playerCount {
                tricksLabels[rowIndex][displayIndex].text = ""
                pointsLabels[rowIndex][displayIndex].text = ""
            }
        }
    }

    // MARK: - Display name

    func updateHeaderNames(playerNames: [String]) {
        for (displayIndex, headerLabel) in headerLabels.enumerated() {
            let playerIndex = playerDisplayOrder[displayIndex]
            headerLabel.text = displayName(for: playerIndex, playerNames: playerNames)
        }
    }

    private func displayName(for playerIndex: Int, playerNames: [String]) -> String {
        return PlayerDisplayNameFormatter.displayName(for: playerIndex, in: playerNames)
    }

    // MARK: - Update column widths

    func updateColumnWidths(
        leftColumnWidth: CGFloat,
        trickColumnWidth: CGFloat,
        pointsColumnWidth: CGFloat
    ) {
        labelFrameResolver = ScoreTableLabelFrameResolver(
            leftColumnWidth: leftColumnWidth,
            trickColumnWidth: trickColumnWidth,
            pointsColumnWidth: pointsColumnWidth,
            headerHeight: headerHeight,
            rowHeight: rowHeight,
            pointsLabelTrailingInset: pointsLabelTrailingInset
        )
    }
}
