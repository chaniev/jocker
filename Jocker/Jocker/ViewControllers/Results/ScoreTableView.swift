//
//  ScoreTableView.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import UIKit

/// Таблица очков — координирует компоненты: layout, лейблы, сетку, декорации.
final class ScoreTableView: UIView, UIScrollViewDelegate {
    typealias RowKind = ScoreTableLayout.RowKind
    typealias RowMapping = ScoreTableLayout.RowMapping

    private typealias ScoreDataSnapshot = ScoreTableRenderSnapshotBuilder.ScoreDataSnapshot
    private typealias ScoreDecorationsSnapshot = ScoreTableRenderSnapshotBuilder.ScoreDecorationsSnapshot
    private typealias InProgressRoundSnapshot = ScoreTableInProgressRoundSnapshotProvider.Snapshot

    private let playerCount: Int
    private let playerDisplayOrder: [Int]
    private let displayIndexByPlayerIndex: [Int: Int]
    private let playerNames: [String]
    private let layout: ScoreTableLayout
    private let layoutData: ScoreTableLayout.LayoutData
    private let snapshotBuilder: ScoreTableRenderSnapshotBuilder
    private let inProgressRoundSnapshotProvider: ScoreTableInProgressRoundSnapshotProvider
    private let rowNavigationResolver: ScoreTableRowNavigationResolver
    private let scrollOffsetResolver: ScoreTableScrollOffsetResolver
    private let tapTargetResolver: ScoreTableTapTargetResolver
    private let rowTextRenderer: ScoreTableRowTextRenderer

    // Компоненты
    private let labelManager: ScoreTableLabelManager
    private let gridRenderer: ScoreTableGridRenderer
    private let premiumDecorator: ScoreTablePremiumDecorator

    private var scoreDataSnapshot: ScoreDataSnapshot?
    private var scoreDecorationsSnapshot: ScoreDecorationsSnapshot = .empty
    private var inProgressRoundSnapshot: InProgressRoundSnapshot = .empty
    private var isScoreRowsDirty = false
    private var isScoreDecorationsDirty = false
    private var lastGeometrySignature: ScoreTableLayout.GeometrySignature?
    private var columnWidths: ScoreTableLayout.ColumnWidths = .init(leftColumn: 36, trickColumn: 44, pointsColumn: 64)

    var onDealRowTapped: ((Int, Int) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerHeight: CGFloat = 28
    private let rowHeight: CGFloat = 24
    private let surfaceColor = UIColor.white

    // MARK: - Инициализация

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

        // Создаём layout
        self.layout = ScoreTableLayout(playerCount: playerCount, headerHeight: headerHeight, rowHeight: rowHeight)
        self.layoutData = layout.buildLayoutData()

        // Создаём сервисы
        self.snapshotBuilder = ScoreTableRenderSnapshotBuilder(
            playerCount: playerCount,
            rowMappings: self.layoutData.rowMappings
        )
        self.inProgressRoundSnapshotProvider = ScoreTableInProgressRoundSnapshotProvider(
            playerCount: playerCount,
            rowMappings: self.layoutData.rowMappings
        )
        self.rowNavigationResolver = ScoreTableRowNavigationResolver(rowMappings: self.layoutData.rowMappings)
        self.scrollOffsetResolver = ScoreTableScrollOffsetResolver(headerHeight: headerHeight, rowHeight: rowHeight)
        self.tapTargetResolver = ScoreTableTapTargetResolver(
            rowMappings: self.layoutData.rowMappings,
            headerHeight: headerHeight,
            rowHeight: rowHeight
        )
        self.rowTextRenderer = ScoreTableRowTextRenderer(
            playerCount: playerCount,
            playerDisplayOrder: self.playerDisplayOrder,
            rowMappings: self.layoutData.rowMappings
        )

        // Создаём компоненты
        self.labelManager = ScoreTableLabelManager(
            playerCount: playerCount,
            playerDisplayOrder: self.playerDisplayOrder,
            rowMappings: self.layoutData.rowMappings,
            headerHeight: headerHeight,
            rowHeight: rowHeight,
            leftColumnWidth: columnWidths.leftColumn,
            trickColumnWidth: columnWidths.trickColumn,
            pointsColumnWidth: columnWidths.pointsColumn
        )
        self.gridRenderer = ScoreTableGridRenderer(
            playerCount: playerCount,
            layout: self.layout,
            headerHeight: headerHeight,
            rowHeight: rowHeight
        )
        self.premiumDecorator = ScoreTablePremiumDecorator(
            playerCount: playerCount,
            displayIndexByPlayerIndex: self.displayIndexByPlayerIndex,
            layout: self.layout,
            headerHeight: headerHeight,
            rowHeight: rowHeight,
            leftColumnWidth: columnWidths.leftColumn,
            trickColumnWidth: columnWidths.trickColumn,
            pointsColumnWidth: columnWidths.pointsColumn
        )

        super.init(frame: .zero)
        setupView()
        buildLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateColumnWidths()
        layoutScrollView()
        labelManager.updateRowFrames()
        labelManager.updatePinnedHeaderPosition(contentOffsetY: scrollView.contentOffset.y)
        updateGridLayers()

        let geometrySignature = currentGeometrySignature()
        if lastGeometrySignature != geometrySignature {
            lastGeometrySignature = geometrySignature
            isScoreDecorationsDirty = true
        }

        refreshRenderedScoreContentIfNeeded()
    }

    // MARK: - Public API

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

        gridRenderer.addLayers(to: contentView)
        premiumDecorator.addPremiumLossLayer(to: contentView)
    }

    private func buildLabels() {
        labelManager.buildLabels(in: contentView)
        labelManager.updateHeaderNames(playerNames: playerNames)
    }

    private func layoutScrollView() {
        let contentSize = layout.calculateContentSize(columnWidths: columnWidths)
        contentView.frame = CGRect(origin: .zero, size: contentSize)
        scrollView.contentSize = contentSize
    }

    // MARK: - Scroll

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        labelManager.updatePinnedHeaderPosition(contentOffsetY: scrollView.contentOffset.y)
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

    // MARK: - Tap Handling

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

    // MARK: - Column Widths

    private func updateColumnWidths() {
        columnWidths = layout.calculateColumnWidths(availableWidth: max(bounds.width, 1))
    }

    // MARK: - Grid

    private func updateGridLayers() {
        gridRenderer.updateGridLayers(in: contentView, columnWidths: columnWidths)
    }

    // MARK: - Content Refresh

    private func refreshRenderedScoreContentIfNeeded() {
        guard let scoreDataSnapshot else {
            if isScoreRowsDirty || isScoreDecorationsDirty {
                labelManager.clearTexts()
                premiumDecorator.clearDecorations()
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
            premiumDecorator.renderDecorations(
                from: scoreDecorationsSnapshot,
                pointsLabels: labelManager.pointsLabels,
                in: contentView
            )
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

        labelManager.updateTexts(
            tricksTexts: rowTextSnapshot.tricksTexts,
            pointsTexts: rowTextSnapshot.pointsTexts
        )
    }

    private func currentGeometrySignature() -> ScoreTableLayout.GeometrySignature {
        return layout.makeGeometrySignature(
            boundsSize: bounds.size,
            columnWidths: columnWidths,
            contentSize: contentView.bounds.size
        )
    }

    // MARK: - Helpers

    private static func buildPlayerDisplayOrder(playerCount: Int, startIndex: Int) -> [Int] {
        guard playerCount > 0 else { return [] }
        let normalizedStart = ((startIndex % playerCount) + playerCount) % playerCount
        return (0..<playerCount).map { offset in
            (normalizedStart + offset) % playerCount
        }
    }

    private static func buildDisplayIndexByPlayerIndex(playerDisplayOrder: [Int]) -> [Int: Int] {
        var map: [Int: Int] = [:]
        for (displayIndex, playerIndex) in playerDisplayOrder.enumerated() {
            map[playerIndex] = displayIndex
        }
        return map
    }
}
