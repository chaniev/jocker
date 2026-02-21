//
//  DealHistoryExportService.swift
//  Jocker
//
//  Created by Codex on 19.02.2026.
//

import Foundation

/// Экспорт истории раздач и training-сэмплов в JSON для оффлайн анализа/обучения.
final class DealHistoryExportService {
    enum ExportReason {
        case blockCompleted(blockIndex: Int)
        case gameCompleted
        case deal(blockIndex: Int, roundIndex: Int)

        fileprivate var identifier: String {
            switch self {
            case .blockCompleted(let blockIndex):
                return "block_\(max(0, blockIndex))"
            case .gameCompleted:
                return "game_final"
            case .deal(let blockIndex, let roundIndex):
                return "deal_b\(max(0, blockIndex))_r\(max(0, roundIndex))"
            }
        }
    }

    struct ExportResult {
        let fileURL: URL
        let dealCount: Int
        let trainingSampleCount: Int
    }

    private let fileManager: FileManager
    private let exportRootURL: URL?
    private let dateProvider: () -> Date
    private let encoder: JSONEncoder
    private let fileTimestampFormatter: DateFormatter
    private let isoFormatter: ISO8601DateFormatter

    init(
        fileManager: FileManager = .default,
        exportRootURL: URL? = nil,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.exportRootURL = exportRootURL
        self.dateProvider = dateProvider

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        timestampFormatter.dateFormat = "yyyyMMdd_HHmmss"
        self.fileTimestampFormatter = timestampFormatter

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.isoFormatter = isoFormatter
    }

    @discardableResult
    func export(
        histories: [DealHistory],
        playerCount: Int,
        playerNames: [String],
        playerControlTypes: [PlayerControlType],
        reason: ExportReason
    ) -> ExportResult? {
        guard !histories.isEmpty else { return nil }
        guard playerCount > 0 else { return nil }
        guard let directoryURL = resolvedExportDirectoryURL() else { return nil }

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            return nil
        }

        let now = dateProvider()
        let fileName = "deal_history_\(reason.identifier)_\(fileTimestampFormatter.string(from: now)).json"
        let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)

        let sortedHistories = histories.sorted { lhs, rhs in
            if lhs.key.blockIndex == rhs.key.blockIndex {
                return lhs.key.roundIndex < rhs.key.roundIndex
            }
            return lhs.key.blockIndex < rhs.key.blockIndex
        }
        let normalizedPlayerNames = (0..<playerCount).map { index in
            playerNames.indices.contains(index) ? playerNames[index] : "Игрок \(index + 1)"
        }
        let normalizedControlTypes = (0..<playerCount).map { index -> String in
            guard playerControlTypes.indices.contains(index) else { return "bot" }
            switch playerControlTypes[index] {
            case .human:
                return "human"
            case .bot:
                return "bot"
            }
        }

        let allTrainingSamples = sortedHistories.flatMap(\.trainingSamples)
        let payload = ExportPayload(
            schemaVersion: 1,
            exportReason: reason.identifier,
            exportedAt: isoFormatter.string(from: now),
            playerCount: playerCount,
            players: zip(normalizedPlayerNames, normalizedControlTypes).enumerated().map { item in
                let (index, data) = item
                return PlayerPayload(
                    playerIndex: index,
                    name: data.0,
                    controlType: data.1
                )
            },
            deals: sortedHistories.map(mapDealPayload),
            trainingSamples: allTrainingSamples.map(mapTrainingSamplePayload)
        )

        guard let rawData = try? encoder.encode(payload) else {
            return nil
        }

        do {
            try rawData.write(to: fileURL, options: .atomic)
        } catch {
            return nil
        }

        return ExportResult(
            fileURL: fileURL,
            dealCount: sortedHistories.count,
            trainingSampleCount: allTrainingSamples.count
        )
    }

    private func resolvedExportDirectoryURL() -> URL? {
        if let exportRootURL {
            return exportRootURL
        }

        if let appSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return appSupportURL
                .appendingPathComponent("Jocker", isDirectory: true)
                .appendingPathComponent("TrainingExports", isDirectory: true)
        }

        if let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            return documentsURL
                .appendingPathComponent("Jocker", isDirectory: true)
                .appendingPathComponent("TrainingExports", isDirectory: true)
        }

        return nil
    }

    private func mapDealPayload(_ history: DealHistory) -> DealPayload {
        return DealPayload(
            blockIndex: history.key.blockIndex,
            roundIndex: history.key.roundIndex,
            trump: suitIdentifier(history.trump),
            initialHands: history.initialHands.enumerated().map { item in
                let (playerIndex, hand) = item
                return PlayerHandPayload(
                    playerIndex: playerIndex,
                    cards: hand.map(mapCardPayload)
                )
            },
            tricks: history.tricks.map { trick in
                TrickPayload(
                    winnerPlayerIndex: trick.winnerPlayerIndex,
                    moves: trick.moves.map(mapMovePayload)
                )
            }
        )
    }

    private func mapTrainingSamplePayload(_ sample: DealTrainingMoveSample) -> TrainingSamplePayload {
        return TrainingSamplePayload(
            blockIndex: sample.blockIndex,
            roundIndex: sample.roundIndex,
            trickIndex: sample.trickIndex,
            moveIndexInTrick: sample.moveIndexInTrick,
            playerIndex: sample.playerIndex,
            playerCount: sample.playerCount,
            cardsInRound: sample.cardsInRound,
            trump: suitIdentifier(sample.trump),
            playerBid: sample.playerBid,
            playerTricksTakenBeforeMove: sample.playerTricksTakenBeforeMove,
            handBeforeMove: sample.handBeforeMove.map(mapCardPayload),
            legalCards: sample.legalCards.map(mapCardPayload),
            playedCardsInTrickBeforeMove: sample.playedCardsInTrickBeforeMove.map(mapMovePayload),
            selectedCard: mapCardPayload(sample.selectedCard),
            selectedJokerPlayStyle: jokerPlayStyleIdentifier(sample.selectedJokerPlayStyle),
            selectedJokerLeadDeclaration: jokerLeadDeclarationIdentifier(sample.selectedJokerLeadDeclaration),
            trickWinnerPlayerIndex: sample.trickWinnerPlayerIndex,
            didPlayerWinTrick: sample.didPlayerWinTrick
        )
    }

    private func mapMovePayload(_ move: DealTrickMove) -> MovePayload {
        return MovePayload(
            playerIndex: move.playerIndex,
            card: mapCardPayload(move.card),
            jokerPlayStyle: jokerPlayStyleIdentifier(move.jokerPlayStyle),
            jokerLeadDeclaration: jokerLeadDeclarationIdentifier(move.jokerLeadDeclaration)
        )
    }

    private func mapCardPayload(_ card: Card) -> CardPayload {
        switch card {
        case .joker:
            return CardPayload(
                kind: "joker",
                suit: nil,
                rankRaw: nil,
                rankSymbol: nil
            )
        case .regular(let suit, let rank):
            return CardPayload(
                kind: "regular",
                suit: suitIdentifier(suit),
                rankRaw: rank.rawValue,
                rankSymbol: rank.symbol
            )
        }
    }

    private func suitIdentifier(_ suit: Suit?) -> String? {
        guard let suit else { return nil }
        switch suit {
        case .diamonds:
            return "diamonds"
        case .hearts:
            return "hearts"
        case .spades:
            return "spades"
        case .clubs:
            return "clubs"
        }
    }

    private func jokerPlayStyleIdentifier(_ style: JokerPlayStyle) -> String {
        switch style {
        case .faceUp:
            return "face_up"
        case .faceDown:
            return "face_down"
        }
    }

    private func jokerLeadDeclarationIdentifier(_ declaration: JokerLeadDeclaration?) -> String? {
        guard let declaration else { return nil }
        switch declaration {
        case .wish:
            return "wish"
        case .above(let suit):
            return "above_\(suitIdentifier(suit) ?? "unknown")"
        case .takes(let suit):
            return "takes_\(suitIdentifier(suit) ?? "unknown")"
        }
    }
}

private struct ExportPayload: Encodable {
    let schemaVersion: Int
    let exportReason: String
    let exportedAt: String
    let playerCount: Int
    let players: [PlayerPayload]
    let deals: [DealPayload]
    let trainingSamples: [TrainingSamplePayload]
}

private struct PlayerPayload: Encodable {
    let playerIndex: Int
    let name: String
    let controlType: String
}

private struct DealPayload: Encodable {
    let blockIndex: Int
    let roundIndex: Int
    let trump: String?
    let initialHands: [PlayerHandPayload]
    let tricks: [TrickPayload]
}

private struct PlayerHandPayload: Encodable {
    let playerIndex: Int
    let cards: [CardPayload]
}

private struct TrickPayload: Encodable {
    let winnerPlayerIndex: Int
    let moves: [MovePayload]
}

private struct MovePayload: Encodable {
    let playerIndex: Int
    let card: CardPayload
    let jokerPlayStyle: String
    let jokerLeadDeclaration: String?
}

private struct CardPayload: Encodable {
    let kind: String
    let suit: String?
    let rankRaw: Int?
    let rankSymbol: String?
}

private struct TrainingSamplePayload: Encodable {
    let blockIndex: Int
    let roundIndex: Int
    let trickIndex: Int
    let moveIndexInTrick: Int
    let playerIndex: Int
    let playerCount: Int
    let cardsInRound: Int
    let trump: String?
    let playerBid: Int?
    let playerTricksTakenBeforeMove: Int?
    let handBeforeMove: [CardPayload]
    let legalCards: [CardPayload]
    let playedCardsInTrickBeforeMove: [MovePayload]
    let selectedCard: CardPayload
    let selectedJokerPlayStyle: String
    let selectedJokerLeadDeclaration: String?
    let trickWinnerPlayerIndex: Int
    let didPlayerWinTrick: Bool
}
