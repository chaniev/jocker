# AGENTS_SKILLS_HARNESS.md

## Назначение

Список скилов, профильных агентов и верификационного harness проекта Jocker,
сформированный по аналогии с CRM-репозиторием
(`docs/AGENT_ROUTING.md` + `docs/HARNESS.md`, `.agents/skills/`,
`.codex/agents/`, `scripts/harness/`).

Документ описывает целевое состояние: какие агенты и скилы заводить, куда
класть, когда использовать, и что уже существует в harness. Читать после:

1. корневого `AGENTS.md` (стек и команды);
2. `FOLDER_STRUCTURE_SPEC.md` (структура и размещение файлов).

## Карта соответствия CRM → Jocker

| CRM | Jocker | Комментарий |
|---|---|---|
| `dotnet-backend-specialist` | `game-rules-specialist` | Доменное ядро: вместо доменных сущностей и API — правила игры, скоринг, модели |
| `react-specialist` | `spritekit-gameplay-specialist` | Клиентский слой: вместо React-компонентов — SKScene/SKNode и игровой стол |
| `ui-designer` | `uikit-flow-specialist` | Implement-ready спецификация экранов: вместо Mantine — UIKit VC и навигация |
| `ux-researcher` | `game-ux-researcher` | UX-сценарий: вместо workflow CRM — потоки торгов, хода, результатов |
| `test-automator` | `test-automator` | XCTest + regression packs вместо Playwright + xUnit |
| `docker-expert` | `xcode-ci-specialist` | Инфраструктура: вместо Docker — Xcode-таргеты, схемы, симуляторы, GitHub Actions |
| `python-pro` | — | В Jocker нет Python-слоя; harness — bash + Swift CLI |
| `refactoring-specialist` | `refactoring-specialist` | Аналогичен CRM; питается `docs/CODE_REFACTORING_BACKLOG.md` |
| — | `bot-ai-specialist` | Специфика Jocker: runtime-логика ботов |
| — | `bot-training-specialist` | Специфика Jocker: self-play эволюция |
| `crm-mobile-first-ui` (skill) | `joker-game-ui` (skill) | Обязательный UI-скил на каждом клиентском этапе |
| `csharp-xunit` (skill) | `xctest-practices` (skill) | Механика тестов под стек проекта |
| `deploy-project` (skill) | — | Нет стенда деплоя; при выходе в App Store завести `app-store-release` |
| `codex-backlog-skill`, `tasks-ready-to-implementation` (skills) | — (пока) | Требуют backlog-структуру, которой в Jocker нет |

## Агенты

Расположение: `.codex/agents/<name>.toml` (формат как в CRM: `name`,
`description`, `model`, `model_reasoning_effort`, `sandbox_mode`,
`developer_instructions`). Все девять агентов созданы; использовать
routing ниже при делегировании задач.

### Выбор агента по типу задачи

| Тип задачи | Основной агент | Когда использовать |
|---|---|---|
| Правила игры: раздача, козырь, джокер, подсчёт очков, премии, режим «пара на пару», модели в `Models/` и `Scoring/` | `game-rules-specialist` | Когда задача затрагивает игровые правила или скоринг; сверка кода с `правила игры/*.txt` обязательна |
| `SKScene`, `SKNode`, игровой стол, анимации, жесты, `Game/Coordinator`, `Game/Services` | `spritekit-gameplay-specialist` | Геймплей-клиент и взаимодействие сцены с правилами |
| `ViewControllers/` (Bidding, GameFlow, Results, Statistics), экраны, навигация, accessibility | `uikit-flow-specialist` | Экранные флоу и представление, без изменения правил |
| Анализ игрового сценария: трение игрока, лишние действия, информационная архитектура экрана | `game-ux-researcher` | Перед новым экраном или существенной переработкой флоу; результат — UX-контракт |
| `BotRuntimePolicy`, `BotTuning`, пресеты сложности, ранжирование ходов (`Models/Bot/`) | `bot-ai-specialist` | Runtime-поведение ботов в приложении |
| `JockerSelfPlayTools`, `train_bot_tuning.sh`, ансамбли, baseline/A/B, guardrails-профили | `bot-training-specialist` | Обучение и валидация тюнинга ботов |
| XCTest (`JockerTests/`, `JockerUITests/`), regression packs, стабилизация CI-тестов | `test-automator` | Покрытие риском тестами, инфраструктура тестирования |
| Xcode-проект: таргеты, схемы, `project.pbxproj`, симуляторы, `.github/workflows/`, `Makefile` | `xcode-ci-specialist` | Сборка, границы таргетов, CI, окружение |
| Структурный рефакторинг без изменения поведения | `refactoring-specialist` | По `docs/CODE_REFACTORING_BACKLOG.md` и планам рефакторинга |

### Маршрутизация типовых сценариев

| Сценарий | Последовательность агентов | Skills |
|---|---|---|
| Новый режим игры (пример: «пара на пару») | `game-ux-researcher` → `game-rules-specialist` → `uikit-flow-specialist` + `spritekit-gameplay-specialist` → `bot-ai-specialist` → `test-automator` | Обязательно `joker-game-rules` и `joker-game-ui` |
| Изменение правила подсчёта очков / премии | `game-rules-specialist` → `test-automator` | `joker-game-rules`; проверка `make joker-pack` |
| Улучшение игрового AI бота | `bot-ai-specialist` → `bot-training-specialist` → `test-automator` | `bot-ai-conventions` + `bot-training-pipeline` |
| Обучение нового тюнинга ботов | `bot-training-specialist` | `bot-training-pipeline`; baseline + A/B до merge |
| Локальная визуальная правка экрана | `uikit-flow-specialist` → `spritekit-gameplay-specialist` | `joker-game-ui` |
| Рефакторинг модуля | `refactoring-specialist` → `test-automator` | `make run_all_tests.sh` до и после |
| Сборка/CI-инфраструктура | `xcode-ci-specialist` → `test-automator` | `xctest-practices` |

Правила границ ответственности:

- корневой `AGENTS.md` приоритетнее любого вложенного `AGENTS.md`;
- `spritekit-gameplay-specialist` и `uikit-flow-specialist` не меняют правила
  подсчёта и раздачи молча — только через `game-rules-specialist`;
- `game-rules-specialist` не трогает presentation-слой;
- `bot-training-specialist` не меняет runtime приложения: источники
  `JockerSelfPlayTools` не компилируются в app-таргет;
- `test-automator` проверяет завершение игрового сценария (итог счета,
  переход хода), а не только наличие элементов UI.

## Skills

Расположение: `.agents/skills/<name>/SKILL.md` (frontmatter `name` +
`description`, как в CRM). Все 14 скилов созданы: процессные — адаптированы
из CRM с перепривязкой к путям и командам jocker, проектные — написаны под
стек и правила этого репозитория.

### Процессные (адаптированы из CRM)

| Skill | Источник в CRM | Назначение |
|---|---|---|
| `task-worktree` | `.agents/skills/task-worktree/` | Изолированные worktree для задач; в Jocker без Docker-стека. Использовать перед любой задачей, меняющей код, и при параллельной работе |
| `architecture-decision` | `.agents/skills/architecture-decision/` | ADR для значимых решений (кандидаты: интеграция SLM по `docs/SLM_INTEGRATION_PROPOSAL.md`, рефакторинг `BotRuntimePolicy`). Не для продуктовых решений |
| `product-plan-clarification` | `.agents/skills/product-plan-clarification/` | Продуктовые пробелы и приоритетные вопросы до реализации (например, по `docs/PRODUCT_OWNER_REVIEW_RU.md`) |
| `implement-release-plan` | `.agents/skills/implement-release-plan/` | Реализация готовых implementation plans до проверенной интеграции в `main`; в Jocker release = merge + зелёный CI, без стенда |
| `autoresearch-chatgpt` | `.agents/skills/autoresearch-chatgpt/` | Мета-скил: бенчмарк и улучшение самих скилов. Переносится как есть |

### Проектные (созданы под jocker)

| Skill | Назначение |
|---|---|
| `joker-game-rules` | Правила игры как источник истины: сверка кода с `правила игры/*.txt` (козырь, джокер, `подсчет очков`, `присуждение премии`, `пара на пару`). Использовать для любой правки правил, скоринга, раздачи |
| `joker-game-ui` | Игровой UI на UIKit + SpriteKit: экраны и состояния (торги, ход, результаты, статистика), анимации стола, accessibility. Аналог `crm-mobile-first-ui` — обязателен на каждом клиентском этапе |
| `spritekit-uikit-best-practices` | Технические конвенции стека: SwiftUI/Combine/async-await запрещены, классы для SK-нод и VC, struct для моделей/сервисов, протоколы для тестируемости, explicit `self.`, `UserDefaults` для персистенции |
| `folder-structure` | Правила `FOLDER_STRUCTURE_SPEC.md`: one type per file, размещение app/test-кода, обновление спеки после структурных изменений |
| `bot-ai-conventions` | Границы `BotRuntimePolicy` + `BotTuning`, пресеты easy/normal/hard, запрет компиляции `JockerSelfPlayTools` в app, поведение ботов в режиме «пара на пару» (кооперация пар) |
| `bot-training-pipeline` | Канонический процесс обучения: `make bt` / `make train-bot-final`, профили smoke/balanced/battle, ансамбли по сидам, early stop + A/B holdout, обязательный baseline-snapshot и A/B-сравнение до замены тюнинга |
| `regression-packs` | Работа с guardrails-пакетами: `joker-pack`, `stage4-phase-pack`, `stage6b-pack` (+ `-list`/`-dry`), правила добавления новых тестов в пакеты |
| `xctest-practices` | Механика XCTest: зеркалирование структуры в `JockerTests/<feature>/`, `-only-testing`, артефакты в `.derivedData/test-runs/<timestamp>/`, deterministic-тесты без тайминговых хрупкостей |
| `ios-hig-audit` | Независимый аудит интерфейса по Apple HIG только по явному запросу; не перепроектирует игровой флоу и не подменяет `joker-game-ui` (аналог `web-design-guidelines`) |

### Отложенные (создать при появлении базы)

- `tasks-ready-to-implementation`, `codex-backlog-skill` — после заведения
  backlog-структуры (`backlog/implementation/`, `backlog/done/`);
- `app-store-release` — при подготовке к публикации (аналог
  `deploy-project`: без потери данных, с release notes);
- `design-first-ui-prompting` — адаптировать из CRM для генерации визуальных
  концепций игровых экранов.

## Harness

### Существующие компоненты

Канонические команды определены корневым `AGENTS.md` и `Makefile`;
`FOLDER_STRUCTURE_SPEC.md` (раздел Tooling & Documentation) — детальная спека.

| Компонент | Команда | Артефакты |
|---|---|---|
| Полный прогон тестов схемы | `bash scripts/run_all_tests.sh` | `.derivedData/test-runs/<ts>/` (лог, `.xcresult`, `summary.txt`) |
| Smoke тренировочного пайплайна | `make training-pipeline-smoke` | compile + baseline + evolution проверки |
| JOKER regression pack | `make joker-pack` / `joker-pack-all` | `.derivedData/joker-regression-runs/<ts>/` |
| Phase guardrails (Stage 4) | `make stage4-phase-pack` | `.derivedData/stage4-phase-runs/<ts>/` |
| Ranking guardrails (Stage 6b) | `make stage6b-pack` / `stage6b-pack-all` | `.derivedData/stage6b-ranking-runs/<ts>/` |
| Baseline-снапшот бота (Stage 0) | `make bot-baseline` | `.derivedData/bot-baseline-runs/<ts>/` |
| A/B сравнение тюнинга | `make bot-compare` | `.derivedData/bot-ab-runs/<ts>/` |
| Scope-валидация эволюции (Stage 3) | `make stage3-scope-validate` | `.derivedData/stage3-runtime-scope-runs/<ts>/` |
| Параллельный бенчмарк (Stage 5) | `make stage5-benchmark` | `.derivedData/stage5-parallel-benchmark/<ts>/` |
| Каноническое обучение | `make bt` / `make train-bot` | `.derivedData/bot-train-main.log` |
| Финальный ансамбль | `make train-bot-final` | `.derivedData/bot-train-final.log` |
| CI | `.github/workflows/ios-tests.yml` (macos-15) | `run_all_tests.sh` → `run_training_pipeline_smoke.sh`, upload артефактов (14 дней) |

Правила:

- все пакеты имеют режимы инспекции `make <pack>-list` / `make <pack>-dry` —
  проверять выборку перед прогоном;
- замена проверенного тюнинга ботов допускается только после
  baseline-снапшота и A/B-сравнения на holdout-сидах;
- `.derivedData/` gitignored и не должна содержать секретов.

### Пробелы относительно CRM и следующая ступень

| Пробел | Что сделать |
|---|---|
| Нет diff-aware входа (аналог `verify_change.py`): выбор проверок по изменённым путям | Добавить `scripts/harness/verify_change.sh|py`: правила вида «изменён `Scoring/` → joker-pack + scoring-тесты», «изменён `Models/Bot/` → stage-пакеты + baseline» |
| Нет машинно-читаемого evidence (JSON) и итогового merge-гейта | Писать JSON-отчёт прогона (команды, статусы, exit codes) в артефакты; при необходимости — агрегатор по образцу `aggregate_evidence.py` |
| Нет валидации инструкций (аналог `validate_agent_instructions.py`) | Актуальная проблема: вложенный `Jocker/Jocker/AGENTS.md` — шаблон про SwiftUI/MVVM/Combine/async-await и прямо противоречит корневому `AGENTS.md` (UIKit + SpriteKit, без SwiftUI). Заменить содержимое на актуальные правила стека или удалить файл |
| Нет unit-тестов на harness-скрипты | При росте числа правил diff-awareSelection покрыть их тестами по образцу `scripts/harness/tests/` в CRM |

## Принципы использования

1. По умолчанию задача маршрутизируется профильному агенту; нет профиля —
   выполняется локально с чтением корневого `AGENTS.md`.
2. `game-ux-researcher` определяет задачу и препятствия, но не подменяет
   `uikit-flow-specialist` / `spritekit-gameplay-specialist`.
3. Продуктовые решения (правила игры, режимы, баланс) не принимаются
   агентами молча — только через владеленные планы/ревью
   (`docs/PRODUCT_OWNER_REVIEW_RU.md`).
4. Любое структурное изменение сопровождается обновлением
   `FOLDER_STRUCTURE_SPEC.md`; этот документ — при изменении набора
   агентов/скилов/harness.
