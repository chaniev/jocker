# Документация карточной подсистемы

## Обзор

Карточная подсистема разделена на четыре уровня:

1. `Models/` — карточные сущности и правила сравнения.
2. `Game/Nodes/` — отрисовка, рука игрока, взятка и индикатор козыря.
3. `Game/Services/` и `Game/Coordinator/` — правила раунда/хода, анимации и оркестрация flow.
4. `Game/Scenes/GameScene.swift` + `GameScene+*.swift` — интеграция UI и сценариев раунда.

## Модели

### `Jocker/Jocker/Models/Card.swift`

- `Card` — `enum`:
  - `.regular(suit:rank:)`
  - `.joker`
- Логика сравнения:
  - `Card.beats(_:trump:)` — сравнение с учётом козыря и джокера.

### `Jocker/Jocker/Models/Suit.swift`

- `Suit` — масти.
- Включает:
  - порядок сортировки мастей;
  - локализованное имя масти;
  - цвет масти (`CardColor`).

### `Jocker/Jocker/Models/Rank.swift`

- `Rank` — ранги от шестерки до туза.
- Содержит:
  - символ ранга для UI;
  - локализованное имя ранга.

### `Jocker/Jocker/Models/CardColor.swift`

- `CardColor` — базовая классификация цвета масти (`red`/`black`).

### `Jocker/Jocker/Models/Deck.swift`

- Формирует колоду 36 карт (с 2 джокерами).
- `shuffle()`, `drawCard()`, `reset()`.
- `dealCards(playerCount:cardsPerPlayer:startingPlayerIndex:)`:
  - возвращает руки игроков;
  - возвращает верхнюю карту как потенциальный козырь.

### `Jocker/Jocker/Models/TrickTakingResolver.swift`

- Чистый алгоритм определения победителя взятки:
  - поддерживает `JokerLeadDeclaration` (`wish`, `above`, `takes`);
  - учитывает `JokerPlayStyle` (`faceUp`, `faceDown`);
  - для обычного хода: приоритет джокера лицом вверх, затем козыря, затем масти первого хода.

### `Jocker/Jocker/Models/JokerLeadDeclaration.swift`

- Объявление при первом ходе джокером:
  - `wish`
  - `above(suit:)`
  - `takes(suit:)`

### `Jocker/Jocker/Models/JokerPlayStyle.swift`

- Способ выкладывания джокера:
  - `faceUp`
  - `faceDown` (подпихивание)

### `Jocker/Jocker/Models/PlayedTrickCard.swift`

- Контейнер карты во взятке с контекстом розыгрыша джокера:
  - индекс игрока;
  - карта;
  - стиль выкладывания джокера;
  - объявление первого джокера.

### `Jocker/Jocker/Models/JokerPlayDecision.swift`

- Решение игрока для UI-выбора режима джокера:
  - `style` (`faceUp` или `faceDown`);
  - `leadDeclaration` для первого хода (`wish`, `above`, `takes`).

## Узлы SpriteKit

### `Jocker/Jocker/Game/Nodes/CardNode.swift`

- Визуальная карточная нода.
- Поддерживает:
  - лицо/рубашку;
  - переворот `flip(animated:)`;
  - подсветку `highlight(_:color:)`.
- Текущие размеры:
  - `cardWidth = 192`
  - `cardHeight = 288`

### `Jocker/Jocker/Game/Nodes/CardHandNode.swift`

- Хранит массивы `cards` и `cardNodes`.
- Операции:
  - добавление/удаление карт;
  - сортировка;
  - раскладка `arrangeCards(animated:)`;
  - переворот всех карт.

### `Jocker/Jocker/Game/Nodes/TrickNode.swift`

- Хранит карты текущей взятки (`playedCards`).
- Хранит контекст джокера для каждой карты (`PlayedTrickCard`).
- Проверяет валидность хода (`canPlayCard`).
- Учитывает режимы `wish/above/takes` для первого джокера.
- Очищает взятку анимацией (`clearTrick`).

### `Jocker/Jocker/Game/Nodes/TrumpIndicator.swift`

- Отдельный виджет отображения текущего козыря.
- `setTrumpCard(_:, animated:)` поддерживает `nil` (козырь не определён).

### `Jocker/Jocker/Game/Nodes/PlayerNode.swift`

- UI игрока: аватар, имя, ставка, взятки, рука.
- Важные методы:
  - `setBid`
  - `incrementTricks`
  - `resetForNewRound`
  - `highlight`

## Интеграция в сцену

### `Jocker/Jocker/Game/Scenes/GameScene.swift`

- Отвечает за UI-связку сцены:
  - обработку тапов;
  - размещение нод и обновление индикаторов;
  - вызовы coordinator для игрового flow.
- Для джокера запрашивает решение у `GameViewController` через callback и
  передаёт `JokerPlayDecision` в `TrickNode.playCard(...)`.
- Держит единые layout-метрики кнопок/индикаторов и обновляет UI через
  позиционные helper-методы (без дублирования «магических» чисел).

### `Jocker/Jocker/Game/Scenes/GameScene+DealingFlow.swift`

- Пайплайн раздачи: подготовка раунда, blind-этап перед раздачей (4-й блок),
  пошаговая раздача и переход к торгам.

### `Jocker/Jocker/Game/Scenes/GameScene+BiddingFlow.swift`

- Пайплайн торгов: порядок хода ставок, правила дилера по запрещённой ставке,
  синхронизация с `GameState` и переход в фазу розыгрыша.

### `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`

- Пайплайн розыгрыша: валидация хода, выбор карты ботом, резолв взятки,
  переходы между взятками/раундами.

### `Jocker/Jocker/Game/Scenes/GameScene+ModalFlow.swift`

- Единые точки показа модальных экранов (ставка, blind, выбор козыря, режим
  джокера) и сохранение статистики по завершённой игре.

### `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift`

- Координирует игровые сервисы и даёт `GameScene` единый API для:
  - подготовки/завершения раунда;
  - автохода;
  - анимации раздачи и резолва взятки.

### `Jocker/Jocker/Game/Services/GameRoundService.swift`

- Переходы между раундами и блоками.
- Запись результатов раунда в `ScoreManager`.

### `Jocker/Jocker/Game/Services/GameTurnService.swift`

- Выбор допустимой карты для автохода.
- Определение победителя взятки.

### `Jocker/Jocker/Game/Services/BotTurnStrategyService.swift`

- Эвристический выбор карты и режима розыгрыша джокера.
- Поддержка оффлайн-обучения через `BotTuning.evolveViaSelfPlay(...)`:
  - детерминированный self-play симулятор раундов;
  - эволюция коэффициентов (мутация + кроссовер);
  - возврат лучшего набора параметров и истории fitness по поколениям.

### `Jocker/Jocker/ViewControllers/JokerModeSelectionViewController.swift`

- Модальное окно выбора розыгрыша джокера:
  - первый ход: `хочу`, `выше`, `забирает` (+ выбор масти);
  - второй и последующие ходы: `лицом вверх` или `подпихнуть`.

### `Jocker/Jocker/Game/Services/GameAnimationService.swift`

- SKAction-анимации раздачи.
- Планирование/отмена отложенного резолва взятки.

## Технические заметки (актуально на 15.02.2026)

- `GameScene` использует универсальный поиск предка-ноды (`findAncestor`) для
  распознавания тапа по карте/игроку и устранения дублированного обхода дерева нод.
- Ставки/выбор козыря запускаются автоматически в flow после раздачи; отдельной
  кнопки вызова торгов в сцене нет.
- `TrickNode` содержит локальный helper проверки масти в руке (`hasSuit`) для
  единообразной валидации обязательных ходов.
- Таблица очков (`ScoreTableView`) форматирует итоговые значения через единый
  `NumberFormatter` (`ru_RU`) и применяет единый метод отрисовки summary-строк.
- `ScoreManager` использует общий путь расчёта базовых очков блока в текущем и
  финализированном состояниях, что упрощает сопровождение.

## Связанные файлы

- `README_CARDS.md` — краткое описание и быстрый старт.
- `XCODE_INTEGRATION.md` — запуск и проверка в Xcode.
