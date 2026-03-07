# Детальный план 05. Параллелизация оценки кандидатов

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.6 / приоритет P2  
**Порядок выполнения:** 5  
**Предусловия:** завершены этапы 01 и 03

## Цель

Сократить wall-clock время обучения за счёт параллельной оценки кандидатов, сохранив детерминизм, повторяемость результатов и читаемый summary.

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
