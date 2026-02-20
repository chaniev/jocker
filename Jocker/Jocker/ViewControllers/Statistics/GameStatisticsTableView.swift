//
//  GameStatisticsTableView.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import UIKit

final class GameStatisticsTableView: UIView {
    private enum Layout {
        static let minimumMetricColumnWidth: CGFloat = 150
        static let preferredMetricColumnWidth: CGFloat = 170
        static let maximumMetricColumnWidth: CGFloat = 190
        static let minimumPlayerColumnWidth: CGFloat = 115
        static let maximumPlayerColumnWidth: CGFloat = 145
        static let rowHeight: CGFloat = 48
    }

    private enum Appearance {
        static let borderColor = GameColors.goldTranslucent.withAlphaComponent(0.55)
        static let headerBackground = UIColor(red: 0.24, green: 0.32, blue: 0.48, alpha: 1.0)
        static let oddRowBackground = UIColor(red: 0.16, green: 0.21, blue: 0.31, alpha: 1.0)
        static let evenRowBackground = UIColor(red: 0.13, green: 0.18, blue: 0.28, alpha: 1.0)
        static let titleColor = GameColors.textPrimary
        static let valueColor = GameColors.textSecondary
    }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let rowsStackView = UIStackView()

    private var contentWidthConstraint: NSLayoutConstraint?
    private var metricColumnWidth: CGFloat = Layout.preferredMetricColumnWidth
    private var playerColumnWidth: CGFloat = Layout.minimumPlayerColumnWidth
    private static let scoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        records: [GameStatisticsPlayerRecord],
        visiblePlayerCount: Int,
        playerNames: [String]
    ) {
        let playerCount = max(1, visiblePlayerCount)
        let sortedRecords = records.sorted { $0.playerIndex < $1.playerIndex }
        var shownRecords = Array(sortedRecords.prefix(playerCount))

        if shownRecords.count < playerCount {
            let startIndex = shownRecords.count
            for playerIndex in startIndex..<playerCount {
                shownRecords.append(GameStatisticsPlayerRecord.empty(playerIndex: playerIndex))
            }
        }

        resolveColumnWidths(playerCount: playerCount)
        rebuildRows(
            records: shownRecords,
            playerNames: playerNames,
            showFourthPlaceRow: playerCount >= 4
        )
        updateContentWidth(playerCount: playerCount)
    }

    private func setupView() {
        backgroundColor = .clear

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        rowsStackView.translatesAutoresizingMaskIntoConstraints = false
        rowsStackView.axis = .vertical
        rowsStackView.spacing = 0
        rowsStackView.alignment = .fill
        rowsStackView.distribution = .fill
        contentView.addSubview(rowsStackView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            rowsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rowsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rowsStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rowsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let minWidthConstraint = contentView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor)
        minWidthConstraint.priority = .required
        minWidthConstraint.isActive = true
    }

    private func rebuildRows(
        records: [GameStatisticsPlayerRecord],
        playerNames: [String],
        showFourthPlaceRow: Bool
    ) {
        clearRows()

        let playerHeaders = records.map { record in
            displayName(for: record.playerIndex, playerNames: playerNames)
        }
        rowsStackView.addArrangedSubview(
            makeRow(
                title: "Показатель",
                values: playerHeaders,
                isHeader: true,
                rowIndex: 0
            )
        )

        var rowIndex = 1
        let metricRows = buildMetricRows(
            records: records,
            showFourthPlaceRow: showFourthPlaceRow
        )
        for row in metricRows {
            rowsStackView.addArrangedSubview(
                makeRow(
                    title: row.title,
                    values: row.values,
                    isHeader: false,
                    rowIndex: rowIndex
                )
            )
            rowIndex += 1
        }
    }

    private func buildMetricRows(
        records: [GameStatisticsPlayerRecord],
        showFourthPlaceRow: Bool
    ) -> [(title: String, values: [String])] {
        let premiums = (0..<GameConstants.totalBlocks).map { blockIndex in
            (
                title: "Премии блок \(blockIndex + 1)",
                values: records.map { record in
                    let value = record.premiumsByBlock.indices.contains(blockIndex)
                        ? record.premiumsByBlock[blockIndex]
                        : 0
                    return "\(value)"
                }
            )
        }

        var rows: [(title: String, values: [String])] = [
            ("Количество игр", records.map { "\($0.gamesPlayed)" }),
            ("1 место", records.map { "\($0.firstPlaceCount)" }),
            ("2 место", records.map { "\($0.secondPlaceCount)" }),
            ("3 место", records.map { "\($0.thirdPlaceCount)" })
        ]

        if showFourthPlaceRow {
            rows.append(("4 место", records.map { "\($0.fourthPlaceCount)" }))
        }

        rows.append(contentsOf: premiums)
        rows.append(("Заказы в темную", records.map { "\($0.blindBidCount)" }))
        rows.append((
            "Макс. очков за игру",
            records.map { record in
                return formattedScore(record.maxTotalScore)
            }
        ))
        rows.append((
            "Мин. очков за игру",
            records.map { record in
                return formattedScore(record.minTotalScore)
            }
        ))

        return rows
    }

    private func displayName(for playerIndex: Int, playerNames: [String]) -> String {
        guard playerNames.indices.contains(playerIndex) else {
            return "Игрок \(playerIndex + 1)"
        }

        let trimmedName = playerNames[playerIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Игрок \(playerIndex + 1)" : trimmedName
    }

    private func makeRow(
        title: String,
        values: [String],
        isHeader: Bool,
        rowIndex: Int
    ) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 0
        rowStack.alignment = .fill
        rowStack.distribution = .fill

        let backgroundColor: UIColor
        if isHeader {
            backgroundColor = Appearance.headerBackground
        } else {
            backgroundColor = rowIndex.isMultiple(of: 2)
                ? Appearance.evenRowBackground
                : Appearance.oddRowBackground
        }

        rowStack.addArrangedSubview(
            makeCell(
                text: title,
                width: metricColumnWidth,
                textColor: Appearance.titleColor,
                backgroundColor: backgroundColor,
                isHeader: isHeader
            )
        )

        for value in values {
            rowStack.addArrangedSubview(
                makeCell(
                    text: value,
                    width: playerColumnWidth,
                    textColor: isHeader ? Appearance.titleColor : Appearance.valueColor,
                    backgroundColor: backgroundColor,
                    isHeader: isHeader
                )
            )
        }

        rowStack.heightAnchor.constraint(equalToConstant: Layout.rowHeight).isActive = true
        return rowStack
    }

    private func makeCell(
        text: String,
        width: CGFloat,
        textColor: UIColor,
        backgroundColor: UIColor,
        isHeader: Bool
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = backgroundColor
        container.layer.borderWidth = 0.5
        container.layer.borderColor = Appearance.borderColor.cgColor

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = textColor
        label.font = UIFont(name: isHeader ? "AvenirNext-DemiBold" : "AvenirNext-Medium", size: isHeader ? 16 : 15)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.numberOfLines = 1

        container.addSubview(label)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: width),

            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func clearRows() {
        for arrangedSubview in rowsStackView.arrangedSubviews {
            rowsStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }

    private func updateContentWidth(playerCount: Int) {
        contentWidthConstraint?.isActive = false

        let width = metricColumnWidth + (CGFloat(playerCount) * playerColumnWidth)
        let fixedWidth = contentView.widthAnchor.constraint(equalToConstant: width)
        fixedWidth.priority = .defaultHigh
        fixedWidth.isActive = true
        contentWidthConstraint = fixedWidth
    }

    private func resolveColumnWidths(playerCount: Int) {
        let fallbackWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let availableWidth = max(bounds.width, fallbackWidth)

        let minTotalWidth = Layout.minimumMetricColumnWidth +
            (CGFloat(playerCount) * Layout.minimumPlayerColumnWidth)
        guard availableWidth >= minTotalWidth else {
            metricColumnWidth = Layout.minimumMetricColumnWidth
            playerColumnWidth = Layout.minimumPlayerColumnWidth
            return
        }

        var resolvedMetricWidth = min(
            max(Layout.minimumMetricColumnWidth, Layout.preferredMetricColumnWidth),
            Layout.maximumMetricColumnWidth
        )

        var resolvedPlayerWidth = floor((availableWidth - resolvedMetricWidth) / CGFloat(playerCount))
        resolvedPlayerWidth = min(max(resolvedPlayerWidth, Layout.minimumPlayerColumnWidth), Layout.maximumPlayerColumnWidth)

        let usedWidth = resolvedMetricWidth + (resolvedPlayerWidth * CGFloat(playerCount))
        let remainingWidth = max(0, availableWidth - usedWidth)
        resolvedMetricWidth = min(Layout.maximumMetricColumnWidth, resolvedMetricWidth + remainingWidth)

        metricColumnWidth = resolvedMetricWidth
        playerColumnWidth = resolvedPlayerWidth
    }

    private func formattedScore(_ value: Double?) -> String {
        guard let value else { return "-" }
        let normalizedValue = (value * 10).rounded() / 10
        return Self.scoreFormatter.string(from: NSNumber(value: normalizedValue)) ?? "-"
    }
}
