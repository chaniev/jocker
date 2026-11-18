import Foundation

struct GameSessionSnapshot: Codable {
    var schemaVersion = 1
    var scoringVersion = 1
    var matchID: UUID
    var revision: Int
    var slot: GameSessionSlot
    var controls: [String]
    var difficulties: [String]
    var firstDealer: Int
    var state: GameStateSnapshot
    var scores: ScoreManagerSnapshot
    var roundService: GameRoundService.Snapshot
    var history: DealHistoryStore.Snapshot
    var flow: GameFlowResumeState
    var hands: [[CardSnapshot]]
    var deck: [CardSnapshot]
    var trick: [DealTrickMoveSnapshot]
    var trump: String?
    var lastPresentedBlock: Int

    var configuration: GameSceneInputConfiguration {
        GameSceneInputConfiguration(playerCount: self.slot.playerCount, gameMode: self.slot.gameMode,
            playerNames: self.state.players.map(\.name),
            playerControlTypes: self.controls.map { $0 == "human" ? .human : .bot },
            botDifficultiesByPlayer: self.difficulties.compactMap(BotDifficulty.init(rawValue:)))
    }

    static func decodeSuit(_ value: String) throws -> Suit {
        guard let suit = CardSnapshot.suit(value) else { throw GameSessionError.invalidSnapshot }
        return suit
    }
    static func decodeStyle(_ value: String) throws -> JokerPlayStyle {
        switch value {
        case "faceUp": return .faceUp
        case "faceDown": return .faceDown
        default: throw GameSessionError.invalidSnapshot
        }
    }

    func validate() throws {
        guard self.schemaVersion == 1, self.scoringVersion == 1 else { throw GameSessionError.unsupportedVersion }
        let count = self.slot.playerCount
        let state = GameState(playerCount: count, gameMode: self.slot.gameMode)
        try self.state.restore(into: state)
        guard self.revision >= 0, (0..<count).contains(self.firstDealer),
              self.controls.count == count, self.controls.allSatisfy({ ["human", "bot"].contains($0) }),
              self.difficulties.count == count, self.difficulties.allSatisfy({ BotDifficulty(rawValue: $0) != nil }),
              self.hands.count == count, self.trick.count <= count,
              self.scores.currentRounds.count == count, self.scores.completedBlocks.count <= 4,
              self.state.players.allSatisfy({ (0...state.currentCardsPerPlayer).contains($0.bid) && (0...state.currentCardsPerPlayer).contains($0.tricks) }),
              self.flow.step >= 0, self.flow.step <= self.flow.order.count,
              Set(self.flow.order).count == self.flow.order.count,
              self.flow.order.allSatisfy({ (0..<count).contains($0) }),
              (0..<count).contains(self.flow.chooser) else { throw GameSessionError.invalidSnapshot }
        if let trump = self.trump { _ = try Self.decodeSuit(trump) }
        for values in [self.flow.bids, self.flow.answered.map { $0 ? 1 : 0 }, self.flow.blindSelections.map { $0 ? 1 : 0 }] {
            guard values.isEmpty || values.count == count else { throw GameSessionError.invalidSnapshot }
        }
        guard self.flow.bids.allSatisfy({ (0...state.currentCardsPerPlayer).contains($0) }) else { throw GameSessionError.invalidSnapshot }
        if [.blind, .bidding].contains(self.flow.stage) {
            guard self.flow.bids.count == count, self.flow.blindSelections.count == count,
                  self.flow.answered.count == count, state.phase == .bidding else { throw GameSessionError.invalidSnapshot }
        }
        if [.blind, .bidding].contains(self.flow.stage) {
            let order = BiddingRules.biddingOrder(dealer: self.state.dealer, playerCount: count)
            let expected = self.flow.stage == .blind ? order : order.filter { !self.flow.blindSelections[$0] }
            guard self.flow.order == expected else { throw GameSessionError.invalidSnapshot }
            let answered = Set(expected.prefix(self.flow.step))
            for index in 0..<count {
                let expectedAnswer = answered.contains(index) || (self.flow.stage == .bidding && self.flow.blindSelections[index])
                guard self.flow.answered[index] == expectedAnswer else { throw GameSessionError.invalidSnapshot }
            }
        }
        if self.flow.stage == .trump {
            guard self.flow.remainingHands.count == count, state.phase == .bidding else { throw GameSessionError.invalidSnapshot }
        }
        if [.playing, .joker].contains(self.flow.stage), state.phase != .playing { throw GameSessionError.invalidSnapshot }
        if self.flow.stage == .terminal, self.scores.completedBlocks.count != 4 { throw GameSessionError.invalidSnapshot }
        let moves = try self.trick.map { try $0.restore() }
        guard Set(moves.map(\.playerIndex)).count == moves.count,
              moves.allSatisfy({ (0..<count).contains($0.playerIndex) }) else { throw GameSessionError.invalidSnapshot }
        for block in self.scores.completedBlocks {
            guard block.roundResults.count == count,
                  [block.baseScores, block.finalScores, block.premiumBonuses, block.premiumPenalties, block.zeroPremiumBonuses].allSatisfy({ $0.count == count }),
                  (block.premiumPlayerIndices + block.zeroPremiumPlayerIndices).allSatisfy({ (0..<count).contains($0) }) else { throw GameSessionError.invalidSnapshot }
        }
        let histories = try self.history.histories.map { try $0.restore() }
        guard Set(histories.map(\.key)).count == histories.count else { throw GameSessionError.invalidSnapshot }
        for history in histories {
            guard (0..<4).contains(history.key.blockIndex), history.key.roundIndex >= 0,
                  history.initialHands.isEmpty || history.initialHands.count == count,
                  history.tricks.allSatisfy({ (0..<count).contains($0.winnerPlayerIndex) && $0.moves.count == count && $0.moves.allSatisfy({ (0..<count).contains($0.playerIndex) }) }) else { throw GameSessionError.invalidSnapshot }
        }
        for history in histories where !history.initialHands.isEmpty {
            guard let block = GameBlock(rawValue: history.key.blockIndex + 1),
                  let cardsPerPlayer = GameConstants.cardsPerPlayer(for: block, roundIndex: history.key.roundIndex, playerCount: count),
                  history.initialHands.allSatisfy({ $0.count == cardsPerPlayer }),
                  history.tricks.count <= cardsPerPlayer else { throw GameSessionError.invalidSnapshot }
            let initialInventory = Dictionary(grouping: history.initialHands.flatMap { $0 }, by: { $0 }).mapValues(\.count)
            let standardInventory = Dictionary(grouping: Deck().cards, by: { $0 }).mapValues(\.count)
            guard initialInventory.allSatisfy({ $0.value <= (standardInventory[$0.key] ?? 0) }) else { throw GameSessionError.invalidSnapshot }
            for trick in history.tricks {
                guard Set(trick.moves.map(\.playerIndex)).count == count else { throw GameSessionError.invalidSnapshot }
            }
            for index in 0..<count {
                var remaining = history.initialHands[index]
                let played = history.tricks.flatMap { $0.moves }.filter { $0.playerIndex == index }.map(\.card)
                for card in played {
                    guard let position = remaining.firstIndex(of: card) else { throw GameSessionError.invalidSnapshot }
                    remaining.remove(at: position)
                }
                if history.key.blockIndex == self.state.block - 1 && history.key.roundIndex == self.state.round {
                    for move in moves where move.playerIndex == index {
                        guard let position = remaining.firstIndex(of: move.card) else { throw GameSessionError.invalidSnapshot }
                        remaining.remove(at: position)
                    }
                    let hidden = self.flow.remainingHands.indices.contains(index) ? self.flow.remainingHands[index] : []
                    let actual = try (self.hands[index] + hidden).map { try $0.restore() }
                    guard remaining.sorted() == actual.sorted() else { throw GameSessionError.invalidSnapshot }
                }
            }
        }
        let currentHistory = histories.first { $0.key.blockIndex == self.state.block - 1 && $0.key.roundIndex == self.state.round }
        let cards = try (self.hands.flatMap { $0 } + self.deck + self.flow.remainingHands.flatMap { $0 }).map { try $0.restore() }
            + moves.map(\.card) + (currentHistory?.tricks.flatMap { $0.moves.map(\.card) } ?? [])
        let inventory = Dictionary(grouping: cards, by: { $0 }).mapValues(\.count)
        let standard = Dictionary(grouping: Deck().cards, by: { $0 }).mapValues(\.count)
        guard inventory == standard else { throw GameSessionError.invalidSnapshot }
        let completedTricks = currentHistory?.tricks.count ?? 0
        if self.flow.stage != .terminal {
            guard self.state.players.reduce(0, { $0 + $1.tricks }) == completedTricks else { throw GameSessionError.invalidSnapshot }
            switch self.flow.stage {
            case .readyToDeal, .blind, .deal:
                guard state.phase == .bidding, self.hands.allSatisfy(\.isEmpty), self.trick.isEmpty,
                      self.deck.count == GameConstants.deckSize else { throw GameSessionError.invalidSnapshot }
            case .trump:
                guard self.hands.enumerated().allSatisfy({ $0.element.count + self.flow.remainingHands[$0.offset].count == state.currentCardsPerPlayer }),
                      self.trick.isEmpty else { throw GameSessionError.invalidSnapshot }
            case .bidding:
                guard self.hands.allSatisfy({ $0.count == state.currentCardsPerPlayer }), self.trick.isEmpty else { throw GameSessionError.invalidSnapshot }
            case .playing, .joker:
                for index in 0..<count {
                    let played = moves.contains { $0.playerIndex == index } ? 1 : 0
                    guard self.hands[index].count == state.currentCardsPerPlayer - completedTricks - played else { throw GameSessionError.invalidSnapshot }
                }
                if let last = moves.last, self.state.currentPlayer != (last.playerIndex + 1) % count { throw GameSessionError.invalidSnapshot }
                if self.flow.stage == .joker {
                    guard self.controls[self.state.currentPlayer] == "human",
                          self.hands[self.state.currentPlayer].contains(where: { $0.suit == nil && $0.rank == nil }) else { throw GameSessionError.invalidSnapshot }
                }
            case .roundEnd:
                guard state.phase == .roundEnd || state.phase == .gameEnd,
                      completedTricks == state.currentCardsPerPlayer, self.hands.allSatisfy(\.isEmpty), self.trick.isEmpty else { throw GameSessionError.invalidSnapshot }
            case .terminal: break
            }
            guard self.history.pending.count == self.trick.count else { throw GameSessionError.invalidSnapshot }
        }
        for sample in self.history.pending {
            guard sample.blockIndex == self.state.block - 1, sample.roundIndex == self.state.round,
                  sample.trickIndex == completedTricks, (0..<count).contains(sample.playerIndex),
                  sample.playerCount == count, sample.cardsInRound == state.currentCardsPerPlayer,
                  (0..<self.trick.count).contains(sample.moveIndexInTrick) else { throw GameSessionError.invalidSnapshot }
        }
        for rounds in self.scores.currentRounds + self.scores.completedBlocks.flatMap({ $0.roundResults }) {
            guard rounds.count <= 12, rounds.allSatisfy({ (1...12).contains($0.cardsInRound)
                && (0...$0.cardsInRound).contains($0.bid) && (0...$0.cardsInRound).contains($0.tricksTaken)
                && (-100_000...100_000).contains($0.recordedScore) }) else { throw GameSessionError.invalidSnapshot }
        }
        let historyStore = DealHistoryStore()
        try historyStore.restore(self.history)
    }
}
