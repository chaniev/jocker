# Детальный план 05. Параллелизация оценки кандидатов

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.6 / приоритет P2  
**Порядок выполнения:** 5  
**Предусловия:** завершены этапы 01 и 03  
**Статус:** реализован  
**Статус gate:** код и automation закрыты; для повторной формальной фиксации достаточно свежего benchmark summary из `scripts/run_stage5_parallel_benchmark.sh`

## Цель

Сократить wall-clock время обучения за счёт параллельной оценки кандидатов, сохранив детерминизм, повторяемость результатов и читаемый summary.

## Статус на 2026-03-13

- Structured concurrency, `maxParallelEvaluations`, детерминированная seed derivation, локальные worker accumulators и фиксированный merge-порядок реализованы в engine.
- Unit tests на parity sequential/parallel и bounds присутствуют; benchmark harness и `make stage5-benchmark` заведены.
- `scripts/run_training_pipeline_smoke.sh` повторно подтверждает живой parallel path (`--max-parallel-evaluations 2`) в текущем состоянии репозитория.
- Свежий Stage-05 benchmark в рамках этой ревизии не прогонялся; при необходимости достаточно запустить штатный benchmark script и сослаться на `summary.txt`.

## Шаги выполнения

### 1. Выделить чистую единицу работы `evaluateCandidate`

1. Вынести оценку одного кандидата в отдельную функцию `evaluateCandidate`.
2. Сделать входом функции:
   - candidate tuning;
   - generation index;
   - candidate index;
   - evaluation seeds;
   - immutable execution config.
3. Сделать выходом функции:
   - `FitnessBreakdown`;
   - `SimulationMetrics`;
   - candidate summary payload.
4. Удалить shared mutable state из тела этой функции.

### 2. Зафиксировать детерминированную схему seed derivation

1. Формировать seed из `generationIndex`, `candidateIndex`, `gameIndex` и `seatRotationIndex`.
2. Использовать одну и ту же seed derivation для sequential и parallel режима.
3. Запретить чтение общего RNG из нескольких worker'ов.
4. Добавить unit tests на повторяемость derived seeds.

### 3. Ввести локальные accumulators на worker

1. Создать отдельный metrics accumulator на каждый worker.
2. Создать отдельный fitness accumulator на каждый worker.
3. Буферизовать progress events локально внутри worker.
4. Выполнять merge результатов только после завершения worker.
5. Выполнять merge в фиксированном порядке `candidateIndex`.

### 4. Перевести generation loop на structured concurrency

1. В `BotSelfPlayEvolutionEngine+Evolution.swift` использовать structured concurrency.
2. Ввести параметр `maxParallelEvaluations`.
3. Оценивать кандидатов внутри поколения параллельно.
4. Оставить оценку seed'ов внутри одного кандидата последовательной на первой итерации.
5. Реализовать fallback `maxParallelEvaluations = 1` как полностью последовательный режим.

### 5. Стабилизировать progress и summary

1. Собирать per-candidate progress в локальные буферы.
2. Печатать общий progress только из центрального coordinator-потока.
3. Печатать итоговый summary строго по возрастанию `candidateIndex`.
4. Сохранить формат артефактов одинаковым для sequential и parallel режима.

### 6. Добавить конфигурацию parallel execution

1. Добавить в public config поле `maxParallelEvaluations`.
2. Поддержать значения:
   - `1`
   - `2`
   - `4`
   - `auto`
3. Для `auto` вычислять значение по числу доступных CPU, но ограничивать верхний предел.
4. Печатать выбранное значение в summary training run.

### 7. Провести сравнение sequential vs parallel

1. Прогнать canonical profile в sequential режиме.
2. Прогнать тот же профиль в parallel режиме.
3. Сравнить итоговые fitness values, metrics и best candidate.
4. Сравнить wall-clock time.
5. Зафиксировать результат в benchmark summary.

## Проверки

1. Unit tests на deterministic seed derivation проходят.
2. Sequential и parallel режимы дают одинаковые aggregated metrics.
3. Summary выводится в одном и том же порядке.
4. Parallel mode даёт измеримый выигрыш по времени на canonical profile.

## Критерии завершения

1. Generation loop умеет оценивать кандидатов параллельно.
2. Sequential и parallel результаты совпадают при одинаковых inputs.
3. Parallelism настраивается публичным параметром.
4. В логах и артефактах нет interleaved шума.
5. Canonical training profile ускорен по wall-clock времени.

## Canonical Stage-05 profile (benchmark reference)

Отдельного stage-05 profile в Makefile нет. **Canonical profile для Stage 05** — тот же, что для полного full-match training: **`bt-hard-fullgame-balanced`** (Makefile target, строка ~135). Параметры: `FULLGAME_BALANCED_ARGS`, один seed `20260220`, `--difficulty hard`. Используется для воспроизводимого benchmark sequential vs parallel и для артефактов закрытия Stage 05.

## Done (PR4: Benchmark and automation)

Stage 05 можно считать закрытым при наличии воспроизводимого benchmark summary и артефактов:

- **Canonical profile:** `bt-hard-fullgame-balanced` (без отдельного stage-05 profile).
- **Benchmark:** `scripts/run_stage5_parallel_benchmark.sh`; warmup через `--compile-only`, прогоны с `--max-parallel-evaluations 1`, `2`, `4`; raw logs и `summary.txt` с parity (aggregated metrics, best candidate) и speedup в `.derivedData/stage5-parallel-benchmark/<timestamp>/`.
- **Makefile:** `make stage5-benchmark` — отдельный target для Stage 05 benchmark.
- **Smoke:** в `run_training_pipeline_smoke.sh` добавлен tiny parallel smoke (`--max-parallel-evaluations 2`), чтобы регрессии не ломали parallel path незаметно.
- **Критерии:** sequential и parallel дают одинаковые aggregated metrics и тот же best candidate; parallel даёт измеримый wall-clock speedup. По итогам прогона можно ссылаться на summary при закрытии Stage 05.
