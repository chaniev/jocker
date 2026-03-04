# Предложения по улучшению AI ботов (Unified)

**Дата:** 2026-03-04  
**Статус:** Черновик для обсуждения  
**Версия:** 3.0 (unified: consolidated + mapped)

Документ объединяет лучшее из:
- `BOT_AI_IMPROVEMENT_PROPOSALS_MAPPED.md` (runtime gaps taxonomy, mapping, определения метрик, уточнения формулировок).
- `BOT_AI_IMPROVEMENT_PROPOSALS_CONSOLIDATED.md` (полный консолидированный backlog, приоритизация P0–P4, дорожная карта, зависимости/риски/тесты).

Цель: иметь один “мастер”-бэклог инициатив с:
- явной моделью текущих проблем (runtime gaps),
- понятной приоритизацией и зависимостями,
- измеримостью (метрики с определениями),
- минимальными gate-тестами для безопасной итерации.

---

## Словарь (метрики и как их понимать)

Опорное правило: метрики должны быть измеримы через self-play harness и сравнимы между запусками при фиксированных seed и профилях (`make bot-baseline` / `make bot-compare`).

### Матчевые метрики (ядро качества)

- `winRate`: среднее `winShare` по симуляциям; в одной игре `winShare = 1 / winnersCount`, если бот набрал максимальный total score (иначе `0`).
- `averageScoreDiff`: среднее `(botTotalScore - opponentsAverageTotalScore)` по симуляциям.
- `averageUnderbidLoss`: средний штраф за систематический недозаказ (self-play penalty).
- `averagePremiumAssistLoss`: средний штраф за “подаренные премии”, когда бот сам премию не взял, а другие взяли (структурный + пропорциональный gain).
- `averagePremiumPenaltyTargetLoss`: средняя сумма штрафов, назначенных боту как penalty target за премию соперника (по правилам премий).

### Операционные метрики (поведенческие “датчики”)

- `premiumCaptureRate`: доля блоков, где игрок взял премию (regular/zero).
- `penaltyTargetRate`: доля блоков, где игрок стал penalty target.
- `blindSuccessRate`: `successfulBlindRounds / totalBlindRounds`, где успех = `bidMatched` в blind-раундах.
- `jokerWishWinRate`: `wishWins / totalWishLeads` (если `totalWishLeads = 0`, harness репортит `0`).
- `earlyJokerSpendRate`: доля розыгрышей джокера “не в последней взятке” среди всех сыгранных джокеров.
- `bidAccuracyRate`: доля раундов с `bidMatched`.
- `overbidRate`: доля раундов, где `tricksTaken > bid`.
- `blindBidRateBlock4`: доля раздач 4-го блока, где выбран blind.
- `averageBlindBidSize`: средний размер blind-ставки среди blind-раундов.
- `blindBidWhenBehindRate`: доля случаев выбора blind, когда игрок “позади” по матчевому сигналу (по логике harness).
- `blindBidWhenLeadingRate`: доля случаев выбора blind, когда игрок “впереди” по матчевому сигналу (по логике harness).
- `earlyLeadWishJokerRate`: частота “lead face-up joker + wish” не в последней взятке.
- `leftNeighborPremiumAssistRate`: доля премий соседа слева, в которых игрок был “ассистентом” (по определению harness).

Примечание: для всех rate-метрик “0” может означать “не было попыток” (деление на 0 в harness обычно даёт 0). Для постановки целей полезно фиксировать рядом счётчики событий (attempt counts).

### Дополнительные/будущие метрики (потребуют инструментирования)

- `endgameAccuracy` (предложение): `bidAccuracyRate` на подмножестве раундов с `cardsInRound <= 3`. Сейчас в harness считаются только агрегаты по всем раундам; для этой метрики нужен раздельный учёт по диапазонам `cardsInRound`.

---

## Runtime gaps taxonomy (RG-1 … RG-8)

Таксономия “дыр” текущего runtime-алгоритма. Каждая инициатива в backlog должна явно закрывать один или несколько gaps.

- `RG-1` Legal-aware win probability: оценка “удержим ли взятку” недостаточно учитывает легальность ответов соперников (обязаловка масти/козыря).
- `RG-2` Belief state: нет формализованного состояния скрытой информации (void suits, вероятности распределений); есть только “unseen cards” и агрегаты.
- `RG-3` Goals/intent: нет явного учёта целей других игроков (их заказы/дефициты/стратегия) в utility, кроме частичных premium/penalty сигналов.
- `RG-4` Lookahead: решения в основном myopic; нет rollout/endgame решателя для top-N кандидатов.
- `RG-5` Consistency: bidding/projection/turn не разделяют единую модель силы руки и ожиданий.
- `RG-6` Utility composition: утилита преимущественно аддитивна; взаимодействия факторов (risk/urgency/joker) выражены неявно и плохо контролируются.
- `RG-7` Blind EV: выбор blind по сути без оценки распределения/EV (нет симуляции/интеграла по “скрытым” рукам).
- `RG-8` Threat context: threat учитывает фазу, но слабо учитывает позицию в взятке и “что уже вышло” (контекст сыгранных карт).

---

## Backlog инициатив (13 шт.)

Состав: 8 инициатив из `BOT_AI_IMPROVEMENT_PROPOSALS.md` + 5 инициатив из `BOT_AI_RUNTIME_ALGORITHM_ANALYSIS.md`.

| ID | Инициатива | Приоритет | Runtime gaps | Оценка |
|---|------------|-----------|--------------|--------|
| P0-1 | Belief state + legal-aware win probability | P0 | `RG-1`, `RG-2` | 12-16 ч |
| P0-2 | Block-level planning | P0 | `RG-3`, `RG-6` | 4-6 ч |
| P1-1 | Opponent intention modeling | P1 | `RG-1`, `RG-2`, `RG-3` | 12-16 ч |
| P1-2 | Opponent bid/deficit pressure in utility | P1 | `RG-3`, `RG-6` | 6-10 ч |
| P1-3 | Rollout для top-N кандидатов | P1 | `RG-4`, `RG-2` | 12-16 ч |
| P2-1 | Composite utility model | P2 | `RG-6` | 8-12 ч |
| P2-2 | Goal-oriented joker declaration | P2 | `RG-4`, `RG-6` | 16-20 ч |
| P2-3 | Эндгейм-решатель | P2 | `RG-4` | 8-12 ч |
| P3-1 | Monte-Carlo blind evaluation | P3 | `RG-7`, `RG-2` | 6-8 ч |
| P3-2 | Context-aware card threat | P3 | `RG-8` | 4-6 ч |
| P3-3 | Единый HandStrength model (bidding+projection) | P3 | `RG-5` | 6-8 ч |
| P4-1 | Multi-factor trump selection | P4 | `RG-5` | 3-4 ч |
| P4-2 | Forbidden-aware bidding | P4 | `RG-5` | 2-3 ч |

---

## Детализация инициатив

### P0-1. Belief state + legal-aware win probability

**Runtime gaps:** `RG-1`, `RG-2`

Проблема: `estimateImmediateWinProbability` сейчас предполагает, что соперник может ответить любой unseen-картой (и “перебить”), что системно смещает вероятность и ломает utility в ключевых местах.

MVP-решение:
- ввести “легковесный” belief state, минимум: `voidSuits` (если игрок не поддержал масть — вероятно void);
- заменить “beaterRatio по всем unseen” на оценку по *легальным* ответам соперников (Monte Carlo 20–50 семплов распределений unseen по игрокам);
- оставить fallback на legacy-оценку (если belief state недоступен или budget ограничен).

Integration touchpoints:
- `BotTurnCardHeuristicsService` (вероятность/оценка перебития),
- `BotTurnCandidateEvaluatorService` (передача контекста игроков/семплинг budget),
- (опционально) новый сервис `BotBeliefStateService`.

Минимальные тесты/гейты:
- Unit: infer void suit по сценарию “не ответил в масть”,
- Unit: legal-aware probability monotonicity (если у всех соперников void leadSuit, вероятность удержания должна расти),
- Regression: joker-pack + stage6b-pack-all + compare-v1.

Риски:
- производительность (семплинг): mitigation через conditional-apply (только endgame/joker/high-urgency) и ограничение итераций.

---

### P0-2. Block-level planning

**Runtime gaps:** `RG-3`, `RG-6`

Проблема: без плана на блок бот принимает решения myopic и “выигрывает взятку ради взятки”, не оптимизируя траекторию премий/штрафов и риск в конце блока.

MVP-решение:
- построить `BlockPlan` на основе `BotMatchContext` (remainingRounds, premium-candidate flags, match risk);
- влиять на utility через понятные коэффициенты/мультипликаторы (risk budget, urgency).

Integration touchpoints:
- `BotTurnCandidateRankingService` (utility adjustment),
- `BotMatchContext` (уже есть нужные поля).

Минимальные тесты/гейты:
- Unit: plan creation invariants (remainingRounds, urgency weights),
- Regression: premium/penalty guardrails packs + compare-v1.

---

### P1-1. Opponent intention modeling

**Runtime gaps:** `RG-1`, `RG-2`, `RG-3`

Проблема: текущая модель соперников в основном “rates-only”; нет предсказания намерения в конкретной взятке/раунде, из-за чего бот часто “помогает” чужому exact-bid или премии.

MVP-решение:
- объединить: (1) belief-state сигналы (void/trump likelihood) + (2) bid-state соперника (needs/over/under) + (3) текущая взятка (позиция/lead suit);
- выдавать компактный `OpponentIntentionModel`, используемый в utility как adjustment (не заменять всю систему).

Integration touchpoints:
- `BotOpponentModel` (как источник “rates”),
- `BotMatchContext`/новый round-context (bids/tricks оппонентов),
- `BotTurnCandidateRankingService` (utility adjustment).

Минимальные тесты/гейты:
- Unit: no-evidence neutrality (при отсутствии evidence adjustment должен быть ~0),
- Regression: stage6b-pack-all (style-shift, neutrality) + compare-v1.

---

### P1-2. Opponent bid/deficit pressure in utility

**Runtime gaps:** `RG-3`, `RG-6`

Проблема: даже без full “intention modeling” боту полезно понимать, кто из соперников близок к exact-bid и как это влияет на ценность конкретной взятки/хода.

MVP-решение:
- протянуть в decision-context минимальный round-state: `bids[]`, `tricksTaken[]` для всех игроков;
- добавить utility adjustment “deny exact”:
  - повышать ценность взятки/контроля, если следующий/левый сосед “needsTricks == 1”;
  - в dump-режиме избегать “безопасных” ходов, которые отдают взятку игроку, который ровно добирает.

Integration touchpoints:
- Flow plumbing: `GameState`/`GameTurnService` -> `BotTurnStrategyService.BotTurnDecisionContext`,
- `BotTurnCandidateRankingService`.

Минимальные тесты/гейты:
- Unit: сценарий “opponent needs 1 trick” (utility shift в нужную сторону),
- Regression: compare-v1 + существующие premium/penalty packs.

---

### P1-3. Rollout для top-N кандидатов

**Runtime gaps:** `RG-4`, `RG-2`

Проблема: в джокере/эндгейме локальные эвристики часто ошибаются; нужен limited lookahead, но только там, где это окупается.

MVP-решение:
- после базового скоринга взять top 2–3 кандидата и досимулировать 1–2 взятки вперёд;
- семплинг скрытых рук оппонентов делать из belief-state (если есть) или через simple unseen split.

Условия применения:
- `handSize <= 4`,
- или ход с джокером,
- или high-urgency (конец блока / критический дефицит взяток).

Риски:
- perf + детерминизм; mitigation через фиксированный seed/PRNG и жёсткий лимит итераций.

---

### P2-1. Composite utility model

**Runtime gaps:** `RG-6`

Проблема: аддитивная утилита плохо отражает взаимодействия факторов (risk/urgency/joker), сложно контролировать масштаб и избежать “побочных побед”.

MVP-решение:
- ввести структуру, где есть:
  - базовая ценность (score / chase-dump),
  - риск-мультипликатор (premium/penalty),
  - urgency-bias,
  - joker-modifier,
  - и строгие ограничения диапазонов, чтобы не раздувать utility.

Не цель (на MVP): переписать все текущие компоненты utility; достаточно “обёртки” для более контролируемой композиции.

---

### P2-2. Goal-oriented joker declaration

**Runtime gaps:** `RG-4`, `RG-6`

Проблема: выбор `wish/above/takes` сейчас в основном “эвристика коэффициентов”, а не оптимизация цели (контроль/denial/controlled loss).

MVP-решение:
- для lead-joker деклараций явным образом оценивать 2–3 цели:
  - `secureTrick` (забрать/удержать),
  - `preserveControl` (удержать управление под будущие взятки),
  - `controlledLoss` (безопасно отдать при dump/penalty-risk),
- подкрепить спорные случаи rollout-оценкой (P1-3).

---

### P2-3. Эндгейм-решатель

**Runtime gaps:** `RG-4`

Проблема: при 1–3 картах на руке можно почти точно оценить последствия; текущая эвристика даёт непропорционально много ошибок именно в конце.

MVP-решение:
- включать решатель только при `handSize <= 3`;
- семплировать скрытые карты оппонентов (если нужно) и выбирать ход по среднему исходу;
- ограничить глубину (до конца раунда) и budget.

---

### P3-1. Monte-Carlo blind evaluation

**Runtime gaps:** `RG-7`, `RG-2`

Проблема: blind-ставка выбирается без оценки распределения/EV; нужен вероятностный слой хотя бы для “стоит ли рисковать” и “какой размер”.

MVP-решение:
- Monte Carlo на прераздаче: оценить распределение `expectedTricks` и выбрать blind bid по ожидаемой полезности (score/variance/risk budget).

---

### P3-2. Context-aware card threat

**Runtime gaps:** `RG-8`

Проблема: threat уже учитывает фазу, но почти не учитывает позицию в взятке и контекст сыгранных карт (сколько старших уже вышло, насколько карта всё ещё “ресурс”).

MVP-решение:
- модификатор threat по позиции (lead/second/third/last),
- модификатор по “вышли ли старшие” (простая оценка на основе сыгранных карт в взятке/раунде),
- не ломать базовую шкалу threat; использовать небольшие коэффициенты.

---

### P3-3. Единый HandStrength model (bidding + projection)

**Runtime gaps:** `RG-5`

Проблема: `BotBiddingService` и `BotTurnRoundProjectionService` используют разные формулы; это создаёт несогласованное поведение “заказал одно — играет в другое”.

MVP-решение:
- вынести оценку силы руки в один pure-модуль,
- использовать его и в bidding, и в projection (возможно, с разными “режимами”).

---

### P4-1. Multi-factor trump selection

**Runtime gaps:** `RG-5`

Проблема: выбор козыря основан на упрощённой оценке; можно улучшить консистентность с hand-strength моделью.

MVP-решение:
- добавить факторы “длина/плотность масти”, “последовательность рангов”, “джокер-синергия”,
- но не усложнять раньше, чем появится единый HandStrength.

---

### P4-2. Forbidden-aware bidding

**Runtime gaps:** `RG-5`

Проблема: при `forbiddenBid` бот просто пропускает значение, не оценивая стоимость отклонения от оптимума.

MVP-решение:
- оценивать “цена отклонения” и выбирать ближайший по utility bid, а не только по projected score.

---

## Зависимости (высокий уровень)

```mermaid
flowchart LR
  Belief[P0-1 Belief state] --> Intention[P1-1 Opponent intention]
  Belief --> Rollout[P1-3 Rollout]
  Rollout --> Joker[P2-2 Goal-oriented joker]
  Rollout --> Endgame[P2-3 Endgame solver]
  Hand[P3-3 HandStrength] --> Trump[P4-1 Trump selection]
  Hand --> Bid[P4-2 Forbidden-aware bidding]
  Block[P0-2 Block planning] --> Utility[P2-1 Composite utility]
```

---

## Дорожная карта (ориентир)

Фаза 1 (P0, “фундамент”):
- P0-1 Belief + legal-aware probability
- P0-2 Block planning
- Gates: build-for-testing + joker-pack + stage6b-pack-all + compare-v1

Фаза 2 (P1, “opponent awareness + lookahead”):
- P1-2 Opponent bid/deficit pressure (как быстрый win для RG-3)
- P1-1 Opponent intention (если P0-1 уже даёт belief state)
- P1-3 Rollout top-N (условно/точечно)

Фаза 3 (P2, “ядро решения”):
- P2-2 Goal-oriented joker (в связке с rollout)
- P2-3 Endgame solver
- P2-1 Composite utility (если стало сложно контролировать взаимодействия)

Фаза 4 (P3–P4, “consistency + полировка”):
- P3-3 HandStrength
- P3-1 Monte-Carlo blind
- P3-2 Context-aware threat
- P4-1 Trump
- P4-2 Forbidden-aware bidding

---

## Целевые метрики (ориентир на “после всех фаз”)

Baseline ниже приведён как пример (обновлять по актуальному `make bot-baseline`).

| Метрика | Baseline (пример) | Target (после всех фаз) |
|---------|-------------------:|-------------------------:|
| `winRate` | 0.25 | 0.40-0.45 |
| `averageScoreDiff` | 0.00 | +450-550 |
| `averagePremiumAssistLoss` | 26.25 | <15 |
| `averagePremiumPenaltyTargetLoss` | 4.95 | <2.5 |
| `blindSuccessRate` | 0.087 | 0.25-0.30 |
| `jokerWishWinRate` | 0.00 | 0.35-0.45 |
| `bidAccuracyRate` | 0.46 | 0.60-0.65 |

---

## Минимальный набор gate-тестов (policy)

Перед любым “compare”:
- `xcodebuild build-for-testing` (или эквивалент),
- `joker-pack` (джокер-регрессии),
- `stage6b-pack-all` (opponent-aware guardrails + flow plumbing),
- затем `make bot-compare` / профиль `compare-v1`.

---

## Риски и митигация (коротко)

- Производительность (rollout/MC): conditional apply, строгий budget, фиксированные seed.
- Сложность отладки (belief state): поэтапное включение + строгие unit-тесты на обновление состояния.
- Overfit: всегда держать holdout-гейт (compare-v1), продвигать только стабильные улучшения.

