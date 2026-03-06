# Рефакторинг: актуальный план для текущей кодовой базы

**Дата:** 2026-03-06  
**Статус:** Обновлено по текущему состоянию репозитория  
**Цель:** зафиксировать реальные refactoring-приоритеты без изменения игрового поведения

## Как анализировалось

План составлен по текущему состоянию репозитория с упором на:
- runtime-слой игры (`GameScene`, flow, scoring, AI runtime),
- UIKit/SpriteKit presentation layer,
- devtools/self-play код,
- unit-тесты и test fixtures.

Приоритеты ниже основаны не только на размере файлов, но и на смешении ответственностей, количестве скрытого состояния и стоимости безопасных изменений.

## Что уже улучшено и не нужно планировать повторно

По сравнению с более ранними черновиками в проекте уже есть заметный прогресс:
- `GameEnvironment` уже вынесен и используется как DI-контейнер для `GameScene`.
- `BotMatchContextBuilder` уже отделён от `GameScene`.
- self-play engine уже разбит на несколько файлов, а не живёт монолитом в одном source file.
- `BotTurnCandidateRankingService` tests уже частично разнесены по тематическим файлам, и для них есть общий fixture.

Ниже только то, что остаётся актуальным после этих улучшений.

## Быстрый срез hot spots

### Самые дорогие точки по размеру и ответственности

| Зона | Файлы | Сигнал |
|---|---|---|
| Игровая сцена | `GameScene.swift` (~1469 LOC), `GameScene+ModalFlow.swift` (~434 LOC) | UI-узлы, runtime state, service caches, modal/navigation, export/statistics plumbing всё ещё переплетены |
| Runtime AI evaluation | `BotTurnCandidateEvaluatorService.swift` (~1518 LOC) | candidate enumeration, belief state, rollout, endgame solving, sampling, RNG и simulation helpers в одном типе |
| Runtime AI ranking | `BotTurnCandidateRankingService.swift` (~1294 LOC), `BotRankingConstants.swift` (~783 LOC) | policy-логика и коэффициенты слишком сконцентрированы, трудно reason about и безопасно тюнить |
| Bidding AI | `BotBiddingService.swift` (~612 LOC), `BotBiddingConstants.swift` (~273 LOC) | blind-risk logic, Monte Carlo и utility policy смешаны |
| Источник правды по счёту | `GameState.swift`, `ScoreManager.swift`, `GameRoundService.swift` | счёт и round result живут сразу в двух моделях |
| Крупные UIKit контроллеры | `DealHistoryViewController.swift` (~502 LOC), `GameParametersViewController.swift` (~428 LOC), `GameStatisticsTableView.swift` (~347 LOC) | presentation, formatting, interaction и export/table logic связаны слишком плотно |
| Devtools simulation | `BotSelfPlayEvolutionEngine+Simulation.swift` (~1469 LOC) | много метрик и симуляционной логики в одном extension |

### Cross-cutting проблемы

1. **Две параллельные конфигурационные системы для AI.**  
   В runtime используются и `BotTuning`, и большие наборы `BotRankingConstants` / `BotBiddingConstants` / `BotHeuristicsConstants`. Это затрудняет понимание, что именно управляет поведением и где корректно менять коэффициенты.

2. **Смешение domain state и presentation state.**  
   Особенно заметно в `GameScene`, где вместе живут SpriteKit nodes, interaction blockers, modal routing, statistics persistence и export.

3. **Двойной источник правды по счёту.**  
   `GameState` мутирует `PlayerInfo.score`, а `ScoreManager` параллельно считает блоки и total scores. Это повышает риск расхождения и усложняет тестирование переходов раунда/блока.

4. **Повторяющийся UIKit chrome.**  
   Во view controllers заметно дублируются panel styles, fonts, buttons, header layout и name normalization.

5. **Высокая стоимость AI-рефакторинга.**  
   Большие сервисы уже покрыты тестами, но локальные правки всё ещё дорогие, потому что границы подсистем внутри этих файлов слабо выражены.

## Приоритетный план изменений

### P1. Сделать `ScoreManager` единственным владельцем счёта

**Статус:** выполнено 2026-03-06

**Реализовано**
- `PlayerInfo` больше не хранит накопленный score.
- `GameState` больше не считает и не накапливает total score при `completeRound()`, а отвечает только за phase/order/bid/trick state.
- Сбор `[RoundResult]` вынесен в общий `GameRoundResultsBuilder` и используется из `GameRoundService` и `GameScene.syncInProgressRoundResultsForScoreTable()`.
- Источником правды по accumulated scores и standings остаётся `ScoreManager`.

**Цель:** убрать дублирование между `GameState` и `ScoreManager`.

**Почему это первый приоритет**
- Сейчас счёт игрока хранится в `PlayerInfo.score`, но итоговая таблица и block progression уже живут в `ScoreManager`.
- `GameRoundService` после `gameState.completeRound()` ещё раз собирает `RoundResult`, что делает flow более хрупким, чем должен быть.

**Что изменить**
- Перестать использовать `PlayerInfo.score` как runtime source of truth.
- Перенести `winner/scoreboard` вычисления в отдельный score snapshot/service слой, работающий от `ScoreManager`.
- Вынести построение `[RoundResult]` в один компонент, который переиспользуется:
  - в `GameRoundService`,
  - в `GameScene.syncInProgressRoundResultsForScoreTable()`,
  - при любых будущих export/statistics сценариях.
- Сделать `GameState` владельцем phase/order/bid/trick state, но не накопленного total score.

**Ожидаемый эффект**
- меньше скрытых инвариантов;
- проще тестировать round/block transitions;
- снижается риск расхождения UI и persisted scores.

**Риск:** средний  
**Проверка:** `GameStateTests`, `ScoreManagerTests`, `GameFlowIntegrationTests`, `GameScenePlayingFlowTests`

### P2. Ужать ответственность `GameScene`

**Статус:** выполнено 2026-03-06

**Реализовано**
- Вынесен `GameSceneSessionState`: pending bids / blind selections, result-presentation flags, export markers и `hasDealtAtLeastOnce` больше не размазаны по `GameScene`.
- Вынесены `GameSceneLayoutResolver` и `GameSceneNodeFactory`: geometry/setup для player seats, action buttons, bid-info/trump overlays и poker table больше не живут как чистые layout calculations прямо в `GameScene`.
- `GameScene+ModalFlow.swift` переведён на `GameSceneModalPresenter`, который инкапсулирует overlay presentation, top-controller lookup и dismiss-to-start-screen navigation.
- Сохранение статистики и deal-history export вынесены в `GameResultsPersistenceCoordinator`.
- Deal history routing из block results вынесен в `DealHistoryPresentationCoordinator`.
- `GameScene` остался orchestration shell: flow по-прежнему живёт в scene/extensions, но UIKit traversal и post-game persistence больше не зашиты прямо в scene-level logic.

**Цель:** оставить `GameScene` в роли orchestration shell, а не контейнера для всего runtime сразу.

**Что видно сейчас**
- В `GameScene.swift` одновременно живут SpriteKit node graph, layout helpers, interaction flags, service caches, score-table sync и блоки экспорта.
- В `GameScene+ModalFlow.swift` вместе собраны modal presentation, navigation до root controller, сохранение статистики и deal history routing.

**Что изменить**
- Вынести session/runtime state в отдельный тип, например `GameSceneSessionState`:
  - presented flags,
  - pending bids / blind selections,
  - export markers,
  - transient deal-flow markers.
- Вынести node/layout setup в отдельные компоненты:
  - `GameSceneNodeFactory` / `GameSceneNodeGraph`,
  - `GameSceneLayoutResolver`.
- Вынести modal/navigation/persistence responsibilities из `GameScene+ModalFlow.swift`:
  - `GameSceneModalPresenter`,
  - `GameResultsPersistenceCoordinator`,
  - `DealHistoryPresentationCoordinator`.
- Убрать прямое знание про `UIWindow` traversal из scene-level logic.

**Ожидаемый эффект**
- `GameScene` станет тоньше;
- тесты будут проверять отдельные сервисы, а не огромную сцену;
- flow-изменения перестанут цеплять UI и persistence одновременно.

**Риск:** средний  
**Проверка:** `AutoPlayFlowTests`, `GameScenePlayingFlowTests`, `GameFlowIntegrationTests`

### P3. Разделить `BotTurnCandidateEvaluatorService` на подсистемы

**Статус:** выполнено 2026-03-06

**Реализовано**
- `BotTurnCandidateEvaluatorService` оставлен тонким фасадом поверх подсистем `BotTurnBeliefStateBuilder`, `BotTurnOpponentOrderResolver`, `BotTurnRolloutService`, `BotTurnEndgameSolver`, `BotTurnSimulationService` и `BotTurnSamplingService`.
- Широкий `DecisionContext` разрезан на `HandContext`, `TableContext` и `RoundContext`, чтобы rollout/endgame/belief-state зависимости читались как отдельные payloads, а не как один монолитный bag of fields.
- Belief-state / opponent-order / simulation / sampling / rollout / endgame код физически вынесен из evaluator-монолита в отдельные source files и подключён в app + `JockerSelfPlayTools`.
- Sampling seeds переведены со стандартного `Hasher` на локальный стабильный deterministic seed builder, чтобы rollout/endgame решения не плавали между процессами и regression tests были воспроизводимыми.

**Цель:** превратить evaluator из монолита в набор узких сервисов с сохранением текущего публичного фасада.

**Что видно сейчас**
- В одном типе сосуществуют:
  - candidate loop,
  - belief state,
  - opponent intention prep,
  - rollout sampling,
  - endgame solving,
  - deterministic RNG,
  - simulated trick/hand helpers.

**Что изменить**
- Оставить `BotTurnCandidateEvaluatorService` фасадом.
- Вынести внутренности в отдельные типы:
  - `BotTurnBeliefStateBuilder`,
  - `BotTurnOpponentOrderResolver`,
  - `BotTurnRolloutService`,
  - `BotTurnEndgameSolver`,
  - `BotTurnSimulationService`,
  - `BotTurnSamplingService`.
- Сжать `DecisionContext` в несколько smaller context objects вместо одного широкого payload.
- Явно отделить deterministic search/simulation utilities от business policy.

**Ожидаемый эффект**
- проще локально менять rollout/endgame части;
- ниже вероятность случайного regress в unrelated heuristics;
- проще расширять и тестировать по подсистемам.

**Риск:** средний  
**Проверка:** `BotTurnCandidateEvaluatorServiceTests`, `BotTurnStrategyServiceTests`, `./scripts/run_stage6b_ranking_guardrails.sh`

### P4. Привести AI policy/config к одной модели

**Статус:** выполнено 2026-03-06

**Реализовано**
- Введён единый runtime policy model `BotRuntimePolicy`, а `BotTuning` теперь стал единственным владельцем как tunable коэффициентов, так и нетюнимых runtime policy groups.
- `BotBiddingService`, `BotTurnCandidateRankingService` и `BotTurnCardHeuristicsService` переведены с `Bot*Constants` на dependency-based policy из `tuning.runtimePolicy`.
- В `BotTuning` добавлен `jokerPolicy` projection, чтобы joker-specific runtime coefficients читались как отдельная policy group, но продолжали опираться на уже существующий `turnStrategy`.
- Старые `BotBiddingConstants` / `BotRankingConstants` / `BotHeuristicsConstants` / `BotMatchContextConstants` удалены из runtime target, а policy baseline теперь задаётся в одном месте с difficulty-specific overrides.

**Цель:** убрать ситуацию, где tuning и policy constants живут в разных системах.

**Что видно сейчас**
- Поведение бота определяется одновременно через:
  - `BotTuning`,
  - `BotRankingConstants`,
  - `BotBiddingConstants`,
  - `BotMatchContextConstants`,
  - `BotHeuristicsConstants`.
- Это делает сложными:
  - тюнинг по difficulty,
  - поиск причин регресса,
  - перенос коэффициентов в self-play/evolution flows.

**Что изменить**
- Свести runtime AI config к одному владельцу:
  - либо расширить `BotTuning`,
  - либо ввести `BotDecisionPolicy` / `BotRuntimePolicy`.
- Разбить коэффициенты на typed группы:
  - ranking,
  - bidding,
  - heuristics,
  - opponent modeling,
  - joker policy.
- Убрать глобальные `static let` там, где значения должны быть частью policy dependency.
- Зафиксировать default baseline и отдельно наслоить difficulty-specific overrides.

**Ожидаемый эффект**
- tuning станет прозрачнее;
- self-play будет проще использовать для изменения реально активных runtime коэффициентов;
- уменьшится количество "магических" изменений в нескольких файлах сразу.

**Риск:** средний  
**Проверка:** `BotTuningTests`, `BotBiddingServiceTests`, все `BotTurnCandidateRankingServiceTests_*`, baseline/self-play smoke

### P5. Разделить `BotTurnCandidateRankingService` на utility calculators

**Статус:** выполнено 2026-03-06

**Реализовано**
- `BotTurnCandidateRankingService` оставлен thin facade: в нём остались только context-модели, DI helper-ов, thin `moveUtility(...)` orchestration и делегирование tie-break в отдельную policy.
- Block/premium/opponent/joker ветви ranking вынесены в `BlockPlanResolver`, `PremiumPreserveAdjuster`, `PenaltyAvoidAdjuster`, `PremiumDenyAdjuster`, `OpponentPressureAdjuster` и `JokerDeclarationAdjuster`.
- Финальная композиция utility вынесена в `MoveUtilityComposer`, а deterministic candidate comparison изолирован в `CandidateTieBreakPolicy`.
- Новые ranking helper-ы подключены в app target и `JockerSelfPlayTools`, а структура зафиксирована в `FOLDER_STRUCTURE_SPEC.md`.

**Цель:** разнести policy-ветви ranking-сервиса по отдельным сущностям.

**Почему это отдельно от P4**
- P4 про конфигурационную поверхность.
- P5 про структуру самих вычислений.

**Что изменить**
- Вынести в отдельные типы/модули:
  - `BlockPlanResolver`,
  - `PremiumPreserveAdjuster`,
  - `PenaltyAvoidAdjuster`,
  - `PremiumDenyAdjuster`,
  - `OpponentPressureAdjuster`,
  - `JokerDeclarationAdjuster`,
  - `MoveUtilityComposer`.
- Сохранить текущий `moveUtility(...)` как тонкий orchestration layer.
- Для tie-break logic оставить отдельный isolated policy object.

**Ожидаемый эффект**
- ranking logic станет ревьюиться кусками, а не монолитом;
- легче будет вносить stage-specific AI improvements без роста файла до 1500+ строк;
- unit tests станут точнее и короче.

**Риск:** средний  
**Проверка:** все `BotTurnCandidateRankingServiceTests_*`, `BotTurnCandidateEvaluatorServiceTests`

### P6. Выделить blind bidding policy из `BotBiddingService`

**Статус:** выполнено 2026-03-06

**Цель:** отделить обычный bid selection от pre-deal blind risk engine.

**Что видно сейчас**
- В `BotBiddingService` смешаны:
  - обычный post-deal bid selection,
  - pre-deal blind risk scoring,
  - blind Monte Carlo,
  - RNG/sampling helpers.

**Что изменить**
- Разделить минимум на:
  - `BotBidSelectionService`,
  - `BotBlindBidPolicy`,
  - `BotBlindBidMonteCarloEstimator`.
- Привести конфигурацию blind policy к тем же принципам, что и остальные AI policy types.
- Подготовить более узкие test fixtures для blind-only сценариев.

**Ожидаемый эффект**
- изменения blind policy перестанут затрагивать обычные ставки;
- проще развивать 4-й блок отдельно от обычных bidding rules.

**Реализовано**
- `BotBiddingService` сокращён до thin facade, который делегирует обычные ставки в `BotBidSelectionService`, а pre-deal blind decisions в `BotBlindBidPolicy`.
- Blind risk scoring и target-share/floor logic вынесены в `BotBlindBidPolicy`, а deterministic blind Monte Carlo sampling и utility ranking в `BotBlindBidMonteCarloEstimator`.
- Blind runtime config приведён к typed policy groups через `tuning.runtimePolicy.bidding.bidSelection`, `blindPolicy` и `blindMonteCarlo`; нормализация `riskBudget` больше не зашита отдельной магической константой внутри сервисов.
- Добавлены узкие blind-only test artifacts: `BotBlindBidPolicyTestFixture` и `BotBlindBidPolicyTests`.

**Риск:** средний  
**Проверка:** `BotBiddingServiceTests`, blind-related regression scenarios

### P7. Вынести общий UIKit panel/chrome слой

**Статус:** выполнено 2026-03-06

**Реализовано**
- Добавлен общий presentation kit для UIKit panel screens: `PanelAppearance`, `PanelTypography`, `PanelContainerView`, `PanelHeaderView`, `PrimaryPanelButton`, `SecondaryPanelButton`.
- На общий chrome переведены `GameParametersViewController`, `DealHistoryViewController`, `GameResultsViewController`, `GameStatisticsViewController`, `FirstPlayerAnnouncementViewController`, `TrumpSelectionViewController`, `JokerModeSelectionViewController` и bidding modals через `BidSelectionModalBaseViewController`.
- Централизован player-name display formatting в `PlayerDisplayNameFormatter`, после чего одинаковая trim/fallback логика убрана из controllers, `GameState`, `GamePlayersSettings`, `GameFinalPlayerSummary`, `DealHistoryExportService`, `ScoreTableLabelManager` и `GameStatisticsTableView`.

**Цель:** убрать копипасту panel setup и сделать presentation code дешевле в сопровождении.

**Что видно сейчас**
- Похожие background colors, border styles, button styles, fonts и header layouts повторяются в:
  - `GameParametersViewController`,
  - `DealHistoryViewController`,
  - `GameResultsViewController`,
  - `GameStatisticsViewController`,
  - bidding modals.

**Что изменить**
- Ввести общий presentation kit для overlay/panel screens:
  - `PanelAppearance`,
  - `PanelContainerView`,
  - `PanelHeaderView`,
  - `PrimaryPanelButton`,
  - `SecondaryPanelButton`.
- Вынести repeatable typography helpers.
- Централизовать name normalization / player display formatting, чтобы это не копировалось по нескольким контроллерам.

**Ожидаемый эффект**
- меньше UI-дублирования;
- правки визуального языка будут точечными;
- новые modal screens станут дешевле.

**Риск:** низкий-средний  
**Проверка:** ручной smoke-test экранов и targeted UI tests, если есть

### P8. Упростить крупные UIViewController'ы через presentation builders

**Статус:** выполнено 2026-03-06

**Реализовано**
- Для `DealHistoryViewController` вынесены `DealHistoryPresentationBuilder` и `DealHistoryExportCoordinator`: секции/rows и export/share flow больше не живут в контроллере.
- Для статистики вынесен `GameStatisticsPresentationProvider`: метрики, seat normalization и number formatting строятся вне `GameStatisticsTableView`, а `GameStatisticsViewController` больше не подготавливает строки вручную.
- Для параметров игры добавлен `PlayerSettingsRowView`, а `GameParametersViewController` переведён на explicit difficulty handlers без tag-based parsing.
- Добавлены unit tests для `DealHistoryPresentationBuilder` и `GameStatisticsPresentationProvider`; обновлены `GameStatisticsTableViewTests`.

**Цель:** убрать из контроллеров форматирование данных и тяжёлую table-building логику.

**Что изменить**
- Для `DealHistoryViewController`:
  - вынести section/row preparation в `DealHistoryPresentationBuilder`,
  - вынести export flow в `DealHistoryExportCoordinator`.
- Для `GameStatisticsTableView`:
  - строить row view models вне UIView,
  - вынести number formatting и metric definitions в отдельный provider.
- Для `GameParametersViewController`:
  - выделить `PlayerSettingsRowView` / row factory,
  - убрать tag-based parsing там, где можно использовать explicit handlers/models.

**Ожидаемый эффект**
- view controllers станут ближе к display/input shell;
- форматирование будет unit-testable;
- проще локально менять table contents без пересборки layout кода.

**Риск:** низкий-средний  
**Проверка:** unit tests для presentation builders + ручной smoke test экранов

### P9. Дочистить devtools/self-play simulation

**Цель:** уменьшить стоимость изменений в training/devtools коде без приоритета выше runtime.

**Что изменить**
- Разбить `BotSelfPlayEvolutionEngine+Simulation.swift` на более узкие части:
  - metrics accumulator,
  - blind exposure tracking,
  - round evaluation,
  - debug payloads,
  - seat service bundle / orchestration.
- Убедиться, что devtools code продолжает зависеть от тех же typed policy objects, что и runtime.

**Ожидаемый эффект**
- проще менять self-play метрики и симуляционные правила;
- легче синхронизировать runtime AI и training surface.

**Риск:** средний  
**Проверка:** self-play smoke, targeted evolution tests

### P10. Унифицировать AI test builders

**Цель:** снизить стоимость рефакторинга AI сервисов.

**Что уже сделано**
- ranking tests уже имеют хороший fixture layer.

**Что ещё осталось**
- Подобный builder/factory слой нужен и для:
  - evaluator tests,
  - strategy tests,
  - bidding tests,
  - context builder tests.
- Нужен общий набор deterministic helpers:
  - `TrickNode` builder без render-side effects,
  - `BotMatchContext` builder,
  - `BotTurnDecisionContext` builder,
  - hand/trump/dealer preset factories.

**Ожидаемый эффект**
- AI refactoring можно будет делать с меньшим объёмом механических правок в тестах;
- новые сценарии станут компактнее и понятнее.

**Риск:** низкий  
**Проверка:** все существующие AI unit tests

## Рекомендуемая последовательность PR'ов

### Волна 1. Foundation

1. P1: один источник правды по счёту (выполнено 2026-03-06)  
2. P2: вынос session state и modal/persistence responsibilities из `GameScene`

### Волна 2. Runtime AI boundaries

3. P3: декомпозиция evaluator  
4. P5: декомпозиция ranking service  
5. P6: разделение blind bidding policy

### Волна 3. Policy cleanup

6. P4: единая модель AI configuration/policy

### Волна 4. Presentation + devtools + tests

7. P7: общий UIKit panel/chrome слой (выполнено 2026-03-06)
8. P8: presentation builders для крупных контроллеров (выполнено 2026-03-06)
9. P9: self-play simulation cleanup  
10. P10: общий AI test fixture layer

## Что не стоит делать сейчас

- Не переписывать проект целиком на SwiftUI ради архитектурной чистоты. Это не соответствует текущей структуре SpriteKit/UIKit приложения и резко увеличит риск.
- Не выносить всё в отдельные модули/пакеты до очистки внутренних границ. Иначе переедет существующая путаница, а не решится.
- Не менять AI коэффициенты "по пути" во время структурного рефакторинга. Сначала структура и контракты, потом тюнинг.

## Инварианты рефакторинга

- Каждый PR должен сохранять поведение.
- Сначала extract/move/rename, потом логические улучшения.
- Для AI и flow изменений сохранять детерминированность там, где она уже используется в тестах.
- Для новых типов соблюдать правило репозитория: один основной type на файл.

## Минимальная матрица проверки после каждого этапа

### Для scoring / flow

- `GameStateTests`
- `ScoreManagerTests`
- `GameFlowIntegrationTests`
- `GameScenePlayingFlowTests`
- `AutoPlayFlowTests`

### Для AI runtime

- `BotTurnStrategyServiceTests`
- `BotTurnCandidateEvaluatorServiceTests`
- все `BotTurnCandidateRankingServiceTests_*`
- `BotBiddingServiceTests`
- `BotMatchContextBuilderTests`

### Для regression-паков

- `./scripts/run_joker_regression_pack.sh`
- `./scripts/run_stage6b_ranking_guardrails.sh`

### Для devtools/self-play изменений

- соответствующие self-play tests/smoke scenarios
- baseline smoke при изменении policy surface

## Критерий успеха

План можно считать выполненным, когда:
- у `GameScene` не останется лишней инфраструктурной ответственности;
- счёт будет жить в одном месте;
- runtime AI будет состоять из небольших policy/simulation компонентов вместо 1-2 больших файлов;
- AI coefficients будут иметь единый и прозрачный ownership;
- крупные UIKit контроллеры станут display-shell поверх presentation builders;
- тесты будут поддерживать эти изменения без лавины механических правок.
