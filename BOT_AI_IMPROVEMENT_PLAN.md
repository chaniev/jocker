# План улучшения AI бота (алгоритмы игры)

## Цель

Повысить качество решений бота в реальной партии за счет:
- учета премиальной системы и контекста блока;
- более корректной логики blind-ставок в 4-м блоке;
- фазозависимой оценки силы/угрозы карт;
- улучшения логики розыгрыша джокера;
- добавления адаптации к стилю соперников;
- сохранения/роста общего win rate после изменений.

## Основание (зафиксированные замечания)

1. Недооценка системы премий.
2. Некорректная оценка blind-ставок в 4-м блоке.
3. Слабая адаптация к стилю игры соперников.
4. Недооценка джокера в контексте объявления.
5. Отсутствие долгосрочного планирования в блоке.
6. Ошибки в оценке "угрозы" карт (без учета фазы игры).

## Принципы реализации

- Сначала исправляем архитектурные ограничения, потом тюним коэффициенты.
- Каждое изменение должно иметь измеримую метрику и регрессионные тесты.
- Изменения внедряем небольшими PR, чтобы не смешивать разные причины поведения.
- Self-play тюнинг выполняется только после стабилизации новой логики.
- Для рискованных этапов заранее фиксируем fallback-версию (упрощенный вариант).

## Критерии успеха (верхнеуровневые)

- Бот лучше играет в матчевом контексте (не только по очкам отдельного раунда).
- Снижается число решений, которые "дарят" соперникам премии.
- Снижается число ситуаций, где бот становится целью штрафа за чужую премию.
- Blind-решения в 4-м блоке становятся более согласованными с ситуацией по счету.
- Улучшается качество выбора объявления джокера (`wish/above/takes`) в контекстных сценариях.
- Нет заметного регресса по win rate/score diff против текущего hard-бота.

## Актуальное состояние кода (после последних изменений)

Ниже зафиксировано текущее состояние AI-слоя, чтобы план отражал реальную архитектуру, а не исходную монолитную версию.

### Что уже изменилось в коде (архитектурная база)

- Runtime-логика хода бота декомпозирована:
  - `BotTurnStrategyService` теперь orchestration-слой;
  - `BotTurnCandidateEvaluatorService` выполняет цикл перебора/оценки кандидатов;
  - `BotTurnCandidateRankingService` отвечает за `utility` и tie-break;
  - `BotTurnCardHeuristicsService` содержит `cardThreat`, joker-варианты, `unseenCards`, `estimateImmediateWinProbability`;
  - `BotTurnRoundProjectionService` содержит `normalizedBid`, прогноз будущих взяток и `expectedRoundScore`.
- Введен `BotTurnStrategyService.BotTurnDecisionContext`, и runtime-API уже умеет принимать контекст-объект.
- `GameTurnService` уже имеет `automaticTurnDecision(context:)`.
- `GameScene+PlayingFlow.swift` уже вызывает автоход через context-based API (`automaticTurnDecision(context:)`).
- Общие признаки руки вынесены в `HandFeatureExtractor` и переиспользуются в `BotBiddingService`, `BotTrumpSelectionService`, `BotTurnRoundProjectionService`.
- Нормализация рангов вынесена в `BotRankNormalization`.

### Что по-прежнему остается проблемой (по поведению)

- Premium-aware / penalty-aware utility уже влияет на runtime utility (этапы 4b/4c в MVP/fallback реализованы), но логика пока неполная: без полноценного моделирования соперников и без retuning после архитектурных изменений.
- `BotTurnCardHeuristicsService.cardThreat(...)` уже стал phase-aware в MVP-варианте, но пока не получает полный threat-context из плана (дефицит/избыток взяток, позиция в взятке, chase/dump, blind).
- Runtime-решения бота уже используют block/premium context по поведению (MVP 4b/4c), но часть coverage пока закреплена probe-сценариями (`XCTSkip`) и требует стабилизации коэффициентов.
- Логика объявлений джокера (`wish/above/takes`) начата в MVP-варианте, но пока без детального моделирования ответов соперников и без полного runtime-покрытия strict-сценариями.
- Нет runtime-адаптации к стилю соперников.

### Влияние на план

- Этапы остаются актуальными по цели, но точки внедрения смещаются в новые сервисы.
- Этапы 2 и 3 теперь должны меняться преимущественно в `BotTurnRoundProjectionService`, `BotTurnCandidateRankingService`, `BotTurnCandidateEvaluatorService`, `BotTurnCardHeuristicsService`, а не только в `BotTurnStrategyService`.
- Этап 2.5 теперь про расширение уже существующего `BotTurnDecisionContext`, а не про ввод context-API с нуля.

## Статус выполнения (зафиксировано на 2026-02-22)

- Этап 0 (baseline): частично
  - добавлен черновик `BOT_AI_TEST_SCENARIOS.md` (есть группы `BLIND/PREMIUM/JOKER/PHASE` и concrete drafts v0);
  - зафиксированы шаблоны метрик/seed/команд;
  - baseline-метрики еще не собраны.
- Этап 1 (Blind fix): выполнен по коду и unit-тестам
  - `makePreDealBlindBid(...)` переведен на risk-score;
  - `blindSafeLeadThreshold` влияет на решение;
  - покрыты сценарии safe-gap / catch-up / dealer-vs-nondealer.
- Этап 2 (Blind-aware play): выполнен по коду и unit-тестам
  - `isBlind` протянут в turn decision/evaluator/projection/ranking utility;
  - добавлены тесты на blind-aware scoring/utility.
- Этап 2.5 (blind plumbing в flow): выполнен по коду
  - `GameScene+PlayingFlow` передает `isBlind` в runtime context;
  - `GameTurnService`/`GameSceneCoordinator` синхронизированы по сигнатурам.
- Этап 3 (Phase-aware threat): в процессе (MVP реализован)
  - `cardThreat(...)` стал phase-aware (ранняя/поздняя фаза);
  - phase-context протянут из `BotTurnCandidateEvaluatorService`;
  - добавлены phase tests (`Heuristics`) и probe test (`Strategy`, допускает `XCTSkip` до retuning).
- Этап 4a (базовый контекст блока): начат
  - добавлен plumbing type `BotMatchContext`;
  - выполнен runtime/bidding plumbing контекста без изменения поведения (feature plumbing first);
  - turn-stack plumbing расширен до `BotTurnCandidateRankingService` / `BotTurnRoundProjectionService`;
  - добавлены behavior-neutral unit-тесты (`projection` / `ranking` / `evaluator`) на прием `matchContext`.
- Этап 4b (Premium utility): начат (MVP-подшаг)
  - добавлен score-only `matchCatchUpUtility` в `BotTurnCandidateRankingService` (без premium-candidate/zero-premium логики);
  - utility учитывает `totalScores` + прогресс блока из `BotMatchContext` только в режиме `chase`;
  - `BotMatchContext` расширен `premium`-snapshot (completed/remaining rounds, premium-candidate, zero-premium-candidate);
  - `GameScene.botMatchContext(...)` начал собирать базовые premium-признаки из `ScoreManager.currentBlockRoundResults`;
  - добавлен MVP `premiumPreserveUtility` в `BotTurnCandidateRankingService` (своя премия / zero-premium, без моделирования соперников), уже с усилением к концу блока (`completed/remaining rounds`);
  - в utility-контекст добавлен `trickDeltaToBidBeforeMove` (точнее отличаем `exact-bid` от уже сорванного `overbid` внутри текущей раздачи);
  - `premiumPreserveUtility` учитывает trajectory-edge (`exact-bid` vs `already broken`) для premium/zero-premium защиты;
  - добавлены runtime probe-тесты/сценарии (`Strategy premium probe`, `PREMIUM-003` draft) для фиксации ожидаемого premium-aware различия решений как цели retuning;
  - добавлены unit-тесты на направление эффекта (отставание/лидерство) и boundary-тест `GameTurnService` с нейтральным `matchContext`.
- Этап 4c (Opponent premium / penalty-aware): начат (fallback MVP)
  - `BotMatchContext.PremiumSnapshot` расширен признаками penalty-risk (`isPenaltyTargetRiskSoFar`, count threatening premium candidates, left-neighbor candidate flag);
  - `GameScene.botMatchContext(...)` начал вычислять risk стать penalty target по текущим premium-candidates (без моделирования будущих ходов);
  - добавлен `penaltyAvoidUtility` в `BotTurnCandidateRankingService` (fallback 4c без `premiumDenyUtility`);
  - начат и расширен упрощенный `premiumDenyUtility` (anti-premium: сосед слева + прочие premium-candidates, с приоритетом соседа слева) в `BotTurnCandidateRankingService`;
  - `BotMatchContext.PremiumSnapshot` расширен счетчиком `opponentPremiumCandidatesSoFarCount` для generalized anti-premium pressure;
  - добавлены runtime probe-тесты/сценарии для `4c` (`Strategy penalty-risk probe`, `Strategy anti-premium probe`, `PREMIUM-006/008` drafts) как цель дальнейшего retuning;
  - добавлен строгий runtime-тест (`Strategy`) на deterministic anti-premium flip в last-seat dump сценарии с усиленным opponent premium pressure;
  - добавлены unit-тесты на направление penalty-risk эффекта и flow-тест источника premium/penalty snapshot.
- Этап 5 (Joker logic): начат (MVP `wish/above/takes`, без сложного моделирования ответов)
  - в `BotTurnCandidateRankingService` выделен helper контекстной оценки объявления ведущего джокера (`wish/above/takes`);
  - добавлены unit-тесты на trump-aware `above` (разный приоритет в `chase`/`dump`) и сохранение `wish` в финальном all-in chase.
  - добавлены strict evaluator-level тесты (forced lead-joker) на `above(trump)` в раннем chase и `wish` в финальном all-in chase;
  - добавлен runtime `Strategy` probe-сценарий (`above` vs `wish` по срочности добора) как цель retuning.
  - helper расширен на MVP scoring для `takes` (chase-пенальти / dump controlled-loss бонус, c учётом trump и фазы);
  - добавлены unit-тесты на `takes(non-trump)` vs `takes(trump)` и `above(trump)` vs `takes(trump)`, а также strict evaluator-тест на выбор `takes(non-trump)` в forced lead-joker dump.
  - добавлены сценарные drafts `JOKER-003/004/005` для utility/evaluator/runtime сравнения объявлений.
  - добавлен runtime `Strategy` probe для `takes` в раннем dump-сценарии с "опасной" trump-рукой (`JOKER-006`) как цель retuning.
  - в `Evaluator` добавлен plumbing сигнала `remaining control in hand after move` для lead-joker declaration scoring (`wish/above/takes`);
  - `leadJokerDeclarationUtility` начал учитывать `remaining control reserve` (низкий reserve сильнее смещает к немедленному контролю в early chase);
  - добавлены unit-тесты на влияние `control reserve` в utility и сценарный draft `JOKER-007`.
  - добавлен runtime `Strategy` probe на reserve-aware lead-joker declaration (`JOKER-008`) как цель retuning/стабилизации до strict runtime-assert.
  - добавлен strict runtime `Strategy`-тест на `above(trump) -> wish` flip по срочности добора (`JOKER-009`) для weak-hand lead-joker сценария.

### Ограничение валидации (текущее окружение)

- Полный `xcodebuild test`/`xcodebuild build` в текущем окружении не проходит из-за проблем с `CoreSimulatorService` и отсутствующего runtime/SDK (`iOS 17.2 Platform Not Installed` в `ibtool`).
- Локально выполнялась синтаксическая проверка измененных Swift-файлов через `swiftc -frontend -parse`.

## Метрики и baseline (этап 0)

До внесения логики нужно зафиксировать baseline.

### Основные матчевые метрики

- `winRate`
- `averageScoreDiff`
- `averageUnderbidLoss`
- `averagePremiumAssistLoss`
- `averagePremiumPenaltyTargetLoss`

### Расширенные операционные метрики (обязательно для baseline)

- `premiumCaptureRate` = `premiumBlocks / totalBlocks`
- `blindSuccessRate` = `successfulBlinds / totalBlinds`
- `jokerWishWinRate` = `wishWins / totalWishLeads`
- `earlyJokerSpendRate` = `earlyJokers / totalJokers`
- `penaltyTargetRate` = `penaltyTimes / totalBlocks`
- `leftNeighborPremiumAssistRate` = `assistedPremiumsToLeftNeighbor / leftNeighborPremiumEvents`
- `bidAccuracyRate` = `exactBids / totalRounds`
- `overbidRate` = `overtricks / totalRounds`
- частота blind-ставок в 4-м блоке
- средний размер blind-ставки
- доля blind-ставок при отставании / при лидерстве
- частота раннего `lead wish` джокером (не в последней взятке)

### Набор сценариев baseline

- Self-play full-match прогон на фиксированных seed.
- Head-to-head: новый кандидат против текущего `hard`.
- Ручные регрессионные сценарии (детерминированные) в отдельном файле `BOT_AI_TEST_SCENARIOS.md` (создается на Этапе 0).
- Минимальные группы сценариев:
  - `BLIND-*`
  - `PREMIUM-*`
  - `JOKER-*`
  - `PHASE-*`

### Артефакты baseline

- Таблица метрик `baseline vs candidate`.
- Набор тест-кейсов и ожидаемое поведение (не только "прошло/не прошло").
- Краткий отчет с выводами по слабым местам текущего бота.
- Зафиксированные seed и команды запуска для повторяемости.

### Готовность к завершению Этапа 0

- [ ] Метрики baseline собраны на фиксированном наборе seed.
- [x] Создан черновик `BOT_AI_TEST_SCENARIOS.md` с детерминированными кейсами.
- [ ] Добавлены/обновлены тесты-инструменты для расчета метрик (если нужны).
- [ ] Есть воспроизводимый способ сравнения `baseline vs candidate`.

## Ориентировочная оценка трудозатрат (часы)

Оценки приблизительные, без учета ожидания CI и итераций ревью.

| Этап | Оценка (часы) | Риск |
|------|---------------|------|
| 0 (Baseline) | 8-12 | Низкий |
| 1 (Blind fix) | 6-10 | Низкий |
| 2 (Blind-aware play) | 10-16 | Средний |
| 2.5 (Интеграция blind в flow) | 4-8 | Средний |
| 3 (Phase-aware threat) | 12-20 | Средний |
| 4a (Базовый контекст блока) | 12-18 | Средний |
| 4b (Premium utility: своя премия) | 16-24 | Высокий |
| 4c (Opponent premium / penalty-aware) | 14-20 | Высокий |
| 5 (Joker logic) | 16-28 | Высокий |
| 6 (Opponent model MVP) | 20-32 | Средний |
| 7 (Retuning) | 40-80+ | Высокий |

**Итого (ориентир):** ~158-268 часов чистого времени.

## Граф зависимостей этапов

```text
Этап 0: Baseline
    ↓
Этап 1: Blind fix
    ↓
Этап 2: Blind-aware play
    ↓
Этап 2.5: Интеграция blind-контекста в flow
    ↓
Этап 3: Phase-aware threat
    ↓
Этап 4a: Базовый контекст блока
    ↓
Этап 4b: Premium utility (своя премия)
    ↓
┌─────────────────────┴─────────────────────┐
↓                                           ↓
Этап 4c: Opponent premium            Этап 5: Joker logic
    ↓                                           ↓
    └───────────────┬───────────────────────────┘
                    ↓
        Этап 6: Opponent model (MVP)
                    ↓
        Этап 7: Self-play retuning
```

## Дорожная карта (этапы)

## Этап 1. Быстрые исправления blind-логики (высокий приоритет)

### Цель

Сделать решение по blind в 4-м блоке более разумным без полной перестройки AI.

### Изменения

- Переработать `BotBiddingService.makePreDealBlindBid(...)`.
- Убрать/исправить "мертвую" ветку, где `blindSafeLeadThreshold` не влияет на итог.
- Заменить простую пороговую схему на риск-скор (эвристический score):
  - отставание от лидера;
  - отрыв от ближайшего соперника;
  - позиция (дилер / не дилер);
  - размер раздачи (`cardsInRound`);
  - диапазон доступных blind-ставок;
  - стадия блока (если доступна на этом этапе).
- Добавить более явный выбор целевого размера blind-ставки:
  - консервативный;
  - догоняющий;
  - авральный.

### Что не делаем на этапе 1

- Полноценную вероятностную модель исхода blind.
- Учет стилей соперников.

### Критерии приемки

- Параметр `blindSafeLeadThreshold` реально влияет на решение.
- В тестах лидер реже выбирает blind без необходимости.
- В тестах отстающий игрок чаще выбирает blind в "догоняющих" сценариях.
- Нет регресса по базовым тестам торгов.

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`
- `Jocker/JockerTests/Bot/BotBiddingServiceTests.swift`

## Этап 2. Blind-aware розыгрыш (высокий приоритет)

### Цель

Сделать поведение бота в blind-раунде отличным от обычного, так как цена ошибки/успеха удваивается.

### Изменения

- Расширить `BotTurnStrategyService.BotTurnDecisionContext` полем `isBlind`.
- Протянуть `isBlind` в `BotTurnCandidateEvaluatorService.DecisionContext` (или вложенный utility/projection context).
- Учесть `isBlind` в `BotTurnRoundProjectionService.expectedRoundScore(...)`.
- При необходимости учесть `isBlind` в `BotTurnCandidateRankingService.moveUtility(...)` (вес риска/награды в `chase`/`dump`).
- Усилить влияние риска/награды при chase/dump в blind-режиме.
- Добавить тесты на различие решений в одинаковом состоянии при `blind=false` и `blind=true`.

### Критерии приемки

- Ходовой AI принимает разные решения в blind и non-blind хотя бы в части тестовых сценариев.
- Улучшается средняя эффективность blind-раундов в self-play/head-to-head.
- Изменения готовы к интеграции в игровой flow без поломки существующей сигнатуры вызова (или с контролируемой миграцией).

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift` (расширение decision context / orchestration)
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnRoundProjectionService.swift`
- `Jocker/JockerTests/Bot/*`

## Этап 2.5. Интеграция blind-контекста в игровой flow (обязательный plumbing-этап)

### Цель

Явно и безопасно протянуть `isBlind` от игрового состояния до ходового AI через уже существующий context-based runtime API.

### Изменения (по слоям)

- `BotTurnStrategyService.BotTurnDecisionContext`:
  - добавить поле `isBlind`.
- `GameScene+PlayingFlow.swift`:
  - определить `isBlindRound` (источник: runtime-состояние игрока, например `gameState.players[playerIndex].isBlindBid`);
  - передать `isBlind` в `BotTurnDecisionContext` при автходе бота.
- `GameTurnService.swift`:
  - использовать уже существующий `automaticTurnDecision(context:)`;
  - убедиться, что новый флаг `isBlind` не теряется при проходе через service boundary.
- `GameSceneCoordinator.swift`:
  - отметить как вторичный путь (если этот API используется для автохода в будущем / в тестовых сценариях), синхронизировать сигнатуру при необходимости.

### Критерии приемки

- `isBlind` проходит по стеку вызова до `BotTurnStrategyService`.
- `isBlind` далее доступен в `BotTurnCandidateEvaluatorService`/projection utility.
- Нет регресса в non-blind раундах.
- Добавлены тесты/проверки на корректную передачу контекста.

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`
- `Jocker/Jocker/Game/Services/Flow/GameTurnService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift` (если требуется синхронизация API)
- `Jocker/JockerTests/Bot/*`

## Этап 3. Фазозависимая оценка угрозы карт (высокий приоритет)

### Цель

Убрать почти статическую оценку `cardThreat` и сделать ее зависимой от фазы игры.

### Изменения

- Расширить сигнатуру `BotTurnCardHeuristicsService.cardThreat(...)` контекстом:
  - сколько взяток осталось;
  - сколько взяток нужно добрать/слить относительно заказа;
  - режим (`chase`/`dump`);
  - `chasePressure`;
  - blind/non-blind;
  - позиция в текущей взятке (lead / mid / last).
- Протянуть новый threat-context через `BotTurnCandidateEvaluatorService` (где сейчас вызывается `cardThreat`).
- Для обычных карт:
  - разная цена сохранения козыря/старшей карты в ранней и поздней фазе;
  - учет дефицита/избытка взяток.
- Для джокера:
  - разная "цена" расхода в начале, середине и конце раунда;
  - разная цена для chase/dump.

### Критерии приемки

- `BotTurnCardHeuristicsService.cardThreat(...)` перестает быть чисто константным по типу карты.
- Появляются тесты на фазовые различия оценки.
- Улучшается качество решений в сценариях "нужно добрать последние 1-2 взятки" и "нужно избегать лишней взятки".

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Services/AI/BotTurnCardHeuristicsService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift` (если часть фазового контекста влияет на utility, а не только на threat)
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift` (минимальный plumbing при изменении контекстов)
- `Jocker/JockerTests/Bot/BotTurnCardHeuristicsServiceTests.swift`
- `Jocker/JockerTests/Bot/BotTurnCandidateEvaluatorServiceTests.swift`
- `Jocker/JockerTests/Bot/BotTurnStrategyServiceTests.swift`

## Этап 4a. Базовый контекст блока в runtime-решениях (ключевой plumbing-этап)

### Цель

Добавить в runtime-решения минимально необходимый матчевый/блоковый контекст без сложной премиальной эвристики.

### Изменения

- Расширить существующий `BotTurnStrategyService.BotTurnDecisionContext` или добавить вложенный `matchContext` / `roundContext`:
  - номер блока;
  - индекс раздачи внутри блока;
  - прогресс блока (раунд X из Y);
  - `totalScores` всех игроков;
  - позиция игрока относительно дилера.
- Передавать этот контекст в:
  - `BotBiddingService`;
  - `BotTurnStrategyService`.
- Внутри turn-stack прокинуть данные до сервисов, где они реально используются:
  - `BotTurnCandidateEvaluatorService`;
  - `BotTurnCandidateRankingService` и/или `BotTurnRoundProjectionService` (в зависимости от места применения).
- Подготовить точки расширения для premium-aware utility, но без сложных вычислений вероятностей.

### Интеграция с flow (обязательная часть 4a)

- Уточнить источники данных контекста в момент хода бота:
  - `gameState.currentBlock`;
  - текущий индекс раздачи в блоке;
  - данные `ScoreManager`/результатов блока, доступные на этом шаге.
- Протянуть контекст через фактически используемый runtime-путь:
  - `GameScene+PlayingFlow.swift` -> `GameTurnService.swift` -> `BotTurnStrategyService.swift`.
- Для альтернативного/резервного пути синхронизировать `GameSceneCoordinator.swift`, если его API используется/будет использоваться для автоходов.
- Аналогично протянуть контекст до `BotBiddingService` в стадиях торгов/blind.

### Критерии приемки

- В момент решения бота доступен базовый контекст блока и счета.
- Нет изменений поведения при отключенном использовании новых полей контекста.
- Добавлены тесты на корректную передачу контекста.

### Готовность к старту Этапа 4a

- [ ] Этапы 1, 2, 2.5 и 3 завершены и протестированы.
- [ ] Зафиксирован baseline по premium-метрикам.
- [x] Понятно, откуда брать блоковый прогресс и `totalScores` в момент хода.
- [x] Есть тестовый контур для проверки plumbing-изменений в flow.

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`
- `Jocker/Jocker/Game/Services/Flow/GameTurnService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnRoundProjectionService.swift` (если контекст влияет на projection utility)
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`
- `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift` (если требуется синхронизация API)
- Возможные новые модели в `Jocker/Jocker/Models/Bot/`
- `Jocker/JockerTests/Bot/*`

## Этап 4b. Premium-aware utility (своя премия / собственная устойчивость)

### Цель

Добавить в utility учет собственной премиальной траектории без моделирования сложного поведения соперников.

### Изменения

- Добавить признаки состояния собственной премии:
  - бот еще кандидат на премию;
  - бот еще кандидат на zero-premium (где применимо);
  - цена срыва точного заказа в текущем блоковом контексте.
- Добавить utility-компоненты:
  - `premiumPreserveUtility` (сохранить шанс на свою премию);
  - `matchCatchUpUtility` (стратегический риск/осторожность по счету).
- Реализовать их в текущем модульном turn-stack:
  - utility-часть преимущественно в `BotTurnCandidateRankingService`;
  - при необходимости признаки/проекции в `BotTurnCandidateEvaluatorService` и `BotTurnRoundProjectionService`.
- Сделать правила фазозависимыми: в конце блока премиальная составляющая должна весить больше.

### Важный компромисс

- Полный `premiumDenyUtility` против соперников не внедряется в 4b.
- Не моделируем дерево ходов соперников.

### Критерии приемки

- В сценариях конца блока бот меняет решения в зависимости от собственного premium-статуса.
- Снижается число срывов собственной премии в детерминированных кейсах.
- Нет явного регресса по базовому win rate.

### Готовность к старту Этапа 4b

- [ ] Этап 4a завершен, контекст стабильно доступен в runtime.
- [ ] Есть сценарии `PREMIUM-*` для собственной премии.
- [ ] Понятно, как вычисляется статус кандидата на премию/zero-premium из доступных данных.

### Fallback для Этапа 4b (если реализация затягивается)

- Начать только с учета текущего блока (без `totalScores`).
- Ограничиться `premiumPreserveUtility` без `matchCatchUpUtility`.

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift` (оркестрация контекста)
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnRoundProjectionService.swift` (если контекст влияет на round-scoring projection)
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`
- Возможные новые utility/helper типы в `Game/Services/AI/`
- `Jocker/JockerTests/Bot/*`

## Этап 4c. Opponent premium / penalty-aware utility (сосед и соперники)

### Цель

Добавить защиту от штрафов за чужую премию и базовый anti-premium контекст по соперникам.

### Изменения

- Добавить признаки premium-статуса соперников (минимум: сосед слева / penalty target relevance).
- Добавить utility-компоненты:
  - `penaltyAvoidUtility` (снизить риск стать целью штрафа);
  - `premiumDenyUtility` (снизить шанс премии соперника) — в упрощенной эвристической форме.
- Основная интеграция expectedly в `BotTurnCandidateRankingService` (utility) с plumbing через `BotTurnCandidateEvaluatorService`.
- Учитывать позицию относительно соседа слева как отдельный фактор.

### Критерии приемки

- В сценариях с риском штрафа бот чаще выбирает безопасные линии.
- Снижается `averagePremiumPenaltyTargetLoss`.
- Снижается `averagePremiumAssistLoss` без сильной деградации win rate.

### Готовность к старту Этапа 4c

- [ ] Этап 4b завершен и стабилен.
- [ ] Есть сценарии на риск штрафа и "подаренную" премию.
- [ ] Есть доступ к необходимой информации о соседе слева в момент решения.

### Fallback для Этапа 4c (если реализация затягивается)

- Реализовать только `penaltyAvoidUtility` (защита от штрафа).
- Отложить `premiumDenyUtility` на следующий цикл.

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift` (оркестрация контекста)
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`
- Возможные новые utility/helper типы в `Game/Services/AI/`
- `Jocker/JockerTests/Bot/*`

## Этап 5. Переработка логики джокера по объявлениям (после этапов 3 и 4b, желательно после 4c)

### Цель

Улучшить выбор `wish/above/takes` не только за счет коэффициентов, а за счет контекстной оценки.

### Изменения

- Выделить отдельную функцию/модуль оценки объявления джокера.
- Оценивать объявление по признакам:
  - цель хода (`chase`/`dump`);
  - фаза раунда;
  - remaining control в руке;
  - козырь / без козыря;
  - необходимость контроля масти после хода;
  - премиальный контекст (если актуален).
- Оставить `BotTuning` коэффициенты (`chaseLeadWishBonus`, `threatLeadWishJoker` и др.) как корректирующие веса, а не основной механизм.
- Встроить новую оценку в текущую модульную схему:
  - генерация вариантов остается в `BotTurnCardHeuristicsService`;
  - scoring/utility обновляется в `BotTurnCandidateRankingService` и/или выделенном joker-helper.

### Критерии приемки

- Снижается частота неудачных ранних `wish` в ситуациях, где выгоднее `above/takes`.
- В тестовых сценариях выбор объявлений соответствует ожидаемой цели (добор/сброс/контроль).
- Self-play метрики не ухудшаются после перехода на новую оценку.

### Fallback для Этапа 5

- Ограничиться только `wish` vs `above`.
- Отложить детальную оптимизацию `takes` до следующего цикла.

### Файлы (ожидаемо)

- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift` (оркестрация/контекст)
- `Jocker/Jocker/Game/Services/AI/BotTurnCardHeuristicsService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- Возможно новый helper/service для джокера
- `Jocker/Jocker/Models/Bot/BotTuning.swift`
- `Jocker/JockerTests/Bot/*`

## Этап 6. Адаптация к стилю соперников (этап 2, после стабилизации ядра)

### Цель

Добавить простую онлайн-адаптацию к наблюдаемым паттернам оппонентов.

### Минимальная версия (MVP)

- Ввести `OpponentModel` с накоплением статистики по игрокам:
  - склонность к blind;
  - агрессивность заказов;
  - частота переразбора/недобора;
  - склонность рано тратить джокер;
  - склонность добирать лишние взятки.
- Использовать модель в:
  - оценке вероятности удержания взятки;
  - risk-score blind;
  - выборе линии розыгрыша в chase/dump.

### Ограничения MVP

- Без ML и сложного обучения.
- Только легкая статистика внутри текущей партии.

### Критерии приемки

- Поведение бота меняется между "агрессивными" и "осторожными" оппонентами в тестовых сценариях.
- Нет заметного падения производительности.
- Логика остается детерминируемой в тестах (при фиксированном состоянии).

### Fallback для Этапа 6

- Начать только с blind-статистики и агрессивности заказов.
- Отложить паттерны джокера на следующий цикл.

### Файлы (ожидаемо)

- Новый тип модели соперника в `Jocker/Jocker/Models/Bot/` или `Game/Services/AI/`
- `Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift` (оркестрация/контекст)
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateEvaluatorService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCandidateRankingService.swift`
- `Jocker/Jocker/Game/Services/AI/BotTurnCardHeuristicsService.swift` (если модель влияет на вероятности/угрозы)
- `Jocker/Jocker/Game/Services/AI/BotBiddingService.swift`
- Игровой flow/координатор для обновления наблюдений
- `Jocker/JockerTests/Bot/*`

## Этап 7. Ретюнинг коэффициентов через self-play (после архитектурных изменений)

### Цель

Переобучить/перетюнить коэффициенты под новую модель, а не "натягивать" старые веса на новую архитектуру.

### Изменения

- Запустить self-play эволюцию на обновленном AI.
- При необходимости расширить fitness-компоненты:
  - премиальная игра;
  - качество blind;
  - штраф за контекстно-плохие джокер-решения.
- Сравнить:
  - текущий hard;
  - hard после архитектурных изменений (до тюнинга);
  - hard после тюнинга.

### Критерии приемки

- Новый `hard` не хуже baseline по ключевым метрикам.
- Есть измеримое улучшение минимум по двум целевым направлениям (премии / blind / джокер / phase-aware play).
- Изменения коэффициентов зафиксированы тестами/снапшотами (где уместно).

### Критерии остановки итерации self-play тюнинга

- `winRate` стабилизировался (изменение < 1% за 3 поколения).
- Fitness-функция не растет (изменение < 0.5% за 5 поколений).
- Достигнут целевой порог минимум по 3 метрикам (например: `premiumCaptureRate`, `blindSuccessRate`, `bidAccuracyRate`).
- Время принятия решения бота превышает согласованный лимит.
- Превышено максимальное число поколений/итераций, заданное для цикла.

### Готовность к старту Этапа 7

- [ ] Этапы 1-6 завершены или явно заморожены с принятым fallback.
- [ ] Метрики baseline и post-architecture версии собраны в сопоставимом формате.
- [ ] Определены лимиты времени/ресурсов на тюнинг-цикл.
- [ ] Зафиксированы критерии остановки и целевые метрики для текущей итерации.

### Fallback для Этапа 7

- Тюнинговать только `turnStrategy`, оставить `bidding`/`trumpSelection` без изменений.
- Уменьшить размер пространства параметров на первую итерацию.

### Файлы (ожидаемо)

- `Jocker/Jocker/Models/Bot/BotTuning.swift`
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine.swift`
- `scripts/train_bot_tuning.sh`
- `Jocker/JockerTests/Bot/BotTuningTests.swift`

## Рекомендуемая нарезка по PR (1 PR = 1 шаг)

1. Этап 0: baseline-метрики + воспроизводимый запуск + черновик `BOT_AI_TEST_SCENARIOS.md` (без изменения поведения).
2. Этап 1: blind-логика (`makePreDealBlindBid`) и тесты.
3. Этап 2: blind-aware runtime utility в `BotTurnStrategyService`.
4. Этап 2.5: plumbing blind-контекста через flow/coordinator/service.
5. Этап 3: phase-aware `cardThreat` и связанные тесты.
6. Этап 4a: базовый контекст блока/счета и его передача.
7. Этап 4b: premium-aware utility (своя премия / match context).
8. Этап 4c: penalty-aware/opponent-premium utility.
9. Этап 5: контекстная логика объявлений джокера.
10. Этап 6: `OpponentModel` (MVP) и интеграция.
11. Этап 7: self-play retuning + финальная валидация.

## Критерии готовности к сложным этапам (чек-листы)

### Готовность к Этапу 4 (серия 4a-4c)

- [ ] Этапы 1-3 завершены и протестированы.
- [x] Есть доступ к `gameState.currentBlock` в момент хода бота.
- [x] Есть доступ к данным счета/результатов блока в момент принятия решения.
- [ ] Написаны тесты на передачу контекста через flow/coordinator/service.
- [ ] Зафиксирован baseline по premium-метрикам.
- [ ] Время принятия решения бота в текущем baseline измерено.

### Готовность к Этапу 5

- [ ] Этап 3 завершен (phase-aware threat стабилен).
- [x] Этап 4b завершен минимум в MVP-виде.
- [x] Есть сценарии `JOKER-*` для `wish/above/takes`.
- [ ] Зафиксирована baseline-частота раннего `lead wish`.

### Готовность к Этапу 7

- [ ] Архитектурные изменения заморожены на текущую итерацию.
- [ ] Метрики собираются автоматически или полуавтоматически одинаковым способом.
- [ ] Есть лимиты по времени/поколениям и критерии остановки.
- [ ] Есть план rollback для неудачного набора коэффициентов.

## Fallback-планы по сложным этапам

| Этап | Если слишком сложно / долго |
|------|-----------------------------|
| 4b (Premium utility) | Начать только с учета текущего блока, игнорировать `totalScores` |
| 4c (Opponent premium) | Реализовать только защиту от штрафа (`penaltyAvoidUtility`) |
| 5 (Joker logic) | Ограничиться `wish` vs `above`, отложить `takes` |
| 6 (Opponent model) | Только blind-статистика и агрессивность заказов |
| 7 (Retuning) | Тюнинговать только `turnStrategy`, зафиксировать остальные блоки |

## Риски и меры снижения

### Риск: недооценка сложности интеграции с flow

- Выделять plumbing-изменения отдельным этапом (например, 2.5 и 4a).
- Проверять доступность контекста в runtime до начала алгоритмических правок.
- Сначала добавлять передачу данных без изменения поведения (feature plumbing first).

### Риск: переусложнение utility и деградация читаемости

- Держать utility-компоненты раздельными именованными функциями.
- Добавлять комментарии только на сложных ветках.
- Покрыть сценарными тестами каждую новую компоненту utility.

### Риск: "улучшили премии, сломали базовую игру"

- Сравнивать метрики пакетно, а не по одной.
- Не объединять премии/джокера/blind в один PR.
- Делать head-to-head against current hard на фиксированных seed.

### Риск: нестабильные тесты из-за вероятностных оценок

- Использовать детерминированные состояния и фиксированные seed.
- Тестировать сравнительное поведение (A > B), а не точные магические числа, где возможно.

### Риск: падение производительности на ходу

- Измерять время принятия решения до/после.
- Сначала вводить легкие эвристики и кешируемые признаки.
- Не добавлять тяжелые переборы без необходимости.

## Definition of Done (для всей инициативы)

- Закрыты все 6 исходных замечаний на уровне кода и тестов.
- Есть документированный baseline и финальное сравнение метрик.
- Есть отдельный файл со сценариями (`BOT_AI_TEST_SCENARIOS.md`) и он используется в регрессии.
- Runtime-бот учитывает blind и блоковый/премиальный контекст.
- `cardThreat` и логика джокера зависят от фазы/цели хода.
- Есть MVP-адаптация к стилю соперников.
- `BotTuning` перетюнинен после архитектурных изменений.
- Обновлены тесты и документация (`FOLDER_STRUCTURE_SPEC.md` при структурных изменениях).
