//
//  ScoreTableView.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

final class ScoreTableView: UIView, UIScrollViewDelegate {

    enum RowKind: Equatable {
        case deal(cards: Int)
        case subtotal
        case cumulative
    }

    private struct Layout {
        let rows: [RowKind]
        let blockEndRowIndices: [Int]
        let rowMappings: [RowMapping]
    }

    struct RowMapping {
        let kind: RowKind
        let blockIndex: Int
        let roundIndex: Int?
    }

    private typealias ScoreDataSnapshot = ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot
    private typealias ScoreDecorationsSnapshot = ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot
    private typealias InProgressRoundSnapshot = ScoreTableInProgressRoundSnapshotProvider.Snapshot

    private struct GeometrySignature: Equatable {
        let boundsSize: CGSize
        let contentSize: CGSize
        let leftColumnWidth: CGFloat
        let trickColumnWidth: CGFloat
        let pointsColumnWidth: CGFloat
    }

    private let playerCount: Int
    private let playerDisplayOrder: [Int]
    private let displayIndexByPlayerIndex: [Int: Int]
    private let playerNames: [String]
    private let layout: Layout
    private let snapshotBuilder: ScoreTableRenderSnapshotBuilder
    private let inProgressRoundSnapshotProvider: ScoreTableInProgressRoundSnapshotProvider
    private let rowNavigationResolver: ScoreTableRowNavigationResolver
    private let scrollOffsetResolver: ScoreTableScrollOffsetResolver
    private let tapTargetResolver: ScoreTableTapTargetResolver
    private let rowPresentationResolver: ScoreTableRowPresentationResolver
    private let rowTextRenderer: ScoreTableRowTextRenderer
    private var scoreDataSnapshot: ScoreDataSnapshot?
    private var scoreDecorationsSnapshot: ScoreDecorationsSnapshot = .empty
    private var inProgressRoundSnapshot: InProgressRoundSnapshot = .empty
    private var isScoreRowsDirty = false
    private var isScoreDecorationsDirty = false
    private var lastGeometrySignature: GeometrySignature?
    var onDealRowTapped: ((Int, Int) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let thinGridLayer = CAShapeLayer()
    private let thickGridLayer = CAShapeLayer()
    private let premiumLossLayer = CAShapeLayer()
    private var premiumScoreStrikeLayers: [CAShapeLayer] = []
    private var premiumTrophyLabels: [UILabel] = []

    private var leftColumnWidth: CGFloat = 36
    private var trickColumnWidth: CGFloat = 44
    private var pointsColumnWidth: CGFloat = 64
    private let headerHeight: CGFloat = 28
    private let rowHeight: CGFloat = 24
    private let pointsLabelTrailingInset: CGFloat = 4

    // Лейблы создаются один раз при инициализации
    private var headerLabels: [UILabel] = []
    private var cardsLabels: [UILabel] = []
    private var tricksLabels: [[UILabel]] = []
    private var pointsLabels: [[UILabel]] = []

    /// Флаг для предотвращения повторного создания лейблов
    private var isLabelsBuilt = false

    private let surfaceColor = UIColor.white
    private let gridThinColor = UIColor(red: 0.80, green: 0.83, blue: 0.88, alpha: 1.0)
    private let gridThickColor = UIColor(red: 0.52, green: 0.58, blue: 0.68, alpha: 1.0)
    private let textPrimaryColor = UIColor(red: 0.10, green: 0.14, blue: 0.22, alpha: 1.0)
    private let textSecondaryColor = UIColor(red: 0.39, green: 0.45, blue: 0.54, alpha: 1.0)
    private let premiumPenaltyColor = UIColor(red: 0.86, green: 0.23, blue: 0.15, alpha: 0.95)

    init(
        playerCount: Int,
        displayStartPlayerIndex: Int = 0,
        playerNames: [String] = []
    ) {
        self.playerCount = playerCount
        self.playerDisplayOrder = ScoreTableView.buildPlayerDisplayOrder(
            playerCount: playerCount,
            startIndex: displayStartPlayerIndex
        )
        self.displayIndexByPlayerIndex = ScoreTableView.buildDisplayIndexByPlayerIndex(
            playerDisplayOrder: self.playerDisplayOrder
        )
        self.playerNames = playerNames
        self.layout = ScoreTableView.buildLayout(playerCount: playerCount)
        self.snapshotBuilder = ScoreTableRenderSnapshotBuilder(
            playerCount: playerCount,
            rowMappings: self.layout.rowMappings
        )
        self.inProgressRoundSnapshotProvider = ScoreTableInProgressRoundSnapshotProvider(
            playerCount: playerCount,
            rowMappings: self.layout.rowMappings
        )
        self.rowNavigationResolver = ScoreTableRowNavigationResolver(
            rowMappings: self.layout.rowMappings
        )
        self.scrollOffsetResolver = ScoreTableScrollOffsetResolver(
            headerHeight: self.headerHeight,
            rowHeight: self.rowHeight
        )
        self.tapTargetResolver = ScoreTableTapTargetResolver(
            rowMappings: self.layout.rowMappings,
            headerHeight: self.headerHeight,
            rowHeight: self.rowHeight
        )
        self.rowPresentationResolver = ScoreTableRowPresentationResolver()
        self.rowTextRenderer = ScoreTableRowTextRenderer(
            playerCount: playerCount,
            playerDisplayOrder: self.playerDisplayOrder,
            rowMappings: self.layout.rowMappings
        )
        super.init(frame: .zero)
        setupView()
        buildLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateColumnWidths()
        layoutScrollView()
        repositionLabels()
        updatePinnedHeaderPosition()
        updateGridLayers()
        let geometrySignature = currentGeometrySignature()
        if lastGeometrySignature != geometrySignature {
            lastGeometrySignature = geometrySignature
            isScoreDecorationsDirty = true
        }
        refreshRenderedScoreContentIfNeeded()
    }

    func update(with scoreManager: ScoreManager) {
        let snapshot = snapshotBuilder.makeDataSnapshot(from: scoreManager)
        scoreDataSnapshot = snapshot
        scoreDecorationsSnapshot = snapshotBuilder.makeDecorationsSnapshot(from: snapshot)
        inProgressRoundSnapshot = inProgressRoundSnapshotProvider.makeSnapshot(from: scoreManager)
        isScoreRowsDirty = true
        isScoreDecorationsDirty = true
        setNeedsLayout()
        refreshRenderedScoreContentIfNeeded()
    }

    func scrollToDeal(blockIndex: Int, roundIndex: Int, animated: Bool) {
        layoutIfNeeded()

        guard let targetRowIndex = rowNavigationResolver.targetDealRowIndex(
            blockIndex: blockIndex,
            roundIndex: roundIndex
        ) else {
            return
        }

        scrollToRow(targetRowIndex, animated: animated)
    }

    func scrollToBlockSummary(blockIndex: Int, animated: Bool) {
        layoutIfNeeded()

        guard let targetRowIndex = rowNavigationResolver.targetSummaryRowIndex(blockIndex: blockIndex) else {
            return
        }

        scrollToRow(targetRowIndex, animated: animated)
    }

    private func scrollToRow(_ rowIndex: Int, animated: Bool) {
        let targetOffsetY = scrollOffsetResolver.targetOffsetY(
            forRowIndex: rowIndex,
            visibleHeight: scrollView.bounds.height,
            contentHeight: scrollView.contentSize.height
        )

        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: targetOffsetY),
            animated: animated
        )
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = surfaceColor

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.indicatorStyle = .black
        scrollView.delegate = self
        addSubview(scrollView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTableTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapRecognizer)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        contentView.backgroundColor = surfaceColor
        scrollView.addSubview(contentView)

        thinGridLayer.fillColor = UIColor.clear.cgColor
        thinGridLayer.strokeColor = gridThinColor.cgColor
        thinGridLayer.lineWidth = 0.5

        thickGridLayer.fillColor = UIColor.clear.cgColor
        thickGridLayer.strokeColor = gridThickColor.cgColor
        thickGridLayer.lineWidth = 2.0

        premiumLossLayer.fillColor = UIColor.clear.cgColor
        premiumLossLayer.strokeColor = premiumPenaltyColor.cgColor
        premiumLossLayer.lineWidth = 2.0
        premiumLossLayer.lineCap = .round

        contentView.layer.addSublayer(thinGridLayer)
        contentView.layer.addSublayer(thickGridLayer)
        contentView.layer.addSublayer(premiumLossLayer)
    }

    private func layoutScrollView() {
        let contentWidth = leftColumnWidth + CGFloat(playerCount) * (trickColumnWidth + pointsColumnWidth)
        let contentHeight = headerHeight + CGFloat(layout.rows.count) * rowHeight
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = contentView.bounds.size
    }

    // MARK: - Создание лейблов (один раз)

    private func buildLabels() {
        guard !isLabelsBuilt else { return }
        isLabelsBuilt = true

        let headerFont = UIFont(name: "AvenirNext-Bold", size: 14)
        let cellFont = UIFont(name: "AvenirNext-Medium", size: 12)
        let summaryFont = UIFont(name: "AvenirNext-DemiBold", size: 12)

        // Заголовки игроков
        headerLabels = []
        for displayIndex in 0..<playerCount {
            let playerIndex = playerDisplayOrder[displayIndex]
            let headerLabel = UILabel()
            headerLabel.text = displayName(for: playerIndex)
            headerLabel.font = headerFont
            headerLabel.textAlignment = .center
            headerLabel.textColor = textPrimaryColor
            headerLabel.backgroundColor = surfaceColor
            headerLabel.adjustsFontSizeToFitWidth = true
            headerLabel.minimumScaleFactor = 0.65
            headerLabel.lineBreakMode = .byTruncatingTail
            contentView.addSubview(headerLabel)
            headerLabels.append(headerLabel)
        }

        // Строки таблицы
        cardsLabels = []
        tricksLabels = Array(repeating: [], count: layout.rows.count)
        pointsLabels = Array(repeating: [], count: layout.rows.count)

        for (rowIndex, rowKind) in layout.rows.enumerated() {
            let pointsLabelStyle = rowPresentationResolver.pointsLabelStyle(for: rowKind)

            let cardsLabel = UILabel()
            cardsLabel.font = cellFont
            cardsLabel.textAlignment = .center
            cardsLabel.textColor = textSecondaryColor
            cardsLabel.text = rowPresentationResolver.cardsLabelText(for: rowKind)
            contentView.addSubview(cardsLabel)
            cardsLabels.append(cardsLabel)

            for _ in 0..<playerCount {
                let tricksLabel = UILabel()
                tricksLabel.font = cellFont
                tricksLabel.textAlignment = .center
                tricksLabel.textColor = textSecondaryColor
                tricksLabel.text = ""
                contentView.addSubview(tricksLabel)
                tricksLabels[rowIndex].append(tricksLabel)

                let pointsLabel = UILabel()
                pointsLabel.font = pointsLabelStyle == .summary ? summaryFont : cellFont
                pointsLabel.textAlignment = .right
                pointsLabel.textColor = textPrimaryColor
                pointsLabel.text = ""
                contentView.addSubview(pointsLabel)
                pointsLabels[rowIndex].append(pointsLabel)
            }
        }
    }

    // MARK: - Репозиционирование лейблов (при каждом layoutSubviews)

    /// Пересчитываем frame лейблов при изменении размеров без пересоздания
    private func repositionLabels() {
        let frameResolver = makeLabelFrameResolver()

        // Заголовки
        for (playerIndex, headerLabel) in headerLabels.enumerated() {
            headerLabel.frame = frameResolver.headerFrame(displayIndex: playerIndex)
        }

        // Строки
        for rowIndex in 0..<layout.rows.count {
            cardsLabels[rowIndex].frame = frameResolver.cardsLabelFrame(rowIndex: rowIndex)

            for playerIndex in 0..<playerCount {
                tricksLabels[rowIndex][playerIndex].frame = frameResolver.tricksLabelFrame(
                    rowIndex: rowIndex,
                    displayIndex: playerIndex
                )
                pointsLabels[rowIndex][playerIndex].frame = frameResolver.pointsLabelFrame(
                    rowIndex: rowIndex,
                    displayIndex: playerIndex
                )
            }
        }
    }

    private func updatePinnedHeaderPosition() {
        let pinnedY = scrollView.contentOffset.y
        let frameResolver = makeLabelFrameResolver()

        for headerLabel in headerLabels {
            headerLabel.frame = frameResolver.pinnedHeaderFrame(
                from: headerLabel.frame,
                contentOffsetY: pinnedY
            )
            contentView.bringSubviewToFront(headerLabel)
        }
    }

    private func makeLabelFrameResolver() -> ScoreTableLabelFrameResolver {
        return ScoreTableLabelFrameResolver(
            leftColumnWidth: leftColumnWidth,
            trickColumnWidth: trickColumnWidth,
            pointsColumnWidth: pointsColumnWidth,
            headerHeight: headerHeight,
            rowHeight: rowHeight,
            pointsLabelTrailingInset: pointsLabelTrailingInset
        )
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePinnedHeaderPosition()
    }

    @objc private func handleTableTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        let locationInScrollView = recognizer.location(in: scrollView)
        let location = recognizer.location(in: contentView)
        guard let target = tapTargetResolver.dealRowTarget(
            scrollViewTapLocationY: locationInScrollView.y,
            contentTapLocation: location,
            contentWidth: contentView.bounds.width
        ) else { return }

        onDealRowTapped?(target.blockIndex, target.roundIndex)
    }

    // MARK: - Данные

    private func refreshRenderedScoreContentIfNeeded() {
        guard let scoreDataSnapshot else {
            if isScoreRowsDirty || isScoreDecorationsDirty {
                clearAllScoreLabels()
                clearPremiumDecorations()
                isScoreRowsDirty = false
                isScoreDecorationsDirty = false
            }
            return
        }

        if isScoreRowsDirty {
            applyScoreRows(from: scoreDataSnapshot)
            isScoreRowsDirty = false
        }

        if isScoreDecorationsDirty {
            guard canRenderPremiumDecorations else { return }
            renderPremiumDecorations(from: scoreDecorationsSnapshot)
            isScoreDecorationsDirty = false
        }
    }

    private var canRenderPremiumDecorations: Bool {
        return contentView.bounds.width > 0 && contentView.bounds.height > 0
    }

    private func applyScoreRows(from snapshot: ScoreDataSnapshot) {
        let rowTextSnapshot = rowTextRenderer.makeSnapshot(
            dataSnapshot: snapshot,
            inProgressRoundSnapshot: inProgressRoundSnapshot
        )

        for rowIndex in 0..<layout.rowMappings.count {
            for displayIndex in 0..<playerCount {
                tricksLabels[rowIndex][displayIndex].text = rowTextSnapshot.tricksTexts[rowIndex][displayIndex]
                pointsLabels[rowIndex][displayIndex].text = rowTextSnapshot.pointsTexts[rowIndex][displayIndex]
            }
        }
    }

    private func clearAllScoreLabels() {
        for rowIndex in 0..<layout.rows.count {
            cardsLabels[rowIndex].text = rowPresentationResolver.cardsLabelText(for: layout.rows[rowIndex])
            for displayIndex in 0..<playerCount {
                tricksLabels[rowIndex][displayIndex].text = ""
                pointsLabels[rowIndex][displayIndex].text = ""
            }
        }
    }

    private func clearPremiumDecorations() {
        premiumLossLayer.path = nil
        clearPremiumScoreStrikeLayers()
        clearPremiumTrophyLabels()
    }

    private func displayName(for playerIndex: Int) -> String {
        guard playerNames.indices.contains(playerIndex) else {
            return "Игрок \(playerIndex + 1)"
        }

        let trimmedName = playerNames[playerIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Игрок \(playerIndex + 1)" : trimmedName
    }

    private func addPremiumScoreStrikeLayer(on label: UILabel) {
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

    private func clearPremiumScoreStrikeLayers() {
        for layer in premiumScoreStrikeLayers {
            layer.removeFromSuperlayer()
        }
        premiumScoreStrikeLayers.removeAll()
    }

    private func renderPremiumDecorations(from snapshot: ScoreDecorationsSnapshot) {
        clearPremiumScoreStrikeLayers()
        renderPenaltyStrikeLayers(from: snapshot.penaltyStrikeCells)
        renderPremiumColumnMarks(snapshot.columnMarks)
    }

    private func renderPenaltyStrikeLayers(
        from strikeCells: Set<ScoreDecorationsSnapshot.PenaltyStrikeCell>
    ) {
        for strikeCell in strikeCells {
            guard pointsLabels.indices.contains(strikeCell.rowIndex) else { continue }
            guard let displayIndex = displayIndexByPlayerIndex[strikeCell.playerIndex] else { continue }
            guard pointsLabels[strikeCell.rowIndex].indices.contains(displayIndex) else { continue }
            addPremiumScoreStrikeLayer(on: pointsLabels[strikeCell.rowIndex][displayIndex])
        }
    }

    private func renderPremiumColumnMarks(
        _ marks: [ScoreDecorationsSnapshot.ColumnMark]
    ) {
        clearPremiumTrophyLabels()

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
            ).insetBy(dx: 3, dy: 3)
            guard markRect.width > 2, markRect.height > 2 else { continue }

            switch mark.kind {
            case .trophy:
                addPremiumTrophyMark(in: markRect)
            case .premiumLoss:
                path.move(to: CGPoint(x: markRect.minX, y: markRect.minY))
                path.addLine(to: CGPoint(x: markRect.maxX, y: markRect.maxY))
                path.move(to: CGPoint(x: markRect.minX, y: markRect.maxY))
                path.addLine(to: CGPoint(x: markRect.maxX, y: markRect.minY))
            }
        }

        premiumLossLayer.path = path.cgPath
    }

    private func addPremiumTrophyMark(in rect: CGRect) {
        let label = UILabel(frame: rect)
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.text = "🏆"
        label.font = UIFont.systemFont(ofSize: min(max(rect.height * 0.72, 17), 28))
        contentView.addSubview(label)
        premiumTrophyLabels.append(label)
    }

    private func clearPremiumTrophyLabels() {
        for label in premiumTrophyLabels {
            label.removeFromSuperview()
        }
        premiumTrophyLabels.removeAll()
    }

    // MARK: - Grid

    private func updateGridLayers() {
        let contentWidth = contentView.bounds.width
        let contentHeight = contentView.bounds.height

        let columnWidths: [CGFloat] = {
            var widths = [leftColumnWidth]
            for _ in 0..<playerCount {
                widths.append(trickColumnWidth)
                widths.append(pointsColumnWidth)
            }
            return widths
        }()

        var xPositions: [CGFloat] = [0]
        var currentX: CGFloat = 0
        for width in columnWidths {
            currentX += width
            xPositions.append(currentX)
        }

        var yPositions: [CGFloat] = [0, headerHeight]
        for rowIndex in 0..<layout.rows.count {
            let y = headerHeight + CGFloat(rowIndex + 1) * rowHeight
            yPositions.append(y)
        }

        let thinPath = UIBezierPath()
        for x in xPositions {
            thinPath.move(to: CGPoint(x: x, y: 0))
            thinPath.addLine(to: CGPoint(x: x, y: contentHeight))
        }
        for y in yPositions {
            thinPath.move(to: CGPoint(x: 0, y: y))
            thinPath.addLine(to: CGPoint(x: contentWidth, y: y))
        }
        thinGridLayer.path = thinPath.cgPath

        let thickPath = UIBezierPath()

        for blockEndIndex in layout.blockEndRowIndices.dropLast() {
            let y = headerHeight + CGFloat(blockEndIndex + 1) * rowHeight
            thickPath.move(to: CGPoint(x: 0, y: y))
            thickPath.addLine(to: CGPoint(x: contentWidth, y: y))
        }

        for playerIndex in 0..<playerCount {
            let x = leftColumnWidth + CGFloat(playerIndex + 1) * (trickColumnWidth + pointsColumnWidth)
            thickPath.move(to: CGPoint(x: x, y: 0))
            thickPath.addLine(to: CGPoint(x: x, y: contentHeight))
        }

        thickGridLayer.path = thickPath.cgPath
    }

    private func updateColumnWidths() {
        let minLeft: CGFloat = 36
        let minTricks: CGFloat = 44
        let minPoints: CGFloat = 64

        let availableWidth = max(bounds.width, 1)
        let minTotal = minLeft + CGFloat(playerCount) * (minTricks + minPoints)

        if availableWidth <= minTotal {
            leftColumnWidth = minLeft
            trickColumnWidth = minTricks
            pointsColumnWidth = minPoints
            return
        }

        leftColumnWidth = minLeft
        trickColumnWidth = minTricks
        let extra = availableWidth - (leftColumnWidth + CGFloat(playerCount) * trickColumnWidth)
        pointsColumnWidth = extra / CGFloat(playerCount)
    }

    private func currentGeometrySignature() -> GeometrySignature {
        return GeometrySignature(
            boundsSize: bounds.size,
            contentSize: contentView.bounds.size,
            leftColumnWidth: leftColumnWidth,
            trickColumnWidth: trickColumnWidth,
            pointsColumnWidth: pointsColumnWidth
        )
    }

    // MARK: - Layout Builder

    private static func buildLayout(playerCount: Int) -> Layout {
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

        return Layout(rows: rows, blockEndRowIndices: blockEndRowIndices, rowMappings: rowMappings)
    }

    private static func buildPlayerDisplayOrder(playerCount: Int, startIndex: Int) -> [Int] {
        guard playerCount > 0 else { return [] }
        let normalizedStart = ((startIndex % playerCount) + playerCount) % playerCount
        return (0..<playerCount).map { offset in
            (normalizedStart + offset) % playerCount
        }
    }

    private static func buildDisplayIndexByPlayerIndex(
        playerDisplayOrder: [Int]
    ) -> [Int: Int] {
        var map: [Int: Int] = [:]
        for (displayIndex, playerIndex) in playerDisplayOrder.enumerated() {
            map[playerIndex] = displayIndex
        }
        return map
    }
}
