# Инструкции, навыки, агенты и harness Jocker

## Источники и применение

[AGENTS.md](../AGENTS.md) определяет владельцев правил, стек, хранение данных,
проверки и локальную интеграцию. [Спецификация структуры](../FOLDER_STRUCTURE_SPEC.md)
определяет размещение файлов. Этот документ — каталог и описание устройства
harness; он не вводит второй набор общих правил.

Выбирать навыки по затронутой области. Профили описывают ответственность при
разрешённом делегировании; наличие профиля не требует запускать отдельного агента
для каждой задачи. Для небольшой задачи достаточно исполнителя с нужными навыками.

- Продуктовая постановка и статусы: [бэклог](../backlog/README.md) и [реестр требований](requirements/README.md).
- Игровой контракт: [правила игры](../правила%20игры/); технические решения: [принятые ADR](architecture/adr/README.md).
- Редакторские точки входа: [Swift](../.cursor/rules/swift.mdc) и [размещение файлов](../.cursor/rules/file.mdc).
- Исторические планы в docs/ используются по правилам возобновления из корневого AGENTS.md.

## Каталог

Раздел между маркерами формируется из `name`/`description` в SKILL.md и профилях
агентов. После изменения метаданных выполнить:

```sh
python3 scripts/harness/instructions.py catalog --write
```

<!-- instruction-catalog:start -->

Навыки: 16. Агенты: 9.

| Навык | Когда использовать |
|---|---|
| [architecture-decision](../.agents/skills/architecture-decision/SKILL.md) | Evaluate and record a significant Jocker technical or architectural choice as an ADR when alternatives affect boundaries, contracts, data, runtime, or long-term reversibility. Do not use for product decisions or routine local implementation choices. |
| [autoresearch-chatgpt](../.agents/skills/autoresearch-chatgpt/SKILL.md) | Benchmark and improve an attached ChatGPT or Codex skill through bounded, isolated trials, binary evals, one-change prompt mutations, and holdout validation. Use when the user asks to optimize, benchmark, evaluate, stress-test, or systematically improve a SKILL.md or skill bundle. Produce an improved candidate without overwriting the source, plus eval definitions, trial results, and a mutation log. |
| [bot-ai-conventions](../.agents/skills/bot-ai-conventions/SKILL.md) | Use for any change to bot intelligence in the app target — BotRuntimePolicy, BotTuning, difficulty presets, turn-candidate ranking, opponent modeling, and pairs-mode cooperation under Models/Bot/. Also use when touching the JockerSelfPlayTools evolution sources or their target boundary. |
| [bot-training-pipeline](../.agents/skills/bot-training-pipeline/SKILL.md) | Use for self-play training runs, tuning replacement, and training-side validation — canonical Makefile profiles (bt, train-bot-final, esab variants), ensembles, early stopping, A/B holdout, baseline snapshots, scope validation, and parallel benchmarks. Use before starting or resuming training, and before accepting any new BotTuning values. |
| [codex-backlog-skill](../.agents/skills/codex-backlog-skill/SKILL.md) | Разобрать входящие заметки в задачи Jocker или сверить статусы выбранных задач с подтверждённой реализацией. Использовать по запросу triage или сверки бэклога; не запускает реализацию. |
| [folder-structure](../.agents/skills/folder-structure/SKILL.md) | Use before any structural change — adding, moving, or renaming files and directories in the Jocker repository — and after it, to keep FOLDER_STRUCTURE_SPEC.md authoritative. Covers the one-type-per-file rule, source-to-test placement mapping, target boundaries, and artifact locations. |
| [implement-release-plan](../.agents/skills/implement-release-plan/SKILL.md) | Реализовать один или несколько implementation plans до проверенной локальной интеграции в основную ветку; при явном запросе дополнительно выполнить прогон CI. Использовать для полного исполнения готовых планов (например, docs/PAIRS_MODE_IMPLEMENTATION_PLAN.md), координации зависимого набора, локального merge, актуализации планов и безопасной очистки task-ресурсов. |
| [ios-hig-audit](../.agents/skills/ios-hig-audit/SKILL.md) | Use only when an independent compliance audit of an implemented Jocker interface is explicitly requested — Apple HIG alignment, accessibility, Dynamic Type, dark mode, touch targets, and interaction consistency. Reports findings without redesigning the game flow or overriding joker-game-ui. |
| [joker-game-rules](../.agents/skills/joker-game-rules/SKILL.md) | Use for any change to Joker game behavior — dealing, bidding, trump and joker mechanics, trick play, scoring, premiums, block/match structure, or the pairs mode. Treats the texts in 'правила игры/' as the source of truth and reconciles code against them. Use before implementing, reviewing, or testing gameplay changes in Models/, Scoring/, or gameplay flow. |
| [joker-game-ui](../.agents/skills/joker-game-ui/SKILL.md) | Design, implement, review, or test Joker screens and gameplay presentation for players — bidding, trick play, results, statistics, and the pairs mode UI on UIKit + SpriteKit. Use for new screens, flow redesigns, interaction states, visual quality, and player-facing acceptance. Preserve rules-core ownership and complete every screen state before polish. |
| [product-plan-clarification](../.agents/skills/product-plan-clarification/SKILL.md) | Выявлять продуктовые пробелы в уже сформированной задаче и формировать приоритетные вопросы для уточнения ожидаемого поведения, ценности и границ продукта. Использовать после создания задачи, до подготовки implementation plan, технического ревью или начала реализации. |
| [regression-packs](../.agents/skills/regression-packs/SKILL.md) | Use when running, extending, or creating Jocker regression packs — targeted xcodebuild test sets for JOKER rules behavior, phase guardrails, and ranking guardrails. Covers pack selection by changed area, -list/-dry inspection, adding tests to a pack, and artifact expectations. |
| [spritekit-uikit-best-practices](../.agents/skills/spritekit-uikit-best-practices/SKILL.md) | Use when implementing, reviewing, or refactoring Jocker app sources to follow the verified stack conventions — UIKit + SpriteKit without SwiftUI/Combine/async-await, value-type services, protocol-based testability, explicit self., one type per file. Derives behavior from root AGENTS.md and FOLDER_STRUCTURE_SPEC.md; use for mechanics and structure, not for game rules or UX design. |
| [task-worktree](../.agents/skills/task-worktree/SKILL.md) | Create, resume, verify, and safely clean up isolated Git worktrees for Joker implementation tasks. Use before starting or resuming any task that changes project code, when several tasks must run in parallel, when an implementation plan declares a branch, or when a merged task workspace must be removed. |
| [tasks-ready-to-implementation](../.agents/skills/tasks-ready-to-implementation/SKILL.md) | Подготовить проверяемые implementation plans для выбранных задач Jocker и, при явном запросе начать работу, перевести готовые задачи в implementation. Использовать после продуктового уточнения, до реализации. |
| [xctest-practices](../.agents/skills/xctest-practices/SKILL.md) | Use when creating, reviewing, or substantially restructuring XCTest tests in JockerTests or JockerUITests — test placement, deterministic setup, targeted execution with -only-testing, artifact locations, and assertion quality. Derives behavior expectations from game rules and existing contracts, not from generic examples. |

| Профиль агента | Когда использовать |
|---|---|
| [bot-ai-specialist](../.codex/agents/bot-ai-specialist.toml) | Use for in-app bot intelligence: BotRuntimePolicy, BotTuning, difficulty presets, turn-candidate ranking, opponent modeling, and bot cooperation in pairs mode under Models/Bot/. |
| [bot-training-specialist](../.codex/agents/bot-training-specialist.toml) | Use for self-play training and validation work: the JockerSelfPlayTools CLI, train_bot_tuning.sh profiles, ensembles, early stopping, A/B holdout validation, baseline snapshots, and benchmark runs. |
| [game-rules-specialist](../.codex/agents/game-rules-specialist.toml) | Use for changes to Joker game rules, dealing, trump and joker handling, scoring, premiums, and gameplay modes. Owns the domain core under Models/, Scoring/, and the rules sources in 'правила игры/'. |
| [game-ux-researcher](../.codex/agents/game-ux-researcher.toml) | Use when a task needs analysis of a Joker game flow as a player experience: friction, unnecessary actions, unclear feedback, and information architecture. Produces a UX contract for designers and implementers; does not implement. |
| [refactoring-specialist](../.codex/agents/refactoring-specialist.toml) | Use when a task needs a low-risk structural refactor that preserves behavior while improving readability, modularity, or maintainability. |
| [spritekit-gameplay-specialist](../.codex/agents/spritekit-gameplay-specialist.toml) | Use for SpriteKit gameplay client work: game scenes, nodes, animations, gestures, the table presentation layer, and the coordinator/services plumbing under Game/. |
| [test-automator](../.codex/agents/test-automator.toml) | Use when a task needs implementation of automated tests, regression pack improvements, or targeted regression coverage in JockerTests/JockerUITests. |
| [uikit-flow-specialist](../.codex/agents/uikit-flow-specialist.toml) | Use for UIKit screen and navigation work under ViewControllers/ (Bidding, GameFlow, Results, Statistics, Common), including screen states, accessibility, and implement-ready UI specifications. |
| [xcode-ci-specialist](../.codex/agents/xcode-ci-specialist.toml) | Use for Xcode project and CI work: target boundaries, project.pbxproj, shared schemes, simulator destinations, DerivedData layout, Makefile wrappers, and the GitHub Actions workflow. |

<!-- instruction-catalog:end -->

## Проверка инструкций

[Проверка](../scripts/harness/instructions.py) входит в обязательный harness.
Она проверяет наличие входных документов, метаданные навыков и профилей,
известные утвердительные рекомендации несовместимого стека, существование
локальных Markdown-ссылок и явных ссылок на инструкции, соответствие каталога
текущим метаданным. Проверяются AGENTS.md, навыки и их Markdown-ресурсы,
профили агентов и правила Cursor; `.derivedData/` и `.git/` исключены.

В спецификации структуры конкретные пути в обратных кавычках начинаются с `./`:
они считаются от корня репозитория. Завершающий `/` требует каталог, остальные
пути — файл; glob должен находить хотя бы один объект нужного вида. Переименование
или удаление последнего подходящего файла делает проверку красной. Пути с
`<placeholders>` и fenced-примеры не утверждают существование; очереди бэклога
и каталоги результатов могут создаваться позже. Выход за пределы репозитория
отклоняется. Список путей берётся из самой спецификации, второго реестра нет;
полнота описания и смысл размещения остаются предметом review.

Файловые ссылки проверяются без проверки якорей и внешних URL. Шаблоны внутри
Markdown code fences исключены. Профили используют существующий простой формат
TOML: строковые поля и многострочный developer_instructions; иной формат требует
явного расширения проверяющего кода. Проверка известных формулировок не является
семантическим анализом: согласованность продуктовых решений проверяется по источникам.

## Harness: текущий контракт, schemaVersion=2

Команды и обязательное покрытие определяет [AGENTS.md](../AGENTS.md),
маршрутизацию — [checks.json](../scripts/harness/checks.json),
исполнение — [verify.py](../scripts/harness/verify.py).

### Выбор и исполнение

`make harness-plan BASE=origin/main` показывает requestedChecks и исполняемый plan. `planning.py` получает актуальные selectors из `--list` существующих pack-скриптов: второго вручную поддерживаемого списка тестов нет. Выборки объединяются; selector класса покрывает selectors его методов. Выполняется ровно одна команда XCTest: полный suite при выборе full-tests, иначе `run_all_tests.sh --only-testing <selector>` с объединённой выборкой. Полный CI suite сохраняется.

Для каждого выбранного пакета остаётся отдельный `<pack>-contract`: запуск его `--dry-run`. План хранит packSelectors, covers, selectionCountBeforeUnion и selectorsAfterUnion. Исключённые test targets/SelectedTests/SkippedTests в shared scheme блокируют допущение о полном покрытии. После прогона selectors сверяются с реально выполненными тестами из xcresult; отсутствующая выборка, нулевой прогон или дубли не дают зелёный статус. Команды других проверок не поглощаются XCTest.

### Окружение

`make harness-doctor DESTINATION='platform=iOS Simulator'` создаёт отдельный JSON-отчёт. Перед дорогими проверками doctor вызывается автоматически. Он проверяет Xcode/Swift, shared scheme, наличие структурированного xcresulttool API (Xcode 16+), список доступных runtime/device и допустимые destinations схемы. Затем фиксирует конкретный UUID и ожидает готовности симулятора. Общий destination выбирает актуальную доступную версию iOS, предпочитая iPhone; явно заданные id/name/OS не подменяются другим устройством.

При ошибке doctor запись имеет status=blocked, пробы с кодами завершения и диагностикой сохранены, сборка и XCTest не запускаются. Документационные проверки не требуют симулятора. Doctor не гарантирует отсутствие более поздних ошибок установки/запуска приложения; они остаются ошибками соответствующего прогона.

### Отчёт и измерения

schemaVersion=2 добавляет requestedDestination, environment (resolvedDestination/device/версии/пробы), plan и requestedChecks. У каждой завершённой проверки есть startedAt, finishedAt, durationSeconds, command (для subprocess), exitCode и log. Общая durationSeconds включает подготовку и чтение результатов.

У XCTest есть testResults: total/passed/failed/skipped/expectedFailures, resultBundle, tests (identifier/status/durationSeconds при наличии в Xcode), failures (identifier/message), missingSelectors и duplicateTests. Число упавших тестов отличается от числа assertions: несколько сообщений могут относиться к одному тесту. Исходный JSON xcresulttool сохраняется рядом с bundle. При отсутствии достоверного результата успешный exit code не превращается в passed. Сборочные ошибки и провалы тестов не маскируются. Сверка source fingerprint до/после исполнения сохраняется.


### Дополнительные механизмы

- Локальные группы Results, Statistics, History и Settings обнаруживают классы XCTest в исходниках. Смешанные изменения объединяют группы и пакеты; неизвестные пути и CI сохраняют полный набор. Пустая группа блокирует план.
- Изменение только FOLDER_STRUCTURE_SPEC.md выбирает базовые проверки документации; добавление спецификации к изменению исходников не расширяет их XCTest-выборку. Изменение инструментов harness по-прежнему требует полного прогона.
- `target-membership` сверяет Swift-файлы с Sources build phases, выявляет отсутствующее/запрещённое членство, дубли и зависимость приложения от тренировочной библиотеки. `main.swift` CLI компилирует shell entrypoint; Xcode tools target является статической библиотекой.
- Doctor допускает до 180 секунд на холодную подготовку CoreSimulator. Ошибки подготовки и дочерних проверок попадают в CI annotations.
- Отчёты и вложенные артефакты сохраняются в `.derivedData/harness-runs/<run-id>/`. CI хранит опубликованные артефакты 14 дней; лимит проверки — 35 минут при лимите workflow 45 минут, локальный лимит — 30 минут.
- Кеш standalone training runner расположен в `.derivedData/dev-tools/bot-training/<fingerprint>/`. Ключ учитывает содержимое исходников, compiler/SDK, флаги и влияющие переменные окружения. Бинарник проверяется по SHA-256, параллельные сборки сериализуются, публикация атомарна. Его наличие не запускает обучение.

## История

Первый этап harness ввёл выбор проверок по diff и версионированный JSON-отчёт.
Второй объединил XCTest-выборки, добавил doctor и чтение xcresult. В ноябре 2026
добавлены модульные группы, проверка target membership, кеш runner и реестр
требований. 18.11.2026 каталог переведён на генерацию из метаданных, а проверка
инструкций расширена. Подробности прежних редакций сохраняются в истории Git;
действующие правила находятся в источниках, перечисленных выше.
