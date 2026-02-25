//
//  ScoreTableGridRenderer.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

/// Рендеринг сетки таблицы очков: тонкие/толстые линии.
final class ScoreTableGridRenderer {
    private struct Colors {
        static let thinGrid = UIColor(red: 0.80, green: 0.83, blue: 0.88, alpha: 1.0)
        static let thickGrid = UIColor(red: 0.52, green: 0.58, blue: 0.68, alpha: 1.0)
    }

    private let playerCount: Int
    private let layout: ScoreTableLayout
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat

    let thinGridLayer: CAShapeLayer
    let thickGridLayer: CAShapeLayer

    init(
        playerCount: Int,
        layout: ScoreTableLayout,
        headerHeight: CGFloat = 28,
        rowHeight: CGFloat = 24
    ) {
        self.playerCount = playerCount
        self.layout = layout
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight

        self.thinGridLayer = CAShapeLayer()
        self.thickGridLayer = CAShapeLayer()

        setupLayers()
    }

    private func setupLayers() {
        thinGridLayer.fillColor = UIColor.clear.cgColor
        thinGridLayer.strokeColor = Colors.thinGrid.cgColor
        thinGridLayer.lineWidth = 0.5

        thickGridLayer.fillColor = UIColor.clear.cgColor
        thickGridLayer.strokeColor = Colors.thickGrid.cgColor
        thickGridLayer.lineWidth = 2.0
    }

    // MARK: - Рендеринг сетки

    func updateGridLayers(
        in contentView: UIView,
        columnWidths: ScoreTableLayout.ColumnWidths
    ) {
        let contentWidth = contentView.bounds.width
        let contentHeight = contentView.bounds.height

        let layoutData = layout.buildLayoutData()

        // Позиции вертикальных линий
        let xPositions = calculateXPositions(columnWidths: columnWidths)

        // Позиции горизонтальных линий
        let yPositions = calculateYPositions(blockEndRowIndices: layoutData.blockEndRowIndices)

        // Тонкие линии
        thinGridLayer.path = buildThinGridPath(
            xPositions: xPositions,
            yPositions: yPositions,
            contentWidth: contentWidth,
            contentHeight: contentHeight
        ).cgPath

        // Толстые линии
        thickGridLayer.path = buildThickGridPath(
            xPositions: xPositions,
            blockEndRowIndices: layoutData.blockEndRowIndices,
            contentWidth: contentWidth,
            contentHeight: contentHeight
        ).cgPath
    }

    // MARK: - Позиции линий

    private func calculateXPositions(columnWidths: ScoreTableLayout.ColumnWidths) -> [CGFloat] {
        var xPositions: [CGFloat] = [0]
        var currentX: CGFloat = 0

        // Левая колонка
        currentX += columnWidths.leftColumn
        xPositions.append(currentX)

        // Колонки игроков (trick + points)
        for _ in 0..<playerCount {
            currentX += columnWidths.trickColumn + columnWidths.pointsColumn
            xPositions.append(currentX)
        }

        return xPositions
    }

    private func calculateYPositions(blockEndRowIndices: [Int]) -> [CGFloat] {
        var yPositions: [CGFloat] = [0, headerHeight]

        for rowIndex in 0..<layout.totalRows {
            let y = headerHeight + CGFloat(rowIndex + 1) * rowHeight
            yPositions.append(y)
        }

        return yPositions
    }

    // MARK: - Построение путей

    private func buildThinGridPath(
        xPositions: [CGFloat],
        yPositions: [CGFloat],
        contentWidth: CGFloat,
        contentHeight: CGFloat
    ) -> UIBezierPath {
        let path = UIBezierPath()

        // Вертикальные линии
        for x in xPositions {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: contentHeight))
        }

        // Горизонтальные линии
        for y in yPositions {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: contentWidth, y: y))
        }

        return path
    }

    private func buildThickGridPath(
        xPositions: [CGFloat],
        blockEndRowIndices: [Int],
        contentWidth: CGFloat,
        contentHeight: CGFloat
    ) -> UIBezierPath {
        let path = UIBezierPath()

        // Горизонтальные толстые линии между блоками
        for blockEndIndex in blockEndRowIndices.dropLast() {
            let y = headerHeight + CGFloat(blockEndIndex + 1) * rowHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: contentWidth, y: y))
        }

        // Вертикальные толстые линии между игроками
        for playerIndex in 0..<playerCount {
            let x = xPositions[playerIndex + 2] // Пропускаем left column и первую trick колонку
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: contentHeight))
        }

        return path
    }

    // MARK: - Add layers to view

    func addLayers(to contentView: UIView) {
        contentView.layer.addSublayer(thinGridLayer)
        contentView.layer.addSublayer(thickGridLayer)
    }

    func removeLayers() {
        thinGridLayer.removeFromSuperlayer()
        thickGridLayer.removeFromSuperlayer()
    }
}
