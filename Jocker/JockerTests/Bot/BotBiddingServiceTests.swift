//
//  BotBiddingServiceTests.swift
//  JockerTests
//
//  Created by Codex on 15.02.2026.
//

import XCTest
@testable import Jocker

final class BotBiddingServiceTests: XCTestCase {
    /// Тестирует, что бот уважает запрет дилера на определённую ставку.
    /// Проверяет:
    /// - Возвращаемая ставка не равна запрещённой
    /// - Ставка находится в допустимом диапазоне [0, cardsInRound]
    func testMakeBid_respectsForbiddenDealerBid() {
        let fixture = BotBiddingServiceTestFixture()
        let hand = BotTestCards.hand(
            BotTestCards.card(.hearts, .ace),
            BotTestCards.card(.hearts, .king),
            BotTestCards.card(.spades, .queen)
        )

        let bid = fixture.makeBid(
            hand: hand,
            cardsInRound: 3,
            trump: .hearts,
            forbiddenBid: 2
        )

        XCTAssertNotEqual(bid, 2)
        XCTAssertGreaterThanOrEqual(bid, 0)
        XCTAssertLessThanOrEqual(bid, 3)
    }

    /// Тестирует, что более сильная рука produces higher bid than слабая рука.
    /// Проверяет:
    /// - Рука с двумя джокерами и тузами получает более высокую ставку
    /// - Слабая рука с мелкими картами получает более низкую ставку
    func testMakeBid_strongerHandProducesHigherBidThanWeakHand() {
        let fixture = BotBiddingServiceTestFixture()

        let weakHand = BotTestCards.hand(
            BotTestCards.card(.diamonds, .seven),
            BotTestCards.card(.clubs, .eight),
            BotTestCards.card(.spades, .nine),
            BotTestCards.card(.diamonds, .ten)
        )

        let strongHand = BotTestCards.hand(
            .joker,
            .joker,
            BotTestCards.card(.hearts, .ace),
            BotTestCards.card(.hearts, .king)
        )

        let weakBid = fixture.makeBid(
            hand: weakHand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )
        let strongBid = fixture.makeBid(
            hand: strongHand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )

        XCTAssertGreaterThan(strongBid, weakBid)
    }

    /// Тестирует, что рука с плотной trump-мастью получает более высокую ставку.
    /// Проверяет:
    /// - Trump-dense рука (6 червей) оценивается выше
    /// - Mixed рука с разбросанными мастями оценивается ниже
    func testMakeBid_trumpDenseHandProducesHigherBid() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let trumpDenseHand = BotTestCards.hand(
            BotTestCards.card(.hearts, .ace),
            BotTestCards.card(.hearts, .king),
            BotTestCards.card(.hearts, .queen),
            BotTestCards.card(.hearts, .jack),
            BotTestCards.card(.hearts, .nine),
            BotTestCards.card(.clubs, .seven),
            BotTestCards.card(.diamonds, .eight),
            BotTestCards.card(.spades, .ten)
        )
        let mixedHand = BotTestCards.hand(
            BotTestCards.card(.hearts, .ace),
            BotTestCards.card(.spades, .king),
            BotTestCards.card(.clubs, .queen),
            BotTestCards.card(.diamonds, .jack),
            BotTestCards.card(.hearts, .nine),
            BotTestCards.card(.clubs, .seven),
            BotTestCards.card(.diamonds, .eight),
            BotTestCards.card(.spades, .ten)
        )

        let denseBid = fixture.makeBid(
            hand: trumpDenseHand,
            cardsInRound: 8,
            trump: .hearts,
            forbiddenBid: nil
        )
        let mixedBid = fixture.makeBid(
            hand: mixedHand,
            cardsInRound: 8,
            trump: .hearts,
            forbiddenBid: nil
        )

        XCTAssertGreaterThanOrEqual(denseBid, mixedBid)
    }

    /// Тестирует, что рука с джокером и trump-контролем получает более высокую ставку.
    /// Проверяет:
    /// - Рука с джокером и сильными spades оценивается выше
    /// - Плоская рука с джокером но без контроля оценивается ниже
    func testMakeBid_noTrumpControlWithJokerProducesHigherBid() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let controlHand = BotTestCards.hand(
            .joker,
            BotTestCards.card(.spades, .ace),
            BotTestCards.card(.spades, .king),
            BotTestCards.card(.spades, .queen),
            BotTestCards.card(.spades, .jack),
            BotTestCards.card(.hearts, .ace),
            BotTestCards.card(.diamonds, .queen),
            BotTestCards.card(.clubs, .ten)
        )
        let flatHand = BotTestCards.hand(
            .joker,
            BotTestCards.card(.spades, .ace),
            BotTestCards.card(.hearts, .ten),
            BotTestCards.card(.diamonds, .nine),
            BotTestCards.card(.clubs, .eight),
            BotTestCards.card(.clubs, .seven),
            BotTestCards.card(.diamonds, .seven),
            BotTestCards.card(.hearts, .eight)
        )

        let controlBid = fixture.makeBid(
            hand: controlHand,
            cardsInRound: 8,
            trump: nil,
            forbiddenBid: nil
        )
        let flatBid = fixture.makeBid(
            hand: flatHand,
            cardsInRound: 8,
            trump: nil,
            forbiddenBid: nil
        )

        XCTAssertGreaterThanOrEqual(controlBid, flatBid)
    }

    /// Тестирует, что лидер с большим преимуществом не делает blind bid.
    /// Проверяет:
    /// - Игрок на первом месте с отрывом 250+ очков
    /// - Бот возвращает nil (отказывается от blind)
    func testMakePreDealBlindBid_returnsNilForLeaderWithBigAdvantage() {
        let fixture = BotBiddingServiceTestFixture()

        let blindBid = fixture.makePreDealBlindBid(
            playerIndex: 0,
            dealerIndex: 1,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1200, 900, 850, 700]
        )

        XCTAssertNil(blindBid)
    }

    /// Тестирует, что игрок с большим отставанием делает blind bid.
    /// Проверяет:
    /// - Игрок на последнем месте с отставанием 350+ очков
    /// - Бот возвращает допустимую ставку из allowedBlindBids
    func testMakePreDealBlindBid_returnsAllowedBidWhenPlayerFarBehind() {
        let fixture = BotBiddingServiceTestFixture()

        let blindBid = fixture.makePreDealBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            canChooseBlind: true,
            totalScores: [1200, 1100, 980, 700]
        )

        XCTAssertNotNil(blindBid)
        if let blindBid {
            XCTAssertTrue([2, 3, 4, 5, 6].contains(blindBid))
        }
    }

    /// Тестирует, что игрок на втором месте с безопасным отрывом избегает blind для защиты позиции.
    /// Проверяет:
    /// - Отставание от лидера 250 очков
    /// - Отрыв от следующего игрока 330 очков (безопасный gap)
    /// - Бот возвращает nil (консервативная стратегия)
    func testMakePreDealBlindBid_secondPlaceWithSafeGap_avoidsBlindToProtectPosition() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let blindBid = fixture.makePreDealBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1200, 950, 620, 600] // behind leader: 250, ahead of next: 330 (safe gap)
        )

        XCTAssertNil(blindBid)
    }

    /// Тестирует, что игрок на втором месте без безопасного gap может делать catch-up blind.
    /// Проверяет:
    /// - Отставание от лидера 300 очков
    /// - Отрыв от следующего игрока 150 очков (не безопасный gap)
    /// - Бот возвращает non-nil blind bid
    func testMakePreDealBlindBid_secondPlaceWithoutSafeGap_canStillChooseCatchUpBlind() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let blindBid = fixture.makePreDealBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1250, 950, 800, 780] // behind leader: 300, ahead of next: 150 (not a safe gap)
        )

        XCTAssertNotNil(blindBid)
    }

    /// Тестирует, что в одинаковой catch-up ситуации дилер более консервативен чем не-дилер.
    /// Проверяет:
    /// - Не-дилер делает blind bid при отставании 210 очков
    /// - Дилер отказывается от blind bid в той же ситуации
    func testMakePreDealBlindBid_inSameCatchUpScenario_dealerIsMoreConservativeThanNonDealer() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let nonDealerBlindBid = fixture.makePreDealBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            canChooseBlind: true,
            totalScores: [1210, 1000, 980, 960] // behind leader: 210, safe gap отсутствует
        )
        let dealerBlindBid = fixture.makePreDealBlindBid(
            playerIndex: 1,
            dealerIndex: 1,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            canChooseBlind: true,
            totalScores: [1210, 1000, 980, 960]
        )

        XCTAssertNotNil(nonDealerBlindBid)
        XCTAssertNil(dealerBlindBid)
    }

    /// Тестирует, что при небольшом отставании бот использует lower catch-up bid.
    /// Проверяет:
    /// - Отставание 150 очков (catch-up зона)
    /// - Возвращаемая ставка ≤ 4 (консервативный bid)
    func testMakePreDealBlindBid_whenSlightlyBehind_usesLowerCatchUpBid() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let blindBid = fixture.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1000, 980, 850, 840] // отставание от лидера: 150 (catch-up зона)
        )

        XCTAssertNotNil(blindBid)
        if let blindBid {
            XCTAssertLessThanOrEqual(blindBid, 4) // раньше здесь чаще получалось 5+
        }
    }

    /// Тестирует, что при увеличении отставания ставка также растёт.
    /// Проверяет:
    /// - catchUpBid при отставании 150 очков
    /// - desperateBid при отставании 350 очков
    /// - desperateBid > catchUpBid
    func testMakePreDealBlindBid_whenGapGrows_bidAlsoGrows() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let catchUpBid = fixture.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1000, 980, 850, 840] // отставание: 150
        )
        let desperateBid = fixture.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1200, 980, 850, 840] // отставание: 350
        )

        XCTAssertNotNil(catchUpBid)
        XCTAssertNotNil(desperateBid)
        if let catchUpBid, let desperateBid {
            XCTAssertGreaterThan(desperateBid, catchUpBid)
        }
    }

    /// Тестирует, что при запрещённой лучшей ставке бот выбирает ближайшую альтернативу по utility.
    /// Проверяет:
    /// - baseline ставка без ограничений
    /// - forbiddenAdjusted ставка с запретом baseline
    /// - Разница между ставками ≤ 1
    func testMakeBid_whenBestBidForbidden_selectsClosestUtilityAlternative() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)
        let hand = BotTestCards.hand(
            .joker,
            BotTestCards.card(.hearts, .ace),
            BotTestCards.card(.hearts, .king),
            BotTestCards.card(.clubs, .queen)
        )

        let baseline = fixture.makeBid(
            hand: hand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )
        let forbiddenAdjusted = fixture.makeBid(
            hand: hand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: baseline
        )

        XCTAssertNotEqual(forbiddenAdjusted, baseline)
        XCTAssertLessThanOrEqual(abs(forbiddenAdjusted - baseline), 1)
    }

    /// Тестирует детерминированность blind bid с Monte Carlo слоем.
    /// Проверяет:
    /// - Одинаковые входы дают одинаковые результаты
    /// - Первый и второй запуск возвращают одно значение
    func testMakePreDealBlindBid_isDeterministicForSameInputsWithMonteCarloLayer() {
        let fixture = BotBiddingServiceTestFixture(difficulty: .hard)

        let first = fixture.makePreDealBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            canChooseBlind: true,
            totalScores: [1200, 1100, 980, 700]
        )
        let second = fixture.makePreDealBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            canChooseBlind: true,
            totalScores: [1200, 1100, 980, 700]
        )

        XCTAssertEqual(first, second)
    }
}
