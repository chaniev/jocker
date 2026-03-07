# Детальный план 08. Experiment harness и отчётность для self-play

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.8 / приоритет P3  
**Порядок выполнения:** 8  
**Предусловия:** завершён этап 01; этапы 02-07 стабилизированы

## Цель

Сделать experiment workflow воспроизводимым, машинно-читаемым и единообразным для baseline, training, compare и post-training regression checks.

## Шаги выполнения

### 1. Ввести machine-readable артефакты

1. Создать versioned schema для experiment artifacts с полем `schemaVersion`.
2. Описать Swift `Codable`-структуры для всех артефактов.
3. Добавить run-level `summary.json`.
4. Добавить `per-seed-metrics.json`.
5. Добавить `comparison.json` для A/B compare.
6. Добавить `metrics.csv` как табличный экспорт основных показателей.
7. Сделать JSON-артефакты источником правды для scripts.

### 2. Обновить training и baseline scripts

1. Переписать `scripts/train_bot_tuning.sh` так, чтобы он читал structured output из Swift runner.
2. Переписать `scripts/run_bot_baseline_snapshot.sh` так, чтобы он публиковал `summary.json` и `per-seed-metrics.json`.
3. Переписать `scripts/run_bot_ab_comparison_snapshot.sh` так, чтобы он строил markdown-таблицу из `comparison.json`.
4. Сохранить существующую структуру каталогов артефактов.

### 3. Сделать holdout частью compare-profile по умолчанию

1. В compare-profile всегда запускать training seeds.
2. В compare-profile всегда запускать holdout seeds.
3. Разделять результаты training и holdout в markdown и JSON summary.
4. Добавить явный флаг отключения holdout только как исключение.

### 4. Расширить отчёты AI-метриками

1. Добавить в markdown и JSON summary следующие метрики:
   - `blindSuccessRate`
   - `jokerWishWinRate`
   - `bidAccuracyRate`
   - `overbidRate`
   - `penaltyTargetRate`
   - `leftNeighborPremiumAssistRate`
   - `earlyJokerSpendRate`
2. Группировать вывод по блокам:
   - outcome metrics;
   - bid metrics;
   - blind metrics;
   - joker metrics;
   - premium metrics.
3. Сохранять одинаковую структуру групп в markdown и JSON.

### 5. Добавить статистические summary

1. Для compare-output считать:
   - mean;
   - median;
   - min;
   - max;
   - wins-by-seed.
2. Добавить bootstrap-based confidence interval для ключевых outcome metrics.
3. Печатать статистический блок отдельно для training и holdout.

### 6. Встроить post-training guardrail gate

1. После compare запускать `run_joker_regression_pack.sh`.
2. После него запускать `run_stage6b_ranking_guardrails.sh`.
3. Публиковать результаты этих запусков в общем experiment summary.
4. Маркировать training run как failed, если guardrail gate не пройден.

### 7. Свести `Makefile` к одному исследовательскому workflow

1. Определить цепочку `baseline -> training -> compare -> guardrails` как основной путь.
2. Привязать к этой цепочке основные targets `make`.
3. Пометить все legacy targets префиксом `legacy-`.
4. Добавить один основной target для полного experiment workflow.

### 8. Зафиксировать контракт артефактов

1. Описать имена файлов и структуру каталогов для каждого типа запуска.
2. Описать обязательные поля каждого JSON-артефакта.
3. Зафиксировать `schemaVersion` и правила его изменения.
4. Добавить tests на генерацию и чтение этих артефактов.
5. Сверить поля JSON-артефактов с markdown summary.

## Проверки

1. Scripts читают structured output, а не парсят human-readable log как источник правды.
2. Compare-profile всегда включает holdout.
3. JSON summary содержит `schemaVersion`.
4. Markdown summary и JSON summary содержат одинаковые группы метрик.
5. Guardrail gate запускается автоматически после compare.
6. Один основной `make` target выполняет полный experiment workflow.

## Критерии завершения

1. Baseline, training и compare порождают machine-readable артефакты.
2. Все JSON-артефакты имеют versioned schema и Swift `Codable`-модель.
3. Holdout входит в compare-profile по умолчанию.
4. Отчёты содержат outcome, bid, blind, joker и premium-метрики.
5. Post-training guardrail gate встроен в workflow.
6. `Makefile` отражает один канонический исследовательский путь.
