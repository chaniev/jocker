//
//  GameResultsViewController.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class GameResultsViewController: UIViewController {
    private struct TableColumn {
        let title: String
        let width: CGFloat
        let alignment: NSTextAlignment
    }

    private enum Appearance {
        static let headerCellColor = UIColor(red: 0.17, green: 0.24, blue: 0.38, alpha: 0.96)
        static let rowCellColor = UIColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 0.95)
        static let rowAlternateCellColor = UIColor(red: 0.08, green: 0.13, blue: 0.22, alpha: 0.95)
        static let headerTextColor = GameColors.gold
        static let rowTextColor = PanelAppearance.primaryTextColor
        static let gridBorderColor = UIColor(red: 0.30, green: 0.41, blue: 0.60, alpha: 0.82)
    }

    private enum Layout {
        static let closeButtonHeight: CGFloat = 50
        static let headerRowHeight: CGFloat = 50
        static let rowHeight: CGFloat = 44
    }

    private let gameMode: GameMode
    private let playerSummaries: [GameFinalPlayerSummary]
    private let teamSummaries: [GameFinalTeamSummary]
    private let onClose: (() -> Void)?
    private var isClosing = false

    init(
        gameMode: GameMode = .freeForAll,
        playerSummaries: [GameFinalPlayerSummary],
        teamSummaries: [GameFinalTeamSummary] = [],
        onClose: (() -> Void)? = nil
    ) {
        self.gameMode = gameMode
        self.playerSummaries = playerSummaries
        self.teamSummaries = teamSummaries
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = PanelAppearance.resultsOverlayColor

        let containerView = PanelContainerView(surfaceColor: PanelAppearance.resultsSurfaceColor)
        view.addSubview(containerView)

        let headerView = PanelHeaderView(
            title: "Итоги игры",
            subtitle: headerSubtitleText(),
            alignment: .center,
            titleFont: PanelTypography.resultsTitle,
            subtitleFont: PanelTypography.body
        )
        headerView.titleLabel.accessibilityIdentifier = "game_results_title_label"
        containerView.addSubview(headerView)

        let tableScrollView = UIScrollView()
        tableScrollView.translatesAutoresizingMaskIntoConstraints = false
        tableScrollView.alwaysBounceVertical = true
        tableScrollView.alwaysBounceHorizontal = true
        containerView.addSubview(tableScrollView)

        let tableContentView = UIView()
        tableContentView.translatesAutoresizingMaskIntoConstraints = false
        tableScrollView.addSubview(tableContentView)

        let tableStack = UIStackView()
        tableStack.translatesAutoresizingMaskIntoConstraints = false
        tableStack.axis = .vertical
        tableStack.spacing = 0
        tableStack.alignment = .leading
        tableContentView.addSubview(tableStack)

        let blockCount = max(playerSummaries.map { $0.blockScores.count }.max() ?? 0, GameConstants.totalBlocks)
        let totalTableWidth = makeResultsContent(
            in: tableStack,
            blockCount: blockCount
        )

        let closeButton = PrimaryPanelButton(title: "Закрыть и в меню")
        closeButton.accessibilityIdentifier = "game_results_close_button"
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.92),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 560),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.90),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360),

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            tableScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 14),
            tableScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tableScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            tableContentView.topAnchor.constraint(equalTo: tableScrollView.contentLayoutGuide.topAnchor),
            tableContentView.leadingAnchor.constraint(equalTo: tableScrollView.contentLayoutGuide.leadingAnchor),
            tableContentView.trailingAnchor.constraint(equalTo: tableScrollView.contentLayoutGuide.trailingAnchor),
            tableContentView.bottomAnchor.constraint(equalTo: tableScrollView.contentLayoutGuide.bottomAnchor),
            tableContentView.heightAnchor.constraint(greaterThanOrEqualTo: tableScrollView.frameLayoutGuide.heightAnchor),
            tableContentView.widthAnchor.constraint(equalToConstant: totalTableWidth),

            tableStack.topAnchor.constraint(equalTo: tableContentView.topAnchor),
            tableStack.leadingAnchor.constraint(equalTo: tableContentView.leadingAnchor),
            tableStack.trailingAnchor.constraint(equalTo: tableContentView.trailingAnchor),
            tableStack.bottomAnchor.constraint(equalTo: tableContentView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: tableScrollView.bottomAnchor, constant: 14),
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.closeButtonHeight),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func tableColumns(blockCount: Int) -> [TableColumn] {
        var columns: [TableColumn] = [
            TableColumn(title: "Игрок", width: 180, alignment: .left),
            TableColumn(title: "Итого", width: 110, alignment: .center)
        ]

        for blockIndex in 0..<blockCount {
            let blockNumber = blockIndex + 1
            columns.append(TableColumn(title: "Б\(blockNumber) очки", width: 110, alignment: .center))
            columns.append(TableColumn(title: "Б\(blockNumber) премия", width: 120, alignment: .center))
        }

        columns.append(TableColumn(title: "Премий всего", width: 120, alignment: .center))
        columns.append(TableColumn(title: "Темнил Б4", width: 110, alignment: .center))
        return columns
    }

    private func teamTableColumns(blockCount: Int) -> [TableColumn] {
        var columns: [TableColumn] = [
            TableColumn(title: "Пара", width: 220, alignment: .left)
        ]

        for blockIndex in 0..<blockCount {
            columns.append(TableColumn(title: "Б\(blockIndex + 1)", width: 96, alignment: .center))
        }

        columns.append(TableColumn(title: "Итого", width: 110, alignment: .center))
        return columns
    }

    private func rowValues(for summary: GameFinalPlayerSummary, blockCount: Int) -> [String] {
        var values: [String] = [
            summary.playerName,
            formattedScore(summary.totalScore)
        ]

        for blockIndex in 0..<blockCount {
            let blockScore = summary.blockScores.indices.contains(blockIndex)
                ? summary.blockScores[blockIndex]
                : 0
            let premiumTaken = summary.premiumTakenByBlock.indices.contains(blockIndex)
                ? summary.premiumTakenByBlock[blockIndex]
                : false

            values.append(formattedScore(blockScore))
            values.append(premiumTaken ? "Да" : "Нет")
        }

        values.append("\(summary.totalPremiumsTaken)")
        values.append("\(summary.fourthBlockBlindCount)")
        return values
    }

    private func teamRowValues(for summary: GameFinalTeamSummary, blockCount: Int) -> [String] {
        var values: [String] = [
            "\(summary.teamLabel) (\(summary.memberNames.joined(separator: " + ")))"
        ]

        for blockIndex in 0..<blockCount {
            let blockScore = summary.blockScores.indices.contains(blockIndex)
                ? summary.blockScores[blockIndex]
                : 0
            values.append(formattedScore(blockScore))
        }

        values.append(formattedScore(summary.totalScore))
        return values
    }

    private func makeResultsContent(
        in tableStack: UIStackView,
        blockCount: Int
    ) -> CGFloat {
        var totalWidth: CGFloat = 0

        if gameMode == .pairs, !teamSummaries.isEmpty {
            let titleLabel = makeSectionTitleLabel(text: "Пары")
            tableStack.addArrangedSubview(titleLabel)

            let teamColumns = teamTableColumns(blockCount: blockCount)
            totalWidth = max(totalWidth, teamColumns.reduce(CGFloat(0)) { $0 + $1.width })
            tableStack.addArrangedSubview(
                makeTableRow(
                    values: teamColumns.map(\.title),
                    columns: teamColumns,
                    isHeader: true,
                    isAlternate: false
                )
            )

            for (index, summary) in teamSummaries.enumerated() {
                tableStack.addArrangedSubview(
                    makeTableRow(
                        values: teamRowValues(for: summary, blockCount: blockCount),
                        columns: teamColumns,
                        isHeader: false,
                        isAlternate: index.isMultiple(of: 2)
                    )
                )
            }
        }

        let playerColumns = tableColumns(blockCount: blockCount)
        totalWidth = max(totalWidth, playerColumns.reduce(CGFloat(0)) { $0 + $1.width })
        if gameMode == .pairs, !teamSummaries.isEmpty {
            tableStack.addArrangedSubview(makeSectionTitleLabel(text: "Игроки"))
        }
        tableStack.addArrangedSubview(
            makeTableRow(
                values: playerColumns.map(\.title),
                columns: playerColumns,
                isHeader: true,
                isAlternate: false
            )
        )

        for (index, summary) in playerSummaries.enumerated() {
            tableStack.addArrangedSubview(
                makeTableRow(
                    values: rowValues(for: summary, blockCount: blockCount),
                    columns: playerColumns,
                    isHeader: false,
                    isAlternate: index.isMultiple(of: 2)
                )
            )
        }

        return totalWidth
    }

    private func headerSubtitleText() -> String {
        if gameMode == .pairs, let winner = teamSummaries.first {
            return "Победила \(winner.teamLabel) • по блокам и матчу видны суммы пары"
        }
        return "Строки: игроки, колонки: показатели"
    }

    private func makeSectionTitleLabel(text: String) -> UIView {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = PanelTypography.headerCell
        label.textColor = Appearance.headerTextColor
        label.backgroundColor = UIColor.clear
        label.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return label
    }

    private func makeTableRow(
        values: [String],
        columns: [TableColumn],
        isHeader: Bool,
        isAlternate: Bool
    ) -> UIView {
        let rowStack = UIStackView()
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.axis = .horizontal
        rowStack.spacing = 0
        rowStack.distribution = .fill

        let cellHeight = isHeader ? Layout.headerRowHeight : Layout.rowHeight
        let cellBackgroundColor: UIColor
        if isHeader {
            cellBackgroundColor = Appearance.headerCellColor
        } else {
            cellBackgroundColor = isAlternate ? Appearance.rowCellColor : Appearance.rowAlternateCellColor
        }

        let textColor = isHeader ? Appearance.headerTextColor : Appearance.rowTextColor
        let font = isHeader
            ? PanelTypography.headerCell
            : PanelTypography.modalSubtitle

        for (index, column) in columns.enumerated() {
            let cellLabel = UILabel()
            cellLabel.translatesAutoresizingMaskIntoConstraints = false
            cellLabel.text = values.indices.contains(index) ? values[index] : ""
            cellLabel.textAlignment = column.alignment
            cellLabel.font = font
            cellLabel.textColor = textColor
            cellLabel.numberOfLines = isHeader ? 2 : 1
            cellLabel.backgroundColor = cellBackgroundColor
            cellLabel.layer.borderWidth = 0.5
            cellLabel.layer.borderColor = Appearance.gridBorderColor.cgColor
            if column.alignment == .left {
                cellLabel.text = "  \(cellLabel.text ?? "")"
            }

            NSLayoutConstraint.activate([
                cellLabel.widthAnchor.constraint(equalToConstant: column.width),
                cellLabel.heightAnchor.constraint(equalToConstant: cellHeight)
            ])

            rowStack.addArrangedSubview(cellLabel)
        }

        return rowStack
    }

    private func formattedScore(_ rawScore: Int) -> String {
        let scoreValue = Double(rawScore) / 100.0
        return String(format: "%.1f", locale: Locale(identifier: "ru_RU"), scoreValue)
    }

    @objc
    private func handleCloseTapped() {
        guard !isClosing else { return }
        isClosing = true

        dismiss(animated: true) { [onClose] in
            onClose?()
        }
    }
}
