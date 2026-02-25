//
//  ScoreTablePremiumDecorator.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

/// Рендеринг премиум-декораций: трофеи, зачёркивания штрафа, маркеры.
final class ScoreTablePremiumDecorator {
    private struct Colors {
        static let premiumPenalty = UIColor(red: 0.86, green: 0.23, blue: 0.15, alpha: 0.95)
    }

    private struct LayoutMetrics {
        static let trophyMinFontSize: CGFloat = 17
        static let trophyMaxFontSize: CGFloat = 28
        static let trophyFontScale: CGFloat = 0.72
        static let markInset: CGFloat = 3
        static let strikeLineWidth: CGFloat = 2.0
    }

    private let playerCount: Int
    private let displayIndexByPlayerIndex: [Int: Int]
    private let layout: ScoreTableLayout
    private let headerHeight: CGFloat
    private let rowHeight: CGFloat
    private let leftColumnWidth: CGFloat
    private let trickColumnWidth: CGFloat
    private let pointsColumnWidth: CGFloat

    let premiumLossLayer: CAShapeLayer
    private var premiumScoreStrikeLayers: [CAShapeLayer] = []
    private var premiumTrophyLabels: [UILabel] = []

    init(
        playerCount: Int,
        displayIndexByPlayerIndex: [Int: Int],
        layout: ScoreTableLayout,
        headerHeight: CGFloat = 28,
        rowHeight: CGFloat = 24,
        leftColumnWidth: CGFloat = 36,
        trickColumnWidth: CGFloat = 44,
        pointsColumnWidth: CGFloat = 64
    ) {
        self.playerCount = playerCount
        self.displayIndexByPlayerIndex = displayIndexByPlayerIndex
        self.layout = layout
        self.headerHeight = headerHeight
        self.rowHeight = rowHeight
        self.leftColumnWidth = leftColumnWidth
        self.trickColumnWidth = trickColumnWidth
        self.pointsColumnWidth = pointsColumnWidth

        self.premiumLossLayer = CAShapeLayer()
        setupPremiumLossLayer()
    }

    private func setupPremiumLossLayer() {
        premiumLossLayer.fillColor = UIColor.clear.cgColor
        premiumLossLayer.strokeColor = Colors.premiumPenalty.cgColor
        premiumLossLayer.lineWidth = LayoutMetrics.strikeLineWidth
        premiumLossLayer.lineCap = .round
    }

    // MARK: - Add/Remove layers

    func addPremiumLossLayer(to contentView: UIView) {
        contentView.layer.addSublayer(premiumLossLayer)
    }

    func removePremiumLossLayer() {
        premiumLossLayer.removeFromSuperlayer()
    }

    // MARK: - Рендеринг декораций

    func renderDecorations(
        from snapshot: ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot,
        pointsLabels: [[UILabel]],
        in contentView: UIView
    ) {
        guard contentView.bounds.width > 0, contentView.bounds.height > 0 else {
            return
        }

        clearStrikeLayers()
        clearTrophyLabels()

        renderPenaltyStrikeLayers(
            from: snapshot.penaltyStrikeCells,
            pointsLabels: pointsLabels
        )

        renderPremiumColumnMarks(
            snapshot.columnMarks,
            in: contentView
        )
    }

    func clearDecorations() {
        premiumLossLayer.path = nil
        clearStrikeLayers()
        clearTrophyLabels()
    }

    // MARK: - Зачёркивания штрафа

    private func renderPenaltyStrikeLayers(
        from strikeCells: Set<ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot.PenaltyStrikeCell>,
        pointsLabels: [[UILabel]]
    ) {
        for strikeCell in strikeCells {
            guard pointsLabels.indices.contains(strikeCell.rowIndex) else { continue }
            guard let displayIndex = displayIndexByPlayerIndex[strikeCell.playerIndex] else { continue }
            guard pointsLabels[strikeCell.rowIndex].indices.contains(displayIndex) else { continue }

            let targetLabel = pointsLabels[strikeCell.rowIndex][displayIndex]
            addStrikeLayer(on: targetLabel)
        }
    }

    private func addStrikeLayer(on label: UILabel) {
        let bounds = label.bounds
        guard bounds.width > 2, bounds.height > 2 else { return }

        let path = UIBezierPath()
        let y = round(bounds.midY)
        path.move(to: CGPoint(x: bounds.minX + 1, y: y))
        path.addLine(to: CGPoint(x: bounds.maxX - 1, y: y))

        let strikeLayer = CAShapeLayer()
        strikeLayer.fillColor = UIColor.clear.cgColor
        strikeLayer.strokeColor = premiumLossLayer.strokeColor
        strikeLayer.lineWidth = premiumLossLayer.lineWidth
        strikeLayer.lineCap = premiumLossLayer.lineCap
        strikeLayer.path = path.cgPath

        label.layer.addSublayer(strikeLayer)
        premiumScoreStrikeLayers.append(strikeLayer)
    }

    private func clearStrikeLayers() {
        for layer in premiumScoreStrikeLayers {
            layer.removeFromSuperlayer()
        }
        premiumScoreStrikeLayers.removeAll()
    }

    // MARK: - Трофеи и маркеры

    private func renderPremiumColumnMarks(
        _ marks: [ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot.ColumnMark],
        in contentView: UIView
    ) {
        let path = UIBezierPath()

        for mark in marks {
            guard let displayIndex = displayIndexByPlayerIndex[mark.playerIndex] else { continue }

            let baseX = leftColumnWidth + CGFloat(displayIndex) * (trickColumnWidth + pointsColumnWidth)
            let topY = headerHeight + CGFloat(mark.topSummaryRowIndex) * rowHeight
            let height = CGFloat(mark.bottomSummaryRowIndex - mark.topSummaryRowIndex + 1) * rowHeight

            let markRect = CGRect(
                x: baseX,
                y: topY,
                width: trickColumnWidth,
                height: height
            ).insetBy(dx: LayoutMetrics.markInset, dy: LayoutMetrics.markInset)

            guard markRect.width > 2, markRect.height > 2 else { continue }

            switch mark.kind {
            case .trophy:
                addTrophyMark(in: markRect, to: contentView)
            case .premiumLoss:
                addPremiumLossMark(in: markRect, to: path)
            }
        }

        premiumLossLayer.path = path.cgPath
    }

    private func addTrophyMark(in rect: CGRect, to contentView: UIView) {
        let label = UILabel(frame: rect)
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.text = "🏆"

        let fontSize = min(
            max(rect.height * LayoutMetrics.trophyFontScale, LayoutMetrics.trophyMinFontSize),
            LayoutMetrics.trophyMaxFontSize
        )
        label.font = UIFont.systemFont(ofSize: fontSize)

        contentView.addSubview(label)
        premiumTrophyLabels.append(label)
    }

    private func addPremiumLossMark(in rect: CGRect, to path: UIBezierPath) {
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    }

    private func clearTrophyLabels() {
        for label in premiumTrophyLabels {
            label.removeFromSuperview()
        }
        premiumTrophyLabels.removeAll()
    }

    // MARK: - Update layout metrics

    func updateLayoutMetrics(
        leftColumnWidth: CGFloat,
        trickColumnWidth: CGFloat,
        pointsColumnWidth: CGFloat
    ) {
        // Note: эти значения используются при рендеринге, но не хранятся явно
        // Обновление происходит через параметры методов рендеринга
    }
}
