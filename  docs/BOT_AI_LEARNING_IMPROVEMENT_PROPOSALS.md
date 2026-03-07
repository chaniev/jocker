# Предложения по улучшению алгоритмов обучения ботов

**Дата обновления:** 6 марта 2026 г.  
**Основание:** сверка `BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md` с текущим кодом self-play, runtime AI и скриптами запуска обучения.

---

## Краткий вывод

Предыдущая версия документа переоценивала объём отсутствующих возможностей и в нескольких местах уже не соответствовала коду.

Главное:

- В проекте уже есть фазовая логика по ходу блока, contextual opponent modeling, rollout и endgame solver.
- Self-play уже собирает много операционных метрик, но fitness использует только 7 компонентов.
- Эволюция сейчас тюнингует не весь `BotTuning`, а только ограниченный `EvolutionGenome` из scale-параметров для части `turnStrategy`, `bidding` и `trumpSelection`.
- В training pipeline есть подтверждённые проблемы, которые нужно исправить раньше, чем расширять алгоритмы.

Самый важный вывод: следующий прирост качества ботов даст не изобретение новой архитектуры с нуля, а выравнивание training pipeline с текущим кодом и расширение тюнинга на реально используемые runtime-policy коэффициенты.

---

## 1. Что есть в коде сейчас

### 1.1 Self-play и эволюция

Текущее обучение реализовано в `BotSelfPlayEvolutionEngine` и его `+PublicTypes`, `+Fitness`, `+Evolution`, `+Genome`, `+Simulation*` файлах.

Фактически сейчас есть:

- self-play по полной партии с блоками, премиями и blind через `useFullMatchRules`;
- ротация кандидата по местам за столом через `rotateCandidateAcrossSeats`;
- early stopping;
- multi-seed обучение с ensemble-агрегацией в `scripts/train_bot_tuning.sh`;
- A/B head-to-head валидация на training seed и holdout seed.

Текущее ядро эволюции:

- популяция формируется вокруг `EvolutionGenome.identity`;
- элиты переносятся без изменений;
- родители выбираются случайно из top-`selectionPoolRatio` после сортировки по fitness;
- используется crossover + mutation;
- для каждого поколения evaluation seeds детерминированно сдвигаются от базового seed.

Важно: это не tournament selection и не mutation over all bot coefficients. Это сравнительно простой GA с фиксированной формой генома.

### 1.2 Что именно тюнингует эволюция

Эволюция тюнингует не весь бот, а только поля, описанные в `EvolutionGenome`.

По факту это:

- часть `turnStrategy`;
- часть `bidding`, включая blind-пороги и blind target share;
- только 2 scale-параметра для `trumpSelection`.

Не тюнингуется:

- `runtimePolicy` с ranking / rollout / endgame / opponent modeling коэффициентами;
- большая часть `turnStrategy`;
- большая часть `trumpSelection`;
- любые фазовые или онлайн-адаптивные коэффициенты как отдельное пространство поиска.

Следствие: главный объём актуальной логики принятия решений уже вынесен в `BotRuntimePolicy`, но self-play пока не умеет оптимизировать эту область.

### 1.3 Текущая fitness-функция

Текущий `FitnessScoringConfig` использует только:

- `winRate`
- `averageScoreDiff`
- `averageUnderbidLoss`
- `averageTrumpDensityUnderbidLoss`
- `averageNoTrumpControlUnderbidLoss`
- `averagePremiumAssistLoss`
- `averagePremiumPenaltyTargetLoss`

При этом `FitnessBreakdown` и `SimulationMetricsAccumulator` уже считают дополнительные метрики:

- `premiumCaptureRate`
- `blindSuccessRate`
- `jokerWishWinRate`
- `earlyJokerSpendRate`
- `penaltyTargetRate`
- `bidAccuracyRate`
- `overbidRate`
- `blindBidRateBlock4`
- `averageBlindBidSize`
- `blindBidWhenBehindRate`
- `blindBidWhenLeadingRate`
- `earlyLeadWishJokerRate`
- `leftNeighborPremiumAssistRate`

То есть проект уже собирает существенно больше обучающих сигналов, чем реально использует при оптимизации.

### 1.4 Runtime AI

В runtime AI уже есть то, что в старом документе предлагалось "добавить":

- фазовый контекст блока через `BotMatchContext.blockProgressFraction`;
- блоковая стратегия через `BlockPlanResolver`;
- opponent modeling через `BotMatchContextBuilder` + `BotOpponentModel` + `OpponentPressureAdjuster`;
- rollout gating и urgency через `BotTurnRolloutService`;
- endgame solver через `BotTurnEndgameSolver`;
- premium / anti-premium сигналы в `PremiumSnapshot`.

Следовательно, предложения вида "добавить фазовую динамику", "добавить opponent modeling", "добавить rollout awareness" нужно не повторять, а переопределить как развитие уже существующих механизмов.

---

## 2. Подтверждённые расхождения между старым документом и текущим кодом

| Тезис из старой версии | Что в коде сейчас | Вывод |
|---|---|---|
| "Мутируется ~150 параметров `BotTuning`" | Мутируется ограниченный `EvolutionGenome`, а не весь `BotTuning` | Документ завышал текущий охват обучения |
| "Текущий GA: турнирная селекция top-40%" | Родители выбираются случайно из top-`selectionPoolRatio` после сортировки | Описание алгоритма было неточным |
| "Нужно добавить фазовую динамику" | `BlockPlanResolver` уже использует `blockProgressFraction` и late-block urgency | Нужно донастроить, а не вводить с нуля |
| "Нужно добавить contextual opponent modeling" | Уже есть `BotOpponentModel` и `OpponentPressureAdjuster` | Следующий шаг: расширение модели, а не создание MVP |
| "Нужно улучшить rollout-политику, потому что её почти нет" | Уже есть rollout gating, urgency и sampled rollout | Нужен тюнинг и расширение policy, а не первый rollout |

---

## 3. Анализ training scripts

### 3.1 `scripts/train_bot_tuning.sh`

Сильные стороны:

- поддерживает multi-seed запуск;
- умеет ensemble aggregation;
- умеет post-training A/B validation;
- печатает расширенный набор метрик;
- поддерживает holdout seed-list для A/B.

Подтверждённые проблемы:

#### P0. Скрипт сейчас не собирает runner

Минимальный запуск подтверждает ошибку компиляции generated `main.swift`:

```text
error: missing arguments for parameters 'playerChosenPairBonus', 'lengthBonusPerExtraCard',
'densityBonusWeight', 'sequenceBonusWeight', 'controlBonusWeight',
'jokerSynergyBase', 'jokerSynergyControlWeight' in call
```

Причина:

- `aggregateTunings()` вручную конструирует `BotTuning.TrumpSelection`;
- структура `BotTuning.TrumpSelection` уже расширена;
- shell-скрипт отстал от модели и генерирует невалидный Swift.

Следствие:

- training pipeline в текущем состоянии нельзя считать рабочим;
- любые дальнейшие предложения по улучшению обучения вторичны, пока не восстановлен базовый запуск.

#### P0. Baseline harness фактически не гарантирует baseline-only режим

`run_bot_baseline_snapshot.sh` использует:

```bash
--generations 0
```

Но `SelfPlayEvolutionConfig.init` нормализует:

```swift
self.generations = max(1, generations)
```

Следствие:

- "baseline-only" режим через `--generations 0` сейчас логически не существует;
- baseline snapshot может запускать хотя бы одно поколение эволюции;
- для multi-seed baseline harness затем читает `ensembleAverageBest*`, то есть агрегат лучших кандидатов, а не чистый baseline.

Это один из самых важных дефектов всего training pipeline.

#### P1. Скрипт хрупкий по архитектуре

Сейчас training runner собирается через heredoc и generated `main.swift` внутри shell-скрипта.

Минусы такого подхода:

- shell-скрипт дублирует модель `BotTuning`;
- изменения в Swift-моделях легко ломают training launcher;
- на эту часть почти невозможно навесить unit tests;
- review диффов становится тяжелее, чем у отдельного Swift CLI target.

### 3.2 `scripts/run_bot_baseline_snapshot.sh`

Плюсы:

- хорошо изолирует артефакты запуска;
- сохраняет команду, лог, summary и metrics;
- уже умеет извлекать расширенные AI-метрики из training log.

Проблемы:

- описание в header устарело: комментарий говорит, что расширенные Stage-0 метрики "пока не собираются", хотя код их уже извлекает;
- baseline semantics сейчас неверны из-за `generations >= 1`.

### 3.3 `scripts/run_bot_ab_comparison_snapshot.sh`

Плюсы:

- есть reproducible training profile;
- есть training seeds и holdout seeds;
- есть markdown-таблица для сравнения A/B.

Проблемы:

- comparison table показывает только ограниченный набор summary-метрик;
- многие уже доступные метрики (`blindSuccessRate`, `jokerWishWinRate`, `bidAccuracyRate`, `leftNeighborPremiumAssistRate` и др.) в итоговую таблицу не попадают;
- скрипт полезен как витрина результатов, но пока не как полный experiment report.

### 3.4 `Makefile`

`Makefile` в проекте уже является важной частью training workflow, а не просто удобной обёрткой.

Что в нём уже полезно:

- есть единая точка входа `make bt` / `make train-bot` для ручного запуска `train_bot_tuning.sh`;
- есть отдельные orchestration targets для baseline и A/B:
  - `make bot-baseline`
  - `make bot-compare`
- есть full-match профили для `hard`:
  - `bt-hard-fullgame-smoke`
  - `bt-hard-fullgame-balanced`
  - `bt-hard-fullgame-battle`
  - `bt-hard-final`
  - `bt-hard-*-esab`
- есть regression harness targets:
  - `joker-pack`
  - `stage6b-pack`

Подтверждённые проблемы:

#### P1. В `Makefile` coexist-ят два несовпадающих режима обучения

Сейчас в `Makefile` одновременно живут:

- legacy random-round профили:
  - `SMOKE_ARGS`
  - `BALANCED_ARGS`
  - `BATTLE_ARGS`
- full-match профили:
  - `FULLGAME_SMOKE_ARGS`
  - `FULLGAME_BALANCED_ARGS`
  - `FULLGAME_BATTLE_ARGS`

Legacy-профили используют:

- `--use-full-match-rules false`
- `--rotate-candidate-across-seats false`
- `--fitness-underbid-loss-weight 0.0`

Следствие:

- через короткие и очевидные targets вроде `bt-hard-smoke` и `bt-hard-balanced` легко запустить режим, который уже хуже отражает текущую целевую модель игры;
- orchestration layer подталкивает разработчика к неканоническому training profile.

#### P1. Нет одного явно обозначенного "рекомендуемого" training target

Сейчас из `Makefile` неочевидно, какой путь считать основным:

- `bt-hard-balanced`
- `bt-hard-fullgame-balanced`
- `bt-hard-final`
- `bt-hard-final-esab`

Следствие:

- разные разработчики могут запускать разные профили и сравнивать несопоставимые результаты;
- proposal-level улучшения сложнее привязывать к одному reproducible entrypoint.

#### P1. `Makefile` наследует дефекты baseline/compare harness без явного предупреждения

Пока `run_bot_baseline_snapshot.sh` и `train_bot_tuning.sh` содержат проблемы, описанные выше, targets:

- `make bot-baseline`
- `make bot-baseline-smoke`

также нельзя считать полностью достоверными.

То есть Make-уровень сейчас не изолирует пользователя от дефектов нижележащего training pipeline.

---

## 4. Обновлённые предложения по улучшению

Ниже список изменений уже не "вообще для ботов", а именно тех улучшений, которые имеют смысл после сверки с кодом.

### 4.1 P0. Сначала восстановить корректность training pipeline

**Приоритет:** критический  
**Почему первым:** без этого нельзя доверять ни baseline, ни результатам обучения.

Что нужно сделать:

1. Починить `train_bot_tuning.sh`, чтобы `aggregateTunings()` соответствовал актуальной структуре `BotTuning.TrumpSelection`.
2. Убрать ложный baseline-only режим через `--generations 0`.
3. Ввести явный отдельный режим baseline evaluation:
   - либо `evaluateBaseline(...)` в Swift;
   - либо CLI-флаг `--baseline-only true`, который вообще не заходит в generation loop.
4. Добавить smoke-проверку training runner в CI:
   - минимальная компиляция runner;
   - один короткий self-play прогон;
   - проверка, что baseline harness не выполняет эволюцию.
5. По возможности вынести generated Swift из shell-скрипта в отдельный checked-in CLI/tool target.
6. После исправления pipeline привести `Makefile` к одному каноническому training path:
   - оставить legacy-профили только как явно помеченные `legacy`;
   - основными сделать full-match профили;
   - выделить один рекомендуемый target для основной тренировки и один для финальной валидации.

Ожидаемый эффект:

- воспроизводимые baseline и A/B;
- исчезновение скрытых регрессий при изменении `BotTuning`;
- orchestration layer в `Makefile` перестаёт вести в устаревшие training modes;
- возможность безопасно развивать обучение дальше.

### 4.2 P1. Расширить fitness, используя уже собираемые метрики

**Приоритет:** высокий  
**Почему это сильнее старой версии документа:** новые сигналы уже есть в пайплайне, их не нужно сначала изобретать и логировать.

Рекомендация:

Не добавлять все метрики в плоскую сумму одинакового типа. Лучше разделить их на две группы.

**Основной fitness:**

- `winRate`
- `averageScoreDiff`
- `averageUnderbidLoss`
- `averagePremiumAssistLoss`
- `averagePremiumPenaltyTargetLoss`

**Guardrails / secondary penalties:**

- `bidAccuracyRate`
- `overbidRate`
- `blindSuccessRate`
- `penaltyTargetRate`
- `earlyJokerSpendRate`
- `leftNeighborPremiumAssistRate`
- `jokerWishWinRate`

Рекомендуемый подход:

- либо добавить новые веса в `FitnessScoringConfig`;
- либо сделать двухступенчатую оценку:
  - сначала основной fitness;
  - потом tie-break или penalty over guardrail violations.

Почему это лучше, чем в старом документе:

- не нужно придумывать `jokerEfficiency` и `trumpSelectionAccuracy` как новые абстракции, пока уже не использованы более прямые текущие метрики;
- приоритет получают именно те сигналы, которые self-play уже честно измеряет.

### 4.3 P1. Расширить пространство эволюции на `runtimePolicy`

**Приоритет:** высокий  
**Причина:** сейчас большая часть актуальной логики бота нетюнима.

Это самый недооценённый gap старой версии документа.

Сейчас бот принимает решения через:

- ranking policy;
- rollout policy;
- endgame policy;
- opponent modeling policy;
- evaluator sub-policies.

Все эти коэффициенты живут в `BotRuntimePolicy`, но self-play их не трогает.

Рекомендация:

Не открывать сразу все scalar-поля. Начать с групповых multiplier-генов:

- `rankingMatchCatchUpScale`
- `rankingPremiumScale`
- `rankingPenaltyAvoidScale`
- `jokerDeclarationScale`
- `rolloutActivationScale`
- `rolloutAdjustmentScale`
- `endgameActivationScale`
- `endgameAdjustmentScale`
- `opponentPressureScale`

Преимущества:

- меньше размерность поиска;
- меньше риск взорвать runtime behavior;
- можно постепенно раскрывать внутренние коэффициенты только там, где есть подтверждённый эффект.

### 4.4 P1. Ввести фазовые multiplier-коэффициенты поверх уже существующей block-progress логики

**Приоритет:** высокий  
**Важно:** это не "добавить фазовую логику с нуля", она уже есть.

Правильная следующая итерация:

- не плодить отдельный `PhaseModifiers` внутри `BotTurnStrategyService`;
- а доучить существующую систему, которая уже опирается на `blockProgressFraction`.

Что стоит обучать по фазам:

- силу `matchCatchUp`;
- anti-premium pressure;
- rollout gating в поздней фазе блока;
- желание тратить джокера в ранней/поздней фазе;
- blind aggression для блока 4.

Предлагаемый формат:

- 3 фазы: early / mid / late;
- на каждый важный policy cluster добавить multiplier;
- применять multiplier внутри `BlockPlanResolver`, `JokerDeclarationAdjuster`, `BotTurnRolloutService`, а не только в одном entrypoint.

### 4.5 P2. Улучшить эволюционный алгоритм без преждевременного усложнения

**Приоритет:** средний-высокий  
**Почему не первым:** прежде нужно починить pipeline и расширить fitness/scope.

Старый документ предлагал сразу `speciation + novelty search + adaptive mutation`.
Это возможно, но не лучший первый шаг.

Рациональный порядок:

1. adaptive mutation rate;
2. random immigrants в каждое поколение;
3. restart from elite archive после стагнации;
4. diversity metric в progress/log;
5. только потом решать, нужен ли полноценный speciation.

Почему так:

- текущий GA пока слишком маленький и слишком узкий по геному, чтобы сразу усложнять его до почти-NEAT схемы;
- сначала надо понять, что именно ограничивает обучение: слабый fitness, узкий genome scope или реальная потеря diversity.

### 4.6 P2. Параллелизовать оценку кандидатов

**Приоритет:** средний-высокий  
**Статус сейчас:** generation loop оценивает кандидатов последовательно.

Что имеет смысл распараллелить:

- кандидатов внутри поколения;
- при необходимости отдельные evaluation seeds внутри одного кандидата.

Условия безопасной параллелизации:

- детерминированная генерация seed на кандидата и на игру;
- иммутабельный evaluation context;
- отсутствие shared mutable state в accumulators;
- фиксированный merge order для progress/reporting.

Ожидаемый результат:

- ощутимое ускорение wall-clock training time;
- возможность увеличивать `gamesPerCandidate` без линейного роста времени.

### 4.7 P2. Развить opponent model до версии 2, а не создавать его заново

**Приоритет:** средний

Что уже есть:

- blind rate;
- exact / over / under bid rates;
- average bid aggression;
- left-neighbor prioritization;
- evidence saturation.

Что реально полезно добавить:

- seat-relative memory не только на текущий блок, но и на матч;
- separate signals for joker usage style;
- tendency to deny premium / save premium;
- confidence score по наблюдениям;
- разделение "агрессивен" и "хаотичен".

Важно:

- эти признаки должны не просто жить в runtime;
- их нужно либо отражать в fitness, либо использовать как holdout scenario families для A/B validation.

### 4.8 P3. Улучшить experiment harness и отчётность

**Приоритет:** средний  
**Это улучшение не алгоритма, а качества исследовательского цикла.**

Предложения:

1. Добавить machine-readable output:
   - JSON summary;
   - JSON per-seed metrics;
   - optional CSV.
2. Сделать holdout обязательной частью compare-profile по умолчанию.
3. Расширить markdown/table отчёт `run_bot_ab_comparison_snapshot.sh` всеми уже доступными AI-метриками.
4. Добавить статистические summary:
   - mean;
   - median;
   - min/max;
   - wins-by-seed;
   - confidence interval или bootstrap estimate.
5. После обучения запускать не только A/B, но и guardrail packs:
   - `run_joker_regression_pack.sh`;
   - `run_stage6b_ranking_guardrails.sh`.
6. Синхронизировать `Makefile` с этим workflow:
   - training target;
   - baseline target;
   - compare target;
   - regression packs как post-training gate.

---

## 5. Что не стоит делать прямо сейчас

Ниже идеи, которые звучат интересно, но пока преждевременны.

### 5.1 Не начинать с meta-learning в матче

Причина:

- уже есть block-local adaptation через opponent model и premium/block context;
- пока не решены базовые проблемы training pipeline;
- без корректного offline evaluation online adaptation будет трудно валидировать.

### 5.2 Не начинать с transfer learning между `hard -> normal -> easy`

Причина:

- сначала нужно стабилизировать один качественный `hard` training loop;
- после этого можно уже думать о деградации `runtimePolicy` и `BotTuning` для lower difficulties;
- сейчас ценность такой работы ниже, чем ценность расширения fitness и genome scope.

### 5.3 Не внедрять полноценный speciation до измерения diversity

Причина:

- пока нет даже штатной метрики diversity в progress/log;
- есть риск сильно усложнить систему до того, как станет ясно, что реальный bottleneck именно в вырождении популяции.

---

## 6. Рекомендуемый порядок внедрения

### Фаза 0. Исправление пайплайна

Сделать сразу:

- починить `train_bot_tuning.sh`;
- ввести честный baseline-only режим;
- обновить baseline harness;
- синхронизировать `Makefile` с исправленными scripts и убрать двусмысленность между legacy/full-match targets;
- добавить smoke-check training runner в CI.

Критерий завершения:

- training script компилируется и делает минимальный self-play run;
- baseline harness не запускает ни одного поколения эволюции;
- `Makefile` имеет один явно рекомендуемый training path;
- baseline и compare harness дают непротиворечивые summary.

### Фаза 1. Улучшение objective function

Сделать после восстановления пайплайна:

- добавить guardrail-метрики в fitness/evaluation;
- пересобрать A/B отчёты так, чтобы эти метрики были видны;
- проверить, какие из текущих дополнительных метрик реально коррелируют с win-rate на holdout.

Критерий завершения:

- новая fitness-конфигурация даёт выигрыш на holdout, а не только на training seeds;
- нет деградации по blind / joker / anti-premium guardrails.

### Фаза 2. Расширение genome scope

Сделать дальше:

- добавить group multipliers для `runtimePolicy`;
- обучить несколько безопасных policy cluster-ов;
- сравнить effect size против старой схемы, где тюнингуется только `turnStrategy/bidding/trumpSelection`.

Критерий завершения:

- improvement держится на holdout;
- нет взрыва нестабильности из-за слишком широкой размерности поиска.

### Фаза 3. Ускорение и устойчивость обучения

После этого:

- параллелизация evaluation;
- adaptive mutation;
- random immigrants;
- diversity tracking.

Критерий завершения:

- training time заметно ниже;
- same or better quality при большем числе симуляций;
- diversity не схлопывается слишком рано.

### Фаза 4. Runtime model v2

Только после предыдущих фаз:

- opponent model v2;
- phase-conditioned multipliers;
- при необходимости speciation.

---

## 7. Конкретные изменения по файлам

| Файл | Что менять | Зачем |
|---|---|---|
| `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Fitness.swift` | расширить scoring/guardrails | использовать уже собираемые метрики |
| `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+PublicTypes.swift` | добавить явный baseline mode и, возможно, новые fitness/runtime-policy флаги | убрать двусмысленность `generations=0` |
| `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Genome.swift` | добавить group multipliers для `runtimePolicy` | расширить реально тюнимую область |
| `Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Evolution.swift` | добавить parallel evaluation, diversity tracking, adaptive mutation | ускорить и стабилизировать эволюцию |
| `scripts/train_bot_tuning.sh` | убрать расхождение с актуальным `BotTuning`, перестать генерировать хрупкий runner | восстановить работоспособность pipeline |
| `scripts/run_bot_baseline_snapshot.sh` | исправить baseline semantics и документацию | сделать baseline честным |
| `scripts/run_bot_ab_comparison_snapshot.sh` | расширить итоговый отчёт метриками blind/joker/bid/premium | улучшить качество анализа результатов |
| `Makefile` | выделить канонические full-match targets и явно пометить legacy-профили | синхронизировать orchestration layer с реальной стратегией обучения |

---

## 8. Обновлённая приоритизация

| № | Изменение | Приоритет | Причина |
|---|---|---|---|
| 1 | Починить `train_bot_tuning.sh` и baseline semantics | P0 | сейчас нельзя доверять training pipeline |
| 2 | Расширить fitness на уже собираемые метрики | P1 | быстрый и содержательный прирост качества |
| 3 | Добавить тюнинг `runtimePolicy` через group multipliers | P1 | главная untuned область текущего AI |
| 4 | Ввести phase multipliers поверх существующего `blockProgressFraction` | P1 | развитие уже работающей логики |
| 5 | Параллелизовать evaluation | P2 | ускорение экспериментов |
| 6 | Adaptive mutation + diversity tracking + immigrants | P2 | устойчивость поиска |
| 7 | Opponent model v2 | P2 | рост качества против сильных/специфичных соперников |
| 8 | Speciation / novelty search | P3 | делать только если простой GA останется bottleneck |

---

## 9. Итог

После сверки с кодом ключевая картина изменилась:

- проект уже содержит больше умной runtime-логики, чем предполагал старый документ;
- главный bottleneck сейчас не отсутствие "фаз", "opponent modeling" или "rollout", а разрыв между этой runtime-логикой и training pipeline;
- наиболее ценные изменения на ближайший этап:
  - починить scripts и baseline semantics;
  - расширить fitness за счёт уже доступных метрик;
  - начать тюнинговать `runtimePolicy`, а не только небольшой subset `BotTuning`.

Именно это даст следующий осмысленный прирост качества ботов и сделает дальнейшие эксперименты достоверными.
