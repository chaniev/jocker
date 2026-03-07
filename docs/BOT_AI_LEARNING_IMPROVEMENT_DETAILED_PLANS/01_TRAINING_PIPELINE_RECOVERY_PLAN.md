# Детальный план 01. Восстановление корректности training pipeline

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.1 / приоритет P0  
**Порядок выполнения:** 1  
**Предусловия:** отсутствуют

## Цель

Привести training pipeline в состояние, в котором:

- training runner компилируется против актуальной формы `BotTuning` и `BotRuntimePolicy`;
- baseline evaluation выполняется отдельным режимом без generation loop;
- shell-скрипты больше не дублируют форму Swift-моделей;
- `Makefile`, baseline harness и compare harness используют один и тот же канонический путь запуска;
- минимальные проверки pipeline выполняются автоматически.

## Шаги выполнения

### 1. Зафиксировать текущее поведение конфигурации тестами

1. Добавить unit tests на `BotRuntimePolicy.preset(for: .easy/.normal/.hard)`.
2. Добавить unit tests на `BotTuning(difficulty: .easy/.normal/.hard)`.
3. Зафиксировать в тестах значения для `ranking`, `bidding`, `rollout`, `heuristics`, `opponentModeling`, `turnStrategy`, `trumpSelection`, `timing`.
4. Зафиксировать в тестах, что joker-настройки читаются из `turnStrategy`, а не из отдельной верхнеуровневой проекции.

### 2. Стабилизировать канонический контракт конфигурации для training tooling

1. Оставить единственными публичными точками входа для training runner:
   - `BotRuntimePolicy.preset(for:)`
   - `BotTuning(difficulty:)`
2. Перевести `BotRuntimePolicy.Bidding` на хранимые nested-структуры:
   - `bidSelection`
   - `blindPolicy`
   - `blindMonteCarlo`
3. Удалить из модели дублирующие scalar-поля и projection-код, который пересобирает `Bidding` из разрозненных значений.
4. Перенести joker-policy на уровень `BotTuning.TurnStrategy` и удалить верхнеуровневую проекцию.
5. Собрать пресеты `BotRuntimePolicy` по секциям и оставить в основном файле только типы, `preset(for:)` и patch-логику difficulty.
6. Собрать пресеты `BotTuning` через `hard` baseline и patch-функции для `normal` и `easy`.
7. Оставить внешний API `BotTuning` неизменным: `turnStrategy`, `bidding`, `trumpSelection`, `runtimePolicy`, `timing`.

### 3. Вынести training runner в checked-in Swift entrypoint

1. Создать checked-in runner в границах `JockerSelfPlayTools`.
2. Перенести в Swift-код запуск self-play, baseline evaluation, generation loop, агрегацию результатов и печать summary.
3. Оставить в `scripts/train_bot_tuning.sh` только orchestration: разбор аргументов, вызов runner, подготовку каталогов артефактов и сохранение логов.
4. Полностью удалить генерацию `main.swift` через heredoc.

### 4. Ввести явный baseline-only режим

1. Добавить в `BotSelfPlayEvolutionEngine+PublicTypes.swift` явный режим запуска `baselineOnly`.
2. Реализовать в `BotSelfPlayEvolutionEngine+Evolution.swift` отдельный путь `evaluateBaseline`, который:
   - не создаёт популяцию;
   - не выполняет mutation и crossover;
   - не заходит в generation loop;
   - печатает summary c `generationCount = 0`.
3. Удалить семантику baseline-only через `--generations 0`.
4. Оставить `generations` только как число поколений эволюции.

### 5. Починить агрегацию tuning values

1. Переписать `aggregateTunings()` так, чтобы агрегация шла по канонической структуре `BotTuning`.
2. Агрегировать `BotTuning.TrumpSelection` по актуальным полям модели.
3. Агрегировать runtime policy через секционные builders и patch-функции, а не через длинные literal-инициализаторы.
4. Удалить из training code прямое знание внутренней формы старых scalar-полей.

### 6. Пересобрать baseline и compare harness

1. Обновить `scripts/run_bot_baseline_snapshot.sh` так, чтобы он использовал только baseline-only режим.
2. Обновить `scripts/run_bot_ab_comparison_snapshot.sh` так, чтобы он использовал тот же runner contract и ту же baseline semantics.
3. Обновить summary baseline-run:
   - печатать режим `baselineOnly`;
   - печатать `generationCount = 0`;
   - не печатать mutation/crossover статистику.
4. Сохранить структуру артефактов прежней по каталогам, но привести содержимое к новой семантике.

### 7. Привести `Makefile` к одному каноническому пути обучения

1. Пометить все legacy training targets префиксом `legacy-`.
2. Оставить основным путём обучения full-match targets.
3. Назначить один основной training target и один основной final-validation target.
4. Привязать `make bot-baseline` и `make bot-compare` к обновлённым scripts без дублирования логики.

### 8. Добавить smoke и regression checks

1. Добавить smoke-проверку компиляции training runner.
2. Добавить короткий baseline-only self-play run.
3. Добавить короткий run на 1 поколение эволюции.
4. Добавить проверку, что baseline harness не выполняет generation loop.
5. Подключить эти проверки к локальному automation path и CI smoke path.

## Проверки

1. Unit tests на пресеты `BotRuntimePolicy` и `BotTuning` проходят.
2. Training runner компилируется без generated `main.swift`.
3. Baseline-only run завершает self-play без mutation и crossover.
4. Короткий evolutionary run на 1 поколение завершается и печатает корректный summary.
5. `make bot-baseline` и `make bot-compare` используют один и тот же runner contract.

## Критерии завершения

1. Training runner живёт в checked-in Swift-коде и не зависит от heredoc-генерации.
2. Baseline-only режим существует как отдельный контракт.
3. `BotTuning` и `BotRuntimePolicy` читаются training tooling только через канонический публичный API.
4. Baseline harness не запускает поколение эволюции.
5. `Makefile` ведёт в один канонический training workflow.
6. Smoke/regression checks ловят повторное расхождение tooling и моделей.
