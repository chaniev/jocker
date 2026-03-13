# Детальный план 04. Фазовые multipliers поверх существующей block-progress логики

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.4 / приоритет P1  
**Порядок выполнения:** 4  
**Предусловия:** завершены этапы 01 и 03  
**Статус:** реализован по коду; validation gate открыт частично  
**Статус gate:** шаги 1-5 закрыты; шаг 6 частично закрыт через deterministic guardrails pack, но self-play holdout и включение `tunePhasePolicy` в canonical profile пока не подтверждены

## Цель

Добавить фазовые multipliers в уже существующие policy-кластеры и сервисы runtime AI так, чтобы бот менял давление, rollout, blind-aggression и joker-spend в зависимости от прогресса блока.

## Статус на 2026-03-13

- В коде есть единый `BotBlockPhase` и `PhaseMultipliers`; фазовые коэффициенты встроены в ranking, rollout, joker declaration и blind policy.
- Профильные runtime-сервисы (`BlockPlanResolver`, `BotTurnRolloutService`, `JokerDeclarationAdjuster`, `BotBlindBidPolicy`) читают фазовые multipliers напрямую из канонических policy-секций.
- Phase-related genes и флаг `tunePhasePolicy` уже раскрыты в genome / patch-layer / runner summary.
- `scripts/run_stage4_phase_guardrails.sh` оформляет 5 scenario families и детерминированно проверяет baseline/candidate expectations, но отдельного self-play holdout summary для phase-enabled training пока нет.

## Шаги выполнения

### 1. Ввести единое представление фазы блока

1. Создать отдельный тип `BotBlockPhase`.
2. Определить в нём три фазы:
   - `early`
   - `mid`
   - `late`
3. Реализовать детерминированное отображение `blockProgressFraction -> BotBlockPhase`.
4. Добавить unit tests на границы переходов между фазами.

### 2. Добавить фазовые multipliers в канонические policy-секции

1. Расширить секцию ranking фазовыми множителями для:
   - `matchCatchUp`
   - `premiumPressure`
   - `penaltyAvoid`
2. Расширить секцию rollout фазовыми множителями для:
   - activation threshold;
   - utility adjustment.
3. Расширить joker-related политику фазовыми множителями для:
   - early spend;
   - late spend;
   - declaration pressure.
4. Расширить blind policy фазовыми множителями для блока 4.
5. Задать нейтральные baseline-значения `1.0` для всех новых фазовых коэффициентов.
6. Подключить эти коэффициенты к `hard` baseline и difficulty patch-функциям.

### 3. Подключить фазовые multipliers к runtime сервисам

1. В `BlockPlanResolver` применять фазовые множители ranking-секции.
2. В `BotTurnRolloutService` применять фазовые множители rollout-секции.
3. В `JokerDeclarationAdjuster` применять фазовые множители joker-секции.
4. В `BotBlindBidPolicy` применять фазовые множители blind-секции.
5. Не добавлять глобальный post-processor; применять multipliers только в профильных сервисах.

### 4. Сохранить нейтральный baseline-path

1. Добавить тест, что при всех фазовых коэффициентах `1.0` поведение совпадает с дорефакторным baseline.
2. Зафиксировать это поведение regression tests для ranking, rollout, blind и joker.
3. Оставить identity genome нейтральным относительно фазовых коэффициентов до их раскрытия в обучении.

### 5. Раскрыть фазовые multipliers для обучения

1. Добавить в genome grouped genes для фазовых коэффициентов:
   - `phaseRankingScale`
   - `phaseRolloutScale`
   - `phaseJokerScale`
   - `phaseBlindScale`
2. Применять эти genes через уже существующий patch-layer.
3. Ограничить диапазоны теми же bounds-механизмами, что и в этапе 03.
4. Обновить summary training run новыми phase-related fields.

### 6. Подготовить scenario-based validation

1. Сформировать отдельные holdout scenario families:
   - early block / low pressure;
   - late block / catch-up;
   - block 4 / blind pressure;
   - premium pressure;
   - joker-sensitive openings.
2. Прогнать baseline и candidate на каждом семействе.
3. Зафиксировать поведение по фазам в summary.

## Проверки

1. Mapping `blockProgressFraction -> BotBlockPhase` покрыт unit tests.
2. Нейтральные коэффициенты `1.0` не меняют baseline behavior.
3. Ranking, rollout, joker и blind сервисы читают фазовые multipliers из канонических policy-секций.
4. Phase-related genes печатаются в training summary.
5. Scenario-based holdout показывает фазоспецифический эффект.

## Критерии завершения

1. В коде есть единый тип фазы блока.
2. Фазовые multipliers встроены в policy-секции и профильные runtime сервисы.
3. Нейтральный baseline сохранён и закрыт regression tests.
4. Фазовые коэффициенты раскрыты для обучения через grouped genes.
5. Эффект подтверждён на phase-specific holdout scenarios.
