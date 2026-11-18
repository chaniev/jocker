# Перенос процесса требований — 15.11.2026

Основание: запрос владельца в текущем чате перенести процесс обработки требований
из `/Users/muradchaniev/Documents/work/crm/` в Jocker.
Источник процесса: CRM AGENTS.md, backlog/AGENTS.md, docs/requirements,
codex-backlog-skill, tasks-ready-to-implementation и validate_requirements.py.

Перенесены 15 предложений. Первые 13 связаны с предложенными REQ, исследования
PROD-014/015 имеют pending. Причина needs-clarification для всех: нет evidence
продуктового принятия; дополнительные вопросы сохранены. Даже у PROD-002/010,
где вопросов о поведении нет, отсутствие одобрения не заменено предположением.
Реализация приложения не начата. Старые планы docs/ остаются историческими
материалами и требуют актуализации при возобновлении, а не фиктивной миграции.

| Старый путь | Новый путь |
|---|---|
| `backlog/PROD-001-save-and-resume.md` | [backlog/needs-clarification/PROD-001-save-and-resume.md](../../backlog/needs-clarification/JCR-001-save-and-resume.md) |
| `backlog/PROD-002-protect-hidden-cards.md` | [backlog/needs-clarification/PROD-002-protect-hidden-cards.md](../../backlog/needs-clarification/JCR-002-protect-hidden-cards.md) |
| `backlog/PROD-003-clear-first-start.md` | [backlog/needs-clarification/PROD-003-clear-first-start.md](../../backlog/needs-clarification/JCR-003-clear-first-start.md) |
| `backlog/PROD-004-gameplay-feedback.md` | [backlog/needs-clarification/PROD-004-gameplay-feedback.md](../../backlog/needs-clarification/JCR-004-gameplay-feedback.md) |
| `backlog/PROD-005-deal-review.md` | [backlog/needs-clarification/PROD-005-deal-review.md](../../backlog/needs-clarification/JCR-005-deal-review.md) |
| `backlog/PROD-006-short-training.md` | [backlog/needs-clarification/PROD-006-short-training.md](../../backlog/needs-clarification/JCR-006-short-training.md) |
| `backlog/PROD-007-personal-progress.md` | [backlog/needs-clarification/PROD-007-personal-progress.md](../../backlog/needs-clarification/JCR-007-personal-progress.md) |
| `backlog/PROD-008-private-friends-game.md` | [backlog/needs-clarification/PROD-008-private-friends-game.md](../../backlog/needs-clarification/JCR-008-private-friends-game.md) |
| `backlog/PROD-009-repeat-game.md` | [backlog/needs-clarification/PROD-009-repeat-game.md](../../backlog/needs-clarification/JCR-009-repeat-game.md) |
| `backlog/PROD-010-score-table-back-button.md` | [backlog/needs-clarification/PROD-010-score-table-back-button.md](../../backlog/needs-clarification/JCR-010-score-table-back-button.md) |
| `backlog/PROD-011-pairs-partner-visibility.md` | [backlog/needs-clarification/PROD-011-pairs-partner-visibility.md](../../backlog/needs-clarification/JCR-011-pairs-partner-visibility.md) |
| `backlog/PROD-012-animation-pace.md` | [backlog/needs-clarification/PROD-012-animation-pace.md](../../backlog/needs-clarification/JCR-012-animation-pace.md) |
| `backlog/PROD-013-small-screen-readability.md` | [backlog/needs-clarification/PROD-013-small-screen-readability.md](../../backlog/needs-clarification/JCR-013-small-screen-readability.md) |
| `backlog/PROD-014-player-pilot.md` | [backlog/needs-clarification/PROD-014-player-pilot.md](../../backlog/needs-clarification/JCR-014-player-pilot.md) |
| `backlog/PROD-015-monetization-validation.md` | [backlog/needs-clarification/PROD-015-monetization-validation.md](../../backlog/needs-clarification/JCR-015-monetization-validation.md) |

## Проверка переноса — 16.11.2026

- `make harness-verify BASE=origin/main`: passed; полный XCTest и training smoke прошли.
- 55 тестов проверяющих скриптов: passed, включая 14 сценариев требований и статусов.
- Четыре новых/изменённых набора инструкций проверены quick_validate: valid.
- Все 15 исходных текстов карточек сверены с origin/main: содержание сохранено;
  изменены metadata, относительные ссылки и добавлено состояние переноса.
- Отчёт проверки: `.derivedData/harness-runs/20261115-210439-ceffccd2/summary.json`
  в рабочей копии `jocker-worktrees/requirements-workflow`.
- Последующая правка только документации уточняет каталог возможностей и
  самостоятельность нормативного текста принятого REQ; проверяется отдельно.

## Переименование задач — 16.11.2026

Основание: явный запрос владельца заменить PROD на JCR, включая описание процесса.
С этого момента используются JCR-001–JCR-015. Номера, содержание и статусы
сохранены; ссылки в исторической таблице выше направлены на новые имена файлов.
Старые обозначения в её тексте описывают состояние до переименования.

| Было | Стало |
|---|---|
| `PROD-001` | [JCR-001](../needs-clarification/JCR-001-save-and-resume.md) |
| `PROD-002` | [JCR-002](../needs-clarification/JCR-002-protect-hidden-cards.md) |
| `PROD-003` | [JCR-003](../needs-clarification/JCR-003-clear-first-start.md) |
| `PROD-004` | [JCR-004](../needs-clarification/JCR-004-gameplay-feedback.md) |
| `PROD-005` | [JCR-005](../needs-clarification/JCR-005-deal-review.md) |
| `PROD-006` | [JCR-006](../needs-clarification/JCR-006-short-training.md) |
| `PROD-007` | [JCR-007](../needs-clarification/JCR-007-personal-progress.md) |
| `PROD-008` | [JCR-008](../needs-clarification/JCR-008-private-friends-game.md) |
| `PROD-009` | [JCR-009](../needs-clarification/JCR-009-repeat-game.md) |
| `PROD-010` | [JCR-010](../needs-clarification/JCR-010-score-table-back-button.md) |
| `PROD-011` | [JCR-011](../needs-clarification/JCR-011-pairs-partner-visibility.md) |
| `PROD-012` | [JCR-012](../needs-clarification/JCR-012-animation-pace.md) |
| `PROD-013` | [JCR-013](../needs-clarification/JCR-013-small-screen-readability.md) |
| `PROD-014` | [JCR-014](../needs-clarification/JCR-014-player-pilot.md) |
| `PROD-015` | [JCR-015](../needs-clarification/JCR-015-monetization-validation.md) |

## Продуктовое уточнение JCR-001 — 16.11.2026

По ответам владельца продукта на вопросы 1–8 в текущем чате принят
REQ-SAVE-001. Карточка JCR-001 перенесена из `needs-clarification` в
`tasks-ready`; актуальная ссылка — [JCR-001](../tasks-ready/JCR-001-save-and-resume.md).
Пути в предыдущих записях отражают расположение на момент тех событий.
Согласованы продолжение с последнего действия, по одному сохранению на
каждый из трёх вариантов игры, выбор продолжения/новой игры после выбора
варианта, удаление заменяемой партии без статистики и истории, сообщения
при потере прогресса, сохранность при обновлении и отсутствие сохранения
успешно завершённой партии. Дополнительное описание сохранения не требуется.
Реализация не начата; задача готова к техническому планированию.

## Планирование JCR-001 — 16.11.2026

По запросу владельца «составь план реалиазции» создан
[план JCR-001](../implementation-plans/JCR-001-save-and-resume.plan.md) и
[ADR-0001](../../docs/architecture/adr/0001-durable-game-session-persistence.md).
Проверены доменные курсоры, состояние в узлах/closures, фиксация финала,
автоматические экспорты и миграция статистики. Предложенная файловая стратегия
требует явного исключения из правила UserDefaults; исходный статус ADR —
`Proposed`, плана — `readiness: no`. Продуктовые ответы 1–8 не изменены.
Приложение и тесты не редактировались, реализация не запускалась.

При ревью плана дополнены восстановимое удаление материалов партии, единый
writer статистики и повторное подключение модального выбора после фона.
Отдельно запрошено поведение при ошибке автосохранения во время обычного хода;
ответ 4 относился только к уже выбранному выходу. До ответа по этому сценарию
и ADR-0001 карточка возвращена в `needs-clarification`; актуальная ссылка —
[JCR-001](../needs-clarification/JCR-001-save-and-resume.md).
REQ-SAVE-001 и первоначальные восемь ответов остаются принятыми.

## Принятие плана JCR-001 — 16.11.2026

Получены ответы владельца в текущем чате: «Да, подтверждаю предложенный способ
хранения» и «если во время обычного хода сохранение не удается то ничего делаем».
ADR-0001 принят; исключение для файлового хранения сессий и канонической
статистики добавлено в корневой AGENTS. Настройки остаются в UserDefaults.
При ошибке автосохранения обычного хода игра продолжается без сообщения,
диалога, дополнительной паузы, отката или выхода. Следующая штатная запись
содержит актуальное состояние; до успеха восстановим только последний целый
checkpoint. Сценарий ошибки при явно выбранном выходе сохранён.
Обновлены REQ-SAVE-001, план и критерии приёмки. Карточка снова в `tasks-ready`:
[JCR-001](../tasks-ready/JCR-001-save-and-resume.md); план — `readiness: yes`,
открытых вопросов нет. Реализация приложения не запускалась.
