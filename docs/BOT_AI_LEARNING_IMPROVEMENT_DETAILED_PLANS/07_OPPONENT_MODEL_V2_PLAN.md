# Детальный план 07. Opponent model v2 поверх существующего MVP

**Источник:** `docs/BOT_AI_LEARNING_IMPROVEMENT_PROPOSALS.md`, пункт 4.7 / приоритет P2  
**Порядок выполнения:** 7  
**Предусловия:** завершены этапы 03 и 04

## Цель

Расширить opponent model до версии 2, добавив match-level память, confidence-gating и отдельные сигналы для joker/premium-стиля соперников, и встроить эти сигналы в каноническую opponent-modeling policy.

## Шаги выполнения

### 1. Расширить модель наблюдений

1. В `BotOpponentModel.swift` разделить наблюдения на:
   - `currentBlockObservations`
   - `currentMatchObservations`
2. Добавить в модель следующие сигналы:
   - joker usage style;
   - premium deny tendency;
   - premium save tendency;
   - aggression score;
   - volatility score;
   - confidence score.
3. Для каждого сигнала задать нейтральное состояние по умолчанию.
4. Добавить unit tests на нейтральное состояние новой модели.

### 2. Расширить сбор наблюдений

1. В `BotMatchContextBuilder.swift` собирать block-level и match-level наблюдения отдельно.
2. Накопление match-level наблюдений вести в рамках одного матча.
3. Block-level наблюдения делать приоритетными над match-level при достаточном количестве данных.
4. Обновить источники истории и runtime context так, чтобы builder получал все новые сигналы.

### 3. Канонизировать opponent-modeling policy

1. В секции `opponentModeling` добавить явные поля для:
   - confidence thresholds;
   - memory weights;
   - joker-style pressure;
   - premium-style pressure;
   - volatility damping.
2. Подключить эти поля к `hard` baseline.
3. Подключить difficulty patch-функции к новым полям.
4. Оставить все thresholds и weights внутри одной policy-секции.

### 4. Подключить v2-сигналы к `OpponentPressureAdjuster`

1. Применять joker-style pressure только при confidence выше порога.
2. Применять premium deny/save pressure только при confidence выше порога.
3. Ослаблять pressure для high-volatility opponents.
4. Сохранять нейтральное поведение при отсутствии достаточных наблюдений.
5. Добавить service-level tests на каждую ветку применения.

### 5. Добавить scenario-based validation для opponent archetypes

1. Сформировать отдельные scenario families для:
   - агрессивного соперника;
   - хаотичного соперника;
   - premium-deny соперника;
   - premium-save соперника;
   - joker-heavy соперника.
2. Прогнать baseline и model v2 на каждом archetype.
3. Зафиксировать изменения в blind/joker/premium-related метриках.
4. Зафиксировать holdout-эффект по archetype families.

### 6. Раскрыть opponent model v2 для обучения

1. Добавить в genome или patch-config коэффициенты для:
   - confidence thresholds;
   - memory weights;
   - opponent pressure scales.
2. Ограничить эти параметры bounds-механизмами этапа 03.
3. Подключить эти параметры к machine-readable summary.
4. Провести отдельный A/B compare baseline vs opponent-model-v2.

## Проверки

1. `BotOpponentModel` имеет нейтральное состояние по умолчанию.
2. Block-level и match-level сигналы собираются и используются раздельно.
3. `OpponentPressureAdjuster` применяет давление только при достаточной confidence.
4. Scenario-based validation показывает эффект на archetype families.
5. Новые policy-параметры сериализуются и видны в training summary.

## Критерии завершения

1. Opponent model хранит block-level и match-level память.
2. В model v2 есть confidence, aggression, volatility, joker-style и premium-style сигналы.
3. Все новые thresholds и weights живут в одной opponent-modeling policy-секции.
4. No-evidence path остаётся нейтральным.
5. Model v2 проходит archetype-based holdout validation.
