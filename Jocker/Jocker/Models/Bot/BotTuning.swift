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
        var utilityTieTolerance: Double

        /// Вес вероятности немедленной победы во взятке при доборе до заказа.
        /// Пример: `55` заставляет бота агрессивнее выбирать выигрышные карты.
        var chaseWinProbabilityWeight: Double
        /// Штраф за розыгрыш "дорогих" карт в режиме добора.
        /// Пример: `0.20` дольше сохраняет сильные карты на руке.
        var chaseThreatPenaltyWeight: Double
        /// Дополнительный штраф за трату джокера, если можно выиграть без него.
        /// Пример: `80` резко снижает ранний розыгрыш джокера.
        var chaseSpendJokerPenalty: Double
        /// Бонус за заход джокером с объявлением `wish` в режиме добора.
        /// Пример: `12` повышает приоритет этого объявления.
        var chaseLeadWishBonus: Double

        /// Награда за проигрыш текущей взятки в режиме сброса.
        /// Пример: `60` уменьшает случайные "лишние" взятки.
        var dumpAvoidWinWeight: Double
        /// Награда за сброс карт с высокой угрозой в режиме сброса.
        /// Пример: `0.30` чаще избавляет от опасных карт.
        var dumpThreatRewardWeight: Double
        /// Штраф за трату джокера в режиме сброса, если есть проигрывающая альтернатива.
        /// Пример: `90` помогает не сжигать джокер зря.
        var dumpSpendJokerPenalty: Double
        /// Штраф за неведущий джокер лицом вверх в режиме сброса.
        /// Пример: `50` смещает выбор к джокеру рубашкой вверх.
        var dumpFaceUpNonLeadJokerPenalty: Double
        /// Бонус за `takes` с некозырной мастью при заходе джокером в режиме сброса.
        /// Пример: `10` делает такую линию хода более частой.
        var dumpLeadTakesNonTrumpBonus: Double

        /// Вес комбинаторной оценки "удержания взятки" в вероятности победы.
        /// Пример: `0.90` больше доверяет моделированию распределения карт.
        var holdFromDistributionWeight: Double
        /// Вес эвристической силы карты в вероятности победы.
        /// Пример: `0.30` повышает влияние оценки cardPower.
        var powerConfidenceWeight: Double

        /// Базовая ценность джокера при оценке будущих взяток.
        /// Пример: `1.4` делает один джокер почти "готовой взяткой".
        var futureJokerPower: Double
        /// Базовая ценность любой обычной карты в прогнозе будущих взяток.
        /// Пример: `0.20` поднимает общий прогноз по любой руке.
        var futureRegularBasePower: Double
        /// Вклад ранга обычной карты в прогноз будущих взяток.
        /// Пример: `0.90` сильнее разделяет младшие и старшие ранги.
        var futureRegularRankWeight: Double
        /// Базовый бонус за козырную карту в прогнозе.
        /// Пример: `0.50` увеличивает ценность козырной масти.
        var futureTrumpBaseBonus: Double
        /// Дополнительный ранговый бонус для козырных карт.
        /// Пример: `0.40` сильнее предпочитает старшие козыри.
        var futureTrumpRankWeight: Double
        /// Бонус за старшие карты вне козыря (Q/K/A).
        /// Пример: `0.20` повышает ценность старших некозырных карт.
        var futureHighRankBonus: Double
        /// Бонус за длину масти (для карт сверх двух в одной масти).
        /// Пример: `0.08` сильнее вознаграждает концентрацию по масти.
        var futureLongSuitBonusPerCard: Double
        /// Глобальный множитель прогноза будущих взяток.
        /// Пример: `0.75` делает итоговый прогноз более оптимистичным.
        var futureTricksScale: Double

        /// Оценка угрозы для ведущего джокера рубашкой вверх.
        /// Пример: `30` делает такой ход более "дорогим" для расхода.
        var threatFaceDownLeadJoker: Double
        /// Оценка угрозы для неведущего джокера рубашкой вверх.
        /// Пример: `4` уменьшает готовность сбрасывать его без нужды.
        var threatFaceDownNonLeadJoker: Double
        /// Оценка угрозы для ведущего джокера с `takes`.
        /// Пример: `50` делает это объявление менее "дешёвым".
        var threatLeadTakesJoker: Double
        /// Оценка угрозы для ведущего джокера с `above`.
        /// Пример: `100` трактует ход как расход очень сильного ресурса.
        var threatLeadAboveJoker: Double
        /// Оценка угрозы для ведущего джокера с `wish`.
        /// Пример: `120` считает это самым дорогим вариантом розыгрыша.
        var threatLeadWishJoker: Double
        /// Оценка угрозы для неведущего джокера лицом вверх.
        /// Пример: `120` мешает тратить его в нейтральных позициях.
        var threatNonLeadFaceUpJoker: Double
        /// Дополнительная угроза для обычных козырных карт.
        /// Пример: `12` заставляет дольше беречь козыри.
        var threatTrumpBonus: Double
        /// Дополнительная угроза для старших обычных рангов.
        /// Пример: `5` усиливает сохранение Q/K/A.
        var threatHighRankBonus: Double

        /// Эвристическая сила для джокера рубашкой вверх.
        /// Пример: `1` оставляет почти минимальную уверенность в силе хода.
        var powerFaceDownJoker: Int
        /// Эвристическая сила для ведущего джокера `takes`.
        /// Пример: `60` повышает уверенность в этом объявлении.
        var powerLeadTakesJoker: Int
        /// Эвристическая сила для ведущего джокера `above`.
        /// Пример: `995` делает ход почти гарантированно сильным в оценке.
        var powerLeadAboveJoker: Int
        /// Эвристическая сила для ведущего джокера `wish`.
        /// Пример: `1000` задаёт максимальную тактическую силу.
        var powerLeadWishJoker: Int
        /// Эвристическая сила для неведущего джокера лицом вверх.
        /// Пример: `1000` считает его максимально сильным прямо сейчас.
        var powerNonLeadFaceUpJoker: Int
        /// Эвристический бонус силы для обычных козырей.
        /// Пример: `140` повышает уверенность при розыгрыше козыря.
        var powerTrumpBonus: Int
        /// Эвристический бонус силы за попадание в масть хода.
        /// Пример: `60` повышает оценку ответов "в масть".
        var powerLeadSuitBonus: Int
        /// Делитель нормализации для перевода силы в вероятность.
        /// Пример: `960` при той же raw-силе даёт более высокую уверенность.
        var powerNormalizationValue: Double
    }

    struct Bidding {
        /// Вклад джокера в оценку ожидаемых взяток при заказе.
        /// Пример: `1.3` повышает заказ при наличии джокеров на руке.
        var expectedJokerPower: Double
        /// Вклад ранга в оценку заказа.
        /// Пример: `0.85` чаще поднимает заказ для "старшей" руки.
        var expectedRankWeight: Double
        /// Базовый козырный бонус в оценке заказа.
        /// Пример: `0.70` повышает заказ при сильной козырной масти.
        var expectedTrumpBaseBonus: Double
        /// Ранговый козырный бонус в оценке заказа.
        /// Пример: `0.60` заметно увеличивает ценность старших козырей.
        var expectedTrumpRankWeight: Double
        /// Бонус за старшие некозырные карты в оценке заказа.
        /// Пример: `0.25` повышает заказ с Q/K/A вне козыря.
        var expectedHighRankBonus: Double
        /// Бонус за длину масти (карты сверх двух в самой длинной масти).
        /// Пример: `0.16` чаще повышает заказ при концентрации по масти.
        var expectedLongSuitBonusPerCard: Double
        /// Дополнительный бонус за плотность козыря в руке.
        /// Пример: `0.45` сильнее поднимает заказ при большом числе козырей.
        var expectedTrumpDensityBonus: Double
        /// Бонус за старшие карты в раскладах без козыря.
        /// Пример: `0.22` поднимает заказ при множестве Q/K/A без козыря.
        var expectedNoTrumpHighCardBonus: Double
        /// Синергия "джокер + контроль руки" в раскладах без козыря.
        /// Пример: `0.60` повышает заказ, если джокер подкреплён длиной/старшими картами.
        var expectedNoTrumpJokerSynergy: Double

        /// Порог отставания для "аврального" риска тёмной ставки.
        /// Пример: `200` включает риск тёмной ставки раньше при большом отставании.
        var blindDesperateBehindThreshold: Int
        /// Порог отставания для "догоняющего" режима тёмной ставки.
        /// Пример: `90` раньше включает умеренный риск.
        var blindCatchUpBehindThreshold: Int
        /// Порог отрыва, после которого бот избегает риска тёмной ставки.
        /// Пример: `260` делает лидирующего бота более осторожным.
        var blindSafeLeadThreshold: Int
        /// Целевая доля тёмной ставки в авральном режиме.
        /// Пример: `0.80` стремится к почти максимальным заказам.
        var blindDesperateTargetShare: Double
        /// Целевая доля тёмной ставки в догоняющем режиме.
        /// Пример: `0.55` чаще выбирает средне-высокие ставки.
        var blindCatchUpTargetShare: Double
        /// Консервативная доля тёмной ставки на нижней границе догоняющего режима.
        /// Пример: `0.30` при небольшом отставании снижает риск ради стабильного добора.
        var blindCatchUpConservativeTargetShare: Double
    }

    struct TrumpSelection {
        /// Базовая сила одной карты масти при выборе козыря.
        /// Пример: `0.60` делает даже средние мастевые наборы "сильнее".
        var cardBasePower: Double
        /// Минимальная сила масти для объявления козыря.
        /// Пример: `1.20` заставляет бота чаще объявлять козырь.
        var minimumPowerToDeclareTrump: Double
        /// Бонус для стадии выбора козыря игроком, когда в 3 открытых картах есть пара одной масти.
        var playerChosenPairBonus: Double
        /// Бонус за каждую карту масти сверх первой.
        var lengthBonusPerExtraCard: Double
        /// Вес плотности масти в оценке выбора козыря.
        var densityBonusWeight: Double
        /// Вес последовательности рангов внутри масти.
        var sequenceBonusWeight: Double
        /// Вес остаточного контроля масти.
        var controlBonusWeight: Double
        /// Базовая синергия джокера с потенциальным козырем.
        var jokerSynergyBase: Double
        /// Дополнительная синергия джокера от контроля масти.
        var jokerSynergyControlWeight: Double
    }

    struct Timing {
        /// Задержка перед ходом бота в фазе игры.
        /// Пример: `0.20` делает ходы бота визуально быстрее.
        var playingBotTurnDelay: TimeInterval
        /// Задержка между последовательными решениями в торгах.
        /// Пример: `0.40` замедляет темп анимации торгов.
        var biddingStepDelay: TimeInterval
        /// Задержка перед колбэком разбора взятки.
        /// Пример: `0.35` быстрее завершает взятку на столе.
        var trickResolutionDelay: TimeInterval
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
    /// Единый runtime policy для ранее разбросанных `static let` конфигов ranking/bidding/heuristics/opponent modeling.
    let runtimePolicy: BotRuntimePolicy
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
        runtimePolicy: BotRuntimePolicy? = nil,
        timing: Timing
    ) {
        self.difficulty = difficulty
        self.turnStrategy = turnStrategy
        self.bidding = bidding
        self.trumpSelection = trumpSelection
        self.runtimePolicy = runtimePolicy ?? BotRuntimePolicy.preset(for: difficulty)
        self.timing = timing
    }

    private static func preset(for difficulty: BotDifficulty) -> BotTuning {
        let hard = hardBaselinePreset

        switch difficulty {
        case .easy:
            return easyPreset(from: hard)

        case .normal:
            return normalPreset(from: hard)

        case .hard:
            return hard
        }
    }
}
