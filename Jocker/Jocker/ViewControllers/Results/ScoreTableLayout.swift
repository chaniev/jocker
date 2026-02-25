//
//  ScoreTableLayout.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

/// Расчёт layout таблицы очков: колонки, строки, размеры.
struct ScoreTableLayout {
    enum RowKind: Equatable {
        case deal(cards: Int)
        case subtotal
        case cumulative
    }

    struct RowMapping {
        let kind: RowKind
        let blockIndex: Int
        let roundIndex: Int?
    }

    struct LayoutData {
        let rows: [RowKind]
        let blockEndRowIndices: [Int]
        let rowMappings: [RowMapping]
    }

    struct ColumnWidths: Equatable {
        let leftColumn: CGFloat
        let trickColumn: CGFloat
        let pointsColumn: CGFloat

        var totalWidth: CGFloat {
            return leftColumn + trickColumn + pointsColumn
        }
    }

    struct GeometrySignature: Equatable {
        let boundsSize: CGSize
        let contentSize: CGSize
        let columnWidths: ColumnWidths

        var leftColumnWidth: CGFloat { columnWidths.leftColumn }
        var trickColumnWidth: CGFloat { columnWidths.trickColumn }
        var pointsColumnWidth: CGFloat { columnWidths.pointsColumn }
    }

    private let playerCount: Int
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat

    // Минимальные размеры колонок
    private let minLeftColumnWidth: CGFloat = 36
    private let minTrickColumnWidth: CGFloat = 44
    private let minPointsColumnWidth: CGFloat = 64

    init(
        playerCount: Int,
        headerHeight: CGFloat = 28,
        rowHeight: CGFloat = 24
    ) {
        self.playerCount = playerCount
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
    }

    // MARK: - Построение структуры строк

    func buildLayoutData() -> LayoutData {
        let blockDeals = GameConstants.allBlockDeals(playerCount: playerCount)

        var rows: [RowKind] = []
        var blockEndRowIndices: [Int] = []
        var rowMappings: [RowMapping] = []

        for blockIndex in 0..<blockDeals.count {
            var roundIndex = 0
            for cards in blockDeals[blockIndex] {
                let rowKind = RowKind.deal(cards: cards)
                rows.append(rowKind)
                rowMappings.append(RowMapping(kind: rowKind, blockIndex: blockIndex, roundIndex: roundIndex))
                roundIndex += 1
            }

            let subtotalKind = RowKind.subtotal
            rows.append(subtotalKind)
            rowMappings.append(RowMapping(kind: subtotalKind, blockIndex: blockIndex, roundIndex: nil))

            if blockIndex >= 1 {
                let cumulativeKind = RowKind.cumulative
                rows.append(cumulativeKind)
                rowMappings.append(RowMapping(kind: cumulativeKind, blockIndex: blockIndex, roundIndex: nil))
            }

            blockEndRowIndices.append(rows.count - 1)
        }

        return LayoutData(
            rows: rows,
            blockEndRowIndices: blockEndRowIndices,
            rowMappings: rowMappings
        )
    }

    // MARK: - Расчёт размеров колонок

    func calculateColumnWidths(availableWidth: CGFloat) -> ColumnWidths {
        let minTotal = minLeftColumnWidth + CGFloat(playerCount) * (minTrickColumnWidth + minPointsColumnWidth)

        guard availableWidth > minTotal else {
            return ColumnWidths(
                leftColumn: minLeftColumnWidth,
                trickColumn: minTrickColumnWidth,
                pointsColumn: minPointsColumnWidth
            )
        }

        let trickColumn = minTrickColumnWidth
        let extraWidth = availableWidth - (minLeftColumnWidth + CGFloat(playerCount) * trickColumn)
        let pointsColumn = extraWidth / CGFloat(playerCount)

        return ColumnWidths(
            leftColumn: minLeftColumnWidth,
            trickColumn: trickColumn,
            pointsColumn: pointsColumn
        )
    }

    // MARK: - Расчёт контента

    func calculateContentSize(columnWidths: ColumnWidths) -> CGSize {
        let layoutData = buildLayoutData()
        let contentWidth = columnWidths.leftColumn + CGFloat(playerCount) * (columnWidths.trickColumn + columnWidths.pointsColumn)
        let contentHeight = headerHeight + CGFloat(layoutData.rows.count) * rowHeight

        return CGSize(width: contentWidth, height: contentHeight)
    }

    // MARK: - Позиции

    func yPosition(forRowIndex rowIndex: Int) -> CGFloat {
        return headerHeight + CGFloat(rowIndex) * rowHeight
    }

    func xPosition(forColumnIndex columnIndex: Int, columnWidths: ColumnWidths) -> CGFloat {
        guard columnIndex >= 0 else { return 0 }

        if columnIndex == 0 {
            return 0
        }

        let leftColumn = columnWidths.leftColumn
        let pairWidth = columnWidths.trickColumn + columnWidths.pointsColumn
        return leftColumn + CGFloat(columnIndex - 1) * pairWidth
    }

    func xPositionForTrickColumn(displayIndex: Int, columnWidths: ColumnWidths) -> CGFloat {
        let baseX = xPosition(forColumnIndex: displayIndex + 1, columnWidths: columnWidths)
        return baseX
    }

    func xPositionForPointsColumn(displayIndex: Int, columnWidths: ColumnWidths) -> CGFloat {
        let baseX = xPosition(forColumnIndex: displayIndex + 1, columnWidths: columnWidths)
        return baseX + columnWidths.trickColumn
    }

    // MARK: - Geometry Signature

    func makeGeometrySignature(
        boundsSize: CGSize,
        columnWidths: ColumnWidths,
        contentSize: CGSize
    ) -> GeometrySignature {
        return GeometrySignature(
            boundsSize: boundsSize,
            contentSize: contentSize,
            columnWidths: columnWidths
        )
    }

    // MARK: - Helper

    var totalRows: Int {
        return buildLayoutData().rows.count
    }

    var totalContentHeight: CGFloat {
        return headerHeight + CGFloat(totalRows) * rowHeight
    }
}
