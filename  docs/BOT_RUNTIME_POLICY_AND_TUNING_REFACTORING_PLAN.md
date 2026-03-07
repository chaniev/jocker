# План рефакторинга `BotRuntimePolicy` и `BotTuning`

**Дата:** 7 марта 2026 г.  
**Объект:** `Jocker/Jocker/Models/Bot/BotRuntimePolicy.swift`, `Jocker/Jocker/Models/Bot/BotTuning.swift`

---

## Цель

Привести конфигурацию AI к форме, в которой:

1. у каждого блока конфигурации есть одно каноническое представление;
2. preset-значения собираются предсказуемо и локально;
3. изменение одного коэффициента не требует правок в нескольких несвязанных местах;
4. training tooling меньше зависит от внутренней формы моделей;
5. поведение ботов после рефакторинга остаётся неизменным.

---

## Зафиксированные решения

В этом рефакторинге принимаются следующие решения:

1. `BotRuntimePolicy` остаётся единым aggregate-root для runtime AI config.
2. `BotRuntimePolicy.Bidding` переводится на хранение nested policy-структур, а не плоского набора scalar-полей.
3. `BotRuntimePolicy` разбивается на preset-builder extension-файлы по смысловым секциям.
4. `BotTuning` сохраняется как единая точка входа для сервисов.
5. `timing` остаётся внутри `BotTuning` в этой итерации.
6. `JokerPolicy` переносится ближе к `TurnStrategy`, чтобы убрать лишнюю projection-логику на верхнем уровне `BotTuning`.
7. preset-значения `BotTuning` перестраиваются от общего baseline с точечными difficulty overrides.
8. рефакторинг выполняется без изменения числовых значений коэффициентов.

---

## Шаги рефакторинга

### Шаг 1. Зафиксировать текущее поведение тестами

**Файлы:**

- `Jocker/JockerTests/...` новые unit tests для preset-конфигурации

**Действия:**

1. Добавить тесты на `BotRuntimePolicy.preset(for: .easy/.normal/.hard)`.
2. Добавить тесты на `BotTuning(difficulty: .easy/.normal/.hard)`.
3. Зафиксировать ключевые значения для `ranking`, `bidding`, `rollout`, `heuristics`, `opponentModeling`, `turnStrategy`, `trumpSelection`, `timing`.
4. Добавить тест на `jokerPolicy`, чтобы после переноса projection-логики не изменились значения полей.

**Результат:**

- есть safety net перед структурными изменениями;
- любое случайное изменение коэффициентов ловится тестами сразу.

### Шаг 2. Разделить `BotRuntimePolicy` preset-код по секциям

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotRuntimePolicy.swift`
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+RankingPreset.swift`
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+BiddingPreset.swift`
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+EvaluatorPreset.swift`
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+RolloutPreset.swift`
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+HeuristicsPreset.swift`
- `Jocker/Jocker/Models/Bot/BotRuntimePolicy+OpponentModelingPreset.swift`

**Действия:**

1. Оставить в `BotRuntimePolicy.swift` только типы, `preset(for:)` и общий `overriding(...)`.
2. Вынести построение baseline preset по секциям в extension-файлы.
3. Для каждой секции сделать отдельную static factory-функцию с одним responsibility.

**Результат:**

- `BotRuntimePolicy.swift` перестаёт быть монолитом на 1200+ строк;
- preset-значения читаются по тематическим блокам.

### Шаг 3. Убрать двойное представление из `BotRuntimePolicy.Bidding`

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotRuntimePolicy.swift`
- все использования `tuning.runtimePolicy.bidding` в AI сервисах

**Действия:**

1. Заменить плоские поля `blind*`, `mc*`, `bidUtility*` на хранимые свойства:
   - `bidSelection: BidSelection`
   - `blindPolicy: BlindPolicy`
   - `blindMonteCarlo: BlindMonteCarlo`
2. Удалить computed projection-методы, которые пересобирают эти структуры из плоских scalar-полей.
3. Обновить preset-строительство так, чтобы nested policy-структуры создавались сразу в baseline preset.
4. Обновить difficulty overrides так, чтобы они меняли nested policy-структуры, а не случайные scalar-поля.

**Результат:**

- у `Bidding` остаётся одно каноническое представление;
- исчезает риск рассинхронизации между stored-полями и projection-кодом.

### Шаг 4. Свести difficulty overrides `BotRuntimePolicy` к явным patch-функциям

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotRuntimePolicy.swift`
- новые extension-файлы preset-секций

**Действия:**

1. Для `normal` сделать отдельную patch-функцию `normalPreset(from baseline: BotRuntimePolicy)`.
2. Для `easy` сделать отдельную patch-функцию `easyPreset(from baseline: BotRuntimePolicy)`.
3. Внутри patch-функций менять только те поля, которые действительно отличаются от `hard`.
4. Удалить размазанные inline-override участки из `preset(for:)`.

**Результат:**

- дифф между difficulty становится коротким и читаемым;
- легче поддерживать эволюцию preset-ов.

### Шаг 5. Перенести `jokerPolicy` ближе к `TurnStrategy`

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotTuning.swift`
- usages в `BotTurnCardHeuristicsService`, `BotTurnCandidateRankingService`, `MoveUtilityComposer`

**Действия:**

1. Переместить projection `jokerPolicy` с уровня `BotTuning` на уровень `BotTuning.TurnStrategy`.
2. Обновить потребителей так, чтобы они брали `tuning.turnStrategy.jokerPolicy`.
3. Удалить верхнеуровневый computed property `BotTuning.jokerPolicy`.

**Результат:**

- projection живёт рядом с источником данных;
- `BotTuning` становится тоньше;
- уменьшается связность верхнего уровня модели.

### Шаг 6. Свести `BotTuning` presets к baseline + patch

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotTuning.swift`
- новые extension-файлы preset-сборки при необходимости

**Действия:**

1. Сделать `hard` базовым preset для `BotTuning`.
2. Собрать `normal` через patch к `hard`.
3. Собрать `easy` через patch к `hard`.
4. Убрать полное тройное дублирование инициализации `TurnStrategy`, `Bidding`, `TrumpSelection`, `Timing`.

**Результат:**

- один источник правды для общих коэффициентов;
- пресеты уровней сложности становятся компактными и предсказуемыми.

### Шаг 7. Выделить shared preset-блоки внутри `BotTuning`

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotTuning.swift`

**Действия:**

1. Вынести общий `TrumpSelection` baseline в отдельную static factory-функцию.
2. Вынести общий `Timing` baseline в отдельную static factory-функцию.
3. Вынести shared parts `TurnStrategy` и `Bidding` в baseline builder-функции.
4. Оставить в difficulty patch-функциях только отличающиеся значения.

**Результат:**

- уменьшается объём literal-инициализации;
- пропадает скрытое дублирование одинаковых значений.

### Шаг 8. Стабилизировать внешний API `BotTuning`

**Файлы:**

- `Jocker/Jocker/Models/Bot/BotTuning.swift`
- сервисы, создающие `BotTuning`

**Действия:**

1. Оставить инициализацию `BotTuning(difficulty:)` без изменения сигнатуры.
2. Оставить структуру публичных top-level полей:
   - `turnStrategy`
   - `bidding`
   - `trumpSelection`
   - `runtimePolicy`
   - `timing`
3. Не менять контракт `BotRuntimePolicy.preset(for:)`.

**Результат:**

- refactor не разносит каскад правок по сервисам и UI-коду;
- меняется внутренняя организация, а не внешний способ потребления.

### Шаг 9. Синхронизировать training tooling с новой формой моделей

**Файлы:**

- `scripts/train_bot_tuning.sh`
- при необходимости training runner Swift code inside script

**Действия:**

1. Обновить доступ к `BotTuning.TrumpSelection` и другим preset-структурам под новую внутреннюю форму.
2. Убрать ручное дублирование shape-моделей там, где это возможно.
3. Проверить, что training runner снова компилируется после рефакторинга моделей.

**Результат:**

- модель и training tooling снова совпадают;
- очередное расширение `BotTuning` не ломает скрипт автоматически.

### Шаг 10. Добавить regression checks на уровень репозитория

**Файлы:**

- `Jocker/JockerTests/...`
- при необходимости `.github/workflows/ios-tests.yml`

**Действия:**

1. Добавить unit tests на preset equality для `BotRuntimePolicy` и `BotTuning`.
2. Добавить smoke-check на компиляцию training runner.
3. Добавить короткий self-play smoke run в локальный automation path.

**Результат:**

- структура конфигурации защищена от повторного расползания;
- изменения в этих моделях перестают быть “хрупкой зоной”.

---

## Порядок выполнения

Рефакторинг выполняется в следующем порядке:

1. тесты на текущие пресеты;
2. разбиение preset-кода `BotRuntimePolicy` по файлам;
3. перевод `BotRuntimePolicy.Bidding` на nested canonical storage;
4. выделение patch-функций для difficulty;
5. перенос `jokerPolicy` к `TurnStrategy`;
6. перевод preset-строительства `BotTuning` на baseline + patch;
7. выделение shared preset-блоков `BotTuning`;
8. стабилизация внешнего API;
9. синхронизация training tooling;
10. regression checks.

---

## Критерии завершения

Рефакторинг считается завершённым, когда выполнены все условия:

1. `BotRuntimePolicy.swift` больше не содержит гигантский monolithic baseline literal.
2. `BotRuntimePolicy.Bidding` хранит nested policy-структуры напрямую.
3. `BotTuning.preset(for:)` строится через baseline + patch, а не через три полноразмерных literal-блока.
4. `jokerPolicy` больше не живёт на верхнем уровне `BotTuning`.
5. training runner компилируется без ручных подгонок shape-модели после каждого изменения конфигурации.
6. preset-тесты проходят для `easy`, `normal`, `hard`.
7. runtime-поведение бота не меняется по regression tests.

---

## Неграницы текущей итерации

В этот рефакторинг не входят:

1. изменение числовых коэффициентов;
2. расширение self-play genome;
3. перенос `timing` за пределы `BotTuning`;
4. redesign AI services;
5. изменение gameplay логики.

---

## Ожидаемый эффект

После выполнения плана кодовая база должна получить:

1. более устойчивую модель конфигурации AI;
2. меньшую стоимость изменения preset-ов;
3. меньшее число ошибок из-за рассинхронизации модели и tooling;
4. более понятную базу для дальнейшего тюнинга и self-play обучения.
