//
//  ScoreTableView.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

final class ScoreTableView: UIView, UIScrollViewDelegate {

    private enum RowKind: Equatable {
        case deal(cards: Int)
        case subtotal
        case cumulative
    }

    private struct Layout {
        let rows: [RowKind]
        let blockEndRowIndices: [Int]
        let rowMappings: [RowMapping]
    }

    private struct RowMapping {
        let kind: RowKind
        let blockIndex: Int
        let roundIndex: Int?
    }

    private let playerCount: Int
    private let playerDisplayOrder: [Int]
    private let playerNames: [String]
    private let layout: Layout
    private var scoreManager: ScoreManager?
    var onDealRowTapped: ((Int, Int) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let thinGridLayer = CAShapeLayer()
    private let thickGridLayer = CAShapeLayer()
    private let premiumLossLayer = CAShapeLayer()
    private var premiumTrophyLabels: [UILabel] = []

    private var leftColumnWidth: CGFloat = 36
    private var trickColumnWidth: CGFloat = 44
    private var pointsColumnWidth: CGFloat = 64
    private let headerHeight: CGFloat = 28
    private let rowHeight: CGFloat = 24

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

    private static let summaryScoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }()

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
        self.playerNames = playerNames
        self.layout = ScoreTableView.buildLayout(playerCount: playerCount)
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
        applyScoreDataIfNeeded()
    }

    func update(with scoreManager: ScoreManager) {
        self.scoreManager = scoreManager
        applyScoreDataIfNeeded()
    }

    func scrollToDeal(blockIndex: Int, roundIndex: Int, animated: Bool) {
        layoutIfNeeded()

        guard let targetRowIndex = targetDealRowIndex(blockIndex: blockIndex, roundIndex: roundIndex) else {
            return
        }

        scrollToRow(targetRowIndex, animated: animated)
    }

    func scrollToBlockSummary(blockIndex: Int, animated: Bool) {
        layoutIfNeeded()

        guard let targetRowIndex = targetSummaryRowIndex(blockIndex: blockIndex) else {
            return
        }

        scrollToRow(targetRowIndex, animated: animated)
    }

    private func scrollToRow(_ rowIndex: Int, animated: Bool) {
        let rowTop = headerHeight + CGFloat(rowIndex) * rowHeight
        let visibleHeight = max(scrollView.bounds.height, 1)
        let maxOffsetY = max(0, scrollView.contentSize.height - visibleHeight)
        let centeredOffsetY = rowTop - (visibleHeight - rowHeight) / 2
        let targetOffsetY = min(max(0, centeredOffsetY), maxOffsetY)

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
        premiumLossLayer.strokeColor = UIColor(red: 0.86, green: 0.23, blue: 0.15, alpha: 0.95).cgColor
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
            let isSummary = rowKind == .subtotal || rowKind == .cumulative

            let cardsLabel = UILabel()
            cardsLabel.font = cellFont
            cardsLabel.textAlignment = .center
            cardsLabel.textColor = textSecondaryColor
            if case let .deal(cards) = rowKind {
                cardsLabel.text = "\(cards)"
            } else {
                cardsLabel.text = ""
            }
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
                pointsLabel.font = isSummary ? summaryFont : cellFont
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
        // Заголовки
        for (playerIndex, headerLabel) in headerLabels.enumerated() {
            headerLabel.frame = CGRect(
                x: leftColumnWidth + CGFloat(playerIndex) * (trickColumnWidth + pointsColumnWidth),
                y: 0,
                width: trickColumnWidth + pointsColumnWidth,
                height: headerHeight
            )
        }

        // Строки
        for rowIndex in 0..<layout.rows.count {
            let rowY = headerHeight + CGFloat(rowIndex) * rowHeight

            cardsLabels[rowIndex].frame = CGRect(x: 0, y: rowY, width: leftColumnWidth, height: rowHeight)

            for playerIndex in 0..<playerCount {
                let baseX = leftColumnWidth + CGFloat(playerIndex) * (trickColumnWidth + pointsColumnWidth)

                tricksLabels[rowIndex][playerIndex].frame = CGRect(
                    x: baseX, y: rowY, width: trickColumnWidth, height: rowHeight
                )
                pointsLabels[rowIndex][playerIndex].frame = CGRect(
                    x: baseX + trickColumnWidth, y: rowY, width: pointsColumnWidth - 4, height: rowHeight
                )
            }
        }
    }

    private func updatePinnedHeaderPosition() {
        let pinnedY = scrollView.contentOffset.y

        for headerLabel in headerLabels {
            var frame = headerLabel.frame
            frame.origin.y = pinnedY
            headerLabel.frame = frame
            contentView.bringSubviewToFront(headerLabel)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePinnedHeaderPosition()
    }

    @objc private func handleTableTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        let locationInScrollView = recognizer.location(in: scrollView)
        guard locationInScrollView.y >= headerHeight else { return }

        let location = recognizer.location(in: contentView)
        guard location.x >= 0, location.x <= contentView.bounds.width else { return }

        let rowIndex = Int((location.y - headerHeight) / rowHeight)
        guard layout.rowMappings.indices.contains(rowIndex) else { return }

        let mapping = layout.rowMappings[rowIndex]
        guard case .deal = mapping.kind else { return }
        guard let roundIndex = mapping.roundIndex else { return }

        onDealRowTapped?(mapping.blockIndex, roundIndex)
    }

    // MARK: - Данные

    private func applyScoreDataIfNeeded() {
        guard let scoreManager = scoreManager else {
            premiumLossLayer.path = nil
            clearPremiumTrophyLabels()
            return
        }

        let completedBlocks = scoreManager.completedBlocks
        let currentBlockResults = scoreManager.currentBlockRoundResults
        let currentBlockScores = scoreManager.currentBlockBaseScores

        for (rowIndex, mapping) in layout.rowMappings.enumerated() {
            switch mapping.kind {
            case .deal:
                applyDealRow(
                    rowIndex: rowIndex,
                    blockIndex: mapping.blockIndex,
                    roundIndex: mapping.roundIndex ?? 0,
                    completedBlocks: completedBlocks,
                    currentBlockResults: currentBlockResults
                )
            case .subtotal:
                applySubtotalRow(
                    rowIndex: rowIndex,
                    blockIndex: mapping.blockIndex,
                    completedBlocks: completedBlocks,
                    currentBlockScores: currentBlockScores
                )
            case .cumulative:
                applyCumulativeRow(
                    rowIndex: rowIndex,
                    blockIndex: mapping.blockIndex,
                    completedBlocks: completedBlocks,
                    currentBlockScores: currentBlockScores
                )
            }
        }

        updatePremiumLossMarks(
            completedBlocks: completedBlocks,
            currentBlockResults: currentBlockResults
        )
    }

    private func displayName(for playerIndex: Int) -> String {
        guard playerNames.indices.contains(playerIndex) else {
            return "Игрок \(playerIndex + 1)"
        }

        let trimmedName = playerNames[playerIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Игрок \(playerIndex + 1)" : trimmedName
    }

    private func targetDealRowIndex(blockIndex: Int, roundIndex: Int) -> Int? {
        let dealRows = layout.rowMappings.enumerated().compactMap { (rowIndex, mapping) -> (rowIndex: Int, roundIndex: Int)? in
            guard mapping.blockIndex == blockIndex else { return nil }

            if case .deal = mapping.kind {
                return (rowIndex, mapping.roundIndex ?? 0)
            }

            return nil
        }

        guard !dealRows.isEmpty else { return nil }

        let safeRound = min(max(roundIndex, 0), dealRows.count - 1)
        if let exactMatch = dealRows.first(where: { $0.roundIndex == safeRound }) {
            return exactMatch.rowIndex
        }

        return dealRows[safeRound].rowIndex
    }

    private func targetSummaryRowIndex(blockIndex: Int) -> Int? {
        return summaryRowsForBlock(blockIndex).max()
    }

    private func applyDealRow(
        rowIndex: Int,
        blockIndex: Int,
        roundIndex: Int,
        completedBlocks: [BlockResult],
        currentBlockResults: [[RoundResult]]
    ) {
        let results: [[RoundResult]]?
        let isCurrentBlock = blockIndex == completedBlocks.count

        if blockIndex < completedBlocks.count {
            results = completedBlocks[blockIndex].roundResults
        } else if isCurrentBlock {
            results = currentBlockResults
        } else {
            results = nil
        }

        for displayIndex in 0..<playerCount {
            let playerIndex = playerDisplayOrder[displayIndex]
            let tricksLabel = tricksLabels[rowIndex][displayIndex]
            let pointsLabel = pointsLabels[rowIndex][displayIndex]

            if
                let results = results,
                playerIndex < results.count,
                roundIndex < results[playerIndex].count
            {
                let roundResult = results[playerIndex][roundIndex]
                applyRoundResult(
                    roundResult,
                    to: tricksLabel,
                    pointsLabel: pointsLabel,
                    displayedTricksTaken: nil,
                    pointsText: "\(roundResult.score)"
                )
                continue
            }

            if
                isCurrentBlock,
                let inProgressResult = scoreManager?.inProgressRoundResult(
                    forBlockIndex: blockIndex,
                    roundIndex: roundIndex,
                    playerIndex: playerIndex
                )
            {
                applyRoundResult(
                    inProgressResult,
                    to: tricksLabel,
                    pointsLabel: pointsLabel,
                    displayedTricksTaken: 0,
                    pointsText: "0"
                )
                continue
            }

            tricksLabel.text = ""
            pointsLabel.text = ""
        }
    }

    private func applyRoundResult(
        _ roundResult: RoundResult,
        to tricksLabel: UILabel,
        pointsLabel: UILabel,
        displayedTricksTaken: Int?,
        pointsText: String
    ) {
        let tricksTaken = displayedTricksTaken ?? roundResult.tricksTaken
        if roundResult.isBlind {
            tricksLabel.text = "\(circledBidText(roundResult.bid))/\(tricksTaken)"
        } else {
            tricksLabel.text = "\(roundResult.bid)/\(tricksTaken)"
        }
        pointsLabel.text = pointsText
    }

    private func circledBidText(_ bid: Int) -> String {
        switch bid {
        case 0: return "⓪"
        case 1...20:
            if let scalar = UnicodeScalar(0x2460 + bid - 1) {
                return String(scalar)
            }
            return "\(bid)"
        default:
            return "\(bid)"
        }
    }

    private func applySubtotalRow(
        rowIndex: Int,
        blockIndex: Int,
        completedBlocks: [BlockResult],
        currentBlockScores: [Int]
    ) {
        let scores: [Int]?

        if blockIndex < completedBlocks.count {
            scores = completedBlocks[blockIndex].finalScores
        } else if blockIndex == completedBlocks.count {
            scores = currentBlockScores
        } else {
            scores = nil
        }

        applySummaryRow(rowIndex: rowIndex, scores: scores)
    }

    private func applyCumulativeRow(
        rowIndex: Int,
        blockIndex: Int,
        completedBlocks: [BlockResult],
        currentBlockScores: [Int]
    ) {
        let scores: [Int]?

        if blockIndex < completedBlocks.count {
            scores = cumulativeScores(through: blockIndex, completedBlocks: completedBlocks)
        } else if blockIndex == completedBlocks.count {
            scores = cumulativeScoresIncludingCurrent(completedBlocks: completedBlocks, currentBlockScores: currentBlockScores)
        } else {
            scores = nil
        }

        applySummaryRow(rowIndex: rowIndex, scores: scores)
    }

    private func displayedSummaryScore(from rawScore: Int) -> String {
        let value = NSNumber(value: Double(rawScore) / 100.0)
        return Self.summaryScoreFormatter.string(from: value) ?? "0,0"
    }

    private func applySummaryRow(rowIndex: Int, scores: [Int]?) {
        for displayIndex in 0..<playerCount {
            let playerIndex = playerDisplayOrder[displayIndex]
            tricksLabels[rowIndex][displayIndex].text = ""
            if let score = summaryScore(for: playerIndex, in: scores) {
                pointsLabels[rowIndex][displayIndex].text = displayedSummaryScore(from: score)
            } else {
                pointsLabels[rowIndex][displayIndex].text = ""
            }
        }
    }

    private func cumulativeScores(through blockIndex: Int, completedBlocks: [BlockResult]) -> [Int] {
        var scores = Array(repeating: 0, count: playerCount)
        guard !completedBlocks.isEmpty else { return scores }

        for index in 0...min(blockIndex, completedBlocks.count - 1) {
            let block = completedBlocks[index]
            for playerIndex in 0..<playerCount {
                if block.finalScores.indices.contains(playerIndex) {
                    scores[playerIndex] += block.finalScores[playerIndex]
                }
            }
        }

        return scores
    }

    private func updatePremiumLossMarks(
        completedBlocks: [BlockResult],
        currentBlockResults: [[RoundResult]]
    ) {
        clearPremiumTrophyLabels()

        let path = UIBezierPath()
        let maxBlockIndex = layout.rowMappings.map(\.blockIndex).max() ?? -1
        guard maxBlockIndex >= 0 else {
            premiumLossLayer.path = nil
            return
        }

        for blockIndex in 0...maxBlockIndex {
            let roundResultsByPlayer: [[RoundResult]]?
            if blockIndex < completedBlocks.count {
                roundResultsByPlayer = completedBlocks[blockIndex].roundResults
            } else if blockIndex == completedBlocks.count {
                roundResultsByPlayer = currentBlockResults
            } else {
                roundResultsByPlayer = nil
            }

            guard let roundResultsByPlayer else { continue }
            let summaryRows = summaryRowsForBlock(blockIndex)
            guard !summaryRows.isEmpty else { continue }
            let sortedRows = summaryRows.sorted()
            guard
                let topRowIndex = sortedRows.first,
                let bottomRowIndex = sortedRows.last
            else {
                continue
            }

            let premiumPlayers: Set<Int>
            if blockIndex < completedBlocks.count {
                let block = completedBlocks[blockIndex]
                premiumPlayers = Set(block.premiumPlayerIndices + block.zeroPremiumPlayerIndices)
            } else {
                premiumPlayers = []
            }

            for displayIndex in 0..<playerCount {
                let playerIndex = playerDisplayOrder[displayIndex]
                guard playerIndex < roundResultsByPlayer.count else { continue }
                let baseX = leftColumnWidth + CGFloat(displayIndex) * (trickColumnWidth + pointsColumnWidth)

                let topY = headerHeight + CGFloat(topRowIndex) * rowHeight
                let height = CGFloat(bottomRowIndex - topRowIndex + 1) * rowHeight
                let markRect = CGRect(x: baseX, y: topY, width: trickColumnWidth, height: height).insetBy(dx: 3, dy: 3)
                guard markRect.width > 2, markRect.height > 2 else { continue }

                if premiumPlayers.contains(playerIndex) {
                    addPremiumTrophyMark(in: markRect)
                    continue
                }

                let playerRoundResults = roundResultsByPlayer[playerIndex]
                guard hasLostPremium(in: playerRoundResults) else { continue }

                path.move(to: CGPoint(x: markRect.minX, y: markRect.minY))
                path.addLine(to: CGPoint(x: markRect.maxX, y: markRect.maxY))
                path.move(to: CGPoint(x: markRect.minX, y: markRect.maxY))
                path.addLine(to: CGPoint(x: markRect.maxX, y: markRect.minY))
            }
        }

        premiumLossLayer.path = path.cgPath
    }

    private func hasLostPremium(in roundResults: [RoundResult]) -> Bool {
        return roundResults.contains(where: { $0.bid != $0.tricksTaken })
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

    private func summaryRowsForBlock(_ blockIndex: Int) -> [Int] {
        return layout.rowMappings.enumerated().compactMap { rowIndex, mapping in
            guard mapping.blockIndex == blockIndex else { return nil }
            switch mapping.kind {
            case .subtotal, .cumulative:
                return rowIndex
            case .deal:
                return nil
            }
        }
    }

    private func cumulativeScoresIncludingCurrent(
        completedBlocks: [BlockResult],
        currentBlockScores: [Int]
    ) -> [Int] {
        var scores = cumulativeScores(through: completedBlocks.count - 1, completedBlocks: completedBlocks)
        for playerIndex in 0..<playerCount {
            if currentBlockScores.indices.contains(playerIndex) {
                scores[playerIndex] += currentBlockScores[playerIndex]
            }
        }
        return scores
    }

    private func summaryScore(for playerIndex: Int, in scores: [Int]?) -> Int? {
        guard let scores else { return nil }
        guard scores.indices.contains(playerIndex) else { return nil }
        return scores[playerIndex]
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
}
