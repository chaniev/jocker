import XCTest
@testable import Jocker

final class GameSessionSnapshotTests: XCTestCase {
    func testReleasedVersionOneFixtureRemainsReadable() throws {
        let snapshot = try GameSessionCodec().decode(GameSessionSchemaFixtures.version1)
        XCTAssertEqual(snapshot.slot, .threePlayers)
        XCTAssertEqual(snapshot.deck.count, 36)
        XCTAssertEqual(snapshot.revision, 1)
    }

    func testInitialSnapshotsRoundTripAllThreeSlotsAndPreserveTwoJokers() throws {
        for slot in GameSessionSlot.allCases {
            let original = GameSessionTestFixture.snapshot(slot: slot)
            let data = try GameSessionCodec().encode(original)
            let restored = try GameSessionCodec().decode(data)
            XCTAssertEqual(restored.slot, slot)
            XCTAssertEqual(restored.deck.filter { $0.rank == nil }.count, 2)
            XCTAssertEqual(restored.configuration.playerCount, slot.playerCount)
            XCTAssertEqual(restored.configuration.gameMode, slot.gameMode)
            XCTAssertEqual(restored.state.players.map(\.bid), original.state.players.map(\.bid))
        }
    }

    func testRejectsDuplicatedCardAndFutureSchemaWithoutRepairingInput() throws {
        var snapshot = GameSessionTestFixture.snapshot()
        snapshot.deck.append(snapshot.deck[0])
        XCTAssertThrowsError(try snapshot.validate())
        snapshot = GameSessionTestFixture.snapshot()
        snapshot.schemaVersion = 2
        XCTAssertThrowsError(try GameSessionCodec().decode(JSONEncoder().encode(snapshot)))
    }

    func testZeroBidIsDistinctFromUnansweredBid() throws {
        var snapshot = GameSessionTestFixture.snapshot()
        var deck = Deck()
        let dealt = deck.dealCards(playerCount: 4, cardsPerPlayer: 1)
        snapshot.hands = dealt.hands.map { $0.map(CardSnapshot.init) }
        snapshot.deck = deck.cards.map(CardSnapshot.init)
        let history = DealHistoryStore()
        history.startDeal(blockIndex: 0, roundIndex: 0)
        history.setInitialHands(dealt.hands, blockIndex: 0, roundIndex: 0)
        snapshot.history = history.snapshot()
        snapshot.flow.stage = .bidding
        snapshot.flow.order = [1, 2, 3, 0]
        snapshot.flow.step = 1
        snapshot.flow.bids = [0, 0, 0, 0]
        snapshot.flow.blindSelections = [false, false, false, false]
        snapshot.flow.answered = [false, true, false, false]
        let restored = try GameSessionCodec().decode(GameSessionCodec().encode(snapshot))
        XCTAssertEqual(restored.flow.answered, [false, true, false, false])
        XCTAssertEqual(restored.flow.step, 1)
    }

    func testBlindAndPartialTrumpCursorsRoundTripEveryVariant() throws {
        for slot in GameSessionSlot.allCases {
            var snapshot = GameSessionTestFixture.snapshot(slot: slot)
            let count = slot.playerCount
            snapshot.state.block = 4
            snapshot.flow.stage = .blind
            snapshot.flow.order = BiddingRules.biddingOrder(dealer: 0, playerCount: count)
            snapshot.flow.step = 1
            snapshot.flow.bids = Array(repeating: 0, count: count)
            snapshot.flow.blindSelections = Array(repeating: false, count: count)
            snapshot.flow.blindSelections[1] = true
            snapshot.flow.answered = Array(repeating: false, count: count)
            snapshot.flow.answered[1] = true
            let blind = try GameSessionCodec().decode(GameSessionCodec().encode(snapshot))
            XCTAssertEqual(blind.flow.step, 1)
            XCTAssertTrue(blind.flow.blindSelections[1])
            var deck = Deck()
            let initial = deck.dealCards(playerCount: count, cardsPerPlayer: 12 / count).hands
            let rest = deck.dealCards(playerCount: count, cardsPerPlayer: 24 / count).hands
            snapshot.hands = initial.map { $0.map(CardSnapshot.init) }
            snapshot.deck = deck.cards.map(CardSnapshot.init)
            snapshot.flow.stage = .trump
            snapshot.flow.remainingHands = rest.map { $0.map(CardSnapshot.init) }
            let history = DealHistoryStore()
            history.startDeal(blockIndex: 3, roundIndex: 0)
            history.setInitialHands((0..<count).map { initial[$0] + rest[$0] }, blockIndex: 3, roundIndex: 0)
            snapshot.history = history.snapshot()
            let trump = try GameSessionCodec().decode(GameSessionCodec().encode(snapshot))
            XCTAssertEqual(trump.hands, snapshot.hands)
            XCTAssertEqual(trump.flow.remainingHands, snapshot.flow.remainingHands)
            let scene = GameSessionTestFixture.scene(slot: slot)
            try scene.restoreSession(trump)
            XCTAssertEqual(scene.players.map { $0.hand.cards }, initial)
            XCTAssertEqual(scene.flow.stage, .trump)
            XCTAssertEqual(scene.gameState.phase, .bidding)
        }
    }

    func testScoresRestoreWithoutReapplyingPremiums() throws {
        let snapshot = GameSessionTestFixture.terminal(slot: .fourPlayersPairs)
        let manager = ScoreManager(playerCount: 4, gameMode: .pairs)
        try snapshot.scores.restore(into: manager)
        let originalTotals = manager.totalScores
        try snapshot.scores.restore(into: manager)
        XCTAssertEqual(manager.totalScores, originalTotals)
        XCTAssertEqual(manager.completedBlocks.count, 4)
        XCTAssertEqual(manager.totalTeamScores, [originalTotals[0] + originalTotals[2], originalTotals[1] + originalTotals[3]])
    }

    func testAllJokerDeclarationsRoundTrip() throws {
        for declaration in [JokerLeadDeclaration.wish] + Suit.allCases.flatMap({ [JokerLeadDeclaration.above(suit: $0), .takes(suit: $0)] }) {
            let saved = JokerDeclarationSnapshot(declaration)
            XCTAssertEqual(try JSONDecoder().decode(JokerDeclarationSnapshot.self, from: JSONEncoder().encode(saved)).restore(), declaration)
        }
    }
}
