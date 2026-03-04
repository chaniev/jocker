# Рефакторинг: проблемы кодовой базы и предложения

**Дата:** 2026-03-04  
**Статус:** Черновик (без изменения поведения)

Цель документа: зафиксировать основные “структурные” проблемы в текущем коде и собрать предложения по рефакторингу, которые улучшают читаемость, тестируемость и скорость итераций без изменения gameplay-логики.

---

## Быстрый срез (что бросается в глаза)

### 1) “God files” (слишком большие файлы/ответственности)

Топ по размеру (LOC, приблизительно):
- `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine.swift` (~3413) — эволюция + симуляция + метрики + фитнес + раннер-утилиты.
- `Jocker/Jocker/Game/Scenes/GameScene.swift` (~1526) — UI/лейаут + flow + построение bot-context + persistence/export.
- `Jocker/JockerTests/Bot/BotTurnCandidateRankingServiceTests.swift` (~3420) — слишком много сценариев в одном файле.
- Также заметно крупные: `BotTurnCandidateRankingService.swift` (~768), `BotTurnCardHeuristicsService.swift` (~391), `BotTurnCandidateEvaluatorService.swift` (~360).

Риск: такие файлы сложно ревьюить, трудно “безопасно” менять локально, растёт стоимость тестов/поиска регрессий.

### 2) Смешение уровней (UI + доменная логика + инфраструктура)

`GameScene` одновременно:
- держит кучу UI-нод и layout-констант,
- оркестрирует игровые потоки (dealing/bidding/playing),
- строит контекст для ботов (`BotMatchContext` + opponent snapshots),
- управляет stores (`UserDefaultsGameStatisticsStore`, `DealHistoryStore`, экспорт).

Риск: высокая связность, много изменяемого состояния, больше вероятности “невозможных” состояний и редких багов на стыках flow.

### 3) Слабая “контрактность” контекстов (много параметров вместо структур)

Есть места, где API уже умеет принимать context (`BotTurnStrategyService.BotTurnDecisionContext`), но по проекту всё ещё встречаются методы с длинными списками параметров (особенно вокруг flow/координатора/сервисов).

Риск: сложно расширять без поломок сигнатур, легко передать несогласованные значения.

### 4) Большие тестовые файлы и дублирующие фикстуры

`BotTurnCandidateRankingServiceTests` огромный и, вероятно, повторяет паттерны “собери TrickNode + hand + context” много раз.

Риск: сложно поддерживать, сложнее понять “какие кейсы реально важны”, растёт время на добавление новых тестов.

### 5) Training/self-play код в app target

Self-play эволюция и тренинг-метрики лежат в `Jocker/Jocker/...` и потенциально компилируются вместе с приложением.

Риск: рост времени компиляции и размера кода приложения, сложнее проводить рефактор без влияния на runtime.

---

## Основные проблемы (формулировки)

1. **Ответственности размазаны**: один файл/класс часто отвечает за несколько слоёв (UI, flow, домен, инфраструктура).
2. **Слабая модульность**: логика внутри крупных файлов не декомпозирована на явно именованные компоненты/подсистемы.
3. **Сложность изменения без регресса**: изменение в “центральном” файле почти всегда затрагивает несколько аспектов сразу.
4. **Тесты трудно масштабировать**: большие test suites хуже читаются и сложнее расширяются.
5. **Скрытые зависимости**: `lazy` карты сервисов/тюнингов внутри `GameScene` затрудняют переиспользование/тестирование и скрывают lifecycle.

---

## Предложения по рефакторингу (backlog)

Ниже инициативы “без изменения поведения”, отсортированы примерно по ROI (impact/effort).

### R1. Декомпозиция `BotSelfPlayEvolutionEngine` на файлы по подсистемам

Цель: снизить когнитивную нагрузку и ускорить ревью/изменения.

Что сделать:
- Вынести вложенные типы в отдельные файлы в той же папке (или под-папку `AI/SelfPlay/`), например:
  - `BotSelfPlayEvolutionEngine+Config.swift` (SelfPlayEvolutionConfig, clamp/validation)
  - `BotSelfPlayEvolutionEngine+Genome.swift` (EvolutionGenome, mutation/crossover)
  - `BotSelfPlayEvolutionEngine+Simulation.swift` (playRound, makeBids, finalizeBlockScores)
  - `BotSelfPlayEvolutionEngine+Metrics.swift` (FitnessAccumulator, SimulationMetricsAccumulator, breakdown structs)
  - `BotSelfPlayEvolutionEngine+Fitness.swift` (FitnessScoringConfig, fitness aggregation)
- Сохранить публичный API в `BotSelfPlayEvolutionEngine.swift`, оставить там только фасад + “routing”.

Риск: низкий (рефакторинг по файлам), если не менять логику/порядок вычислений.

### R2. Вытащить сбор контекста бота из `GameScene` в отдельный builder

Цель: отделить “интеграцию” (GameState/ScoreManager -> BotMatchContext/BotOpponentModel) от UI.

Что сделать:
- Новый pure/тестируемый компонент, например `BotMatchContextBuilder`:
  - вход: `GameState`, `ScoreManager`, `playerIndex`, `playerCount`
  - выход: `BotMatchContext`
- В `GameScene` оставить только вызов builder + plumbing.

Плюс: можно покрыть unit-тестами edge cases (неполные scores, indices, block progress).

### R3. Единый `GameEnvironment`/DI контейнер для `GameScene`

Цель: убрать из `GameScene` создание инфраструктуры и сделать зависимости явными.

Что сделать:
- Создать структуру `GameEnvironment` (stores, export services, factories).
- Передавать её в `GameScene` на этапе создания (или устанавливать до `didMove`), вместо того чтобы хранить `UserDefaultsGameStatisticsStore()` внутри `GameScene`.

Плюс: проще писать интеграционные тесты без UserDefaults/файлов.

### R4. Ужать публичную поверхность `GameScene` (access control)

Цель: уменьшить случайные зависимости и упростить reasoning про состояние.

Что сделать:
- Проставить `private`/`private(set)`/`fileprivate` для UI-нод/служебных флагов, которые не должны читаться/писаться извне.
- Явно разделить “конфиг входа” (playerCount/names/controlTypes/difficulties) и “runtime state”.

### R5. Стандартизировать context-объекты в flow/координаторе

Цель: уменьшить списки параметров и сделать расширение безопаснее.

Что сделать:
- Для `GameTurnService`/`GameSceneCoordinator` использовать `BotTurnDecisionContext` как первичный API, а “плоские” перегрузки оставить только как thin wrapper.
- Аналогично для модальных запросов (bid/trump/blind): вместо длинных списков полей — структуры `BidChoiceContext`, `TrumpChoiceContext`, `BlindChoiceContext`.

### R6. Разбить `BotTurnCandidateRankingServiceTests` по категориям

Цель: сделать тесты читабельнее и проще поддерживать.

Что сделать:
- Разнести по файлам:
  - `BotTurnCandidateRankingServiceTests_TieBreak.swift`
  - `..._Blind.swift`
  - `..._PremiumPenalty.swift`
  - `..._JokerDeclaration.swift`
  - `..._PhaseThreat.swift`
- Ввести общий `TestFixture`/builders:
  - быстрый `TrickNode(rendersCards: false)` по умолчанию,
  - фабрики `makeContext(...)`, `makeHand(...)`, `play(...)`.

### R7. Вынести UI-билдеры модалок из `GameScene+ModalFlow`

Цель: уменьшить UI-код внутри сцены и сделать модалки переиспользуемыми/тестируемыми.

Что сделать:
- `makeFirstPlayerAnnouncementModal` и похожие большие блоки UI переносить в отдельные `UIViewController` классы (каждый в свой файл).
- Либо завести “ModalFactory” с общими стилями (цвета/шрифты/constraints).

### R8. Отделить training/self-play от runtime модуля приложения

Цель: уменьшить вес app target и снизить связность.

Варианты:
- Вынести self-play в отдельный target (например, `JockerDevTools`) или Swift Package внутри репо.
- Либо закрыть компиляцию в app через `#if DEBUG`/feature-flag (если допустимо).

Риск: средний (структурные изменения проекта), но долгосрочно окупается.

---

## Рекомендуемый порядок (если делать постепенно)

1. R1 (разбиение SelfPlay engine) + R6 (реорганизация тестов): самые безопасные, дают быстрый выигрыш в поддерживаемости.
2. R2 + R5: укрепляют контракты между flow и AI, уменьшают “параметрический шум”.
3. R3 + R4 + R7: приводят `GameScene` к роли UI/оркестратора, меньше скрытых зависимостей.
4. R8: отдельным PR, после стабилизации.

---

## Инварианты рефакторинга (чтобы не сломать поведение)

- Рефакторить “по слоям”: сначала файлы/типы/доступ, затем улучшения архитектуры.
- После каждого PR прогонять минимум:
  - `xcodebuild build-for-testing`
  - `./scripts/run_joker_regression_pack.sh`
  - `./scripts/run_stage6b_ranking_guardrails.sh --include-flow-plumbing` (если изменения касаются flow/AI).

