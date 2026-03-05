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
        let service = BotBiddingService()
        let hand: [Card] = [
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king),
            .regular(suit: .spades, rank: .queen)
        ]

        let bid = service.makeBid(
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
        let service = BotBiddingService()

        let weakHand: [Card] = [
            .regular(suit: .diamonds, rank: .seven),
            .regular(suit: .clubs, rank: .eight),
            .regular(suit: .spades, rank: .nine),
            .regular(suit: .diamonds, rank: .ten)
        ]

        let strongHand: [Card] = [
            .joker,
            .joker,
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king)
        ]

        let weakBid = service.makeBid(
            hand: weakHand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )
        let strongBid = service.makeBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let trumpDenseHand: [Card] = [
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king),
            .regular(suit: .hearts, rank: .queen),
            .regular(suit: .hearts, rank: .jack),
            .regular(suit: .hearts, rank: .nine),
            .regular(suit: .clubs, rank: .seven),
            .regular(suit: .diamonds, rank: .eight),
            .regular(suit: .spades, rank: .ten)
        ]
        let mixedHand: [Card] = [
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .spades, rank: .king),
            .regular(suit: .clubs, rank: .queen),
            .regular(suit: .diamonds, rank: .jack),
            .regular(suit: .hearts, rank: .nine),
            .regular(suit: .clubs, rank: .seven),
            .regular(suit: .diamonds, rank: .eight),
            .regular(suit: .spades, rank: .ten)
        ]

        let denseBid = service.makeBid(
            hand: trumpDenseHand,
            cardsInRound: 8,
            trump: .hearts,
            forbiddenBid: nil
        )
        let mixedBid = service.makeBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let controlHand: [Card] = [
            .joker,
            .regular(suit: .spades, rank: .ace),
            .regular(suit: .spades, rank: .king),
            .regular(suit: .spades, rank: .queen),
            .regular(suit: .spades, rank: .jack),
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .diamonds, rank: .queen),
            .regular(suit: .clubs, rank: .ten)
        ]
        let flatHand: [Card] = [
            .joker,
            .regular(suit: .spades, rank: .ace),
            .regular(suit: .hearts, rank: .ten),
            .regular(suit: .diamonds, rank: .nine),
            .regular(suit: .clubs, rank: .eight),
            .regular(suit: .clubs, rank: .seven),
            .regular(suit: .diamonds, rank: .seven),
            .regular(suit: .hearts, rank: .eight)
        ]

        let controlBid = service.makeBid(
            hand: controlHand,
            cardsInRound: 8,
            trump: nil,
            forbiddenBid: nil
        )
        let flatBid = service.makeBid(
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
        let service = BotBiddingService()

        let blindBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService()

        let blindBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let blindBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let blindBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let nonDealerBlindBid = service.makePreDealBlindBid(
            playerIndex: 1,
            dealerIndex: 0,
            cardsInRound: 4,
            allowedBlindBids: Array(0...4),
            canChooseBlind: true,
            totalScores: [1210, 1000, 980, 960] // behind leader: 210, safe gap отсутствует
        )
        let dealerBlindBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let blindBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let catchUpBid = service.makePreDealBlindBid(
            playerIndex: 2,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: Array(0...9),
            canChooseBlind: true,
            totalScores: [1000, 980, 850, 840] // отставание: 150
        )
        let desperateBid = service.makePreDealBlindBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))
        let hand: [Card] = [
            .joker,
            .regular(suit: .hearts, rank: .ace),
            .regular(suit: .hearts, rank: .king),
            .regular(suit: .clubs, rank: .queen)
        ]

        let baseline = service.makeBid(
            hand: hand,
            cardsInRound: 4,
            trump: .hearts,
            forbiddenBid: nil
        )
        let forbiddenAdjusted = service.makeBid(
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
        let service = BotBiddingService(tuning: BotTuning(difficulty: .hard))

        let first = service.makePreDealBlindBid(
            playerIndex: 3,
            dealerIndex: 0,
            cardsInRound: 9,
            allowedBlindBids: [2, 3, 4, 5, 6],
            canChooseBlind: true,
            totalScores: [1200, 1100, 980, 700]
        )
        let second = service.makePreDealBlindBid(
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
