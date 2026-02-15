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
        static let overlayColor = GameColors.sceneBackground.withAlphaComponent(0.72)
        static let containerColor = UIColor(red: 0.12, green: 0.17, blue: 0.27, alpha: 0.97)
        static let borderColor = GameColors.goldTranslucent
        static let titleColor = GameColors.textPrimary
        static let secondaryTextColor = GameColors.textSecondary
        static let headerCellColor = UIColor(red: 0.17, green: 0.24, blue: 0.38, alpha: 0.96)
        static let rowCellColor = UIColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 0.95)
        static let rowAlternateCellColor = UIColor(red: 0.08, green: 0.13, blue: 0.22, alpha: 0.95)
        static let headerTextColor = GameColors.gold
        static let rowTextColor = GameColors.textPrimary
        static let gridBorderColor = UIColor(red: 0.30, green: 0.41, blue: 0.60, alpha: 0.82)
        static let buttonColor = GameColors.buttonFill
        static let buttonTextColor = GameColors.buttonText
    }

    private enum Layout {
        static let containerCornerRadius: CGFloat = 16
        static let closeButtonHeight: CGFloat = 50
        static let headerRowHeight: CGFloat = 50
        static let rowHeight: CGFloat = 44
    }

    private let playerSummaries: [GameFinalPlayerSummary]
    private let onClose: (() -> Void)?
    private var isClosing = false

    init(
        playerSummaries: [GameFinalPlayerSummary],
        onClose: (() -> Void)? = nil
    ) {
        self.playerSummaries = playerSummaries
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
        view.backgroundColor = Appearance.overlayColor

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = Appearance.containerColor
        containerView.layer.cornerRadius = Layout.containerCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = Appearance.borderColor.cgColor
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        let titleLabel = makeLabel(
            text: "Итоги игры",
            font: UIFont(name: "AvenirNext-Bold", size: 28),
            color: Appearance.titleColor
        )
        containerView.addSubview(titleLabel)

        let subtitleLabel = makeLabel(
            text: "Строки: игроки, колонки: показатели",
            font: UIFont(name: "AvenirNext-Medium", size: 15),
            color: Appearance.secondaryTextColor
        )
        subtitleLabel.numberOfLines = 2
        containerView.addSubview(subtitleLabel)

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
        let columns = tableColumns(blockCount: blockCount)
        let totalTableWidth = columns.reduce(CGFloat(0)) { $0 + $1.width }

        tableStack.addArrangedSubview(
            makeTableRow(
                values: columns.map(\.title),
                columns: columns,
                isHeader: true,
                isAlternate: false
            )
        )

        for (index, summary) in playerSummaries.enumerated() {
            tableStack.addArrangedSubview(
                makeTableRow(
                    values: rowValues(for: summary, blockCount: blockCount),
                    columns: columns,
                    isHeader: false,
                    isAlternate: index.isMultiple(of: 2)
                )
            )
        }

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Закрыть и в меню", for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        closeButton.setTitleColor(Appearance.buttonTextColor, for: .normal)
        closeButton.backgroundColor = Appearance.buttonColor
        closeButton.layer.cornerRadius = 12
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = GameColors.buttonStroke.cgColor
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.92),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 560),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.90),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            tableScrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
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
            ? UIFont(name: "AvenirNext-Bold", size: 14)
            : UIFont(name: "AvenirNext-Medium", size: 14)

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

    private func makeLabel(
        text: String,
        font: UIFont?,
        color: UIColor
    ) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        return label
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
