# Карточная система Jocker

## Что реализовано

- Модель карты и колоды:
  - `Jocker/Jocker/Models/Card.swift`
  - `Jocker/Jocker/Models/Deck.swift`
- Розыгрыш взятки:
  - `Jocker/Jocker/Models/TrickTakingResolver.swift`
  - `Jocker/Jocker/Game/Nodes/TrickNode.swift`
- Визуализация карт и руки:
  - `Jocker/Jocker/Game/Nodes/CardNode.swift`
  - `Jocker/Jocker/Game/Nodes/CardHandNode.swift`
  - `Jocker/Jocker/Game/Nodes/TrumpIndicator.swift`
- Интеграция в игру:
  - `Jocker/Jocker/Game/Scenes/GameScene.swift`
  - `Jocker/Jocker/Game/Scenes/GameScene+DealingFlow.swift`
  - `Jocker/Jocker/Game/Scenes/GameScene+BiddingFlow.swift`
  - `Jocker/Jocker/Game/Scenes/GameScene+PlayingFlow.swift`
  - `Jocker/Jocker/Game/Scenes/GameScene+ModalFlow.swift`
  - `Jocker/Jocker/Game/Coordinator/GameSceneCoordinator.swift`
  - `Jocker/Jocker/Game/Services/GameRoundService.swift`
  - `Jocker/Jocker/Game/Services/GameTurnService.swift`
  - `Jocker/Jocker/Game/Services/GameAnimationService.swift`
  - `Jocker/Jocker/Game/Services/BotBiddingService.swift`
  - `Jocker/Jocker/Game/Services/BotTrumpSelectionService.swift`

## Проверка в приложении

1. Открыть `Jocker/Jocker.xcodeproj`.
2. Запустить схему `Jocker`.
3. На экране игры:
   - нажать `Раздать карты`;
   - пройти модальные шаги выбора (ставки/выбор козыря/режим джокера в нужных блоках);
   - разыграть карты;
   - проверить, что бот-ходы выполняются автоматически;
   - проверить `Очки`.

## Документация

- Подробно: `CARDS_DOCUMENTATION.md`
- Интеграция/Xcode: `XCODE_INTEGRATION.md`
- Правила: папка `правила игры/`
