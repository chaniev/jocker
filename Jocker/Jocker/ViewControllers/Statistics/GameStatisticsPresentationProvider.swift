//
//  GameStatisticsPresentationProvider.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct GameStatisticsPresentationProvider {
    struct Presentation {
        struct Row {
            let title: String
            let values: [String]
            let isHeader: Bool
        }

        let visiblePlayerCount: Int
        let rows: [Row]
    }

    private static let scoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    func makePresentation(
        records: [GameStatisticsPlayerRecord],
        visiblePlayerCount: Int,
        playerNames: [String]
    ) -> Presentation {
        let playerCount = max(1, visiblePlayerCount)
        let displayedRecords = normalizedRecords(records, playerCount: playerCount)
        let headerValues = displayedRecords.map { record in
            PlayerDisplayNameFormatter.displayName(
                for: record.playerIndex,
                in: playerNames
            )
        }

        var rows: [Presentation.Row] = [
            Presentation.Row(
                title: "Показатель",
                values: headerValues,
                isHeader: true
            )
        ]
        rows.append(
            contentsOf: metricRows(
                records: displayedRecords,
                showFourthPlaceRow: playerCount >= 4
            )
        )

        return Presentation(
            visiblePlayerCount: playerCount,
            rows: rows
        )
    }

    private func normalizedRecords(
        _ records: [GameStatisticsPlayerRecord],
        playerCount: Int
    ) -> [GameStatisticsPlayerRecord] {
        let recordsByPlayerIndex = Dictionary(
            uniqueKeysWithValues: records.map { ($0.playerIndex, $0) }
        )

        return (0..<playerCount).map { playerIndex in
            recordsByPlayerIndex[playerIndex] ?? GameStatisticsPlayerRecord.empty(playerIndex: playerIndex)
        }
    }

    private func metricRows(
        records: [GameStatisticsPlayerRecord],
        showFourthPlaceRow: Bool
    ) -> [Presentation.Row] {
        var rows: [Presentation.Row] = [
            Presentation.Row(title: "Количество игр", values: records.map { "\($0.gamesPlayed)" }, isHeader: false),
            Presentation.Row(title: "1 место", values: records.map { "\($0.firstPlaceCount)" }, isHeader: false),
            Presentation.Row(title: "2 место", values: records.map { "\($0.secondPlaceCount)" }, isHeader: false),
            Presentation.Row(title: "3 место", values: records.map { "\($0.thirdPlaceCount)" }, isHeader: false)
        ]

        if showFourthPlaceRow {
            rows.append(
                Presentation.Row(
                    title: "4 место",
                    values: records.map { "\($0.fourthPlaceCount)" },
                    isHeader: false
                )
            )
        }

        rows.append(contentsOf: premiumRows(records: records))
        rows.append(
            Presentation.Row(
                title: "Заказы в темную",
                values: records.map { "\($0.blindBidCount)" },
                isHeader: false
            )
        )
        rows.append(
            Presentation.Row(
                title: "Макс. очков за игру",
                values: records.map { formattedScore($0.maxTotalScore) },
                isHeader: false
            )
        )
        rows.append(
            Presentation.Row(
                title: "Мин. очков за игру",
                values: records.map { formattedScore($0.minTotalScore) },
                isHeader: false
            )
        )
        return rows
    }

    private func premiumRows(records: [GameStatisticsPlayerRecord]) -> [Presentation.Row] {
        return (0..<GameConstants.totalBlocks).map { blockIndex in
            Presentation.Row(
                title: "Премии блок \(blockIndex + 1)",
                values: records.map { record in
                    let value = record.premiumsByBlock.indices.contains(blockIndex)
                        ? record.premiumsByBlock[blockIndex]
                        : 0
                    return "\(value)"
                },
                isHeader: false
            )
        }
    }

    private func formattedScore(_ value: Double?) -> String {
        guard let value else { return "-" }
        let normalizedValue = (value * 10).rounded() / 10
        return Self.scoreFormatter.string(from: NSNumber(value: normalizedValue)) ?? "-"
    }
}
