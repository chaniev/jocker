//
//  BotTuning.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Централизованные коэффициенты и тайминги для ИИ ботов.
struct BotTuning {
    struct TurnStrategy {
        /// Допуск при сравнении utility-кандидатов.
        /// Пример: `0.001` чаще считает близкие варианты равными.
        let utilityTieTolerance: Double

        /// Вес вероятности немедленной победы во взятке при доборе до заказа.
        /// Пример: `55` заставляет бота агрессивнее выбирать выигрышные карты.
        let chaseWinProbabilityWeight: Double
        /// Штраф за розыгрыш "дорогих" карт в режиме добора.
        /// Пример: `0.20` дольше сохраняет сильные карты на руке.
        let chaseThreatPenaltyWeight: Double
        /// Дополнительный штраф за трату джокера, если можно выиграть без него.
        /// Пример: `80` резко снижает ранний розыгрыш джокера.
        let chaseSpendJokerPenalty: Double
        /// Бонус за заход джокером с объявлением `wish` в режиме добора.
        /// Пример: `12` повышает приоритет этого объявления.
        let chaseLeadWishBonus: Double

        /// Награда за проигрыш текущей взятки в режиме сброса.
        /// Пример: `60` уменьшает случайные "лишние" взятки.
        let dumpAvoidWinWeight: Double
        /// Награда за сброс карт с высокой угрозой в режиме сброса.
        /// Пример: `0.30` чаще избавляет от опасных карт.
        let dumpThreatRewardWeight: Double
        /// Штраф за трату джокера в режиме сброса, если есть проигрывающая альтернатива.
        /// Пример: `90` помогает не сжигать джокер зря.
        let dumpSpendJokerPenalty: Double
        /// Штраф за неведущий джокер лицом вверх в режиме сброса.
        /// Пример: `50` смещает выбор к джокеру рубашкой вверх.
        let dumpFaceUpNonLeadJokerPenalty: Double
        /// Бонус за `takes` с некозырной мастью при заходе джокером в режиме сброса.
        /// Пример: `10` делает такую линию хода более частой.
        let dumpLeadTakesNonTrumpBonus: Double

        /// Вес комбинаторной оценки "удержания взятки" в вероятности победы.
        /// Пример: `0.90` больше доверяет моделированию распределения карт.
        let holdFromDistributionWeight: Double
        /// Вес эвристической силы карты в вероятности победы.
        /// Пример: `0.30` повышает влияние оценки cardPower.
        let powerConfidenceWeight: Double

        /// Базовая ценность джокера при оценке будущих взяток.
        /// Пример: `1.4` делает один джокер почти "готовой взяткой".
        let futureJokerPower: Double
        /// Базовая ценность любой обычной карты в прогнозе будущих взяток.
        /// Пример: `0.20` поднимает общий прогноз по любой руке.
        let futureRegularBasePower: Double
        /// Вклад ранга обычной карты в прогноз будущих взяток.
        /// Пример: `0.90` сильнее разделяет младшие и старшие ранги.
        let futureRegularRankWeight: Double
        /// Базовый бонус за козырную карту в прогнозе.
        /// Пример: `0.50` увеличивает ценность козырной масти.
        let futureTrumpBaseBonus: Double
        /// Дополнительный ранговый бонус для козырных карт.
        /// Пример: `0.40` сильнее предпочитает старшие козыри.
        let futureTrumpRankWeight: Double
        /// Бонус за старшие карты вне козыря (Q/K/A).
        /// Пример: `0.20` повышает ценность старших некозырных карт.
        let futureHighRankBonus: Double
        /// Бонус за длину масти (для карт сверх двух в одной масти).
        /// Пример: `0.08` сильнее вознаграждает концентрацию по масти.
        let futureLongSuitBonusPerCard: Double
        /// Глобальный множитель прогноза будущих взяток.
        /// Пример: `0.75` делает итоговый прогноз более оптимистичным.
        let futureTricksScale: Double

        /// Оценка угрозы для ведущего джокера рубашкой вверх.
        /// Пример: `30` делает такой ход более "дорогим" для расхода.
        let threatFaceDownLeadJoker: Double
        /// Оценка угрозы для неведущего джокера рубашкой вверх.
        /// Пример: `4` уменьшает готовность сбрасывать его без нужды.
        let threatFaceDownNonLeadJoker: Double
        /// Оценка угрозы для ведущего джокера с `takes`.
        /// Пример: `50` делает это объявление менее "дешёвым".
        let threatLeadTakesJoker: Double
        /// Оценка угрозы для ведущего джокера с `above`.
        /// Пример: `100` трактует ход как расход очень сильного ресурса.
        let threatLeadAboveJoker: Double
        /// Оценка угрозы для ведущего джокера с `wish`.
        /// Пример: `120` считает это самым дорогим вариантом розыгрыша.
        let threatLeadWishJoker: Double
        /// Оценка угрозы для неведущего джокера лицом вверх.
        /// Пример: `120` мешает тратить его в нейтральных позициях.
        let threatNonLeadFaceUpJoker: Double
        /// Дополнительная угроза для обычных козырных карт.
        /// Пример: `12` заставляет дольше беречь козыри.
        let threatTrumpBonus: Double
        /// Дополнительная угроза для старших обычных рангов.
        /// Пример: `5` усиливает сохранение Q/K/A.
        let threatHighRankBonus: Double

        /// Эвристическая сила для джокера рубашкой вверх.
        /// Пример: `1` оставляет почти минимальную уверенность в силе хода.
        let powerFaceDownJoker: Int
        /// Эвристическая сила для ведущего джокера `takes`.
        /// Пример: `60` повышает уверенность в этом объявлении.
        let powerLeadTakesJoker: Int
        /// Эвристическая сила для ведущего джокера `above`.
        /// Пример: `995` делает ход почти гарантированно сильным в оценке.
        let powerLeadAboveJoker: Int
        /// Эвристическая сила для ведущего джокера `wish`.
        /// Пример: `1000` задаёт максимальную тактическую силу.
        let powerLeadWishJoker: Int
        /// Эвристическая сила для неведущего джокера лицом вверх.
        /// Пример: `1000` считает его максимально сильным прямо сейчас.
        let powerNonLeadFaceUpJoker: Int
        /// Эвристический бонус силы для обычных козырей.
        /// Пример: `140` повышает уверенность при розыгрыше козыря.
        let powerTrumpBonus: Int
        /// Эвристический бонус силы за попадание в масть хода.
        /// Пример: `60` повышает оценку ответов "в масть".
        let powerLeadSuitBonus: Int
        /// Делитель нормализации для перевода силы в вероятность.
        /// Пример: `960` при той же raw-силе даёт более высокую уверенность.
        let powerNormalizationValue: Double
    }

    struct Bidding {
        /// Вклад джокера в оценку ожидаемых взяток при заказе.
        /// Пример: `1.3` повышает заказ при наличии джокеров на руке.
        let expectedJokerPower: Double
        /// Вклад ранга в оценку заказа.
        /// Пример: `0.85` чаще поднимает заказ для "старшей" руки.
        let expectedRankWeight: Double
        /// Базовый козырный бонус в оценке заказа.
        /// Пример: `0.70` повышает заказ при сильной козырной масти.
        let expectedTrumpBaseBonus: Double
        /// Ранговый козырный бонус в оценке заказа.
        /// Пример: `0.60` заметно увеличивает ценность старших козырей.
        let expectedTrumpRankWeight: Double
        /// Бонус за старшие некозырные карты в оценке заказа.
        /// Пример: `0.25` повышает заказ с Q/K/A вне козыря.
        let expectedHighRankBonus: Double

        /// Порог отставания для "аврального" риска тёмной ставки.
        /// Пример: `200` включает риск тёмной ставки раньше при большом отставании.
        let blindDesperateBehindThreshold: Int
        /// Порог отставания для "догоняющего" режима тёмной ставки.
        /// Пример: `90` раньше включает умеренный риск.
        let blindCatchUpBehindThreshold: Int
        /// Порог отрыва, после которого бот избегает риска тёмной ставки.
        /// Пример: `260` делает лидирующего бота более осторожным.
        let blindSafeLeadThreshold: Int
        /// Целевая доля тёмной ставки в авральном режиме.
        /// Пример: `0.80` стремится к почти максимальным заказам.
        let blindDesperateTargetShare: Double
        /// Целевая доля тёмной ставки в догоняющем режиме.
        /// Пример: `0.55` чаще выбирает средне-высокие ставки.
        let blindCatchUpTargetShare: Double
    }

    struct TrumpSelection {
        /// Базовая сила одной карты масти при выборе козыря.
        /// Пример: `0.60` делает даже средние мастевые наборы "сильнее".
        let cardBasePower: Double
        /// Минимальная сила масти для объявления козыря.
        /// Пример: `1.20` заставляет бота чаще объявлять козырь.
        let minimumPowerToDeclareTrump: Double
    }

    struct Timing {
        /// Задержка перед ходом бота в фазе игры.
        /// Пример: `0.20` делает ходы бота визуально быстрее.
        let playingBotTurnDelay: TimeInterval
        /// Задержка между последовательными решениями в торгах.
        /// Пример: `0.40` замедляет темп анимации торгов.
        let biddingStepDelay: TimeInterval
        /// Задержка перед колбэком разбора взятки.
        /// Пример: `0.35` быстрее завершает взятку на столе.
        let trickResolutionDelay: TimeInterval
    }

    /// Выбранный уровень пресета.
    /// Пример: `.hard` применяет более агрессивные коэффициенты и быстрые тайминги.
    let difficulty: BotDifficulty
    /// Коэффициенты логики выбора карты и розыгрыша джокера на ход.
    /// Пример: настройка этого блока меняет поведение внутри взятки.
    let turnStrategy: TurnStrategy
    /// Коэффициенты торгов и выбора тёмной ставки.
    /// Пример: настройка этого блока меняет склонность к высоким/низким заказам.
    let bidding: Bidding
    /// Коэффициенты выбора козыря по неполной руке.
    /// Пример: снижение порога делает объявления козыря более частыми.
    let trumpSelection: TrumpSelection
    /// Задержки, определяющие темп бота и визуальный ритм партии.
    /// Пример: уменьшение задержек делает игру динамичнее.
    let timing: Timing

    init(difficulty: BotDifficulty) {
        self = BotTuning.preset(for: difficulty)
    }

    init(
        difficulty: BotDifficulty,
        turnStrategy: TurnStrategy,
        bidding: Bidding,
        trumpSelection: TrumpSelection,
        timing: Timing
    ) {
        self.difficulty = difficulty
        self.turnStrategy = turnStrategy
        self.bidding = bidding
        self.trumpSelection = trumpSelection
        self.timing = timing
    }

    private static func preset(for difficulty: BotDifficulty) -> BotTuning {
        switch difficulty {
        case .easy:
            return BotTuning(
                difficulty: .easy,
                turnStrategy: TurnStrategy(
                    utilityTieTolerance: 0.001,

                    chaseWinProbabilityWeight: 42.0,
                    chaseThreatPenaltyWeight: 0.10,
                    chaseSpendJokerPenalty: 35.0,
                    chaseLeadWishBonus: 4.0,

                    dumpAvoidWinWeight: 42.0,
                    dumpThreatRewardWeight: 0.11,
                    dumpSpendJokerPenalty: 45.0,
                    dumpFaceUpNonLeadJokerPenalty: 20.0,
                    dumpLeadTakesNonTrumpBonus: 2.0,

                    holdFromDistributionWeight: 0.68,
                    powerConfidenceWeight: 0.32,

                    futureJokerPower: 1.05,
                    futureRegularBasePower: 0.10,
                    futureRegularRankWeight: 0.60,
                    futureTrumpBaseBonus: 0.24,
                    futureTrumpRankWeight: 0.20,
                    futureHighRankBonus: 0.08,
                    futureLongSuitBonusPerCard: 0.03,
                    futureTricksScale: 0.52,

                    threatFaceDownLeadJoker: 18.0,
                    threatFaceDownNonLeadJoker: 1.0,
                    threatLeadTakesJoker: 24.0,
                    threatLeadAboveJoker: 72.0,
                    threatLeadWishJoker: 90.0,
                    threatNonLeadFaceUpJoker: 90.0,
                    threatTrumpBonus: 7.0,
                    threatHighRankBonus: 2.0,

                    powerFaceDownJoker: 1,
                    powerLeadTakesJoker: 24,
                    powerLeadAboveJoker: 900,
                    powerLeadWishJoker: 960,
                    powerNonLeadFaceUpJoker: 960,
                    powerTrumpBonus: 80,
                    powerLeadSuitBonus: 24,
                    powerNormalizationValue: 960.0
                ),
                bidding: Bidding(
                    expectedJokerPower: 0.9,
                    expectedRankWeight: 0.58,
                    expectedTrumpBaseBonus: 0.35,
                    expectedTrumpRankWeight: 0.28,
                    expectedHighRankBonus: 0.10,

                    blindDesperateBehindThreshold: 320,
                    blindCatchUpBehindThreshold: 180,
                    blindSafeLeadThreshold: 140,
                    blindDesperateTargetShare: 0.45,
                    blindCatchUpTargetShare: 0.30
                ),
                trumpSelection: TrumpSelection(
                    cardBasePower: 0.35,
                    minimumPowerToDeclareTrump: 1.90
                ),
                timing: Timing(
                    playingBotTurnDelay: 0.55,
                    biddingStepDelay: 0.35,
                    trickResolutionDelay: 0.65
                )
            )

        case .normal:
            return BotTuning(
                difficulty: .normal,
                turnStrategy: TurnStrategy(
                    utilityTieTolerance: 0.000_1,

                    chaseWinProbabilityWeight: 50.0,
                    chaseThreatPenaltyWeight: 0.14,
                    chaseSpendJokerPenalty: 55.0,
                    chaseLeadWishBonus: 8.0,

                    dumpAvoidWinWeight: 50.0,
                    dumpThreatRewardWeight: 0.18,
                    dumpSpendJokerPenalty: 70.0,
                    dumpFaceUpNonLeadJokerPenalty: 35.0,
                    dumpLeadTakesNonTrumpBonus: 6.0,

                    holdFromDistributionWeight: 0.82,
                    powerConfidenceWeight: 0.18,

                    futureJokerPower: 1.25,
                    futureRegularBasePower: 0.15,
                    futureRegularRankWeight: 0.75,
                    futureTrumpBaseBonus: 0.35,
                    futureTrumpRankWeight: 0.30,
                    futureHighRankBonus: 0.12,
                    futureLongSuitBonusPerCard: 0.05,
                    futureTricksScale: 0.62,

                    threatFaceDownLeadJoker: 24.0,
                    threatFaceDownNonLeadJoker: 2.0,
                    threatLeadTakesJoker: 36.0,
                    threatLeadAboveJoker: 88.0,
                    threatLeadWishJoker: 100.0,
                    threatNonLeadFaceUpJoker: 100.0,
                    threatTrumpBonus: 9.0,
                    threatHighRankBonus: 3.0,

                    powerFaceDownJoker: 1,
                    powerLeadTakesJoker: 30,
                    powerLeadAboveJoker: 980,
                    powerLeadWishJoker: 1000,
                    powerNonLeadFaceUpJoker: 1000,
                    powerTrumpBonus: 100,
                    powerLeadSuitBonus: 40,
                    powerNormalizationValue: 1000.0
                ),
                bidding: Bidding(
                    expectedJokerPower: 1.1,
                    expectedRankWeight: 0.72,
                    expectedTrumpBaseBonus: 0.55,
                    expectedTrumpRankWeight: 0.45,
                    expectedHighRankBonus: 0.18,

                    blindDesperateBehindThreshold: 250,
                    blindCatchUpBehindThreshold: 130,
                    blindSafeLeadThreshold: 180,
                    blindDesperateTargetShare: 0.65,
                    blindCatchUpTargetShare: 0.45
                ),
                trumpSelection: TrumpSelection(
                    cardBasePower: 0.45,
                    minimumPowerToDeclareTrump: 1.55
                ),
                timing: Timing(
                    playingBotTurnDelay: 0.35,
                    biddingStepDelay: 0.25,
                    trickResolutionDelay: 0.55
                )
            )

        case .hard:
            return BotTuning(
                difficulty: .hard,
                turnStrategy: TurnStrategy(
                    utilityTieTolerance: 0.000_05,

                    chaseWinProbabilityWeight: 55.245_862,
                    chaseThreatPenaltyWeight: 0.188_093,
                    chaseSpendJokerPenalty: 80.192_701,
                    chaseLeadWishBonus: 14.0,

                    dumpAvoidWinWeight: 65.813_347,
                    dumpThreatRewardWeight: 0.188_897,
                    dumpSpendJokerPenalty: 75.535_974,
                    dumpFaceUpNonLeadJokerPenalty: 45.0,
                    dumpLeadTakesNonTrumpBonus: 8.0,

                    holdFromDistributionWeight: 0.899_377,
                    powerConfidenceWeight: 0.100_623,

                    futureJokerPower: 1.397_471,
                    futureRegularBasePower: 0.18,
                    futureRegularRankWeight: 0.82,
                    futureTrumpBaseBonus: 0.42,
                    futureTrumpRankWeight: 0.35,
                    futureHighRankBonus: 0.15,
                    futureLongSuitBonusPerCard: 0.07,
                    futureTricksScale: 0.676_39,

                    threatFaceDownLeadJoker: 28.0,
                    threatFaceDownNonLeadJoker: 3.0,
                    threatLeadTakesJoker: 45.0,
                    threatLeadAboveJoker: 95.0,
                    threatLeadWishJoker: 110.0,
                    threatNonLeadFaceUpJoker: 110.0,
                    threatTrumpBonus: 12.018_376,
                    threatHighRankBonus: 4.370_318,

                    powerFaceDownJoker: 1,
                    powerLeadTakesJoker: 45,
                    powerLeadAboveJoker: 995,
                    powerLeadWishJoker: 1000,
                    powerNonLeadFaceUpJoker: 1000,
                    powerTrumpBonus: 120,
                    powerLeadSuitBonus: 55,
                    powerNormalizationValue: 1000.0
                ),
                bidding: Bidding(
                    expectedJokerPower: 0.430_818,
                    expectedRankWeight: 0.274_157,
                    expectedTrumpBaseBonus: 0.215_409,
                    expectedTrumpRankWeight: 0.176_244,
                    expectedHighRankBonus: 0.070_497,

                    blindDesperateBehindThreshold: 250,
                    blindCatchUpBehindThreshold: 140,
                    blindSafeLeadThreshold: 300,
                    blindDesperateTargetShare: 0.72,
                    blindCatchUpTargetShare: 0.52
                ),
                trumpSelection: TrumpSelection(
                    cardBasePower: 0.638_293,
                    minimumPowerToDeclareTrump: 1.211_691
                ),
                timing: Timing(
                    playingBotTurnDelay: 0.22,
                    biddingStepDelay: 0.15,
                    trickResolutionDelay: 0.45
                )
            )
        }
    }
}
