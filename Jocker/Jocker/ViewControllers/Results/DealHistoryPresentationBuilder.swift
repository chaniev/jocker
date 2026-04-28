//
//  DealHistoryPresentationBuilder.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct DealHistoryPresentationBuilder {
    struct Presentation {
        struct ExportData: Equatable {
            let playerCount: Int
            let gameMode: GameMode
            let playerNames: [String]
            let playerControlTypes: [PlayerControlType]
        }

        struct Section: Equatable {
            struct Row: Equatable {
                enum Kind: Equatable {
                    case hand
                    case move
                }

                let kind: Kind
                let title: String
                let detail: String?
            }

            let title: String
            let rows: [Row]
        }

        let title: String
        let subtitle: String
        let trumpText: String
        let sections: [Section]
        let exportData: ExportData

        var isEmpty: Bool {
            sections.isEmpty
        }
    }

    func build(
        dealHistory: DealHistory,
        playerNames: [String],
        playerControlTypes: [PlayerControlType],
        gameMode: GameMode = .freeForAll
    ) -> Presentation {
        let playerCount = resolvedPlayerCount(
            dealHistory: dealHistory,
            playerNames: playerNames,
            playerControlTypes: playerControlTypes
        )
        let normalizedPlayerNames = PlayerDisplayNameFormatter.normalizedNames(
            playerNames,
            playerCount: playerCount
        )
        let normalizedControlTypes = normalizedPlayerControlTypes(
            playerControlTypes,
            playerCount: playerCount
        )

        var sections: [Presentation.Section] = []
        if playerCount > 0 {
            sections.append(
                Presentation.Section(
                    title: "Карты на руках после раздачи",
                    rows: buildHandRows(
                        dealHistory: dealHistory,
                        playerNames: normalizedPlayerNames,
                        playerControlTypes: normalizedControlTypes
                    )
                )
            )
        }

        sections.append(
            contentsOf: buildTrickSections(
                dealHistory: dealHistory,
                playerNames: normalizedPlayerNames
            )
        )

        return Presentation(
            title: "Раздача \(dealHistory.key.roundIndex + 1), блок \(dealHistory.key.blockIndex + 1)",
            subtitle: "Подробная история хода и стартовых рук игроков",
            trumpText: trumpText(for: dealHistory.trump),
            sections: sections,
            exportData: Presentation.ExportData(
                playerCount: playerCount,
                gameMode: gameMode,
                playerNames: normalizedPlayerNames,
                playerControlTypes: normalizedControlTypes
            )
        )
    }

    private func resolvedPlayerCount(
        dealHistory: DealHistory,
        playerNames: [String],
        playerControlTypes: [PlayerControlType]
    ) -> Int {
        let maxPlayerIndexFromMoves = dealHistory.tricks
            .flatMap(\.moves)
            .map(\.playerIndex)
            .max() ?? -1

        return max(
            playerNames.count,
            playerControlTypes.count,
            dealHistory.initialHands.count,
            maxPlayerIndexFromMoves + 1
        )
    }

    private func normalizedPlayerControlTypes(
        _ playerControlTypes: [PlayerControlType],
        playerCount: Int
    ) -> [PlayerControlType] {
        return (0..<playerCount).map { index in
            guard playerControlTypes.indices.contains(index) else {
                return .bot
            }
            return playerControlTypes[index]
        }
    }

    private func buildHandRows(
        dealHistory: DealHistory,
        playerNames: [String],
        playerControlTypes: [PlayerControlType]
    ) -> [Presentation.Section.Row] {
        return playerNames.enumerated().map { index, playerName in
            Presentation.Section.Row(
                kind: .hand,
                title: "\(playerName) (\(roleText(for: index, playerControlTypes: playerControlTypes)))",
                detail: handText(for: index, dealHistory: dealHistory)
            )
        }
    }

    private func buildTrickSections(
        dealHistory: DealHistory,
        playerNames: [String]
    ) -> [Presentation.Section] {
        return dealHistory.tricks.enumerated().map { trickIndex, trick in
            let winnerName = playerNames.indices.contains(trick.winnerPlayerIndex)
                ? playerNames[trick.winnerPlayerIndex]
                : PlayerDisplayNameFormatter.fallbackName(for: trick.winnerPlayerIndex)

            let rows = trick.moves.enumerated().map { moveIndex, move in
                let playerName = playerNames.indices.contains(move.playerIndex)
                    ? playerNames[move.playerIndex]
                    : PlayerDisplayNameFormatter.fallbackName(for: move.playerIndex)
                return Presentation.Section.Row(
                    kind: .move,
                    title: "\(moveIndex + 1). \(playerName): \(moveText(for: move))",
                    detail: nil
                )
            }

            return Presentation.Section(
                title: "Взятка \(trickIndex + 1) • Забрал: \(winnerName)",
                rows: rows
            )
        }
    }

    private func trumpText(for trump: Suit?) -> String {
        guard let trump else {
            return "Козырь: без козыря"
        }
        return "Козырь: \(trump.name)"
    }

    private func roleText(
        for playerIndex: Int,
        playerControlTypes: [PlayerControlType]
    ) -> String {
        guard playerControlTypes.indices.contains(playerIndex) else {
            return "Бот"
        }

        switch playerControlTypes[playerIndex] {
        case .human:
            return "Человек"
        case .bot:
            return "Бот"
        }
    }

    private func handText(for playerIndex: Int, dealHistory: DealHistory) -> String {
        guard dealHistory.initialHands.indices.contains(playerIndex) else {
            return "Нет данных"
        }

        let hand = dealHistory.initialHands[playerIndex].sorted()
        guard !hand.isEmpty else {
            return "Пусто"
        }

        return hand.map(cardText(for:)).joined(separator: "  ")
    }

    private func cardText(for card: Card) -> String {
        switch card {
        case .joker:
            return "🃏"
        case .regular(let suit, let rank):
            return "\(rank.symbol)\(suit.rawValue)"
        }
    }

    private func moveText(for move: DealTrickMove) -> String {
        switch move.card {
        case .regular(let suit, let rank):
            return "\(rank.symbol)\(suit.rawValue)"
        case .joker:
            let styleSuffix = move.jokerPlayStyle == .faceDown ? "рубашкой вверх" : "лицом вверх"
            guard let declaration = move.jokerLeadDeclaration else {
                return "🃏 (\(styleSuffix))"
            }
            return "🃏 (\(styleSuffix), \(declarationText(declaration)))"
        }
    }

    private func declarationText(_ declaration: JokerLeadDeclaration) -> String {
        switch declaration {
        case .wish:
            return "хочу"
        case .above(let suit):
            return "выше \(suit.name.lowercased())"
        case .takes(let suit):
            return "забирает \(suit.name.lowercased())"
        }
    }
}
