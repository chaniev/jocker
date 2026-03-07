# Детальный план 02. Расширение fitness и guardrail-метрик

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.2 / приоритет P1  
**Порядок выполнения:** 2  
**Предусловия:** завершён этап 01

## Цель

Расширить objective function так, чтобы self-play использовал уже собираемые метрики и разделял:

- основную цель обучения;
- guardrail-штрафы;
- диагностический breakdown причин победы кандидата.

## Шаги выполнения

### 1. Разделить fitness на два слоя

1. В `BotSelfPlayEvolutionEngine+Fitness.swift` ввести два независимых слоя оценки:
   - `primaryFitness`
   - `guardrailPenalty`
2. В `primaryFitness` включить только:
   - `winRate`
   - `averageScoreDiff`
   - `averageUnderbidLoss`
   - `averagePremiumAssistLoss`
   - `averagePremiumPenaltyTargetLoss`
3. В `guardrailPenalty` включить только:
   - `bidAccuracyRate`
   - `overbidRate`
   - `blindSuccessRate`
   - `penaltyTargetRate`
   - `earlyJokerSpendRate`
   - `leftNeighborPremiumAssistRate`
   - `jokerWishWinRate`
4. Итоговый score вычислять по формуле:
   - `finalFitness = primaryFitness - guardrailPenalty`

### 2. Вынести веса и пороги в отдельные конфигурации

1. Создать структуру `PrimaryFitnessWeights`.
2. Создать структуру `GuardrailPenaltyWeights`.
3. Создать структуру `GuardrailThresholds`.
4. Подключить эти структуры к `FitnessScoringConfig`.
5. Удалить плоский набор scalar-весов, который смешивает primary и guardrail-метрики.

### 3. Привести сбор метрик к полному coverage нового fitness

1. Проверить, что все метрики из `guardrailPenalty` действительно собираются в `SimulationMetricsAccumulator`.
2. Добавить недостающие поля в `FitnessBreakdown`.
3. Добавить в `FitnessBreakdown` раздельный вывод:
   - primary components;
   - guardrail penalties;
   - final fitness.
4. Обновить summary training runner под новый breakdown.

### 4. Зафиксировать deterministic semantics тестами

1. Добавить тест, где одинаковый `primaryFitness` и худший guardrail profile проигрывают лучшему guardrail profile.
2. Добавить тест, где сильное падение `winRate` не компенсируется вторичными метриками.
3. Добавить тест, где отсутствие данных по guardrail-метрике даёт нулевой штраф.
4. Добавить тест, где baseline config воспроизводит ожидаемый breakdown без скрытых штрафов.

### 5. Обновить A/B validation

1. Прогнать baseline vs candidate на training seeds.
2. Прогнать baseline vs candidate на holdout seeds.
3. Сравнить `primaryFitness`, `guardrailPenalty` и `finalFitness` по обоим наборам.
4. Зафиксировать в summary отдельные блоки для training и holdout.

## Проверки

1. Все метрики из `primaryFitness` и `guardrailPenalty` видны в `FitnessBreakdown`.
2. Unit tests на новый scoring semantics проходят.
3. Training log показывает причину победы кандидата по компонентам.
4. Holdout validation не показывает деградацию `finalFitness` относительно старой схемы.

## Критерии завершения

1. Fitness разделён на основной objective и guardrail-штрафы.
2. Уже собираемые blind/joker/bid/premium-метрики реально участвуют в оценке.
3. Breakdown читается из training log без ручного анализа сырых метрик.
4. Новая формула проходит holdout-проверку.
5. Изменение весов и порогов не требует правки логики engine.
