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

## Проверка в приложении

1. Открыть `Jocker/Jocker.xcodeproj`.
2. Запустить схему `Jocker`.
3. На экране игры:
   - нажать `Раздать карты`;
   - открыть `Взятки` и задать ставки;
   - разыграть карты;
   - проверить `Очки`.

## Документация

- Подробно: `CARDS_DOCUMENTATION.md`
- Интеграция/Xcode: `XCODE_INTEGRATION.md`
- Правила: папка `правила игры/`
